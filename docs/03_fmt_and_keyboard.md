# `fmt` and keyboard support

## Summary
1. [Introduction](#introduction)
2. [FMT Package](#fmt-package)
    - [Buffer Helpers](#buffer-helpers)
        - [Mapping](#mapping)

## Introduction
In this Chapter we'll be implementing two things:
1. The `fmt` package: This will allow us to pretty-print messages in our terminal.
2. Keyboard support: We want to detect what keys we're pressing, e.g: `a`, `1`, `f2`, `CTRL`, `SHIFT + A`, etc.

## FMT Package

### Buffer Helpers
Before we start writing our `fmt` package, let's add a few functionalities to our `src/terminal/terminal.zig`:

#### Mapping
So, to make our lifes easier(IMO), instead of using the _buffer_(`[*]volatile u16`) as it's, we'll be implementing a _map_:
```zig
pub const terminal = struct {
    // ...
    // This will be our map
    var map: [VGA_WIDTH][VGA_HEIGHT]*volatile u16 = undefined;

    pub fn initialize() void {
        var y: usize = 0;
        while (y < VGA_HEIGHT) : (y += 1) {
            var x: usize = 0;
            while (x < VGA_WIDTH) : (x += 1) {
                // We'll add the following assertion
                // passing the address to it's representation
                // in the map/matrix.
                map[x][y] = &buffer[(y * VGA_WIDTH) + x];
                putCharAt(' ', color, x, y);
            }
        }
    }

    // ...
    fn putCharAt(c: u8, new_color: u8, x: usize, y: usize) void {
        // instead of using the old:
        //      const index = y * VGA_WIDTH + x;
        //      buffer[index] = vgaEntry(c, new_color);
        // we can just do:
        map[x][y].* = vgaEntry(c, new_color);
    }
}
```

