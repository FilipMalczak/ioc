module ioc.container;

import ioc.stdmeta;
import ioc.meta;
import ioc.proxy;
import ioc.testing;
import ioc.codebase;
import ioc.weaver;

import poodinis;

import std.stdio;

import std.string;
import std.regex;
import std.algorithm;

//todo: collect UDAs to one place?
//todo: organize public API facing enduser, export it in package module

@Stereotype
enum Component;

//todo: profile in runtime support, probably as map profile name -> container
//todo: stereotypes should be annotable with @Autobind and component classes with @DisableAutobinding

synchronized class IocContainer(packageNames...) if (stringsOnly!(packageNames) && packageNames.length > 0){
    //todo: make those nicer, add compilation flags to control this output
    pragma(msg, "Initializing IoC container for following packages: ", packageNames);
    alias Stereotypes = memberAliases!(isStereotype, "ioc", packageNames);
    pragma(msg, "Stereotypes: ", Stereotypes);

    protected DependencyContainer poodinisContainer;
    alias weaver = Weaver!packageNames;

    this(){
        poodinisContainer = new DependencyContainer();
        
        foreach (T; memberAliases!(hasStereotype!Stereotypes, packageNames)){
            static if (!isAspect!(T)) {
                static if (is(T == interface)) {
                    bindIfPossible!(T)();
                }  else static if (is(T == class)) {
                    register!(T)();
                }
            }
        }
    }
        
    void register(alias T1)(){
        alias weaved = weaver.weave!(T1);
        poodinisContainer.register!(T1, weaved)();
    }
    
    void bind(alias T1, alias T2)(){
        poodinisContainer.register!(T1, weaver.weave!(T2))();
    }
    
    void unregister(alias T1)(){
        poodinisContainer.removeRegistration!(weaver.weave!(T1))();
    }
    
    protected void bindIfPossible(alias I)(){
        template extends(T...) if (T.length == 1){
            static if (is(T[0]: I))
                alias extends = True;
            else
                alias extends = False;
        }
        alias candidates = importables!(and!(hasStereotype!Stereotypes, extends, isClass), packageNames);
        static if (!(is(typeof(candidates) == void)) && candidates.length == 1) {
            alias Impl = candidates[0].imported!();
            bind!(I, Impl)();
        }
    }
    
    T resolve(alias T)(){
        return poodinisContainer.resolve!(T)();
    }
}
