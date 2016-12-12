module ioc.extendMethod;

import ioc.meta;
import ioc.logging;
import ioc.stdmeta;

template chooseOverload(overloads, T...){
    static assert (overloads.length > 0);
    static if (accepts!(overloads[0], T))
        alias chooseOverload = overloads[0];
    else
        alias chooseOverload = chooseOverload!(overloads[1..$], T);
}

template getTarget(Inter, string fooName, T...){
    alias overloads = AliasSeq!(__traits(getOverloads, Inter, fooName));
    static assert (overloads.length > 0);
    static if (overloads.length == 1)
        alias getTarget = overloads[0];
    else 
        alias getTarget = chooseOverload!(overloads, T);
}

interface Interceptor(Inter, string fooName, T...) if (is(Inter == interface)) {
    alias target = getTarget!(Inter, fooName, T);
    alias repr = Alias!(func!(target)());
    alias params = Parameters!target;
    alias returned = ReturnType!target;
    alias interceptedMethod = fooName;
        
    void before(params);
    static if (is(returned == void))
        returned after(params);
    else
        returned after(params, returned);
    
    void scopeExit(params, Throwable);
    void scopeSuccess(params);
    void scopeFailure(params, Throwable);
    
    returned hijackException(Throwable);
    /* todo:
     * hijack return value
     * hijack params
     * 
     * storage classes, attributes
    */
    
}

class InterceptorAdapter(Inter, string fooName): Interceptor!(Inter, fooName){
    override void before(params p){}
    static if (is(returned == void))
        override returned after(params p){}
    else
        override returned after(params p, returned r){ return r; }
    
    override void scopeExit(params p, Throwable t){}
    override void scopeSuccess(params p){}
    override void scopeFailure(params p, Throwable t){}
    
    override returned hijackException(Throwable t) { throw t; }
}

template ExtendMethod(alias Impl, alias TheInterceptor) {
    mixin("import "~moduleName!TheInterceptor~";");

    string overrideIfNeeded(){
        static if (__traits(isVirtualMethod, TheInterceptor.target))
            return "override ";
        else
            return "";
    }
    
    string methodDeclaration(){
        return func!(TheInterceptor.target).forImplementation;
    }
    
    string doTheImports(){
        return func!(TheInterceptor.target).forImportingContext;
    }
    
    string callBefore(string interceptorInstanceName){
        static if (TheInterceptor.params.length == 0) {
            return interceptorInstanceName~".before();";
        } else {
            return interceptorInstanceName~".before("~func!(TheInterceptor.target).parameters.forInvoking~");";
        }
    }
    
    string callAfter(string interceptorInstanceName, string resultName){
        static if (is(TheInterceptor.returned == void)) {
            static if (TheInterceptor.params.length == 0) {
                return interceptorInstanceName~"."~"after();";
            } else {
                return interceptorInstanceName~"."~"after("~func!(TheInterceptor.target).parameters.forInvoking~");";
            }
        } else {
            static if (TheInterceptor.params.length == 0) {
                return interceptorInstanceName~"."~"after("~resultName~");";
            } else {
                return interceptorInstanceName~"."~"after("~func!(TheInterceptor.target).parameters.forInvoking~", "~resultName~");";
            }
        }
    }
    
    string invoke(string resultName){
        static if (is(TheInterceptor.returned == void)) {
            static if (TheInterceptor.params.length == 0) {
                return "super."~TheInterceptor.interceptedMethod~"();";
            } else {
                return "super."~TheInterceptor.interceptedMethod~"("~func!(TheInterceptor.target).parameters.forInvoking~");";
            }
        } else {
            static if (TheInterceptor.params.length == 0) {
                return resultName~" = super."~TheInterceptor.interceptedMethod~"();";
            } else {
                return resultName~" = super."~TheInterceptor.interceptedMethod~"("~func!(TheInterceptor.target).parameters.forInvoking~");";
            }
        }
    }
    
    string declareResult(string resultName){
        static if (is(TheInterceptor.returned == void)) {
            return "";
        } else {
            return fullyQualifiedName!(TheInterceptor.returned)~" "~resultName~";";
        }
    }
    
    string declareThrowable(string throwableName){
        return "Throwable "~throwableName~" = null;";
    }
    
    string scopes(string interceptorInstanceName, string throwableName){
        static if (TheInterceptor.params.length == 0) {
            return "scope(exit) "~interceptorInstanceName~".scopeExit("~throwableName~");"~
                "scope(success) "~interceptorInstanceName~".scopeSuccess(); "~
                    "scope(failure) "~interceptorInstanceName~".scopeFailure("~throwableName~");";
        } else {
            return "scope(exit) "~interceptorInstanceName~".scopeExit("~func!(TheInterceptor.target).parameters.forInvoking~", "~throwableName~");"~
                "scope(success) "~interceptorInstanceName~".scopeSuccess("~func!(TheInterceptor.target).parameters.forInvoking~"); "~
                    "scope(failure) "~interceptorInstanceName~".scopeFailure("~func!(TheInterceptor.target).parameters.forInvoking~", "~throwableName~");";
        }
    }
    
    string tryCatch(string interceptorInstanceName, string invocation, string throwableName){
        string result = "try {"~
            invocation~
                "} catch (Throwable t) { "~
                throwableName~" = t; ";
        result ~= func!(TheInterceptor.target).returnIfNeeded~interceptorInstanceName~".hijackException(t);";
        result ~= "}";
        return result;
    }
    
    string overloadedMethodText(string interceptorInstanceName, string resultName, string throwableName){
        return overrideIfNeeded()~methodDeclaration()~"{ "~
            doTheImports()~
            declareThrowable(throwableName)~
                declareResult(resultName)~
                scopes(interceptorInstanceName, throwableName)~
                callBefore(interceptorInstanceName)~
                tryCatch(interceptorInstanceName, invoke(resultName), throwableName) ~
                " return "~callAfter(interceptorInstanceName, resultName)~
                " }";
    }

    string classText(string className, string interceptorInstanceName, string resultName, string throwableName){
        return "class "~className~": Impl { auto "~interceptorInstanceName~" = new "~fullyQualifiedName!TheInterceptor~"(); "~overloadedMethodText(interceptorInstanceName, resultName, throwableName)~" }";
    }

    string className(){
        return Impl.stringof ~ "_with_" ~ TheInterceptor.stringof;
    }

    version(unittest) {
        static if (logGeneratedCode) {
            pragma(msg, "- ExtendMethod ---------------------");
            pragma(msg, "Impl: ", Impl, " TheInterceptor: ", TheInterceptor);
            pragma(msg, "Result class name: ", className());
            pragma(msg, "Imports:");
            pragma(msg, doTheImports);
            pragma(msg, "/Imports");
            pragma(msg, overloadedMethodText("_interceptorInstance", "_result", "_throwable"));
            pragma(msg, "= ExtendMethod =====================");
        }
    }

    mixin(classText(className(), "_interceptorInstance", "_result", "_throwable"));
    
    mixin("alias ExtendMethod = "~className()~";");
}
