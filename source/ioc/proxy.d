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
                pragma(msg, "- Proxy ----------------------------");
                pragma(msg, methodsString());
                pragma(msg, "====================================");
            }
        }
        mixin(methodsString());
    }

    alias Proxy = ProxyImpl;
}
