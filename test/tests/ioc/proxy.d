module tests.ioc.proxy;

import ioc.proxy;


interface A {
    void foo();
    int bar();
    void baz(int i);
    float baz(string);
    void baz(int, string, float);
}

alias Proxied = Proxy!A;

unittest {
    Proxied proxied;
    //todo: do real testing
}

