const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Arg = struct {
    allocator: *Allocator,
    value: ?f64 = null,
    term: []u8 = "",

    pub fn deinit(self: *Arg) void {
        if (self.allocator) |allocator| {
            allocator.free(self.term);
        }
    }

    pub fn parse(self: *Arg, s: []const u8) bool {
        var startIndex: usize = 0;

        while (startIndex < s.len and
            !std.ascii.isDigit(s[startIndex])) : (startIndex += 1)
        {}

        if (startIndex > 0) {
            _ = self.setTerm(s[0..startIndex]);
        }

        if (startIndex == s.len) {
            return false;
        }

        var endIndex = startIndex;
        while (endIndex < s.len and
            (std.ascii.isDigit(s[endIndex]) or
            s[endIndex] == '.')) : (endIndex += 1)
        {}

        _ = self.setValue(s[startIndex..endIndex]);

        if (endIndex < s.len) {
            _ = self.setTerm(s[endIndex..s.len]);
        }

        return true;
    }

    fn setTerm(self: *Arg, str: []const u8) bool {
        self.term = self.allocator.alloc(u8, str.len) catch |err| switch (err) {
            error.OutOfMemory => return false,
        };

        @memcpy(self.term, str);
        return true;
    }

    fn setValue(self: *Arg, str: []const u8) bool {
        self.value = std.fmt.parseFloat(f64, str) catch |err|
            switch (err) {
            error.InvalidCharacter => return false,
        };

        return true;
    }
};
