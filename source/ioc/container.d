module ioc.container;

import ioc.stdmeta;

import poodinis;

import std.stdio;
import std.string;
import std.algorithm;

/**
 * See container.md in sources for abstract for this module.
 */

//todo: finish docs once the API stabilizes
interface Layer {

    /**
     * An alias to AliasSeq of layers that need to be used before this one is 
     * used; default value is empty AliasSeq.
     */
    alias requiredLayers = AliasSeq!();
    
    void onLayerEntry(T...)();// if (T.length == 2);
    
    template handle(T...) {// if (T.length == 2){
    }

    void onLayerExit(T...)();// if (T.length == 2);
}

class NullLayer: Layer {
    
    void onLayerEntry(T...)(){}
    
    void onLayerExit(T...)(){}
}

class WritelnMsgLayer: Layer {
    void onLayerEntry(T...)(){
        import std.stdio;
        writeln("onLayerEntry(", T.stringof, ")");
    }
    
    template handle(T...){
        pragma(msg, "handle(", T, ")");
    }

    void onLayerExit(T...)(){
        import std.stdio;
        writeln("onLayerExit(", T.stringof, ")");
    }
}

struct Resolver(LayerClasses...){
    string[][string] requirements; // X is required by Y => X in requirements[Y]
    string[][string] reverseRequirements; // X is required by Y => Y in reverseRequirements[X]

    //todo: extract, make generic
    static string[][string] deepcopy(string[][string] original){
        string[][string] result;
        foreach (k, v; original){
            result[k] = []~v; //todo: there is nicer way to do this
        }
        return result;
    }

    template typeidsTemp(int i, LayerClass){
        static if (i<LayerClass.requiredLayers.length){
            alias typeidsTemp = AliasSeq!(fullyQualifiedName!(LayerClass.requiredLayers[i]), typeidsTemp!(i+1, LayerClass));
        } else
            alias typeidsTemp = AliasSeq!();
    }

    string[] requiredTypeids(LayerClass)(){
        return [typeidsTemp!(0, LayerClass)];
    }

    void iterLayerClasses(int i=0)(){
        static if (i<LayerClasses.length){
            requirements[fullyQualifiedName!(LayerClasses[i])] = requiredTypeids!(LayerClasses[i])();
            iterLayerClasses!(i+1)();
        }
    }

    void fillRequiredBy(){
        iterLayerClasses!(0)();
    }
    
    //fixme: do I even need reverseIndex?
    void reverseIndex(){
        foreach (depending, required; requirements){
            foreach (req; required){
                if (req !in reverseRequirements)
                    reverseRequirements[req] = [];
                if (!reverseRequirements[req].canFind(depending))
                    reverseRequirements[req] ~= depending;
            }
        }
    }
    
    string[] resolve(string requirement, string[] a = []){
        string[] acc = [] ~ a;
        //writeln("resolve ", requirement, " ; ", acc);
        foreach (dependency; requirements[requirement])
            if (!acc.canFind(dependency)) {
                acc = resolve(dependency, acc);
                //writeln("acc => ", acc);
            }
        if (!acc.canFind(requirement))
            acc ~= requirement;
        //writeln("return ", acc);
        return acc;
    }
    
    string[] findOrder(){
        //writeln("findOrder");
        string[] result = [];
        //auto req = deepcopy(requirements);
        //auto revReq = deepcopy(reverseRequirements);
        foreach (requirement; requirements.keys){
            //writeln("req ", requirement, ", result before ", result);
            result = resolve(requirement, result);
            //writeln("req ", requirement, ", result after ", result);
        }
        //writeln("return ", result);
        return result;
    }
}

version(unittest){
    string classString(string name, string[] required){
        return "class "~name~" { alias requiredLayers = AliasSeq!("~required.join(", ")~"); }";
    }

    mixin(classString("A", []));
    mixin(classString("B", ["A"]));
    mixin(classString("C", ["A"]));
    mixin(classString("D", ["B", "C"]));
    mixin(classString("E", ["D"]));
    mixin(classString("F", []));
    mixin(classString("G", []));
    mixin(classString("H", ["G"]));
    mixin(classString("I", ["G", "E"]));
    mixin(classString("J", ["I"]));
    mixin(classString("K", ["H", "J"]));
}

unittest {
    auto r = Resolver!(A, B, C, D, E, F, G, H, I, J, K)();
    r.fillRequiredBy();
    //todo: this will need porting
    assert(r.requirements == [
        "ioc.container.A":[], 
        "ioc.container.B":["ioc.container.A"],
        "ioc.container.C":["ioc.container.A"], 
        "ioc.container.D":["ioc.container.B", "ioc.container.C"], 
        "ioc.container.E":["ioc.container.D"], 
        "ioc.container.F":[], 
        "ioc.container.G":[], 
        "ioc.container.H":["ioc.container.G"], 
        "ioc.container.I":["ioc.container.G", "ioc.container.E"], 
        "ioc.container.J":["ioc.container.I"], 
        "ioc.container.K":["ioc.container.H", "ioc.container.J"]
    ]);
    r.reverseIndex();
    //writeln(r.reverseRequirements);//todo: make assert out of this
    writeln(r.findOrder());//todo: make assert out of this
    //r.findOrder();
}

//todo: constraints on class template args
class Container(LayerClasses...) {
    Layer[] layers;
    
    this(){
        layers = [];
        loadLayers();
    }
    
    private void loadLayersIter(int i)(){
        static if (i<LayerClasses.length){
            mixin("this.layers ~= new "~fullyQualifiedName!(LayerClasses[i])~"();");
            //todo: add initialization
            loadLayersIter!(i+1)();
        }
    }
    
    private void loadLayers(){
        loadLayersIter!(0)();
    }
    
    void autoscan(string packageName)(){
        
    }
}

unittest {
    auto c = new Container!(WritelnMsgLayer)();
}
