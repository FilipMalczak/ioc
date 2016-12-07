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

    @property string returnIfNeeded(){
        if (returnType == "void")
            return "";
        return "return";
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

Function[] overloads(string name)(){
    return overloads!(__MODULE__, name)();
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

version(unittest){
    interface A {int foo();}
    interface B: A { int foo(int); }
    interface C { void bar(string); }
    interface D: B, C {}
    
    class E: A { int foo(){ return 0; } }
    class F: D { int foo(){ return 0; } int foo(int x){ return x; } void bar(string s){} }
    class G: F {}

    void foo(int i){}
    void foo(){}
    void foo(string a, const float b){}
    //todo: defaults
    //todo: variadics
}

unittest {

    static assert (is(allInterfaces!A == AliasSeq!(A)));
    static assert (is(allInterfaces!B == AliasSeq!(B, A)));
    static assert (is(allInterfaces!D == AliasSeq!(D, B, A, C)));
    static assert (is(allInterfaces!E == AliasSeq!(A)));
    static assert (is(allInterfaces!F == AliasSeq!(D, B, A, C)));
    static assert (is(allInterfaces!G == AliasSeq!(D, B, A, C)));


    alias p0 = functionParams!(__traits(getOverloads, aModule!(__MODULE__), "foo")[0]);
    alias p1 = functionParams!(__traits(getOverloads, aModule!(__MODULE__), "foo")[1]);
    alias p2 = functionParams!(__traits(getOverloads, aModule!(__MODULE__), "foo")[2]);

    static assert (p0.forImplementation == "int i");
    static assert (p1.forImplementation == "");
    static assert (p2.forImplementation == "string a, const(float) b");

    static assert (p0.forDeclaration == "int");
    static assert (p1.forDeclaration == "");
    static assert (p2.forDeclaration == "string, const(float)");

    static assert (p0.forInvoking == "i");
    static assert (p1.forInvoking == "");
    static assert (p2.forInvoking == "a, b");
    static assert (overloads!("foo") == [
        Function("void", "foo", p0), 
        Function("void", "foo", p1), 
        Function("void", "foo", p2)
    ]);

    static assert (allInterfaceMethods!G == [
            Function("int", "foo", FunctionParameters([])), 
            Function("int", "foo", FunctionParameters([
                FunctionParameter("int", "x")
            ])), 
            Function("void", "bar", FunctionParameters([
                FunctionParameter("string", "s")
            ]))
        ]);
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

version(unittest){
    void foo2(long i){}
    void bar2(string a, int b){}
    struct X{
        void foo2(bool b){}
    }
}

unittest {
    static assert (accepts!(foo2, long));
    static assert (accepts!(foo2, int));
    static assert (!accepts!(foo2, string));
    static assert (accepts!(bar2, string, int));
    static assert (!accepts!(bar2, string, long));
    static assert (!accepts!(bar2, int));
    static assert (accepts!(__traits(getOverloads, X, "foo2")[0], bool));
    static assert (!accepts!(__traits(getOverloads, X, "foo2")[0], int));
    static assert (!accepts!(__traits(getOverloads, X, "foo2")[0], string));
}

// todo: need to rethink that idea
//template apply(alias foo, T=string){
//    void impl(T arg)(){
//        foo(arg);
//    }
//    alias apply = impl;
//}

//version(unittest){
//    struct Helper {
//        static string val = "";
//    }
//    
//    void useHelper(string s){
//        Helper.val = s;
//    }
//    
//    template useAndCheck(string dummy="dummy"){
//        apply!(useHelper, dummy)();
//        alias useAndCheck = Helper.val == dummy;
//    }
//    
//    static assert(useAndCheck!("dummy text"));
//}
