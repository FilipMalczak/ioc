module poodinisTest.b;

version(unittest) {

    import poodinisTest.a;
    import ioc.testing;
    import ioc.poodinis.registering;

    class NotAComponent: I {
        void foo(){
            LogEntries.add("foo in NotAComponent");
        }
    } 
    
    @Component
    class AComponent: I {
        void foo(){
            LogEntries.add("foo in AComponent");
        }
    }

}
