# ioc
Slow approach to Ionversion of Control in D2 language

# Features

## Package scan

Add execution of generate_index.d with rdmd to your DUB file's 
preGenerateCommands to trigger building an index of modules. It works by adding
_index module to each package, that will contain struct with proper enumerations.
Values of those enums are submodules and subpackages, and that makes it possible
to traverse module tree both at compile- and runtime.

See unittest for example usage.

I'd propose adding **/_index.d to .gitignore.

## Interceptors

### ioc.extendMethod

ioc.extendMethod defines Interceptor template interface and ExtendMethod template.

Interceptor is customized with interface from amongst which methods one will be intercepted,
name of that method and optional list of parameter types - needed only when there
is more than one overload for the method.

ExtendMethod template takes a concrete type and Interceptor implementation and
creates type that extends the concrete type but has a method intercepted.

See unittests for examples of usage and expected behaviour.

There is also InterceptorAdapter which provides empty interceptor for any
method - useful when we only want to intercept single crossing point.

### ioc.proxy

Provides simple delegating class with Proxy template. It does nothing, but
forward all the public API to wrapped instance.

### ioc.compose

Used to compose several interceptors with single template.


