module ioc.poodinis.registering;

import std.traits;

import poodinis;

import ioc.stereotypes;

@Stereotype
enum Component;

struct RegisterFromPackage(Stereotype, string pkgName){
    static shared DependencyContainer container;

    struct ClassHandler(ToRegister){
        static void run(){
            static if (!is(ToRegister == interface))
                RegisterFromPackage.container.register!ToRegister;
        };
    }

    static void run(){
        ScanForStereotype!(Stereotype, pkgName, ClassHandler).run();
    }
}

version (unittest){
    import poodinisTest.a;
    import poodinisTest.b;
    import std.stdio;
    
    class X {
        @Autowire
        AComponent component;
    }
}

unittest {

    auto dependencies = new shared DependencyContainer();
    RegisterFromPackage!(Component, "poodinisTest").container = dependencies;
    RegisterFromPackage!(Component, "poodinisTest").run();
    auto impl = dependencies.resolve!AComponent;
    static assert (is(typeof(impl) == AComponent));
    dependencies.register!X;
    auto x = dependencies.resolve!X;
    static assert (is(typeof(x) == X));
    static assert (is(typeof(x.component) == AComponent));
}

