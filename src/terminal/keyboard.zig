const Key = @import("keys.zig").Key;

/// State represents the current key's state.
pub const State = enum {
    Pressed,
    Released,
    Hit,
};

pub const Modifiers = struct {
    rightShift: bool = false,
    leftShift: bool = false,
    rightAlt: bool = false,
    leftAlt: bool = false,
    rightCtrl: bool = false,
    leftCtrl: bool = false,

    pub fn isShiftPressed(self: *const Modifiers) bool {
        return self.rightShift or self.leftShift;
    }

    pub fn isAltPressed(self: *const Modifiers) bool {
        return self.rightAlt or self.leftAlt;
    }

    pub fn isCtrlPressed(self: *const Modifiers) bool {
        return self.rightCtrl or self.leftCtrl;
    }

    pub fn update(self: *const Modifiers, event: *const Event) void {
        switch (event.unshiftedKey) {
            Key.Key_LeftShift => self.leftShift = event.state == State.Pressed,
            Key.Key_RightShift => self.rightShift = event.state == State.Pressed,
            Key.Key_LeftAlt => self.leftAlt = event.state == State.Pressed,
            Key.Key_RightAlt => self.rightAlt = event.state == State.Pressed,
            Key.Key_LeftCtrl => self.leftCtrl = event.state == State.Pressed,
            Key.Key_RightCtrl => self.rightCtrl = event.state == State.Pressed,
            else => {},
        }
    }
};

pub const Event = struct {
    unshiftedKey: Key,
    state: State,
    modifiers: Modifiers,
    key: Key,
    char: ?u8,

    pub fn init(unshiftedKey: Key, shiftedKey: ?Key, state: State, modifiers: *const Modifiers) Event {
        return Event{
            .unshiftedKey = unshiftedKey,
            .state = state,
            .modifiers = modifiers.*,
            .key = if (shiftedKey != null and modifiers.isShiftPressed()) shiftedKey.? else unshiftedKey,
            .char = null,
        };
    }
};
