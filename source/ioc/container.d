module ioc.container;

import ioc.stdmeta;
import ioc.meta;
import ioc.testing;

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

template inSeq(val, seq...){
    static if (seq.length == 0)
        alias inSeq = False;
    else
        static if (is(seq[0] == val))
            alias inSeq = True;
        else
            alias inSeq = inSeq!(val, seq[1..$]);
}

template resolveOrder(Layers...){
    template resolve(Layer, AlreadyResolved...){
        alias requirements = Layer.requiredLayers;
        template iterRequired(int i, Acc...){
            static if (i<requirements.length){
                static if (inSeq!(requirements[i], Acc))
                    alias iterRequired = iterRequired!(i+1, Acc);
                else
                    alias iterRequired = iterRequired!(i+1, resolve!(requirements[i], Acc));
            } else {
                static if (inSeq!(Layer, Acc))
                    alias iterRequired = Acc;
                else
                    alias iterRequired = AliasSeq!(Acc, Layer);
            }
        }
        alias resolve = iterRequired!(0, AlreadyResolved);
    }
    template iterLayers(int i, Acc...){
        static if (i<Layers.length){
            alias iterLayers = iterLayers!(i+1, resolve!(Layers[i], Acc));
        } else
            alias iterLayers = Acc;
    }
    alias resolveOrder = iterLayers!(0, AliasSeq!());
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

    mixin(classString("JJ", []));
    mixin(classString("AA", ["JJ"]));
    mixin(classString("CC", ["AA"]));
    mixin(classString("DD", ["CC"]));
    mixin(classString("HH", []));
    mixin(classString("BB", ["AA", "HH"]));
    mixin(classString("EE", ["DD", "BB"]));
    mixin(classString("FF", ["EE"]));
    mixin(classString("II", ["BB"]));
    mixin(classString("KK", ["CC", "DD"]));
    mixin(classString("LL", ["KK"]));
    mixin(classString("MM", ["FF", "LL"]));
    mixin(classString("GG", ["FF", "MM"]));

    mixin template assertOrderedAccordingToRequirements(T...){
        mixin template iter(int i){
            static if (i<T.length){
                alias current = T[i];
                mixin template iterReq(int j){
                    static if (j<current.requiredLayers.length){
                        alias idxInResult = staticIndexOf!(current.requiredLayers[j], T);
                        static assert (idxInResult >= 0);
                        static assert (idxInResult < i);
                        mixin iterReq!(j+1);
                    }
                }
                mixin iterReq!0;
                mixin iter!(i+1);
            }
        }
        mixin iter!0;
    }
}

unittest {
    alias input1 = AliasSeq!(A, B, C, D, E, F, G, H, I, J, K);
    alias result1 = resolveOrder!(input1);
    pragma(msg, "result1 ", result1);
    mixin assertSequencesSetEqual!(seq!(input1), seq!result1);
    mixin assertOrderedAccordingToRequirements!(result1);

    alias input2 = AliasSeq!(K, J, I, H, G, F, E, D, C, B, A);
    alias result2 = resolveOrder!(input2);
    pragma(msg, "result2 ", result2);
    mixin assertSequencesSetEqual!(seq!(input2), seq!result2);
    mixin assertOrderedAccordingToRequirements!(result2);

    alias input3 = AliasSeq!(AA, BB, CC, DD, EE, FF, GG, HH, II, JJ, KK, LL, MM);
    alias result3 = resolveOrder!(input3);
    pragma(msg, "result3 ", result3);
    mixin assertSequencesSetEqual!(seq!(input3), seq!result3);
    mixin assertOrderedAccordingToRequirements!(result3);

    alias input4 = AliasSeq!(CC, DD, II, JJ, FF, KK, LL, GG, EE, AA, BB, MM, HH);
    alias result4 = resolveOrder!(input3);
    pragma(msg, "result4 ", result4);
    mixin assertSequencesSetEqual!(seq!(input4), seq!result4);
    mixin assertOrderedAccordingToRequirements!(result4);
}

//todo: constraints on class template args
class Container(LayerClasses...) {
    alias LayerOrder = resolveOrder!LayerClasses;
    Layer[] layers;
    
    this(){
        layers = [];
        loadLayers();
    }
    
    private void loadLayersIter(int i)(){
        static if (i<LayerOrder.length){
            mixin("this.layers ~= new "~fullyQualifiedName!(LayerOrder[i])~"();");
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
