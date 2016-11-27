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
 *                  where target is type which has UDA
 */
struct EachWithStereotypeInModule(S, string moduleName, alias TemplateToApply) if(isStereotype!(S)) {
    static void run(){
        mixin importModuleAs!(moduleName, "moduleAlias");
        foreach (symbol; __traits(allMembers, moduleAlias)) {
            mixin("alias symbolAlias = "~moduleName~"."~symbol~";");
            static if (hasUDA!(symbolAlias, S)) {
                TemplateToApply!(symbolAlias).run();
            }
        }
    };
}

version(unittest){
    struct LogEntriesWithCast(S){
        static void run() {
            UseLogEntries!(fullyQualifiedName!S).run();
        }
    }
}

unittest{
    EachWithStereotypeInModule!(Stereotype, __MODULE__, LogEntriesWithCast).run();
    assert (LogEntries.isSetEqual([fullyQualifiedName!Ann, fullyQualifiedName!AnnWithFields, fullyQualifiedName!AnnStr, fullyQualifiedName!AnnStrWithParams]));
    LogEntries.reset();
}

/**
 * @S stereotype - struct or enum
 * @moduleAlias name of package to be scanned for stereotypes
 * @templateToApply anything that can be applied as templateToApply!(target)() 
 *                  where target is alias which has UDA
 */
struct ScanForStereotype(S, string pkgName, alias TemplateToApply){
    struct DoApply(string modName){
        static void run(){
            EachWithStereotypeInModule!(S, modName, TemplateToApply).run();
        };
    }

    static void run(){
        DepthFirst!(pkgName, DoApply).run();
    };
}

unittest {
    import toppkg.a: MyStereotype;
    ScanForStereotype!(MyStereotype, "toppkg", LogEntriesWithCast).run();
    assert (LogEntries.isSetEqual(["toppkg.sub.y.Y", "toppkg.a.A", "toppkg.b.B", "toppkg.b.BC"]));
}
