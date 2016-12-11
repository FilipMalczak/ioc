module tests.ioc.extendMethod;

import ioc.extendMethod;

import ioc.meta;
import ioc.logging;
import ioc.stdmeta;

import ioc.testing;
import std.conv;
   /* 
interface TestInterface {
    void foo();
    
    int bar(float x);
    
    void baz();
    int baz2(int x);
}

class TestImplementation: TestInterface {
    override void foo(){
        LogEntries.add("foo()");
    }
    
    override int bar(float x){
        LogEntries.add("bar(", x, ")");
        return to!int(x);
    }
    
    override void baz(){
        LogEntries.add("baz()");
        throw new Exception("ABC");
    }
    
    override int baz2(int x){
        LogEntries.add("baz2(", x, ")");
        throw new Exception("ABC "~to!string(x));
    }
}

class BeforeAfterVoid: InterceptorAdapter!(TestInterface, "foo") {
    override void before(){
        LogEntries.add("foo BEFORE");
    }
    override void after(){
        LogEntries.add("foo AFTER");
    }
}

class BeforeAfterReturned: InterceptorAdapter!(TestInterface, "bar") {
    override void before(float x){
        LogEntries.add("bar BEFORE ", x);
    }
    override int after(float x, int r){
        LogEntries.add("bar AFTER ", x, " ", r);
        return r+1;
    }
}

class ScopeSuccessNoParams: InterceptorAdapter!(TestInterface, "foo") {
    override void scopeSuccess(){
        LogEntries.add("Success");
    }
}

class ScopeExitNoParams: InterceptorAdapter!(TestInterface, "foo") {
    override void scopeExit(Throwable t){
        LogEntries.add("Exit ", t);
    }
}

class ScopeFailureNoParams: InterceptorAdapter!(TestInterface, "baz") {
    override void scopeFailure(Throwable t){
        LogEntries.add("Fail ", t.msg);
    }
}

class ScopeSuccessParams: InterceptorAdapter!(TestInterface, "bar") {
    override void scopeSuccess(float x){
        LogEntries.add("Success ", x);
    }
}

class ScopeExitParams: InterceptorAdapter!(TestInterface, "bar") {
    override void scopeExit(float x, Throwable t){
        LogEntries.add("Exit ", x, " ", t);
    }
}

class ScopeFailureParams: InterceptorAdapter!(TestInterface, "baz2") {
    override void scopeFailure(int z, Throwable t){
        LogEntries.add("Fail ", z, " ", t.msg);
    }
}

class ExceptionHijackVoid: InterceptorAdapter!(TestInterface, "baz"){
    override void hijackException(Throwable t) { 
        LogEntries.add("hijacked void");
    }
}

class ExceptionHijackNonVoid: InterceptorAdapter!(TestInterface, "baz2"){
    override int hijackException(Throwable t) { 
        LogEntries.add("hijacked ", t.msg);
        return 8;
    }
}

class FirstInterceptor: InterceptorAdapter!(TestInterface, "foo"){
    override void before(){
        LogEntries.add("foo FIRST BEFORE");
    }
    override void after(){
        LogEntries.add("foo FIRST AFTER");
    }
}

class SecondInterceptor: InterceptorAdapter!(TestInterface, "foo"){
    override void before(){
        LogEntries.add("foo SECOND BEFORE");
    }
    override void after(){
        LogEntries.add("foo SECOND AFTER");
    }
}

unittest {
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
    
}*/
