module tests.ioc.container;

import ioc.container;
import ioc.testing;

import std.stdio;

import poodinisTest.a;

unittest {
    auto c = new shared IocContainer!("toppkg", "poodinisTest", "tests.aspects")();
    auto inst = c.resolve!(I)();
    inst.foo();
    auto fooIdx = LogEntries.indexOf("foo in AComponent");
    foreach (expectedBefore; ["B#advice2()", "B#advice()", "A#advice()", "MatchingByName#bar()", "MatchingByName#foo()"])
        assert(LogEntries.indexOf(expectedBefore) < fooIdx);
    foreach (expectedAfter; ["2", "3"])
        assert(LogEntries.indexOf(expectedAfter) > fooIdx);
    LogEntries.reset();
}
