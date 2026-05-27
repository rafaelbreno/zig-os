// _start is the entry point of the OS
// `noreturn` is used because a infinite loop doesn't return anything.
// callconv(.naked)
//  The callconv specifier changes the calling convention of the function.
//  .naked makes it no have a prologue/epilogue
export fn _start() callconv(.naked) noreturn {
    while (true) {}
}
