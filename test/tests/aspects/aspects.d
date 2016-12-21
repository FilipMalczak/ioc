module tests.aspects.aspects;

import ioc.weaver;
import ioc.testing;
import std.stdio;

@Aspect
class NoConstructorInPointcut {}

@Aspect
class DefaultConstructorInPointCut {}

@Aspect
@Pointcut!(name!("poodinisTest.**.AComponent"))
class WithWildcard{}

@Aspect
@Pointcut!(name!("poodinisTest.b.AComponent"))
class MatchingByName {
    @Before
    void foo(){
        LogEntries.add("MatchingByName#foo()");
    }

    @Before
    @Pointcut!(method!("foo"))
    void bar(){
        LogEntries.add("MatchingByName#bar()");
    }
}

@Aspect
@Pointcut!(name!("a"))
class NotMatchingAtAll{}


@Aspect
@Pointcut!(name!("poodinisTest.b.AComponent"), method!("foo"))
class A {
    
    @Advice
    @Before
    void advice(){
        LogEntries.add("A#advice()");
    }

    @After
    void afterAdvice(){
        LogEntries.add("2");
    }

    @After
    void afterAdvice2(){
        LogEntries.add("3");
    }

    @After
    @Pointcut!(name!("a.**"))
    void afterAdvice3(){
        LogEntries.add("4");
    }
}

@Aspect
@Pointcut!(name!("poodinisTest.b.AComponent"), method!("foo"))
@Before
class B {
    @Advice
    void advice(){
        LogEntries.add("B#advice()");
    }

    @Advice
    @Pointcut!(name!"**.b.*")
    void advice2(){
        LogEntries.add("B#advice2()");
    }

}
