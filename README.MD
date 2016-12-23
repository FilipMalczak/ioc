[![Codacy Badge](https://api.codacy.com/project/badge/Grade/a44012e468534c10a13853f5f31cc634)](https://www.codacy.com/app/filip-malczak/ioc?utm_source=github.com&utm_medium=referral&utm_content=FilipMalczak/ioc&utm_campaign=badger)
# ioc [![Build Status](https://travis-ci.org/FilipMalczak/ioc.svg?branch=master)](https://travis-ci.org/FilipMalczak/ioc)
Slow approach to Inversion of Control in D2 language

# Features

Basically all of the features are covered with tests - some do lack those, but
mostly for edge cases. Anyway, to see how to use something you basically always
have an example in the form of test for random, "normal" scenario.

You are also very welcome to read the code, it may clarify a lot.

I've tried to descirbe preconditions as well as I could, but if you fail them,
error will not be helpful, sometimes you may get a linkage error, sometimes 
a compilation error, and as often - runtime errors. This will need a lot of work,
but first I wanna handle happy scenarios.

## Package scan

Add execution of `generate_index.d` with `rdmd` to your DUB file's 
`preGenerateCommands` to trigger building an index of modules. It works by adding
`_index` module to each package, that will contain metadata for package traversal.

I'd propose adding `**/_index.d` rule to `.gitignore`. This project is configured
for this lib to work. Unfortunately, you have to download the script yourself
and add proper rule to `preGenerateCommands`. At some point I will probably 
prepare a shell script for automatic download. It's not much work, but I need to
focus on main functional areas now. Feel free to contribute.

### ioc.codebase

This module provides low-level iteration tools:
 * `template foldModuleNames(string pkgName, alias apply, initVal...)` where  
    `apply` is a eponymous template with parameters `(string moduleName, accumulated...)`
    "returning" `newAccumulated...` being new accumulated value. Template evaluates
    to result of applying over each module name in given package.
 * `template foldAllMembers(string pkgName, alias qualifier, alias apply, initVal...)`
    and its multi-package version, but without initial value: 
    `template foldAllMembers(alias qualifier, alias apply, pkgNames...) if (pkgNames.length > 0 && stringsOnly!(pkgNames))`
    
    In both cases `qualifier` is template with parameters `(T...)`, eponymous with
    `alias` to a boolean, stating whether a symbol qualifies to applying, while
    `template apply(alias importable, accumulated...) -> newAccumulated...`
    where `importable` is alias to `struct Importable` with adequate module and 
    member names as template params. Templates "return" result of applying to
    each symbol that qualifies.

Neither of those templates defines any particular order of traversing module
tree. There is only a guarantee that every entry (module name or importable) in
the hierarchy will be visited and applied to exactly once (if wanted).

There are already several predefined qualifiers and higher order templates:
 * `template isClass(T...) if (T.length == 1)`
 * `template isInterface(T...) if (T.length == 1)`
 * `template isStruct(T...) if (T.length == 1)`
 * `template isEnum(T...) if (T.length == 1)`
 * ```template or(templates...) {
        template impl(T...) if (T.length == 1) {
            (...)
        }
        alias or = impl;
    }```
 * ```template and(templates...){
        template impl(T...) if (T.length == 1) {
            (...)
        }
        alias and = impl;
    }```
 * `isType(T...)` working as alternative of `isClass`, `isInterface`, `isStruct`, `isEnum`
 * `template isStereotype(Annotation...) if (Annotation.length == 1)` recognising
    stereotype UDA types. Stereotype is any type that is annotated with `@Stereotype`
    or `enum Stereotype` itself. It's used by:
 * ```template hasStereotype(Stereotypes...) if (Stereotypes.length > 0) {
        template impl(T...) if (T.length == 1) {
            (...)
        }
        alias hasStereotype = impl;
    }```

Hopefully, they are pretty straight-forward.

Last, but not least (and most probably most useful of all other contents of 
this module), there are predefined collecting templates, returning AliasSeq of
either fully qualified names, aliases of, or Importables of each member that qualify:

 * `template memberNames(string pkgName, alias qualifier, initVal...)`
 * `template memberNames(alias qualifier, pkgNames...) if (pkgNames.length > 0 && stringsOnly!(pkgNames))`
 * `template memberAliases(string pkgName, alias qualifier, initVal...)`
 * `template memberAliases(alias qualifier, pkgNames...) if (pkgNames.length > 0 && stringsOnly!(pkgNames))`
 * `template importables(string pkgName, alias qualifier, initVal...)`
 * `template importables(alias qualifier, pkgNames...) if (pkgNames.length > 0 && stringsOnly!(pkgNames))`

You can use them to iterate over symbols manually.

### Low-level `_index.d` API

There is also lower-level API, exposed in `_index` module of each package. That 
module is generated by `generate_index.d` script and exposes `struct Index`, which
has 3 `enum` members: `packageName` having one value of string name of package in 
which it is located; `submodules` and `subpackages`, having one member per submodule 
or subpackage. Each member has package name with dots (`.`) replaced with underscores
(`_`) for member name and package name as string for member value. There of course
may be no members at all for either of those `enum`s. `package.d` modules are not 
supported in indexing and won't be creating any members in `enum submodules`.

> There are two reasons not to support package modules.
>
> First is technical: `allMembers` trait is behaving in a weird way when used on 
> a module or module alias that points to package module. I cannot exactly 
> understand why yet, but it looks like it even behaved differently on different
> platforms and may be a bug in the compiler - though it needs way more research
> and experiments before submitting such bug ticket. For now I think the time is
> better spent on developing simpler, but wider set of features, thus disabling
> support for package module, because...
>
> Second reason is more about idea behind the framework itself. My goal here is
> to create bare-metal architecture for pluggable framework, with low-level API
> and this essential "glue" to start developing environment of easily composable
> modules. It is highly convention-oriented, without many configuration 
> possibilities, though intention is to create API that allows for creating 
> higher abstractions, with more configuration options. Convention I would like
> to force here on API is that user should be working with top-level classes and
> interfaces, with fully qualified names that are distingishable and easily 
> broken down to tuples of package name, module name and simple name of a symbol.
> This rule is broken for package modules, which may be wonderful idea when 
> exposing an API, but rather poor when implementing something anyway. 
>
> Additionally, when looking at second reason from technical perspective, it is
> really helpful to assume that `fullyQualifiedName!(symbol)` can be splitted by a
> dot, last two elements taken as module and simple name of a symbol and rest 
> treated as package name. That assumption holds, because framework only 
> supports top-level classes and interfaces.
>
> For the record: there is support for manipulating (registering, weaving aspects,
> etc) only classes and interfaces, but there is also support for enums and structs
> besides them, when it comes to UDAs used as annotations.

## Interceptors and other low-level type behaviour modifications

### ioc.extendMethod

ioc.extendMethod defines `interface Interceptor` and `template ExtendMethod`.

`Interceptor` is customized with `interface` from amongst which methods one will be intercepted,
name of that method and optional list of parameter types - needed only when there
is more than one overload for the method.

`ExtendMethod` template takes a concrete type and `Interceptor` implementation and
creates type that extends the concrete type but has a method intercepted.

There is also `InterceptorAdapter` which provides empty interceptor for any
method - useful when we only want to intercept single crossing point.

### ioc.proxy

Provides simple delegating class with Proxy template. It does nothing, but
forward all the public API to wrapped instance.

### ioc.compose

Used to compose several interceptors with single template.

### Coming soon

Aspects. You'll read about it in chapter about IoC container

# IoC Container

_(surprise)_

I've once read that inversion of control can be boiled down to a set of 4 
techniques or ideas:
 * dependency injection,
 * aspects,
 * events,
 * framework.

# Dependency Injection

I'm using existing DI framework: [poodinis](https://github.com/mbierlee/poodinis).

But, there is a `synchronized class IocContainer(packageNames...) if (stringsOnly!(packageNames) && packageNames.length > 0)`
in package ioc.container. It provides simple DI methods (`register` and `resolve`)
and renames poodinis' real overload of `register` to `bind`. Besides, by default
it returns `null` instead of throwing resolving exception. `resolveAll` method was
dropped to be replaced with autobinding.

The real added value here is autoregistration. Packages given as template arguments
of the container class are scanned in search for `@Component` stereotype. Every `class` with
such annotation is registered and every `interface` is subject to autobinding.

> At the nearest future things will change a bit: classes won't be registered with
> themselves, but rather with some generated subclass than weaves in aspects. 

Autobinding is process in which set of all component `class`es are searched for
one that implements that `interface`. If there is exactly one such `class`, then that
`interface` and this `class` are bound with bind method. 

> Aspects will change that too, but not much.

## Todo

 * incorporate some ORM and provide support for repository interfaces 
 * extend that idea to full MVC

# Aspects

Just taking a break to write some docs and I'll be going back to implementing this.

I'll be inspiring myself with Spring AOP a lot. In that spirit I'm gonna use
ioc.compose module together with ioc.container to weave in aspects declared
with proper annotations across whole codebase matching some join points.

# Events

One of next steps - probably gonna incorporate some existing event loop library,
but I wanna build some support for asynchronous services.

# Framework

I've got a slowly growing idea for entry point method parametrized with
struct defining modes and commands of your program. Far away in the future anyway.
