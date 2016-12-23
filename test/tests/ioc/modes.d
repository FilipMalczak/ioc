module tests.ioc.modes;

import ioc.modes;
import ioc.testing;

unittest {
    Foo foo = new Foo();
    Configurator!Foo(["bar", "baz", "--verbose", "--val", "10", "--txt", "abc"]).configure(foo);
    auto expected = "tests.ioc.modes.Foo [ROOT] = 
  tests.ioc.modes.Bar bar = 
    bool verbose = true
  tests.ioc.modes.Baz baz = 
    int i = 0
    string txt = abc
  tests.ioc.modes.Submode sub = null
  long along = 0
";
    assert(toStringTree!Foo(foo) == expected);
}

class Bar: Command {
    bool verbose = false;

    void execute(this T)(string[] args){
        LogEntries.add("Bar.execute(", args, ") ; verbose = "~verbose);
    }
}

class Baz: Command {
    int i;
    string txt = "a text";

    void execute(this T)(string[] args){
        LogEntries.add("Baz.execute(", args, "); i = "~i, ", txt='"~txt~"'");
    }
}

class Foobar: Command {
//    @Parent
//    Submode papa;

    int[] args;
}

class Submode: Mode {
    Foobar foobar;
}

class Foo: Mode {
    Bar bar;
    Baz baz;
    Submode sub;
    long along;
}

unittest {
    Foo foo = new Foo();
    Configurator!Foo(["bar", "baz", "--verbose", "--val", "10", "--txt", "abc"]).configure(foo);
    Foo expected = new Foo();
    expected.bar = new Bar();
    expected.bar.verbose = true;
    expected.baz = new Baz();
    expected.baz.i = 0;
    expected.baz.txt = "abc";
    expected.sub = null;
    expected.along = 0;
    assert(toStringTree!Foo(foo) == toStringTree!Foo(expected));
}
