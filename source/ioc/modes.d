module ioc.modes;

import std.stdio;
import std.algorithm;
import std.conv;
import std.traits;

interface ExecNode {
    void execute(this T)(string[] args);
}

interface Command: ExecNode {}

class Mode: ExecNode {
    void execute(this T)(string[] args){
        foreach (i, fieldName; FieldNameTuple!T) {
            alias fieldType = Fields!(T)[i];
            if (is(fieldType: ExecNode)){
                mixin("fieldType val = (cast(T) this)."~fieldName~";");
                if (val !is null)
                    val.execute(args);
            }
        }
    }
}

//todo: move to utils module or smth
string prefix(int lvl, string indent="  "){
    string result = "";
    while (lvl--)
        result ~= indent;
    return result;
}

string toStringTree(T: ExecNode)(T inst, int lvl = 0, string name="[ROOT]"){
    string result = prefix(lvl)~fullyQualifiedName!T~" "~name~" = \n";
    //writeln(__LINE__, "result: |", result);
    foreach (i, fieldName; FieldNameTuple!T) {
        alias fieldType = Fields!(T)[i];
        //mixin("fieldType val = inst."~fieldName~";");
        //writeln(__LINE__, "GETSHERE", i, fieldName);
        fieldType val = __traits(getMember, inst, fieldName);
        //writeln(__LINE__, "GETSHERE", val);
        static if (is(fieldType: ExecNode)) {
            if (val !is null)
                result ~= toStringTree!fieldType(val, lvl+1, fieldName);
            else {
                result ~= prefix(lvl+1)~fullyQualifiedName!fieldType~" "~fieldName~" = null\n";
            }
            //writeln(__LINE__, "result: |", result);
        } else {
            result ~= prefix(lvl+1)~fullyQualifiedName!fieldType~" "~fieldName~" = "~to!string(val)~"\n";
            //writeln(__LINE__, "result: |", result);
        }
    }
    return result;
}

struct Configurator(T: ExecNode){
    string[] args;

    protected string[] argsForField(FT, string fieldName)(){
        static if (is(FT: ExecNode))
            return [ fieldName ];
        else static if (fieldName.length == 1)
            return [ "-"~fieldName ];
        else
            return [ "--"~fieldName ];
    }

    protected auto idxInArgs(FT, string fieldName)(){
        foreach (searched; argsForField!(FT, fieldName)()) {
            auto idx = countUntil(args, searched);
            //writeln("idxInArgs ", searched, " -> ", idx);
            if (idx>=0) {
                //writeln("idxInArgs returns ", idx);
                return idx;
            }
        }
        //writeln("idxInArgs returns -1");
        return -1;
    }

    protected bool inArgs(FT, string fieldName)(){
        auto idx = idxInArgs!(FT, fieldName)();
        return idx >= 0;
    }

    protected void consumeArg(FT, string fieldName)(){
        auto consumeAfter = select!(is(FT: bool) || is(FT: ExecNode))(0, 1);
        auto idx = idxInArgs!(FT, fieldName)();
        //writeln(FT.stringof, " ", fieldName, " -> ", idx);
        if (idx >= 0)
            args = args[0..idx] ~ args[idx+consumeAfter+1 .. $];
    }

    protected FT parseValue(FT, string fieldName)() if (!is(FT: ExecNode)) {
        auto idx = idxInArgs!(FT, fieldName)();
        FT result;
        static if (is(FT: bool))
            result = idx>=0;
        else
            result = to!FT(args[idx+1]);
        consumeArg!(FT, fieldName)();
        return result;
    }

    protected FT parseValue(FT: ExecNode, string fieldName)(){
        consumeArg!(FT, fieldName)();
        FT ft = new FT();
        Configurator!(FT) conf = Configurator!(FT)(args);
        conf.configure(ft);
        args = conf.args;
        return ft;
    }

    protected void processField(FT, string fieldName)(ref T inst){
        if (is(FT: bool) || inArgs!(FT, fieldName)()) {
            FT val = parseValue!(FT, fieldName)();
            mixin("inst."~fieldName~" = val;");
        }
    }

    protected void eachMatchingField(alias pred)(ref T inst){
        foreach (i, fieldName; FieldNameTuple!T) {
            alias fieldType = Fields!(T)[i];
            static if (pred!(fieldType, fieldName)){
                processField!(fieldType, fieldName)(inst);
            }
        }
    }

    protected enum isMode(FT, string fn) = is(FT: Mode);
    protected enum isCommand(FT, string fn) = is(FT: Command);
    protected enum isntExecNode(FT, string fn) = !is(FT: ExecNode);

    void configure(T)(ref T inst){
        eachMatchingField!(isMode)(inst);
        static if (is(T: Mode))
            eachMatchingField!(isCommand)(inst);
        eachMatchingField!(isntExecNode)(inst);
    }
}

