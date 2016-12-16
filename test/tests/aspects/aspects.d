module tests.aspects.aspects;

import ioc.weaver;
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
    void advice(){}

    @After
    void afterAdvice(){}

    @After
    void afterAdvice2(){}

    @After
    @Pointcut!(name!("a.**"))
    void afterAdvice3(){}
}

@Aspect
@Pointcut!(name!("poodinisTest.b.AComponent"), method!("foo"))
@After
class B {
    @Advice
    void advice(){}

    @Advice
    @Pointcut!(name!"**.b.*")
    void advice2(){}

}
