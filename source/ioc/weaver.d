module ioc.weaver;

import ioc.stdmeta;
import ioc.meta;
import ioc.codebase;
import ioc.extendMethod;

import std.conv;
import std.string;
import std.algorithm;

@Stereotype
enum Aspect;

enum AdviceType {
    NONE, //added only for fluency, to be default value
    BEFORE, AFTER,
    THROW, FINALLY
}

alias NONE = AdviceType.NONE;
alias BEFORE = AdviceType.BEFORE;
alias AFTER = AdviceType.AFTER;
alias THROW = AdviceType.THROW;
alias FINALLY = AdviceType.FINALLY;

template Advice(alias AdviceType type){
    alias adviceType = type;
}

alias Before = Advice!BEFORE;
alias After = Advice!AFTER;

template Pointcut(T...){
    alias matchers = T;
};

template name(string s){};
template method(string s){};

alias isAspect = and!(isClass, hasStereotype!(Aspect));

template extractPointcuts(alias ClassOrMethod){
    alias allAttrs = AliasSeq!(__traits(getAttributes, ClassOrMethod));
    template iter(int i=0, acc...){
        static if (i<allAttrs.length){
            alias attr = allAttrs[i];
            static if (__traits(compiles, TemplateOf!(attr)) && __traits(isSame, Pointcut, TemplateOf!(attr))){
                alias iter = iter!(i+1, Alias!(attr), acc);
            } else
                alias iter = iter!(i+1, acc);
        } else
            alias iter = acc;
    }
    alias extractPointcuts = iter!();
}

template extractAdviceTypes(alias ClassOrMethod){
    alias allAttrs = AliasSeq!(__traits(getAttributes, ClassOrMethod));
    template iter(int i=0, acc...){
        static if (i<allAttrs.length){
            alias attr = allAttrs[i];
            static if (__traits(compiles, TemplateOf!(attr))) {
                static if (__traits(isSame, Advice, TemplateOf!(attr))){
                    alias iter = iter!(i+1, TemplateArgsOf!(attr), acc);
                } else
                    alias iter = iter!(i+1, acc);
            } else
                static if(__traits(isSame, attr, Advice)){
                    alias iter = iter!(i+1, Alias!NONE, acc);
                } else
                    alias iter = iter!(i+1, acc);

        } else
            alias iter = acc;
    }
    alias extractAdviceTypes = iter!();
}

template mergePointcuts(alias p1, alias p2){
    //todo: make 'template ... if (...)' contract out of those asserts
    static assert(__traits(compiles, TemplateOf!p1) && __traits(isSame, Pointcut, TemplateOf!p1));
    static assert(__traits(compiles, TemplateOf!p2) && __traits(isSame, Pointcut, TemplateOf!p2));
    alias mergePointcuts = Pointcut!(p1.matchers, p2.matchers);
}

template mergeTypes(alias t1, alias t2){}

template WeavingCommand(alias p, alias AdviceType at){
    alias pointcut = p;
    alias adviceType = at;
}

template crossMergePointcuts(alias classPointcuts, alias methodPointcuts){
    //if only class or only method is annotated, take pointcuts from the other one
    static if (classPointcuts.length * methodPointcuts.length == 0) {
        alias crossMergePointcuts = AliasSeq!(classPointcuts.sequence, methodPointcuts.sequence);
    } else {
        template iter1(int i=0, acc1...){
            static if (i<classPointcuts.length){
                template iter2(int j=0, acc2...){
                    static if (j<methodPointcuts.length) {
                        alias iter2 = iter2!(j+1, mergePointcuts!(classPointcuts.sequence[i], methodPointcuts.sequence[j]), acc2);
                    }
                    else
                        alias iter2 = acc2;
                }
                alias iter1 = iter1!(i+1, iter2!(), acc1);
            } else
                alias iter1 = acc1;
        }
        alias crossMergePointcuts = iter1!();
    }
}

template crossMergeTypes(alias classAdviceTypes, alias methodAdviceTypes){
    template iter1(int i=0, acc1...){
        static if (i<classAdviceTypes.length){
            template iter2(int j=0, acc2...){
                static if (j<methodAdviceTypes.length) {
                    alias classType = classAdviceTypes._[i];
                    alias methodType = methodAdviceTypes._[j];
                    //todo: alternative approach: skip clashing types
                    static assert (classType * methodType == 0);
                    alias result = Alias!(cast(AdviceType)(classType + methodType));
                    alias iter2 = iter2!(j+1, result, acc2);
                } else
                    alias iter2 = acc2;
            }
            alias iter1 = iter1!(i+1, iter2!(), acc1);
        } else
            alias iter1 = acc1;
    }
    alias crossMergeTypes = iter1!();
}

template crossMerge(alias classPointcuts, alias classAdviceTypes, alias methodPointcuts, alias methodAdviceTypes){
    alias mergedPointcuts = crossMergePointcuts!(classPointcuts, methodPointcuts);
    alias mergedTypes = crossMergeTypes!(classAdviceTypes, methodAdviceTypes);
    template iter1(int i=0, acc1...){
        static if (i<mergedPointcuts.length){
            template iter2(int j=0, acc2...){
                static if (j<mergedTypes.length)
                    alias iter2 = iter2!(j+1, WeavingCommand!(mergedPointcuts[i], mergedTypes[j]), acc2);
                else
                    alias iter2 = acc2;
            }
            alias iter1 = iter1!(i+1, iter2!(), acc1);
        } else
            alias iter1 = acc1;
    }
    alias crossMerge = iter1!();
}

//todo: probably move to ioc.meta
template allMembersWithOverloads(alias Class){
    alias memberNames = seq!(__traits(derivedMembers, Class)); //todo: allMembers?
    template iter(int i=0, acc...){
        static if (i<memberNames.length){
            alias iter = iter!(i+1, __traits(getOverloads, Class, memberNames._[i]), acc);
        } else
            alias iter = acc;
    }
    alias allMembersWithOverloads = iter!();
}

template gatherCommandsFromAspectClass(alias AspectClass){
    alias classPointcuts = seq!(extractPointcuts!(AspectClass));
    alias classAdviceTypes = seq!(extractAdviceTypes!(AspectClass));
    alias overloads = allMembersWithOverloads!(AspectClass);
    template iter(int i=0, acc...){
        static if (i<overloads.length){
            alias iter = iter!(i+1, crossMerge!(
                classPointcuts,
                classAdviceTypes,
                seq!(extractPointcuts!(overloads[i])),
                seq!(extractAdviceTypes!(overloads[i])),
            ), acc);
        } else
            alias iter = acc;
    }
    alias gatherCommandsFromAspectClass = iter!();
}

template collectCommands(Aspects...) { //todo: constraint: all(isClass, Aspects)
    template iter(int i=0, acc...){
        static if (i<Aspects.length) {
            alias aspect = Aspects[i];
            alias commands = gatherCommandsFromAspectClass!(aspect);
            pragma(msg, "Aspect ", fullyQualifiedName!aspect, " introduces ", to!string(commands.length), " weaving command");
            alias iter = iter!(i+1, commands, acc);
        } else
            alias iter = acc;
    }
    alias collectCommands = iter!();
}

template Weaver(packageNames...) if (stringsOnly!(packageNames) && packageNames.length > 0){
    alias Aspects = memberAliases!(isAspect, "ioc", packageNames);
    pragma(msg, "Aspects: ", Aspects);
    alias Commands = collectCommands!(Aspects);
    pragma(msg, "Weaving commands: ", Commands.stringof);

    template weave(T){
        alias weave = T;
    }
}
