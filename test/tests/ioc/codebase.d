module tests.ioc.codebase;

import ioc.codebase;

import ioc.testing;
import ioc.stdmeta;
import ioc.meta;

import std.string;

unittest {
    mixin assertSequencesSetEqual!(
        seq!(
            "toppkg.b", "toppkg.a", "toppkg.sub.y", "toppkg.subpkg.x"
        ),
        seq!(
            moduleNames!("toppkg")
        )
    );
}

unittest {
    mixin assertSequencesSetEqual!(
        seq!(
            "toppkg.b.BC", "toppkg.sub.y.DeeplyNestedClass"
        ),
        seq!(
            memberNames!("toppkg", isClass)
        )
    );
    mixin assertSequencesSetEqual!(
        seq!(
            "toppkg.sub.y.Y"
        ),
        seq!(
            memberNames!("toppkg", isEnum)
        )
    );
    mixin assertSequencesSetEqual!(
        seq!(
            "toppkg.b.C", "toppkg.b.B", "toppkg.a.A", "toppkg.a.MyStereotype"
        ),
        seq!(
            memberNames!("toppkg", isStruct)
        )
    );
    mixin assertSequencesSetEqual!(
        seq!(
            "toppkg.subpkg.x.AnInterface"
        ),
        seq!(
            memberNames!("toppkg", isInterface)
        )
    );
}

version(unittest) {
    template nameStartsWithB(T...) if (T.length == 1){
        alias name = fullyQualifiedName!(T[0]);
        alias nameStartsWithB = Bool!(name.length > 0 && (name.split(".")[$-1]).toLower().startsWith("b"));
    }
}

unittest {
    mixin assertSequencesSetEqual!(
        seq!(
            "toppkg.b.BC", "toppkg.subpkg.x.AnInterface", "toppkg.sub.y.DeeplyNestedClass"
        ),
        seq!(
            memberNames!("toppkg", or!(isClass, isInterface))
        )
    );

    mixin assertSequencesSetEqual!(
        seq!(
            "toppkg.b.BC"
        ),
        seq!(
            memberNames!("toppkg", and!(isClass, nameStartsWithB))
        )
    );
}

version(unittest){
    @Stereotype
    enum Ann;

    enum NotAnn;

    @Stereotype
    enum AnnWithFields {
        A, B
    }

    enum NotAnnWithFields {
        A, B
    }

    @Stereotype
    struct AnnStr{}

    @AnnStr
    struct NotAnnStr{}

    @Stereotype
    struct AnnStrWithParams{
        string a;
        int b;
    }

    struct NotAnnStrWithParams{
        string a;
        int b;
    }

    //todo: test templates, e.g. struct A(B, string c){}
}

unittest{
    static assert (isStereotype!Ann);
    static assert (!isStereotype!NotAnn);
    static assert (isStereotype!AnnWithFields);
    static assert (!isStereotype!NotAnnWithFields);
    static assert (isStereotype!AnnStr);
    static assert (!isStereotype!NotAnnStr);
    static assert (isStereotype!AnnStrWithParams);
    static assert (!isStereotype!NotAnnStrWithParams);
}

version(unittest){
    @Ann
    class ClassWithAnn {}

    @Stereotype @Ann
    class ClassWithStereotypeAndAnn {}

    @Stereotype @NotAnn
    class ClassWithStereotypeAndNotAnn {}
}

unittest {
    alias has_Stereotype = hasStereotype!(Stereotype);
    static assert(has_Stereotype!(Ann));
    static assert(!has_Stereotype!(NotAnn));
    alias has_Ann = hasStereotype!(Ann);
    static assert(has_Ann!(ClassWithStereotypeAndAnn));
    static assert(!has_Ann!(ClassWithStereotypeAndNotAnn));
    alias has_Stereotype_or_Ann = hasStereotype!(Stereotype, Ann);
    static assert(has_Stereotype_or_Ann!(Ann));
    static assert(has_Stereotype_or_Ann!(ClassWithAnn));
    static assert(has_Stereotype_or_Ann!(ClassWithStereotypeAndAnn));
    static assert(has_Stereotype_or_Ann!(ClassWithStereotypeAndNotAnn));

    //todo: way, way more cases here
}

unittest {
    static assert (stringsOnly!());
    static assert (stringsOnly!("a"));
    static assert (stringsOnly!("a", "b", "c"));
    static assert (!stringsOnly!(ClassWithAnn));
    static assert (!stringsOnly!(ClassWithAnn, "b", "c"));
    static assert (!stringsOnly!("a", ClassWithStereotypeAndAnn, "c"));
    static assert (!stringsOnly!("a", "b", ClassWithStereotypeAndNotAnn));
    static assert (!stringsOnly!(ClassWithAnn, "b", ClassWithStereotypeAndNotAnn));
    static assert (!stringsOnly!(ClassWithAnn, ClassWithStereotypeAndAnn, ClassWithStereotypeAndNotAnn));
}

unittest {
    mixin assertSequencesSetEqual!(
        seq!(
            "toppkg.subpkg.x.AnInterface", "poodinisTest.a.I"
        ),
        seq!(
            memberNames!(isInterface, "poodinisTest", "toppkg")
        )
    );
}
