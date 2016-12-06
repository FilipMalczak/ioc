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

/**
 * apply(string moduleName, <X>, accumulated...) -> newAccumulated...
 * where <X> is anything that can be returned by
 *   __traits(getMember, aliasedModule, __traits(allMembers, aliasedModule)[i])
 * where i varies for every fold.
 */
template foldAllMembers(string pkgName, alias qualifier, alias apply, initVal...){
    template implApplyForModuleName(string modName, acc...){
        alias imported = aModule!(modName);
        alias members = aliasSeqOf!([__traits(allMembers, imported)]);
        template iter(int i, iterAcc...){
            static if (i<members.length){
                alias qualifies = qualifier!(__traits(getMember, imported, members[i]));
                static if (qualifies)
                    alias iter = iter!(i+1, apply!(modName, __traits(getMember, imported, members[i]), iterAcc));
                else
                    alias iter = iter!(i+1, iterAcc);
            } else
                alias iter = iterAcc;
        }
        alias implApplyForModuleName = iter!(0, acc);
    }
    alias foldAllMembers = foldModuleNames!(pkgName, implApplyForModuleName);
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

    template collectNames(string modName, clazz, acc...){
        alias collectNames = AliasSeq!(fullyQualifiedName!clazz, acc);
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
            foldAllMembers!("toppkg", isClass, collectNames, AliasSeq!())
        )
    );
    mixin assertSequencesSetEqual!(
        seq!(
            "toppkg.sub.y.Y"
        ),
        seq!(
            foldAllMembers!("toppkg", isEnum, collectNames, AliasSeq!())
        )
    );
    mixin assertSequencesSetEqual!(
        seq!(
            "toppkg.b.C", "toppkg.b.B", "toppkg.a.A", "toppkg.a.MyStereotype"
        ),
        seq!(
            foldAllMembers!("toppkg", isStruct, collectNames, AliasSeq!())
        )
    );
    mixin assertSequencesSetEqual!(
        seq!(
            "toppkg.subpkg.x.AnInterface"
        ),
        seq!(
            foldAllMembers!("toppkg", isInterface, collectNames, AliasSeq!())
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
            foldAllMembers!("toppkg", or!(isClass, isInterface), collectNames, AliasSeq!())
        )
    );

    mixin assertSequencesSetEqual!(
        seq!(
            "toppkg.b.BC"
        ),
        seq!(
            foldAllMembers!("toppkg", and!(isClass, nameStartsWithB), collectNames, AliasSeq!())
        )
    );
}
