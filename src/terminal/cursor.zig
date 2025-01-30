pub const Cursor = struct {
    row: usize,
    column: usize,
    max_width: usize,
    max_height: usize,

    const Self = @This();

    pub fn init(width: usize, height: usize) Self {
        return Self{
            .row = 0,
            .column = 0,
            .max_width = width,
            .max_height = height,
        };
    }

    pub fn getPosition(self: *const Self) struct { usize, usize } {
        return .{ self.row, self.column };
    }

    pub fn moveTo(self: *Self, r: usize, col: usize) void {
        if (r >= self.max_height or col >= self.max_width) return;
        self.row = r;
        self.column = col;
    }

    pub fn advance(self: *Self) void {
        self.column += 1;
        if (self.column >= self.max_width) {
            self.column = 0;
            self.row += 1;
            if (self.row >= self.max_height) {
                self.row = 0;
            }
        }
    }

    pub fn backOne(self: *Self) void {
        if (self.column > 0) {
            self.column = self.column - 1;
            return;
        }
        if (self.row == 0) {
            return;
        }

        self.row = self.row - 1;
        self.column = self.max_width - 1;
    }

    pub fn newLine(self: *Self) void {
        self.column = 0;
        self.row += 1;
        if (self.row >= self.max_height) {
            self.row = 0;
        }
    }

    pub fn reset(self: *Self) void {
        self.column = 0;
        self.row = 0;
    }
};
