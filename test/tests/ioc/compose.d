module tests.ioc.compose;

import ioc.compose;

import ioc.extendMethod;
import tests.ioc.extendMethod;
import ioc.testing;
import std.conv;
/*
interface TestInterface{
    void foo(int);
    string bar(float f);
}

class TestImpl: TestInterface{
    override void foo(int x){
        LogEntries.add("IMPL foo ", x);
    }

    override string bar(float f){
        LogEntries.add("IMPL bar ", f);
        return to!string(f);
    }
}

class TestImplWithConstr: TestInterface{
    bool arg;

    this(bool b){
        arg = b;
    }

    override void foo(int x){
        LogEntries.add("IMPL foo ", arg, " ", x);
    }
    
    override string bar(float f){
        LogEntries.add("IMPL bar ", arg, " ",  f);
        return to!string(f);
    }
}

class FirstFooInterceptor: InterceptorAdapter!(TestInterface, "foo"){
    override void before(int x){
        LogEntries.add("First foo before ", x);
    }
    override void after(int x){
        LogEntries.add("First foo after ", x);
    }
}

class SecondFooInterceptor: InterceptorAdapter!(TestInterface, "foo"){
    override void before(int x){
        LogEntries.add("Second foo before ", x);
    }
    override void after(int x){
        LogEntries.add("Second foo after ", x);
    }
}

class FirstBarInterceptor: InterceptorAdapter!(TestInterface, "bar"){
    override void before(float f){
        LogEntries.add("First bar before ", f);
    }
    override string after(float f, string s){
        LogEntries.add("First bar after ", f, " ", s);
        return s~"+first";
    }
}

class SecondBarInterceptor: InterceptorAdapter!(TestInterface, "bar"){
    override void before(float f){
        LogEntries.add("Second bar before ", f);
    }
    override string after(float f, string s){
        LogEntries.add("Second bar after ", f, " ", s);
        return s~"+second";
    }
}

unittest{
    alias ComposedType = compose!(TestImpl, FirstFooInterceptor, SecondFooInterceptor);
    ComposedType simple = new ComposedType();
    simple.foo(1);
    assert (LogEntries.entries == [
        "Second foo before 1",
        "First foo before 1",
        "IMPL foo 1",
        "First foo after 1",
        "Second foo after 1"
    ]);
    LogEntries.reset();

    alias ComposedType2 = compose!(TestImpl, FirstBarInterceptor, SecondBarInterceptor);
    ComposedType2 simple2 = new ComposedType2();
    assert(simple2.bar(3.14) == "3.14+first+second");
    assert (LogEntries.entries == [
        "Second bar before 3.14",
        "First bar before 3.14",
        "IMPL bar 3.14",
        "First bar after 3.14 3.14",
        "Second bar after 3.14 3.14+first"
    ]);
    LogEntries.reset();

    //todo: full test suite for composition, scopes, hijacking, etc
}*/
