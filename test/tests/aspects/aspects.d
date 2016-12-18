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
    void foo(){}

    @Before
    @Pointcut!(method!("foo"))
    void bar(){}
}

@Aspect
@Pointcut!(name!("a"))
class NotMatchingAtAll{}


@Aspect
@Pointcut!(name!("a.b.C"), method!("foo"))
class A {
    @Before
    void advice(){
        LogEntries.add("1");
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
        writeln("ADVICE");
        LogEntries.add("5");
    }

    @Advice
    @Pointcut!(name!"**.b.*")
    void advice2(){
        writeln("ADVICE2");
        LogEntries.add("6");    
    }

}
