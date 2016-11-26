module ioc.proxy;

import ioc.meta;

import std.meta;
import std.traits;
import std.stdio;
import std.typecons;

const bool logGeneratedCode = false;

template Proxy(Original){
    string methodsString(){
        string result = "";
        int unnamedParams = 0;
        foreach (method; allInterfaceMethods!Original()) {
            result ~= method.forImplementation~"{ "~method.returnIfNeeded~" _target."~method.forInvoking~"; }\n";
        }
        return result;
    }

    class ProxyImpl: allInterfaces!(Original) {
        Original _target;
        
        this(Original target){ _target = target; }

        version(unittest){
            static if (logGeneratedCode) {
                pragma(msg, "- Proxy ----------------------------");
                pragma(msg, methodsString());
                pragma(msg, "====================================");
            }
        }
        mixin(methodsString());
    }

    alias Proxy = ProxyImpl;
}

version(unittest) {
    interface A {
        void foo();
        int bar();
        void baz(int i);
        float baz(string);
        void baz(int, string, float);
    }

    alias Proxied = Proxy!A;
}

unittest {
    Proxied proxied;
}

