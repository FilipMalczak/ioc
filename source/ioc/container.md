# Docs for ioc.container module

Abstraction used in this module is as goes:
Container consists of set of layers.

We say that if a layer A is executed before layer B, then A lies below B.
In other words A is lower layer than B, while B is the higher layer.

General idea is to scan codebase of project for any kind of symbols (filtering
of the codebase during scanning is your responsibility, though I'm providing 
some predefined utilities using codebase module). To each of this symbols
a container would coordinate application of several compile- and runtime
steps. Each of those steps is applied to the original symbol and value
obtained from applying that step to either lower layer or original value. 
Order of applying layers is defined only by "requiresLayers" alias, which
should point to other layer types that need to be applied to the value before
this layer. There is no guarantee that no other layer will be applied before
this one - in the end every layer is applied exactly once.
`//todo: rewrite this, it sounds gibberish`

> PRO DEV NOTE: interfaces can have template and alias members. There is no 
> typechecking on "calls" to templates, and default "behaviour" must
> be defined in interface, but it is a way to clarify API in this
> module.


 * Each layer has following API:
 * - alias requiresLayers
 * -- should be alias to AliasSeq of layers that need to be used before this
 *    one is used; default value is empty AliasSeq
 *
 * - method void onLayerEntry(T...)() if (T.length == 2)
 * -- called at the very beginning of processing layers; T is symbol that is obtained
 *    from codebase scan or from previous layer
 *
 * - template handle(T...) if (T.length == 1)
 * -- called right after onLayerEntry; can do any compile-time action. Should
 *    "return" symbol that will be passed to higher layers.
 *
 * - method void onLayerExit(T...)() if (T.length == 2)
