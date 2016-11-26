module ioc.stereotypes;

import std.typecons;
import std.meta;
import std.traits;

import ioc.testing;
import ioc.scan;
import ioc.meta;
import ioc.traits;


enum Stereotype;

enum isStereotype(Annotation) = is(Annotation == Stereotype) || hasUDA!(Annotation, Stereotype);

version(unittest){
    import std.stdio;

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
    
    @AnnStr
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

/**
 * @S stereotype - struct or enum
 * @moduleAlias name of module to be scanned for stereotypes
 * @templateToApply anything that can be applied as templateToApply!(target)() 
 *                  where target is alias which has UDA
 */
template forEachWithStereotypeInModule(S, string moduleName, alias templateToApply) if(isStereotype!(S)) {
    void impl(){
        mixin importModuleAs!(moduleName, "moduleAlias");
        foreach (symbol; __traits(allMembers, moduleAlias)) {
            mixin("alias symbolAlias = "~moduleName~"."~symbol~";");
            static if (hasUDA!(symbolAlias, S)) {
                alias foo = templateToApply!(symbolAlias);
                foo();
            }
        }
    }
    alias forEachWithStereotypeInModule = impl;
}

version(unittest){
    template logEntriesWithCast(S){
        alias logEntriesWithCast = useLogEntries!(fullyQualifiedName!S);
    }
}

unittest{
    forEachWithStereotypeInModule!(Stereotype, __MODULE__, logEntriesWithCast)();
    assert (LogEntries.isSetEqual([fullyQualifiedName!Ann, fullyQualifiedName!AnnWithFields, fullyQualifiedName!AnnStr, fullyQualifiedName!AnnStrWithParams]));
    LogEntries.reset();
}

/**
 * @S stereotype - struct or enum
 * @moduleAlias name of package to be scanned for stereotypes
 * @templateToApply anything that can be applied as templateToApply!(target)() 
 *                  where target is alias which has UDA
 */
template scanForStereotype(S, string pkgName, alias templateToApply){
    template doApply(string modName){
        void implApply(){
            forEachWithStereotypeInModule!(S, modName, templateToApply)();
        }
        alias doApply = implApply;
    }

    void impl(){
        depthFirst!(pkgName, doApply)();
    }
    alias scanForStereotype = impl;
}

unittest {
    import toppkg.a: MyStereotype;
    scanForStereotype!(MyStereotype, "toppkg", logEntriesWithCast)();
    assert (LogEntries.isSetEqual(["toppkg.sub.y.Y", "toppkg.a.A", "toppkg.b.B", "toppkg.b.BC"]));
}
