import std.stdio;
import std.file;
import std.path;
import std.conv;
import std.string;

string toModuleName(string base, string path){
    string[] splitted = [];
    foreach (p; pathSplitter(stripExtension(relativePath(absolutePath(path), absolutePath(base)))))
        splitted ~= p;
    if (splitted[$-1] == "package")
        splitted = splitted[0..$-1];
	return splitted.join(".");
}

string toEnumName(string moduleName){
    return moduleName.split(".").join("_");

}

void main(string[] args){
	assert(args.length==2);
	foreach (DirEntry d; dirEntries(args[1], SpanMode.breadth))
		if (d.isDir) {
			auto pkgFilePath = chainPath(d.name, "_index.d");
            auto pkgFile = File(pkgFilePath,"w");
			pkgFile.writeln("module "~toModuleName(args[1], d.name)~"._index;");
//            pkgFile.writeln("import std.range;");
            pkgFile.writeln();
            pkgFile.writeln("struct Index {");
            pkgFile.writeln("\tenum packageName = \""~toModuleName(args[1], d.name)~"\";");
            //pkgFile.writeln("\tstatic immutable string packageName = \""~toModuleName(args[1], d.name)~"\";");
            pkgFile.writeln();
			pkgFile.writeln("\tenum submodules {");
            //pkgFile.writeln("\tenum submodules = [");
            //pkgFile.writeln("\tstatic pure nothrow immutable string[] submodules = [");
			foreach(DirEntry d2; dirEntries(d.name, SpanMode.shallow)){
                if (d2.isFile && d2.name.extension == ".d" && d2.name.baseName() != "_index.d"){
					auto modName = toModuleName(args[1], d2.name);
                    auto enumName = toEnumName(modName);
					pkgFile.writeln("\t\t"~enumName~" = \""~modName~"\",");
				}
			}
            pkgFile.writeln("\t}");
            //pkgFile.writeln("\t];");
            pkgFile.writeln();
            string[] subpkgs = [];
			pkgFile.write("\tenum subpackages");
            //pkgFile.writeln("\tenum subpackages = [");
            //pkgFile.writeln("\tstatic pure nothrow immutable string[] subpackages = [");
            bool anyFound = false;
            foreach(DirEntry d2; dirEntries(d.name, SpanMode.shallow)){
				if (d2.isDir){
                    if (!anyFound)
                        pkgFile.writeln(" {");
                    anyFound = true;
					auto modName = toModuleName(args[1], d2.name);
                    subpkgs ~= modName;
					auto enumName = toEnumName(modName);
					pkgFile.writeln("\t\t"~enumName~" = \""~modName~"\",");
				}
			}
            if (anyFound)
                pkgFile.writeln("\t}");
            else
                pkgFile.writeln("\t;");
            //pkgFile.writeln("\t];");
            pkgFile.writeln();

            /*
            pkgFile.writeln("\tstatic @property pure nothrow immutable(string[]) moduleTree() {");
            string[] toBeChained = [ "submodules" ];
            foreach (i, p; subpkgs) {
                auto name = "Index_"~to!string(i);
                pkgFile.writeln("\t\timport "~p~"._index: "~name~" = Index;");
                toBeChained ~= name~".moduleTree";
            }
            pkgFile.writeln();
            pkgFile.write("\t\treturn ");
            pkgFile.write(toBeChained.join(" ~ "));
            pkgFile.writeln(";");
            pkgFile.writeln("\t}");*/
            pkgFile.writeln("}");
		}
}

