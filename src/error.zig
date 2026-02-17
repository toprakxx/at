// Error returns are not compatible with wasm freestanding calling convention so using enums as errors

pub const TA_ERR = enum(u32) {
    SUCCESS = 0,
    BAD_INIT = 1,
    BAD_ALLOC = 2,
    OOM = 3, //out of mem

};
