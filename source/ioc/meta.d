module ioc.meta;

import std.algorithm;
import std.string;
import std.meta;
import std.conv;
import std.traits;
import std.typecons;

alias True = Alias!true;
alias False = Alias!false;

template Bool(T...) if (T.length == 1) {
    static if (T[0])
        alias Bool = True;
    else
        alias Bool = False;
}

template allInterfaces(Original){
    static if (is(Original == interface))
        alias allInterfaces = AliasSeq!(Original, InterfacesTuple!Original);
    else
        alias allInterfaces = InterfacesTuple!Original;
}

/*
 * 1st approach
 */
template aModule(string name){
    mixin("import "~name~";");
    mixin("alias aModule = "~name~";");
}

/*
 * 2nd approach
 */
mixin template importModuleAs(string modName, string aliasName){
    mixin("import "~modName~";");
    mixin("alias "~aliasName~" = "~modName~";");
}

/*
 * 3rd approach
 */
//mixin template importModule(string name){
//    mixin("import "~name~";");
//}

//mixin template t_alias(string name, string currentName){
//    mixin("alias "~name~" = "~currentName~";");
//}

//todo: which way is better?

struct FunctionParameter {
    string type;
    string name;

    static int unnamedParams = 0;

    @property string forImplementation(){
        return type~" "~name;
    }

    @property string forDeclaration(){
        return type;
    }

    @property string forInvoking(){
        return name;
    }
    
    @property string forImportingContext(){
        auto parts = type.split(".");
        while (parts.length < 3)
            parts = [""] ~ parts;
        return parts[$-2];
    }
}

struct FunctionParameters {
    FunctionParameter[] parameters = [];

    @property string forImplementation(){
        string[] parts = [];
        foreach (param; parameters)
            parts ~= param.forImplementation;
        return parts.join(", ");
    }

    @property string forDeclaration(){
        string[] parts = [];
        foreach (param; parameters)
            parts ~= param.forDeclaration;
        return parts.join(", ");
    }
    
    @property string forInvoking(){
        string[] parts = [];
        foreach (param; parameters)
            parts ~= param.forInvoking;
        return parts.join(", ");
    }
    
    @property string forImportingContext(){
        string[] parts = [];
        foreach (param; parameters)
            parts ~= param.forImportingContext;
        return parts.join(" ");
    }
}

struct Function {
    string returnType;
    string name;
    FunctionParameters parameters;
    //todo: modifiers, storage class, attributes, etc

    @property string forImplementation(){
        return returnType~" "~name~"("~parameters.forImplementation~")";
    }

    @property string forDeclaration(){
        return returnType~" "~name~"("~parameters.forDeclaration~")";
    }

    @property string forInvoking(){
        return name~"("~parameters.forInvoking~")";
    }
    
    string forImportingContext(){
        string result = "";
        if (FunctionParameter(returnType, "").forImportingContext)
            result = FunctionParameter(returnType, "").forImportingContext;
        result ~= " "~parameters.forImportingContext;
        return result;
    }

    @property string returnIfNeeded(){
        if (returnType == "void")
            return "";
        return "return ";
    }
}

FunctionParameters functionParams(alias foo)(){
    alias names = ParameterIdentifierTuple!foo;
    alias types = Parameters!foo;
    FunctionParameters result;
    result.parameters = [];
    int unnamedParams = 0;
    foreach (i, name; names){
        FunctionParameter param;
        param.name = name;
        if (param.name == "")
            param.name = "_unnamedParam_"~to!string(unnamedParams++);
        param.type = fullyQualifiedName!(types[i]);
        result.parameters ~= param;
    }
    return result;
}

Function func(alias foo)(){
    Function result;
    result.parameters = functionParams!foo();
    result.name = __traits(identifier, foo);
    result.returnType = fullyQualifiedName!(ReturnType!foo);
    return result;
}

Function[] overloads(alias T, string name)(){
    Function[] result = [];
    foreach (overload; __traits(getOverloads, T, name))
        result ~= func!overload();
    return result;
}

Function[] overloads(string mod, string name)(){
    return overloads!(aModule!(mod), name)();
}

Function[] overloads(string name, string moduleName=__MODULE__, T=Function)(){
    return overloads!(moduleName, name)();
}

Function[] allInterfaceMethods(T)(){
    Function[] result = [];
    foreach (inter; allInterfaces!T) {
        foreach(mem; __traits(derivedMembers, inter)) {
            foreach (overload; overloads!(T, mem)())
                if (!result.canFind(overload))
                    result ~= overload;
        }
    }
    return result;
}

template accepts(alias foo, T...){
    alias params = Parameters!foo;
    static if (params.length != T.length)
        enum accepts = false;
    else {
        template match(int i) {
            static if (i >= params.length)
                enum match = true;
            else 
                enum match = isAssignable!(params[i], T[i]) && match!(i+1);
        }
        enum accepts = match!(0);
    }
}

/*
template seq(T...){
    struct seqImpl {
        alias sequence = T;
    }
    alias seq = seqImpl;
}*/

template reverse(T...){
    static if (T.length == 0)
        alias reverse = T;
    else
        alias reverse = AliasSeq!(reverse(T[1..$]), T[0]);
}

struct seq(T...){
    alias sequence = T;
    alias _ = sequence;
    alias length = Alias!(T.length);
    alias empty = Alias!(length == 0);

    template at(size_t i){
        alias at = sequence[i];
    }

    //todo: test it
    //todo: (apply, acc) or (acc, apply)? I'm mostly using the former, but ther latter makes more sense
    //todo: use it
    template fold(alias apply, initVal...){
        template impl(int i=0, acc...){
            static if (i<length)
                alias impl = impl!(i+1, apply!(sequence[i]), acc);
        }
        alias fold = imp!(0, initVal);
    }

    template reversed() { alias reversed = seq!(reverse!(T)); }
}


template derivedOverloads(alias Class){
    alias memberNames = seq!(__traits(derivedMembers, Class));
    template iter(int i=0, acc...){
        static if (i<memberNames.length){
            alias iter = iter!(i+1, __traits(getOverloads, Class, memberNames._[i]), acc);
        } else
            alias iter = acc;
    }
    alias derivedOverloads = iter!();
}

template allOverloads(alias Class){
    alias memberNames = seq!(__traits(allMembers, Class));
    template iter(int i=0, acc...){
        static if (i<memberNames.length){
            alias iter = iter!(i+1, __traits(getOverloads, Class, memberNames._[i]), acc);
        } else
            alias iter = acc;
    }
    alias derivedOverloads = iter!();
}

template derivedOverloads(T...){ //todo: if all are classes/interfaces
    static if (T.length == 0)
        alias derivedOverloads = AliasSeq!();
    else
        alias derivedOverloads = AliasSeq!(derivedOverloads!(T[0]), derivedOverloads!(T[1..$]));
}

template allOverloads(T...){ //todo: if all are classes/interfaces
    static if (T.length == 0)
        alias allOverloads = AliasSeq!();
    else
        alias allOverloads = AliasSeq!(allOverloads!(T[0]), allOverloads!(T[1..$]));
}

template interfaceOverloads(Class){
    alias interfaceOverloads = derivedOverloads!(InterfacesTuple!Class);
}
