module tests.aspects.scanningTests;

import ioc.weaver;

// no commands at all

class Nothing {}

@Pointcut!(name!"tests")
class NoType{
    @Advice
    void foo(){}
}

@Before
class NoPointcut{
    @Advice
    void foo(){}
}

// single pointcut, single advice

@Pointcut!(name!"tests")
@Before
class ClassSinglePntcutClassSingleTypeMethodAdvice{
    @Advice
    void foo(){}
}

@Pointcut!(name!"tests")
class ClassSinglePntcutMethodSingleTypeMethodAdvice{
    @Advice
    @After
    void foo(){}
}

@Pointcut!(name!"tests")
@Throw
class ClassSinglePntcutMethodSingleTypeNoAdvice{
    void foo(){}
}

// many pointcuts, single advice

@Pointcut!(name!"tests")
@Pointcut!(name!"pkg")
@Before
class ClassManyPntcutClassSingleTypeMethodAdvice{
    @Advice
    void foo(){}
}

@Pointcut!(name!"tests")
@Pointcut!(name!"pkg")
class ClassManyPntcutMethodSingleTypeMethodAdvice{
    @Advice
    @After
    void foo(){}
}

@Pointcut!(name!"tests")
@Pointcut!(name!"pkg")
@Throw
class ClassManyPntcutMethodSingleTypeNoAdvice{
    void foo(){}
}

// single pointcut, many advices

@Pointcut!(name!"tests")
@Before
@After
class ClassSinglePntcutClassManyTypesMethodAdvice{
    @Advice
    void foo(){}
}

@Pointcut!(name!"tests")
class ClassSinglePntcutMethodManyTypesMethodAdvice{
    @Advice
    @After
    @Finally
    void foo(){}
}

@Pointcut!(name!"tests")
@Throw
@After
class ClassSinglePntcutMethodManyTypesNoAdvice{
    void foo(){}
}

// unstructurized cases

class Custom1 {
    @Pointcut!(name!"X")
    @Before
    void foo(){}
}

/*
Follwing are unsupported:

@After
class ... {
    @Pointcut!(name!"X")
    @Before
    void foo(){}
}

because it looks like an error

@After
class ... {
    @Pointcut!(name!"X")
    @Before
    @Advice
    void foo(){}
}

because @Advice is ambiguous and generally we cannot say if it applies to @After or @Before
*/

@Before
@After
class Custom2 {
    @Pointcut!(name!"X")
    void foo(){}
}
