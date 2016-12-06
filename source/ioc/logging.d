module ioc.logging;

enum debugLoggingOn = true;

enum logGeneratedCode = false;

mixin template debugLog(Arg...){
    static if (debugLoggingOn){
        pragma(msg, Arg.expand);
    }
}
