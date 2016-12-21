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
alias Throw = Advice!THROW;
alias Finally = Advice!FINALLY;

template Pointcut(T...){
    alias matchers = T;

    template matches(Target, string foo, Args...){
        template iter(int i=0){
            static if (i<matchers.length){
                alias matcher = matchers[i];
                static if (matcher.matches!(Target, foo, Args)) {
                    alias iter = iter!(i+1);
                } else {
                    alias iter = False;
                }
            } else {
                alias iter = True;
            }
        }
        alias matches = iter!();
    }
};

template name(string s){
    //todo: rename to matchClassName
    bool match(string rule, string target){
        return match(rule.split("."), target.split("."));
    }

    //todo: rename to matchClassName
    bool match(string[] ruleParts, string[] targetParts){
        if (ruleParts.length * targetParts.length == 0) {
            return ruleParts == targetParts;
        }
        if (ruleParts[0] == "**") {
            auto restOfRule = ruleParts[1..$];
            foreach (i; 0..targetParts.length+1) {
                if (match (restOfRule, targetParts[i..$])) {
                    return true;
                }
            }
            return false;
        } else if (ruleParts[0] == "*")
            return match(ruleParts[1..$], targetParts[1..$]);
        return ruleParts[0] == targetParts[0] && match(ruleParts[1..$], targetParts[1..$]);
    }

    template matches(Target, string foo, Args...){
        alias matches = Alias!(match(s, fullyQualifiedName!Target));
    }
};
template method(string s, T...){
    template matches(Target, string foo, Args...){
        static if(s == "*")
            alias matches = Alias!(is(seq!T == seq!Args));
        else static if (s == "**")
            alias matches = True;
        else
            alias matches = Alias!(s == foo && is(seq!T == seq!Args));
    }
};

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

struct WeavingCommand(alias p, alias AdviceType at, alias AspectType, string foo, Args...){
    alias pointcut = p;
    alias adviceType = at;
    alias aspectClass = AspectType;
    alias adviceMethodName = foo;
    alias adviceMethodArgs = Args;

    template matches(alias Target, string method, MethodArgs...){
        alias matches = p.matches!(Target, method, MethodArgs);
    }

    template execute(alias Target, string method, MethodArgs...){
        alias interceptor = Interceptor!(Target, method, false, MethodArgs);
    
        class WeavingInterceptor: InterceptorAdapter!(Target, method, false, MethodArgs) {
            AspectType _aspectInstance = new AspectType();
            alias _adviceMethod = getTarget!(_aspectInstance, foo, Args);
            static if (adviceType == BEFORE) {
                override void before(interceptor.params p){
                    mixin("_aspectInstance."~foo~"(p);");
                }
            } else static if (adviceType == AFTER) {
                static if (is(interceptor.returned == void)) {
                    override void after(interceptor.params p){
                        mixin("_aspectInstance."~foo~"(p);");
                    }
                } else {
                    static if (is(ReturnType!(_adviceMethod) == void)) 
                        override interceptor.returned after(interceptor.params p, interceptor.returned r){
                            //mixin("return _aspectInstance."~foo~"(p, r);");
                            mixin("_aspectInstance."~foo~"(p, r);");
                            return r;
                        }
                    else {
                        override interceptor.returned after(interceptor.params p, interceptor.returned r){
                            mixin("return _aspectInstance."~foo~"(p, r);");
                        }
                    }
                }
            } else static if (adviceType == THROW) {
                static if (is(ReturnType!(_adviceMethod) == void)) {
                    override interceptor.returned hijackException(Throwable t){
                        static if (Parameters!_adviceMethod.length == 0)
                            mixin("_aspectInstance."~foo~"();");
                        else
                            mixin("_aspectInstance."~foo~"(t);");
                        throw t;
                    }
                } else {
                    override interceptor.returned hijackException(Throwable t){
                        static if (Parameters!_adviceMethod.length == 0)
                            mixin("return _aspectInstance."~foo~"();");
                        else
                            mixin("return _aspectInstance."~foo~"(t);");
                    }
                }
            } else static if (adviceType == FINALLY) {
                override void scopeExit(params, Throwable){
                    mixin("_aspectInstance."~foo~"();");
                }
            }
        }
        mixin("class WeaverOf_"~AspectType.stringof~"_"~foo~" : WeavingInterceptor {}");
        mixin("alias execute = ExtendMethod!(Target, WeaverOf_"~AspectType.stringof~"_"~foo~");");
    }
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
    template withoutNones(types...){
        template iter(int i, acc...){
            static if (i < types.length)
                static if (types[i] > 0)
                    alias iter = iter!(i+1, types[i], acc);
                else
                    alias iter = iter!(i+1, acc);
            else
                alias iter = acc;
        }
        alias withoutNones = iter!(0);
    }
    static if (classAdviceTypes.length * methodAdviceTypes.length == 0) {
        alias crossMergeTypes = withoutNones!(classAdviceTypes.sequence, methodAdviceTypes.sequence);
        
    } else {
        template iter1(int i=0, acc1...){
            static if (i<classAdviceTypes.length){
                template iter2(int j=0, acc2...){
                    static if (j<methodAdviceTypes.length) {
                        alias classType = classAdviceTypes._[i];
                        alias methodType = methodAdviceTypes._[j];
                        //todo: alternative approach: skip clashing types
                        static assert (classType * methodType == 0);
                        //todo: alternative approach: error on no real advice type
                        static if (classType + methodType > 0) {
                            alias result = Alias!(cast(AdviceType)(classType + methodType));
                            alias iter2 = iter2!(j+1, result, acc2);
                        } else {
                            alias iter2 = iter2!(j+1, acc2);
                        }
                    } else
                        alias iter2 = acc2;
                }
                alias iter1 = iter1!(i+1, iter2!(), acc1);
            } else
                alias iter1 = acc1;
        }
        alias crossMergeTypes = iter1!();
    }
}

template crossMerge(alias classPointcuts, alias classAdviceTypes,
                    alias methodPointcuts, alias methodAdviceTypes,
                    alias AspectType, string foo, Args...){
    alias mergedPointcuts = crossMergePointcuts!(classPointcuts, methodPointcuts);
    alias mergedTypes = crossMergeTypes!(classAdviceTypes, methodAdviceTypes);
    template iter1(int i=0, acc1...){
        static if (i<mergedPointcuts.length){
            template iter2(int j=0, acc2...){
                static if (j<mergedTypes.length) {
                    alias iter2 = iter2!(j+1,
                        WeavingCommand!(
                            mergedPointcuts[i], mergedTypes[j],
                            AspectType, foo, Args
                        ),
                        acc2
                    );
                } else
                    alias iter2 = acc2;
            }
            alias iter1 = iter1!(i+1, iter2!(), acc1);
        } else
            alias iter1 = acc1;
    }
    alias crossMerge = iter1!();
}

template gatherCommandsFromAspectClass(alias AspectClass){
    alias classPointcuts = seq!(extractPointcuts!(AspectClass));
    alias classAdviceTypes = seq!(extractAdviceTypes!(AspectClass));
    alias overloads = derivedOverloads!(AspectClass);
    template iter(int i=0, acc...){
        static if (i<overloads.length){
            alias iter = iter!(i+1, crossMerge!(
                classPointcuts,
                classAdviceTypes,
                seq!(extractPointcuts!(overloads[i])),
                seq!(extractAdviceTypes!(overloads[i])),
                AspectClass, __traits(identifier, overloads[i]), Parameters!(overloads[i])
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
            pragma(msg, "Aspect ", fullyQualifiedName!aspect, " introduces ", to!string(commands.length), " weaving command(s)");
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
    pragma(msg, to!string(Commands.length), " weaving command(s) found based on ", to!string(Aspects.length), " aspect(s)");

    template weaveInCommands(alias Target, string foo, Args...){
        template iter(int i=0, alias acc){
            static if (i<Commands.length) {
                alias cond = Alias!(Commands[i].matches!(Target, foo, Args));
                static if (cond) {
                    alias iter = iter!(i+1, Commands[i].execute!(acc, foo, Args));
                } else {
                    alias iter = iter!(i+1, acc);
                }
            } else
                alias iter = acc;
        }
        alias weaveInCommands = iter!(0, Target);
    }

    template weave(T){
        alias overloads = interfaceOverloads!T;
        template iter(int i=0, alias acc){
            static if (i<overloads.length){
                alias foo = Alias!(__traits(identifier, overloads[i]));
                alias Args = Parameters!(overloads[i]);
                alias iter = iter!(i+1, weaveInCommands!(T, foo, Args));
            } else
                alias iter = acc;
        }
        alias weave = iter!(0, T);
    }
}
