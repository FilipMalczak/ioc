module poodinisTest.a;

version(unittest) {
    import ioc.container;
    
    @Component
    interface I {
        void foo();
    }
}
