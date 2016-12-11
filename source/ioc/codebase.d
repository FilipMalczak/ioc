module ioc.codebase;

import ioc.testing;
import ioc.logging;
import ioc.stdmeta;
import ioc.meta;

import std.string;

//todo: those beg to be moved to some other module. but where to?

template getPackageIndex(string name){
    alias getPackageIndex = aModule!(name~"._index").Index;
}

template collect(T...){
    alias collect = T;
}

/**
 * apply(string moduleName, accumulated...) -> newAccumulated...
 */
template foldModuleNames(string pkgName, alias apply, initVal...){
    alias submodules = EnumMembers!(getPackageIndex!(pkgName).submodules);
    alias subpackages = EnumMembers!(getPackageIndex!(pkgName).subpackages);
    template iterateOverSubmodules(int i, acc...){
        static if (i<submodules.length){
            alias iterateOverSubmodules = iterateOverSubmodules!(i+1, apply!(submodules[i], acc));
        } else
            alias iterateOverSubmodules = acc;
    }
    template iterateOverSubpackages(int i, acc...){
        static if (i<subpackages.length){
            alias iterateOverSubpackages = iterateOverSubpackages!(i+1, foldModuleNames!(subpackages[i], apply, acc));
        } else
            alias iterateOverSubpackages = acc;
    }
    alias foldModuleNames = iterateOverSubmodules!(0, iterateOverSubpackages!(0, initVal));
}

template moduleNames(string pkgName){
    alias moduleNames = foldModuleNames!(pkgName, collect, AliasSeq!());
}

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

template Importable(string modName, string memName){
    alias moduleName = modName;
    alias memberName = memName;
    
    alias fullName = Alias!(moduleName~"."~memberName);
    
    template imported(){
        //todo: clean up importing utilities, this is 4th implementation of the same use case; see ioc.meta
        mixin("import "~moduleName~";");
        mixin("alias imported = "~memberName~";");
    }
    
    template qualifies(alias qualifier){
        alias qualifies = qualifier!(imported!());
    }
}


/**
 * apply(alias importable, accumulated...) -> newAccumulated...
 * where importable is alias to Importable with adequate module and member names
 * as template params.
 */
template foldAllMembers(string pkgName, alias qualifier, alias apply, initVal...){
    template implApplyForModuleName(string modName, acc...){
        alias imported = aModule!(modName);
        alias members = aliasSeqOf!([__traits(allMembers, imported)]);
        template iter(int i, iterAcc...){
            static if (i<members.length){
                alias importable = Importable!(modName, members[i]);
                static if (importable.qualifies!(qualifier))
                    alias iter = iter!(i+1, apply!(importable, iterAcc));
                else
                    alias iter = iter!(i+1, iterAcc);
            } else
                alias iter = iterAcc;
        }
        alias implApplyForModuleName = iter!(0, acc);
    }
    alias foldAllMembers = foldModuleNames!(pkgName, implApplyForModuleName, initVal);
}

template collectMemberNamesApply(alias importable, acc...){
    alias collectMemberNamesApply = AliasSeq!(importable.fullName, acc);
}

template collectMemberAliasesApply(alias importable, acc...){
    alias collectMemberAliasesApply = AliasSeq!(importable.imported!(), acc);
}

template memberNames(string pkgName, alias qualifier, initVal...){
    alias memberNames = foldAllMembers!(pkgName, qualifier, collectMemberNamesApply, initVal);
}

template memberAliases(string pkgName, alias qualifier, initVal...){
    alias memberAliases = foldAllMembers!(pkgName, qualifier, collectMemberAliasesApply, initVal);
}

template importables(string pkgName, alias qualifier, initVal...){
    alias importables = foldAllMembers!(pkgName, qualifier, collect, initVal);
}

template isClass(T...) if (T.length == 1){ alias isClass = Alias!(is(T[0] == class)); }
template isInterface(T...) if (T.length == 1){ alias isInterface = Alias!(is(T[0] == interface)); }
template isStruct(T...) if (T.length == 1){ alias isStruct = Alias!(is(T[0] == struct)); }
template isEnum(T...) if (T.length == 1){ alias isEnum = Alias!(is(T[0] == enum)); }

version(unittest){
    template tester(string modName, clazz...){
        pragma(msg, modName, " ", fullyQualifiedName!clazz[0]);
        alias tester = acc;
    }

    
}

/*
 * FIXME: for some reason package modules return empty tuple when treated with allMembers trait:
 *     import toppkg.sub;
 *     pragma(msg, __traits(allMembers, toppkg.sub));
 * shows:
 *     tuple()
 * while:
 *    import toppkg;
 *    pragma(msg, __traits(allMembers, toppkg));
 * shows:
 *     tuple("object")
 * This behaviour is weird, but it works for non-package modules, so for now lets
 * just say that there is no package module support (even though it was supported
 * in generated package index; it is now disabled).
 */

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

template or(templates...) {
    template impl(T...) if (T.length == 1) {
        template iter(int i){
            static if (i < templates.length) {
                alias temp = templates[i];
                static if (temp!(T[0]))
                    alias iter = True;
                else
                    alias iter = iter!(i+1);
            } else {
                alias iter = False;
            }
        }
        alias impl = iter!0;
    }
    alias or = impl;
}

template and(templates...){
    template impl(T...) if (T.length == 1) {
        template iter(int i){
            static if (i < templates.length) {
                alias temp = templates[i];
                static if (!temp!(T[0]))
                    alias iter = False;
                else
                    alias iter = iter!(i+1);
            } else {
                alias iter = True;
            }
        }
        alias impl = iter!0;
    }
    alias and = impl;
}

template isType(T...) {
    alias alternative = or!(isClass, isInterface, isStruct, isEnum);
    alias isType = alternative!T;
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

enum Stereotype;

template isStereotype(Annotation...) if (Annotation.length == 1) {
    static if (isType!Annotation && (is(Annotation[0] == Stereotype) || hasUDA!(Annotation[0], Stereotype)))
        alias isStereotype = True;
    else
        alias isStereotype = False;
}

version(unittest){
    import std.stdio;

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

template hasStereotype(Stereotypes...) if (Stereotypes.length > 0) {
    template impl(T...) if (T.length == 1) {
        template iter(int i){
            static if (i < Stereotypes.length){
                static if ( hasUDA!(T[0], Stereotypes[i]) )
                    alias iter = True;
                else
                    alias iter = iter!(i+1);
            } else {
                alias iter = False;
            }
        }
        alias impl = iter!(0);
    }
    alias hasStereotype = impl;
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

template stringsOnly(A...){
    static if (A.length == 0)
        alias stringsOnly = True;
    else
        static if (is(typeof(A[0]) == string))
            alias stringsOnly = stringsOnly!(A[1..$]);
        else
            alias stringsOnly = False;
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

template foldAllMembers(alias qualifier, alias apply, pkgNames...) if (pkgNames.length > 0 && stringsOnly!(pkgNames)) {
    template iter(int i){
        static if (i < pkgNames.length){
            alias iter = foldAllMembers!(pkgNames[i], qualifier, apply, iter!(i+1));
        } else {
            alias iter = AliasSeq!();
        }
    }
    alias foldAllMembers = iter!(0);
}

template memberNames(alias qualifier, pkgNames...) if (pkgNames.length > 0 && stringsOnly!(pkgNames)) {
    alias memberNames = foldAllMembers!(qualifier, collectMemberNamesApply, pkgNames);
}

template memberAliases(alias qualifier, pkgNames...) if (pkgNames.length > 0 && stringsOnly!(pkgNames)) {
    alias memberAliases = foldAllMembers!(qualifier, collectMemberAliasesApply, pkgNames);
}

template importables(alias qualifier, pkgNames...) if (pkgNames.length > 0 && stringsOnly!(pkgNames)) {
    alias importables = foldAllMembers!(qualifier, collect, pkgNames);
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
