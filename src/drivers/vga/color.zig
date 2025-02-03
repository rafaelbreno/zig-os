// Hardware text mode color constants
const VgaColor = u8;
pub const Color = enum(VgaColor) {
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGrey = 7,
    DarkGrey = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    LightMagenta = 13,
    LightBrown = 14,
    White = 15,
};

// foreground | background color.
pub fn vgaEntryColor(fg: Color, bg: Color) u8 {
    // will build the byte representing the color.
    return @intFromEnum(fg) | (@intFromEnum(bg) << 4);
}

pub fn vgaEntry(uc: u8, color: u8) u16 {
    const c: u16 = color;

    // build the 2 bytes representing the printable caracter w/ EntryColor.
    return uc | (c << 8);
}
