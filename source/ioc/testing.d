﻿module ioc.testing;

version(unittest){
    import std.conv;
    import std.algorithm.searching;
    
    import ioc.stereotypes;
    
    struct GenericLogEntries(E) {
        static E[] entries = [];
        
        static private E stringize(T...)(T args){
            E result = "";
            foreach (a; args)
                result ~= to!E(a);
            return result;
        }
        
        static void add(T...)(T args){
            entries ~= stringize(args);
        }
        
        static bool contains(T...)(T args){
            return entries.canFind(stringize(args));
        }
        
        static bool containsAll(E[] args){
            foreach (a; args)
                if (!contains(a))
                    return false;
            return true;
        }
        
        static bool isSetEqual(E[] args){
            return args.length == entries.length && containsAll(args);
        }
        
        static expect(T...)(T args){
            assert(contains(args));
        }
        
        static size_t indexOf(T...)(T args){
            return entries.length - entries.find(stringize(args)).length;
        }
        
        static void reset(){
            entries = [];
        }
    }
    
    alias LogEntries = GenericLogEntries!string;
    
    enum SimpleAnnotation;
    
    @Stereotype
    enum SimpleStereotype;
}
