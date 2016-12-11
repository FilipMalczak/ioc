module ioc.proxy;

import ioc.meta;
import ioc.logging;
import ioc.stdmeta;

import std.stdio;

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
                mixin debugLog!("- Proxy ----------------------------");
                mixin debugLog!(methodsString());
                mixin debugLog!("====================================");
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
    //todo: do real testing
}

