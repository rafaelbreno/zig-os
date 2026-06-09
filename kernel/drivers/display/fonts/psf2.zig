// PSF2 (PC Screen Font version 2) parser and glyph renderer.
// PSF2 is a simple bitmap font format used by the Linux console.
// A PSF2 file is laid out as: [Header][glyph_0][glyph_1]...[glyph_N][Unicode table]
// Each glyph is a packed bitmap: 1 bit per pixel, rows padded to the nearest byte.

const serial = @import("../../../arch/arch.zig").serial;

const DisplayInfo = @import("../display.zig").DisplayInfo;

// PSF2 header, laid out exactly as the file format specifies.
// `extern struct` guarantees C-compatible layout (no reordering, no padding),
// which is required for @ptrCast to correctly overlay this struct onto raw file bytes.
pub const Header = extern struct {
    magic: u32, // must be 0x864ab572 — identifies this as a PSF2 file
    version: u32, // PSF2 version, currently always 0
    header_size: u32, // offset in bytes from the start of the file to the first glyph
    flags: u32, // bit 0: unicode table present after glyphs
    number_of_glyphs: u32, // total number of glyphs in the file
    bytes_per_glyph: u32, // size of one glyph in bytes (height * bytes_per_row)
    height: u32, // glyph height in pixels
    width: u32, // glyph width in pixels
};

// A loaded font: a reference to the raw file bytes and a parsed header.
// `data` is the complete file contents embedded at compile time via @embedFile.
// `header` is a zero-copy view into the first bytes of `data` — no allocation needed.
pub const Font = struct {
    const Self = @This();

    data: []const u8, // complete PSF2 file bytes, embedded at compile time
    header: *const Header, // points directly into data[0]; no copy made

    // getGlyph: returns the raw bitmap bytes for the given ASCII character.
    // The glyph data starts at header_size and each glyph is bytes_per_glyph bytes long.
    // The returned slice is a view into `data` — no allocation.
    pub fn getGlyph(self: Self, char: u8) []const u8 {
        const glyph_start: usize = self.header.header_size + (@as(usize, @intCast(char)) * self.header.bytes_per_glyph);
        const glyph_end = glyph_start + self.header.bytes_per_glyph;
        return self.data[glyph_start..glyph_end];
    }
};

// load: parse a PSF2 font from raw bytes.
// `data` is typically the result of @embedFile — a compile-time constant byte slice.
// The header is overlaid directly onto the first bytes of `data` via @ptrCast,
// so no copying or allocation occurs. `data` must outlive the returned Font.
pub fn load(data: []const u8) Font {
    // @alignCast is required because &data[0] is *const u8 (align 1),
    // but *const Header requires align 4. @alignCast asserts the alignment at runtime
    // in debug builds; in release builds it's a no-op.
    const header: *const Header = @ptrCast(@alignCast(&data[0]));
    return Font{
        .data = data,
        .header = header,
    };
}

// drawChar: render a single ASCII character onto the display at pixel position (x, y).
// Iterates over each row of the glyph bitmap, then each byte in that row, then each bit.
// A set bit draws a foreground pixel; a clear bit draws a background pixel.
//
// Glyph layout for a 16-wide font (2 bytes per row):
//   row 0: glyph[0], glyph[1]       — leftmost 8 pixels, rightmost 8 pixels
//   row 1: glyph[2], glyph[3]
//   ...
//   row N: glyph[N*2], glyph[N*2+1]
pub fn drawChar(
    font: Font,
    display: DisplayInfo,
    char: u8,
    x: u64, // screen X of the glyph's top-left corner, in pixels
    y: u64, // screen Y of the glyph's top-left corner, in pixels
    fg: u32, // foreground color (set bits), 0x00RRGGBB
    bg: u32, // background color (clear bits), 0x00RRGGBB
) void {
    const glyph = font.getGlyph(char);

    // Outer loop: one iteration per glyph row.
    // bytes_per_glyph / 2 gives the number of rows for a 16-wide (2 bytes/row) font.
    for (0..(font.header.bytes_per_glyph) / 2) |i| {
        // Middle loop: one iteration per byte in this row (2 bytes = 16 pixels).
        for (0..2) |j| {
            const glyph_byte = glyph[(2 * i) + j];
            // Inner loop: test each of the 8 bits in this byte, MSB first.
            // Bit 7 (MSB) is the leftmost pixel; bit 0 (LSB) is the rightmost.
            for (0..8) |n| {
                // Shift the target bit to position 0, then mask off everything else.
                // This correctly handles bytes where multiple bits are set.
                if (glyph_byte >> @as(u3, @intCast(7 - n)) & 1 == 1) {
                    display.drawPixel(x + n + (j * 8), y + i, fg);
                } else {
                    display.drawPixel(x + n + (j * 8), y + i, bg);
                }
            }
        }
    }
}
