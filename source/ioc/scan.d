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
 * @ModuleNameCallback anything that can be applied as ModuleNameCallback!(string submodule).run()
 */
struct DepthFirst(string name, alias ModuleNameCallback){
    static void run(){
        foreach(subpkg; EnumMembers!(getPackageIndex!(name).subpackages))
            DepthFirst!(subpkg, ModuleNameCallback).run();
        foreach(submodule; EnumMembers!(getPackageIndex!(name).submodules)) {
            ModuleNameCallback!(submodule).run();
        }
    }
}

version(unittest){
    import std.stdio;

    struct Wln(string txt){
        static void run(){
            writeln(txt);
        }
    }
    
    struct UseLogEntries(string s){
        static void run(){
            LogEntries.add(s);
        }
    }
}

unittest {
    DepthFirst!("toppkg", UseLogEntries).run();
    assert(LogEntries.entries == ["toppkg.subpkg.x", "toppkg.sub", "toppkg.sub.y", "toppkg", "toppkg.a", "toppkg.b"]);
    LogEntries.reset();
}

