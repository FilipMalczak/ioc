module tests.ioc.meta;

import ioc.meta;

import std.algorithm;
import std.string;
import std.meta;
import std.conv;
import std.traits;
import std.typecons;

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
    /*static assert (overloads!("foo") == [
        Function("void", "foo", p0), 
        Function("void", "foo", p1), 
        Function("void", "foo", p2)
    ]);*/

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

void foo2(long i){}
void bar2(string a, int b){}
struct X{
    void foo2(bool b){}
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

