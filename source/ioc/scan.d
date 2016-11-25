module ioc.scan;

import std.typecons;
import std.meta;
import std.traits;

template importModule(string name){
    mixin("import "~name~";");
    mixin("alias importModule = "~name~";");
}

template getPackageIndex(string name){
    alias getPackageIndex = importModule!(name~"._index").Index;
}

template depthFirst(string name, alias moduleNameCallback){
    void impl(){
        foreach(subpkg; EnumMembers!(getPackageIndex!(name).subpackages))
            depthFirst!(subpkg, moduleNameCallback)();
        foreach(submodule; EnumMembers!(getPackageIndex!(name).submodules))
            moduleNameCallback!(submodule)();
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
}

unittest {
    depthFirst!("toppkg", wln)();
}

