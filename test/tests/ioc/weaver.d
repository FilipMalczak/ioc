module tests.ioc.weaver;

import ioc.testing;
import ioc.stdmeta;
import std.traits: TemplateArgsOf, TemplateOf;
import ioc.weaver;

/*
unittest {
    pragma(msg, "------------------");
    alias allAttrs = AliasSeq!(__traits(getAttributes, B.advice));
    foreach (i, a; allAttrs) {
        pragma(msg, i, " -> ", a.stringof, " ; ",  fullyQualifiedName!a);
        pragma(msg, __traits(isSame, a, Advice));
        pragma(msg, __traits(isSame, a, Advice!NONE));
    }
    pragma(msg, fullyQualifiedName!Advice);
    //pragma(msg, TemplateOf!Advice);
    pragma(msg, __traits(compiles, TemplateArgsOf!Advice));
    pragma(msg, __traits(compiles, TemplateArgsOf!(Advice!(NONE))));
    pragma(msg, fullyQualifiedName!(Advice!(NONE)));
    //pragma(msg, TemplateOf!(Advice!(NONE)));
    pragma(msg, TemplateArgsOf!(Advice!(NONE)));
    pragma(msg, "==================");
}


unittest {
    pragma(msg, gatherPointcuts!(A)());
    pragma(msg, gatherPointcuts!(A.advice)());
    pragma(msg, gatherPointcuts!(A.afterAdvice)());
    pragma(msg, gatherPointcuts!(A.afterAdvice2)());
    pragma(msg, gatherPointcuts!(A.afterAdvice3)());
    //todo: these look sane, but should be turned to real tests
}

unittest {
    static assert(match("**", "a.b.C"));
    static assert(match("*.*.*", "a.b.C"));
    static assert(match("*.*.**", "a.b.C"));
    static assert(match("*.**.*", "a.b.C"));
    static assert(match("**.*.*", "a.b.C"));
    static assert(match("a.b.C", "a.b.C"));
    static assert(match("a.*.C", "a.b.C"));
    static assert(match("a.**.C", "a.b.C"));
    static assert(match("a.b.*", "a.b.C"));
    static assert(match("a.b.**", "a.b.C"));

    static assert(!match("a.b.C.**", "a.b.C"));
}

unittest {
    import std.stdio;
    writeln("A ", __traits(getAttributes, A));
    A a = new A();
    writeln(typeof(__traits(getAttributes, a.advice)).stringof);
    writeln("B ", __traits(getAttributes, B));
    B b = new B();
    writeln(typeof(__traits(getAttributes, b.advice)).stringof);
}*/
