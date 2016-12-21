module ioc.testing;

version(unittest){
    import std.conv;
    import std.algorithm.searching;

    public import std.conv: to;
    public import std.stdio: writeln;
    public import std.algorithm.searching: canFind;

    import ioc.stdmeta;
    import ioc.meta;
    public import ioc.meta: seq;
    import ioc.logging;
    
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

    //fixme: has similiar version in container
    template inSeq(string val, seq...){
        static if (seq.length == 0)
            alias inSeq = False;
        else
            static if (seq[0] == val)
                alias inSeq = True;
            else
                alias inSeq = inSeq!(val, seq[1..$]);
    }

    void assertSetsEqual(U: W, V: W, W)(U[] expected, V[] result){
        assert(expected.length == result.length);
        foreach (element; expected)
            assert(result.canFind(element));
    }

    mixin template assertSequencesSetEqual(alias expected, alias result){
        static assert (expected.sequence.length == result.sequence.length);
        mixin template iter(int i){
            static if (i<expected.sequence.length){
                alias name = Alias!(expected.sequence[i]);
                static assert (inSeq!(name, result.sequence));
                mixin iter!(i+1);
            }
        }
        mixin iter!0;
    }



/*    enum SimpleAnnotation;
    
    @Stereotype
    enum SimpleStereotype;*/
}
