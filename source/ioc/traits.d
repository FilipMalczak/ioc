module ioc.traits;

import std.typecons;
import std.meta;
import std.stdio;

import ioc.testing;

/*
Here's the list of all traits:
    isAbstractClass
    isArithmetic
    isAssociativeArray
    isFinalClass
    isPOD
    isNested
    isFloating
    isIntegral
    isScalar
    isStaticArray
    isUnsigned
    isVirtualFunction
    isVirtualMethod
    isAbstractFunction
    isFinalFunction
    isStaticFunction
    isOverrideFunction
    isTemplate
    isRef
    isOut
    isLazy
    hasMember
    identifier
    getAliasThis
    getAttributes
    getFunctionAttributes
    getMember
    getOverloads
    getPointerBitmap
    getProtection
    getVirtualFunctions
    getVirtualMethods
    getUnitTests
    parent
    classInstanceSize
    getVirtualIndex
    allMembers
    derivedMembers
    isSame
    compiles

Over time and as needed some of them will become templates and enums.
    */

enum hasMember(alias Target, string name) = __traits(hasMember, Target, name);

version(unittest){
    struct A {
        int a;
        
        void foo(){}
    }
    
    class B {
        int b;
        
        static int bar(int x){
            return 2*x;
        }
    }
    
    interface C {
        void foo();
    }
    
    interface D: C {
        void bar();
        void bar(int, int);
    }
    
    @SimpleAnnotation
    class WithAttr{}
}

unittest{
    static assert(hasMember!(A, "a"));
    static assert(!hasMember!(A, "b"));
    static assert(hasMember!(B, "b"));
    static assert(!hasMember!(B, "c"));
    static assert(hasMember!(C, "foo"));
    static assert(!hasMember!(C, "d"));
    static assert(hasMember!(D, "foo"));
    static assert(hasMember!(D, "bar"));
    static assert(!hasMember!(A, "b"));
}


enum identifier(alias Target) = __traits(identifier, Target);

unittest{
    static assert(identifier!A=="A");
}

template getAttributes(alias Target) { alias getAttributes = AliasSeq!(__traits(getAttributes, Target)); }
alias attributes = getAttributes;

unittest{
    static assert(is(getAttributes!(WithAttr) == AliasSeq!(SimpleAnnotation)));
    static assert(is(attributes!(A) == AliasSeq!()));
}

enum allMembers(alias Target) = AliasSeq!(__traits(allMembers, Target));

unittest {
    static assert([allMembers!A] == ["a", "foo"]);
}

enum derivedMembers(alias Target) = __traits(derivedMembers, Target);

unittest {
    static assert([derivedMembers!D] == ["bar"]);
}
