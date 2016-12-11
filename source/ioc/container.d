module ioc.container;

import ioc.stdmeta;
import ioc.meta;
import ioc.proxy;
import ioc.testing;
import ioc.codebase;

import poodinis;

import std.stdio;
import std.string;
import std.algorithm;

//todo: collect UDAs to one place?
//todo: organize public API facing enduser, export it in package module

@Stereotype
enum Component;

//todo: profile in runtime support, probably as map profile name -> container

synchronized class IocContainer(packageNames...) if (stringsOnly!(packageNames) && packageNames.length > 0){
    protected DependencyContainer poodinisContainer;
    
    alias Stereotypes = memberAliases!(isStereotype, "ioc", packageNames);
    
    this(){
        poodinisContainer = new DependencyContainer();
        
        foreach (T; memberAliases!(hasStereotype!Stereotypes, packageNames)){
            static if (is(T == interface)) {
                bindIfPossible!(T)();
            }  else static if (is(T == class)) {
                register!(T)();
            }
        }
    }
    
    void register(T1)(){
        poodinisContainer.register!(T1)();
    }
    
    void bind(T1, T2)(){
        poodinisContainer.register!(T1, T2)();
    }
    
    void unregister(T1)(){
        poodinisContainer.removeRegistration!(T1)();
    }
    
    protected void bindIfPossible(I)(){
        template extends(T...) if (T.length == 1){
            static if (is(T[0]: I))
                alias extends = True;
            else
                alias extends = False;
        }
        //todo: some way to disable autobinding, probably with some annotation
        alias candidates = importables!(and!(hasStereotype!Stereotypes, extends, isClass), packageNames);
        static if (!(is(typeof(candidates) == void)) && candidates.length == 1) {
            alias Impl = candidates[0].imported!();
            bind!(I, Impl)();
        }
    }
    
    T resolve(T)(){
        return poodinisContainer.resolve!(T)();
    }
}

unittest {
    import poodinisTest.a;
    auto c = new shared IocContainer!("toppkg", "poodinisTest")();
    writeln(c.resolve!I());
}
