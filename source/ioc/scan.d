module ioc.scan;

import std.typecons;
import std.meta;
import std.traits;

import ioc.testing;

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

enum Stereotype;

enum isStereotype(Annotation) = is(Annotation == Stereotype) || hasUDA!(Annotation, Stereotype);

version(unittest){
    @Stereotype
    enum Ann;
    
    enum NotAnn;
    
    @Stereotype
    enum AnnWithFields {
        A, B
    }
    
    enum NotAnnWithFields {
        A, B
    }
    
    @Stereotype
    struct AnnStr{}
    
    struct NotAnnStr{}
    
    @Stereotype
    struct AnnStrWithParams{
        string a;
        int b;
    }
    
    struct NotAnnStrWithParams{
        string a;
        int b;
    }
    
    //todo: test templates, e.g. struct A(B, string c){}
}

unittest{
    static assert (isStereotype!Ann);
    static assert (!isStereotype!NotAnn);
    static assert (isStereotype!AnnWithFields);
    static assert (!isStereotype!NotAnnWithFields);
    static assert (isStereotype!AnnStr);
    static assert (!isStereotype!NotAnnStr);
    static assert (isStereotype!AnnStrWithParams);
    static assert (!isStereotype!NotAnnStrWithParams);
}

template forEachWithStereotypeInModule(S, alias moduleAlias, alias templateToApply){
    void impl(){
    foreach (symbol; getSymbolsByUDA!(moduleAlias, S))
        templateToApply!(symbol);
    }
    alias forEachWithStereotypeInModule = impl;
}

version(unittest){
    template toApply(S){
        alias toApply = useLogEntries!(fullyQualifiedName!S);
    }
}

unittest{
    forEachWithStereotypeInModule!(Stereotype, importModule!(__MODULE__), toApply)();
    assert (LogEntries.entries == ["ioc.scan.Ann", "ioc.scan.AnnWithFields", "ioc.scan.AnnStr", "ioc.scan.AnnStrWithParams"]);
    LogEntries.reset();
}
