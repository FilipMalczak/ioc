module ioc.extendMethod;
import std.traits;
import std.meta;
import std.typecons;

//todo: rewrite to use ioc.meta.Function and friends

import ioc.meta;

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
	//alias params = Parameters!(__traits(getMember, Inter, fooName));
	//alias returned = ReturnType!(__traits(getMember, Inter, fooName));
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
	
	//static if (!is(returned == void))
		returned hijackException(Throwable);
	/*
	 * hijack return value
	 * hijack params
	 * 
	 * storage classes, attributes
	*/
	
}

class InterceptorAdapter(Inter, string fooName): Interceptor!(Inter, fooName){
	void before(params p){}
	static if (is(returned == void))
		returned after(params p){}
	else
		returned after(params p, returned r){ return r; }
	
	void scopeExit(params p, Throwable t){}
	void scopeSuccess(params p){}
	void scopeFailure(params p, Throwable t){}
	
	//static if (!is(returned == void))
	returned hijackException(Throwable t) { throw t; }
}

template ExtendMethod(Impl, TheInterceptor) {
	//template ExtendMethod(Impl, TheInterceptor, string foo, theInterface) {
	//template ExtendMethod(Impl: theInterface, TheInterceptor: Interceptor!(theInterface, foo), string foo, theInterface) {
	string methodDeclaration(){
		static if (is(TheInterceptor.returned == void)) {
			static if (TheInterceptor.params.length == 0) {
				return "void "~TheInterceptor.interceptedMethod~"()";
			} else {
				return "void "~TheInterceptor.interceptedMethod~"(T...)(T t)";
			}
		} else {
			static if (TheInterceptor.params.length == 0) {
				return fullyQualifiedName!(TheInterceptor.returned)~" "~TheInterceptor.interceptedMethod~"()";
			} else {
				return fullyQualifiedName!(TheInterceptor.returned)~" "~TheInterceptor.interceptedMethod~"(T...)(T t)";
			}
		}
	}
	
	string callBefore(string interceptorInstanceName){
		static if (TheInterceptor.params.length == 0) {
			return interceptorInstanceName~".before();";
		} else {
			return interceptorInstanceName~".before(tuple(t).expand);";
		}
	}
	
	string callAfter(string interceptorInstanceName, string resultName){
		static if (is(TheInterceptor.returned == void)) {
			static if (TheInterceptor.params.length == 0) {
				return interceptorInstanceName~"."~"after();";
			} else {
				return interceptorInstanceName~"."~"after(tuple(t).expand);";
			}
		} else {
			static if (TheInterceptor.params.length == 0) {
				return interceptorInstanceName~"."~"after("~resultName~");";
			} else {
				return interceptorInstanceName~"."~"after(tuple(t).expand, "~resultName~");";
			}
		}
	}
	
	string invoke(string resultName){
		static if (is(TheInterceptor.returned == void)) {
			static if (TheInterceptor.params.length == 0) {
				return "super."~TheInterceptor.interceptedMethod~"();";
			} else {
				return "super."~TheInterceptor.interceptedMethod~"(tuple(t).expand);";
			}
		} else {
			static if (TheInterceptor.params.length == 0) {
				return resultName~" = super."~TheInterceptor.interceptedMethod~"();";
			} else {
				return resultName~" = super."~TheInterceptor.interceptedMethod~"(tuple(t).expand);";
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
			return "scope(exit) "~interceptorInstanceName~".scopeExit(tuple(t).expand, "~throwableName~");"~
				"scope(success) "~interceptorInstanceName~".scopeSuccess(tuple(t).expand); "~
					"scope(failure) "~interceptorInstanceName~".scopeFailure(tuple(t).expand, "~throwableName~");";
		}
	}
	
	string tryCatch(string interceptorInstanceName, string invocation, string throwableName){
		string result = "try {"~
			invocation~
				"} catch (Throwable t) { "~
				throwableName~" = t; ";
		//static if (!is(TheInterceptor.returned == void))
			result ~= "return "~interceptorInstanceName~".hijackException(t);";
		result ~= "}";
		return result;
	}
	
	string overloadedMethodText(string interceptorInstanceName, string resultName, string throwableName){
		return methodDeclaration()~"{ "~
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
		pragma(msg, "- ExtendMethod ---------------------");
		pragma(msg, "Impl: ", Impl, " TheInterceptor: ", TheInterceptor);
		pragma(msg, "Result class name: ", className());
		pragma(msg, overloadedMethodText("_interceptorInstance", "_result", "_throwable"));
		pragma(msg, "= ExtendMethod =====================");
	}

	/*class ExtendMethodImpl: Impl {
		auto _interceptorInstance = new TheInterceptor();

		mixin(mixinText("_interceptorInstance", "_result", "_throwable"));
	}*/

	mixin(classText(className(), "_interceptorInstance", "_result", "_throwable"));
	
	mixin("alias ExtendMethod = "~className()~";");
}

version(unittest){
	import ioc.testing;
	import std.conv;
	
	interface TestInterface {
		void foo();
		
		int bar(float x);
		
		void baz();
		int baz2(int x);
	}
	
	class TestImplementation: TestInterface {
		void foo(){
			LogEntries.add("foo()");
		}
		
		int bar(float x){
			LogEntries.add("bar(", x, ")");
			return to!int(x);
		}
		
		void baz(){
			LogEntries.add("baz()");
			throw new Exception("ABC");
		}
		
		int baz2(int x){
			LogEntries.add("baz2(", x, ")");
			throw new Exception("ABC "~to!string(x));
		}
	}
	
	class BeforeAfterVoid: InterceptorAdapter!(TestInterface, "foo") {
		void before(){
			LogEntries.add("foo BEFORE");
		}
		void after(){
			LogEntries.add("foo AFTER");
		}
	}
	
	class BeforeAfterReturned: InterceptorAdapter!(TestInterface, "bar") {
		void before(float x){
			LogEntries.add("bar BEFORE ", x);
		}
		int after(float x, int r){
			LogEntries.add("bar AFTER ", x, " ", r);
			return r+1;
		}
	}
	
	class ScopeSuccessNoParams: InterceptorAdapter!(TestInterface, "foo") {
		void scopeSuccess(){
			LogEntries.add("Success");
		}
	}

	class ScopeExitNoParams: InterceptorAdapter!(TestInterface, "foo") {
		void scopeExit(Throwable t){
			LogEntries.add("Exit ", t);
		}
	}

	class ScopeFailureNoParams: InterceptorAdapter!(TestInterface, "baz") {
		void scopeFailure(Throwable t){
			LogEntries.add("Fail ", t.msg);
		}
	}

	class ScopeSuccessParams: InterceptorAdapter!(TestInterface, "bar") {
		void scopeSuccess(float x){
			LogEntries.add("Success ", x);
		}
	}
	
	class ScopeExitParams: InterceptorAdapter!(TestInterface, "bar") {
		void scopeExit(float x, Throwable t){
			LogEntries.add("Exit ", x, " ", t);
		}
	}
	
	class ScopeFailureParams: InterceptorAdapter!(TestInterface, "baz2") {
		void scopeFailure(int z, Throwable t){
			LogEntries.add("Fail ", z, " ", t.msg);
		}
	}

	class ExceptionHijackVoid: InterceptorAdapter!(TestInterface, "baz"){
		void hijackException(Throwable t) { 
			LogEntries.add("hijacked void");
		}
	}

	class ExceptionHijackNonVoid: InterceptorAdapter!(TestInterface, "baz2"){
		int hijackException(Throwable t) { 
			LogEntries.add("hijacked ", t.msg);
			return 8;
		}
	}

	class FirstInterceptor: InterceptorAdapter!(TestInterface, "foo"){
		void before(){
			LogEntries.add("foo FIRST BEFORE");
		}
		void after(){
			LogEntries.add("foo FIRST AFTER");
		}
	}

	class SecondInterceptor: InterceptorAdapter!(TestInterface, "foo"){
		void before(){
			LogEntries.add("foo SECOND BEFORE");
		}
		void after(){
			LogEntries.add("foo SECOND AFTER");
		}
	}

}

unittest {
	import std.stdio;
	void beforeAfterTests(){
		auto beforeAfterVoid = new ExtendMethod!(TestImplementation, BeforeAfterVoid)();
		beforeAfterVoid.foo();
		assert(LogEntries.entries == ["foo BEFORE", "foo()", "foo AFTER"]);
		LogEntries.reset();

		auto beforeAfterReturned = new ExtendMethod!(TestImplementation, BeforeAfterReturned)();
		assert(beforeAfterReturned.bar(2.4)==3);
		assert(LogEntries.entries == ["bar BEFORE 2.4", "bar(2.4)", "bar AFTER 2.4 2"]);
		LogEntries.reset();
	}

	void scopeNoParamsTests(){
		auto scopeSuccessNoParams = new ExtendMethod!(TestImplementation, ScopeSuccessNoParams)();
		scopeSuccessNoParams.foo();
		assert(LogEntries.entries == ["foo()", "Success"]);
		LogEntries.reset();

		auto scopeExitNoParams = new ExtendMethod!(TestImplementation, ScopeExitNoParams)();
		scopeExitNoParams.foo();
		assert(LogEntries.entries == ["foo()", "Exit null"]);
		LogEntries.reset();

		auto scopeFailureNoParams = new ExtendMethod!(TestImplementation, ScopeFailureNoParams)();
		try { scopeFailureNoParams.baz(); } catch(Throwable t) {  }
		assert(LogEntries.entries == ["baz()", "Fail ABC"]);
		LogEntries.reset();
	}

	void scopeParamsTests(){
		auto scopeSuccessParams = new ExtendMethod!(TestImplementation, ScopeSuccessParams)();
		scopeSuccessParams.bar(2);
		assert(LogEntries.entries == ["bar(2)", "Success 2"]);
		LogEntries.reset();
		
		auto scopeExitParams = new ExtendMethod!(TestImplementation, ScopeExitParams)();
		scopeExitParams.bar(2);
		assert(LogEntries.entries == ["bar(2)", "Exit 2 null"]);
		LogEntries.reset();
		
		auto scopeFailureParams = new ExtendMethod!(TestImplementation, ScopeFailureParams)();
		try { scopeFailureParams.baz2(3); } catch(Throwable t) {  }
		assert(LogEntries.entries == ["baz2(3)", "Fail 3 ABC 3"]);
		LogEntries.reset();
	}

	void scopeTests(){
		scopeNoParamsTests();
		scopeParamsTests();
	}

	void hijackingTest(){
		auto hijackingVoid = new ExtendMethod!(TestImplementation, ExceptionHijackVoid)();
		hijackingVoid.baz();
		assert(LogEntries.entries == ["baz()", "hijacked void"]);
		LogEntries.reset();

		auto hijackingNonVoid = new ExtendMethod!(TestImplementation, ExceptionHijackNonVoid)();
		assert(hijackingNonVoid.baz2(4) == 8);
		assert(LogEntries.entries == ["baz2(4)", "hijacked ABC 4"]);
		LogEntries.reset();
	}

	void compositionTest(){
		auto composed = new ExtendMethod!(ExtendMethod!(TestImplementation, FirstInterceptor), SecondInterceptor)();
		composed.foo();
		assert(LogEntries.entries == ["foo SECOND BEFORE", "foo FIRST BEFORE", "foo()", "foo FIRST AFTER", "foo SECOND AFTER"]);
		LogEntries.reset();

		// of course this would need more tests - for other methods
		// but for now I'm just surprised that it works, since _interceptor_instance is overwritten
		// still, it works, so - yay!
	}

	beforeAfterTests();
	scopeTests();
	hijackingTest();
	compositionTest();
}