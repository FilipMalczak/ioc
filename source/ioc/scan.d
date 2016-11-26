module ioc.scan;

import std.typecons;
import std.meta;
import std.traits;

import ioc.testing;

import ioc.meta: importModule = aModule;

template getPackageIndex(string name){
    alias getPackageIndex = importModule!(name~"._index").Index;
}

/**
 * @name name of the package to be traversed
 * @moduleNameCallback anything that can be applied as moduleNameCallback!(submodule)()
 */
template depthFirst(string name, alias moduleNameCallback){
    void impl(){
        foreach(subpkg; EnumMembers!(getPackageIndex!(name).subpackages))
            depthFirst!(subpkg, moduleNameCallback)();
        foreach(submodule; EnumMembers!(getPackageIndex!(name).submodules)) {
            alias foo = moduleNameCallback!(submodule);
            foo();
        }
    }
    alias depthFirst = impl;
}

version(unittest){
    import std.stdio;

    template wln(string txt){
        void impl(){
            writeln(txt);
        }
        alias wln = impl;
    }
    
    template useLogEntries(string s){
        void impl(){
            LogEntries.add(s);
        }
        alias useLogEntries = impl;
    }
}

unittest {
    depthFirst!("toppkg", useLogEntries)();
    assert(LogEntries.entries == ["toppkg.subpkg.x", "toppkg.sub", "toppkg.sub.y", "toppkg", "toppkg.a", "toppkg.b"]);
    LogEntries.reset();
}

