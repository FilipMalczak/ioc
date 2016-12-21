module tests.ioc.weaver;

import ioc.testing;
import ioc.stdmeta;
import ioc.weaver;

/*
 * scanning
 */

import tests.aspects.scanningTests;

// no commands at all

unittest {
    foreach (shouldYieldNoCommands; AliasSeq!(Nothing, NoType, NoPointcut)) {
        alias result = collectCommands!shouldYieldNoCommands;
        static assert(result.length == 0);
    }
}

// single pointcut, single advice

unittest {
    alias classClassMethod = collectCommands!ClassSinglePntcutClassSingleTypeMethodAdvice;
    static assert(classClassMethod.length == 1);
    static assert(is(classClassMethod[0].aspectClass == ClassSinglePntcutClassSingleTypeMethodAdvice));
    static assert(classClassMethod[0].adviceMethodName == "foo");
    static assert(classClassMethod[0].adviceType == BEFORE);
    
    alias classMethodMethod = collectCommands!ClassSinglePntcutMethodSingleTypeMethodAdvice;
    static assert(classMethodMethod.length == 1);
    static assert(is(classMethodMethod[0].aspectClass == ClassSinglePntcutMethodSingleTypeMethodAdvice));
    static assert(classMethodMethod[0].adviceMethodName == "foo");
    static assert(classMethodMethod[0].adviceType == AFTER);
    
    alias classMethodNone = collectCommands!ClassSinglePntcutMethodSingleTypeNoAdvice;
    static assert(classMethodNone.length == 1);
    static assert(is(classMethodNone[0].aspectClass == ClassSinglePntcutMethodSingleTypeNoAdvice));
    static assert(classMethodNone[0].adviceMethodName == "foo");
    static assert(classMethodNone[0].adviceType == THROW);
}

// many pointcuts, single advice

unittest {
    alias classClassMethod = collectCommands!ClassManyPntcutClassSingleTypeMethodAdvice;
    static assert(classClassMethod.length == 2);
    foreach (cmd; classClassMethod) {
        static assert(is(cmd.aspectClass == ClassManyPntcutClassSingleTypeMethodAdvice));
        static assert(cmd.adviceMethodName == "foo");
        static assert(cmd.adviceType == BEFORE);
    }
    
    alias classMethodMethod = collectCommands!ClassManyPntcutMethodSingleTypeMethodAdvice;
    static assert(classMethodMethod.length == 2);
    foreach (cmd; classMethodMethod) {
        pragma(msg, cmd);
        static assert(is(cmd.aspectClass == ClassManyPntcutMethodSingleTypeMethodAdvice));
        static assert(cmd.adviceMethodName == "foo");
        static assert(cmd.adviceType == AFTER);
    }
    
    alias classMethodNone = collectCommands!ClassManyPntcutMethodSingleTypeNoAdvice;
    static assert(classMethodNone.length == 2);
    foreach (cmd; classMethodNone) {
        static assert(is(cmd.aspectClass == ClassManyPntcutMethodSingleTypeNoAdvice));
        static assert(cmd.adviceMethodName == "foo");
        static assert(cmd.adviceType == THROW);
    }
}

// single pointcut, many advices

unittest {
    AdviceType[] types;

    types = [];
    alias classClassMethod = collectCommands!ClassSinglePntcutClassManyTypesMethodAdvice;
    static assert(classClassMethod.length == 2);
    foreach (cmd; classClassMethod) {
        static assert(is(cmd.aspectClass == ClassSinglePntcutClassManyTypesMethodAdvice));
        static assert(cmd.adviceMethodName == "foo");
        types ~= cmd.adviceType;
    }
    assertSetsEqual([BEFORE, AFTER], types);
    
    types = [];
    alias classMethodMethod = collectCommands!ClassSinglePntcutMethodManyTypesMethodAdvice;
    static assert(classMethodMethod.length == 2);
    foreach (cmd; classMethodMethod) {
        pragma(msg, cmd);
        static assert(is(cmd.aspectClass == ClassSinglePntcutMethodManyTypesMethodAdvice));
        static assert(cmd.adviceMethodName == "foo");
        types ~= cmd.adviceType;
    }
    assertSetsEqual([AFTER, FINALLY], types);
    
    types = [];
    alias classMethodNone = collectCommands!ClassSinglePntcutMethodManyTypesNoAdvice;
    static assert(classMethodNone.length == 2);
    foreach (cmd; classMethodNone) {
        static assert(is(cmd.aspectClass == ClassSinglePntcutMethodManyTypesNoAdvice));
        static assert(cmd.adviceMethodName == "foo");
        types ~= cmd.adviceType;
    }
    assertSetsEqual([THROW, AFTER], types);
}

// unstructurized cases

unittest {
    alias custom1 = collectCommands!Custom1;
    static assert(custom1.length == 1);
    static assert(is(custom1[0].aspectClass == Custom1));
    static assert(custom1[0].adviceMethodName == "foo");
    static assert(custom1[0].adviceType == BEFORE);

    AdviceType[] types = [];
    alias custom2 = collectCommands!Custom2;
    static assert(custom2.length == 2);
    foreach (cmd; custom2) {
        static assert(is(cmd.aspectClass == Custom2));
        static assert(cmd.adviceMethodName == "foo");
        types ~= cmd.adviceType;
    }
    assertSetsEqual([BEFORE, AFTER], types);
}
