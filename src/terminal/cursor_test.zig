const std = @import("std");
const testing = std.testing;
const Cursor = @import("cursor.zig").Cursor;

test "cursor initialization" {
    const cursor = Cursor.init(80, 25);
    try testing.expectEqual(@as(usize, 0), cursor.row);
    try testing.expectEqual(@as(usize, 0), cursor.column);
    try testing.expectEqual(@as(usize, 80), cursor.max_width);
    try testing.expectEqual(@as(usize, 25), cursor.max_height);
}

test "cursor movement" {
    var cursor = Cursor.init(80, 25);

    // Test moveTo within bounds
    cursor.moveTo(5, 10);
    try testing.expectEqual(@as(usize, 5), cursor.row);
    try testing.expectEqual(@as(usize, 10), cursor.column);

    // Test moveTo out of bounds (should not change position)
    cursor.moveTo(100, 10);
    try testing.expectEqual(@as(usize, 5), cursor.row);
    try testing.expectEqual(@as(usize, 10), cursor.column);
}

test "cursor advance" {
    var cursor = Cursor.init(5, 5);

    // Test normal advance
    cursor.advance();
    try testing.expectEqual(@as(usize, 0), cursor.row);
    try testing.expectEqual(@as(usize, 1), cursor.column);

    // Test line wrap
    cursor.moveTo(0, 4);
    cursor.advance();
    try testing.expectEqual(@as(usize, 1), cursor.row);
    try testing.expectEqual(@as(usize, 0), cursor.column);

    // Test screen wrap
    cursor.moveTo(4, 4);
    cursor.advance();
    try testing.expectEqual(@as(usize, 0), cursor.row);
    try testing.expectEqual(@as(usize, 0), cursor.column);
}

test "cursor backOne" {
    var cursor = Cursor.init(5, 5);

    // Test normal back movement
    cursor.moveTo(0, 2);
    cursor.backOne();
    try testing.expectEqual(@as(usize, 0), cursor.row);
    try testing.expectEqual(@as(usize, 1), cursor.column);

    // Test line wrap backwards
    cursor.moveTo(1, 0);
    cursor.backOne();
    try testing.expectEqual(@as(usize, 0), cursor.row);
    try testing.expectEqual(@as(usize, 4), cursor.column);

    // Test at beginning (should not move)
    cursor.moveTo(0, 0);
    cursor.backOne();
    try testing.expectEqual(@as(usize, 0), cursor.row);
    try testing.expectEqual(@as(usize, 0), cursor.column);

    // Test at beginning (should not move)
    cursor.moveTo(1, 0);
    cursor.backOne();
    try testing.expectEqual(@as(usize, 0), cursor.row);
    try testing.expectEqual(@as(usize, cursor.max_width - 1), cursor.column);
}

test "cursor newLine" {
    var cursor = Cursor.init(5, 5);

    // Test normal newline
    cursor.moveTo(0, 3);
    cursor.newLine();
    try testing.expectEqual(@as(usize, 1), cursor.row);
    try testing.expectEqual(@as(usize, 0), cursor.column);

    // Test newline wrap
    cursor.moveTo(4, 3);
    cursor.newLine();
    try testing.expectEqual(@as(usize, 0), cursor.row);
    try testing.expectEqual(@as(usize, 0), cursor.column);
}

test "cursor reset" {
    var cursor = Cursor.init(80, 25);
    cursor.moveTo(10, 15);
    cursor.reset();
    try testing.expectEqual(@as(usize, 0), cursor.row);
    try testing.expectEqual(@as(usize, 0), cursor.column);
}

test "cursor getPosition" {
    var cursor = Cursor.init(80, 25);
    cursor.moveTo(5, 10);
    const pos = cursor.getPosition();
    try testing.expectEqual(@as(usize, 5), pos[0]);
    try testing.expectEqual(@as(usize, 10), pos[1]);
}
