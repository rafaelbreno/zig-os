const std = @import("std");
const testing = std.testing;
const Cursor = @import("cursor.zig").Cursor;

test "Cursor - initialization" {
    const cursor = Cursor.init(80, 25);

    try testing.expectEqual(@as(usize, 0), cursor.row);
    try testing.expectEqual(@as(usize, 0), cursor.column);
    try testing.expectEqual(@as(usize, 25), cursor.max_height);
    try testing.expectEqual(@as(usize, 80), cursor.max_width);
    try testing.expectEqual(false, cursor.needs_scroll);
}

test "Cursor - getPosition" {
    var cursor = Cursor.init(80, 25);
    cursor.row = 5;
    cursor.column = 10;

    const pos = cursor.getPosition();
    try testing.expectEqual(@as(usize, 5), pos[0]);
    try testing.expectEqual(@as(usize, 10), pos[1]);
}

test "Cursor - moveTo valid position" {
    var cursor = Cursor.init(80, 25);
    cursor.moveTo(5, 10);

    try testing.expectEqual(@as(usize, 5), cursor.row);
    try testing.expectEqual(@as(usize, 10), cursor.column);
    try testing.expectEqual(false, cursor.needs_scroll);
}

test "Cursor - moveTo invalid position" {
    var cursor = Cursor.init(80, 25);
    const initial_row = cursor.row;
    const initial_col = cursor.column;

    // Try to move beyond bounds
    cursor.moveTo(100, 90);

    // Should remain at initial position
    try testing.expectEqual(initial_row, cursor.row);
    try testing.expectEqual(initial_col, cursor.column);
}

test "Cursor - advance within bounds" {
    var cursor = Cursor.init(80, 25);
    cursor.moveTo(0, 78);
    cursor.advance();

    try testing.expectEqual(@as(usize, 0), cursor.row);
    try testing.expectEqual(@as(usize, 79), cursor.column);
    try testing.expectEqual(false, cursor.needs_scroll);
}

test "Cursor - advance with line wrap" {
    var cursor = Cursor.init(80, 25);
    cursor.moveTo(0, 79);
    cursor.advance();

    try testing.expectEqual(@as(usize, 1), cursor.row);
    try testing.expectEqual(@as(usize, 0), cursor.column);
    try testing.expectEqual(false, cursor.needs_scroll);
}

test "Cursor - advance with scroll needed" {
    var cursor = Cursor.init(80, 25);
    cursor.moveTo(24, 79);
    cursor.advance();

    try testing.expectEqual(@as(usize, 24), cursor.row);
    try testing.expectEqual(@as(usize, 0), cursor.column);
    try testing.expectEqual(true, cursor.needs_scroll);
}

test "Cursor - backOne within line" {
    var cursor = Cursor.init(80, 25);
    cursor.moveTo(5, 10);
    cursor.backOne();

    try testing.expectEqual(@as(usize, 5), cursor.row);
    try testing.expectEqual(@as(usize, 9), cursor.column);
    try testing.expectEqual(false, cursor.needs_scroll);
}

test "Cursor - backOne with line wrap" {
    var cursor = Cursor.init(80, 25);
    cursor.moveTo(5, 0);
    cursor.backOne();

    try testing.expectEqual(@as(usize, 4), cursor.row);
    try testing.expectEqual(@as(usize, 79), cursor.column);
    try testing.expectEqual(false, cursor.needs_scroll);
}

test "Cursor - backOne at start" {
    var cursor = Cursor.init(80, 25);
    cursor.backOne();

    try testing.expectEqual(@as(usize, 0), cursor.row);
    try testing.expectEqual(@as(usize, 0), cursor.column);
    try testing.expectEqual(false, cursor.needs_scroll);
}

test "Cursor - newLine within bounds" {
    var cursor = Cursor.init(80, 25);
    cursor.moveTo(5, 10);
    cursor.newLine();

    try testing.expectEqual(@as(usize, 6), cursor.row);
    try testing.expectEqual(@as(usize, 0), cursor.column);
    try testing.expectEqual(false, cursor.needs_scroll);
}

test "Cursor - newLine with scroll needed" {
    var cursor = Cursor.init(80, 25);
    cursor.moveTo(24, 10);
    cursor.newLine();

    try testing.expectEqual(@as(usize, 24), cursor.row);
    try testing.expectEqual(@as(usize, 0), cursor.column);
    try testing.expectEqual(true, cursor.needs_scroll);
}

test "Cursor - reset" {
    var cursor = Cursor.init(80, 25);
    cursor.moveTo(5, 10);
    cursor.needs_scroll = true;
    cursor.reset();

    try testing.expectEqual(@as(usize, 0), cursor.row);
    try testing.expectEqual(@as(usize, 0), cursor.column);
    try testing.expectEqual(false, cursor.needs_scroll);
}

test "Cursor - checkScroll" {
    var cursor = Cursor.init(80, 25);
    cursor.needs_scroll = true;

    try testing.expectEqual(true, cursor.checkScroll());
    try testing.expectEqual(false, cursor.needs_scroll);
    try testing.expectEqual(false, cursor.checkScroll());
}
