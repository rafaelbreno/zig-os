const Console = @import("io/console/console.zig").Console;
const serial = @import("arch/arch.zig").serial;

pub const Log = struct {
    console: *Console,

    pub fn log(self: Log, comptime fmt: []const u8, args: anytype) void {
        self.console.println(fmt, args) catch {};
        serial.println(fmt, args) catch {};
    }

    pub fn info(self: Log, comptime fmt: []const u8, args: anytype) void {
        self.console.println("[INFO] " ++ fmt, args) catch {};
        serial.println("[INFO] " ++ fmt, args) catch {};
    }

    pub fn debug(self: Log, comptime fmt: []const u8, args: anytype) void {
        self.console.println("[DEBUG] " ++ fmt, args) catch {};
        serial.println("[DEBUG] " ++ fmt, args) catch {};
    }

    pub fn warning(self: Log, comptime fmt: []const u8, args: anytype) void {
        self.console.println("[WARN] " ++ fmt, args) catch {};
        serial.println("[WARN] " ++ fmt, args) catch {};
    }

    pub fn err(self: Log, comptime fmt: []const u8, args: anytype) void {
        self.console.println("[ERR] " ++ fmt, args) catch {};
        serial.println("[ERR] " ++ fmt, args) catch {};
    }
};

var instance: ?Log = null;

pub fn init(console: *Console) void {
    instance = Log{
        .console = console,
    };
}

pub fn getInstance() Log {
    return instance.?;
}
