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
    pragma(msg, "foldModuleNames(", pkgName, ", ...)");
    alias submodules = EnumMembers!(getPackageIndex!(pkgName).submodules);
    alias subpackages = EnumMembers!(getPackageIndex!(pkgName).subpackages);
    pragma(msg, "submodules ", submodules);
    pragma(msg, "subpackages", subpackages);
    template iterateOverSubmodules(int i, acc...){
        pragma(msg, "foldModuleNames(", pkgName, ", ...) => iterateOverSubmodules(", i, ", ", acc, ")");
        static if (i<submodules.length){
            alias iterateOverSubmodules = iterateOverSubmodules!(i+1, apply!(submodules[i], acc));
        } else
            alias iterateOverSubmodules = acc;
    }
    template iterateOverSubpackages(int i, acc...){
        pragma(msg, "foldModuleNames(", pkgName, ", ...) => iterateOverSubpackages(", i, ", ", acc, ")");
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
    alias collected = moduleNames!("toppkg");
    alias expected = aliasSeqOf!(["toppkg.b", "toppkg.a", "toppkg.sub.y", "toppkg.subpkg.x"]);
    //alias expected = aliasSeqOf!(["toppkg.b", "toppkg.a", "toppkg", "toppkg.sub.y", "toppkg.sub", "toppkg.subpkg.x"]);
    static assert (expected.length == collected.length);
    foreach (name; expected) {
        static assert (inSeq!(name, collected));
    }
}

/**
 * apply(string moduleName, <X>, accumulated...) -> newAccumulated...
 * where <X> is anything that can be returned by
 *   __traits(getMember, aliasedModule, __traits(allMembers, aliasedModule)[i])
 * where i varies for every fold.
 */
template foldAllMembers(string pkgName, alias qualifier, alias apply, initVal...){
    template implApplyForModuleName(string modName, acc...){
        pragma(msg, "implApply...("~modName~", ...)");
        alias imported = aModule!(modName);
        alias members = aliasSeqOf!([__traits(allMembers, imported)]);
        pragma(msg, "members: ", members);
        template iter(int i, iterAcc...){
            static if (i<members.length){
                pragma(msg, "member: ", members[i]);
                alias qualifies = qualifier!(__traits(getMember, imported, members[i]));
                pragma(msg, "qualifies ", qualifies);
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
 * just say that there is not package module support (even though it was supported
 * in generated package index; it is now disabled).
 */

unittest {
    alias collected = foldAllMembers!("toppkg", isClass, collectNames, AliasSeq!());
    alias expected = aliasSeqOf!(["toppkg.b.BC", "toppkg.sub.y.DeeplyNestedClass"]);
    static assert (expected.length == collected.length);
    foreach (name; expected) {
        static assert (inSeq!(name, collected));
    }
}
