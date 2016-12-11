module ioc.compose;

import ioc.extendMethod;

template compose(Base, Interceptors...){
    static if (Interceptors.length > 1)
        alias compose = compose!(ExtendMethod!(Base, Interceptors[0]), Interceptors[1..$]);
    else
        alias compose = ExtendMethod!(Base, Interceptors[0]);
}
