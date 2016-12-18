module tests.ioc.container;

import ioc.container;
import ioc.testing;

import std.stdio;

import poodinisTest.a;

unittest {
    auto c = new shared IocContainer!("toppkg", "poodinisTest", "tests.aspects")();
    auto inst = c.resolve!(I)();
//    writeln(c);
    writeln(inst);
    inst.foo();
    writeln(LogEntries.entries);
    //assert(LogEntries.entries == ["foo in AComponent"]);
    assert(LogEntries.entries == ["5", "6", "foo in AComponent"] || 
            LogEntries.entries == ["6", "5", "foo in AComponent"]);
    LogEntries.reset();
}
