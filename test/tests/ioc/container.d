module tests.ioc.container;

import ioc.container;
import ioc.testing;

import std.stdio;

import poodinisTest.a;

unittest {
    auto c = new shared IocContainer!("toppkg", "poodinisTest", "tests.aspects")();
    c.resolve!(I)().foo();
    assert(LogEntries.entries == ["foo in AComponent"]);
    LogEntries.reset();
}
