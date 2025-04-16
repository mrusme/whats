const std = @import("std");

pub const Arg = struct {
    allocator: std.mem.Allocator,
    value: ?f64 = null,
    term: []u8 = "",

    pub fn deinit(self: *Arg) void {
        if (self.term.len > 0) {
            self.allocator.free(self.term);
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

pub const ArgList = struct {
    allocator: std.mem.Allocator,
    argList: std.MultiArrayList(Arg),

    pub fn init(allocator: std.mem.Allocator) ArgList {
        return ArgList{
            .allocator = allocator,
            .argList = std.MultiArrayList(Arg){},
        };
    }

    pub fn deinit(self: *ArgList) void {
        for (0.., self.argList.items(.term)) |i, _| {
            const tmp = self.argList.get(i);
            @constCast(&tmp).deinit();
        }
        @constCast(&self.argList).deinit(self.allocator);
    }

    pub fn parse(self: *ArgList) !void {
        var argsIter = try std.process.ArgIterator.initWithAllocator(self.allocator);
        defer argsIter.deinit();
        _ = argsIter.next();

        std.log.debug("Args:", .{});

        var i: usize = 0;
        while (argsIter.next()) |argStr| {
            var targ = Arg{
                .allocator = self.allocator,
            };

            _ = targ.parse(argStr);

            std.log.debug("{s} ", .{targ.term});
            if (targ.value) |number| {
                std.log.debug("{d} ", .{number});
            }

            i += 1;
            try self.argList.ensureTotalCapacity(self.allocator, i);
            try self.argList.append(self.allocator, targ);
        }

        return;
    }

    pub fn has(self: *ArgList, num: usize) bool {
        return self.argList.len == num;
    }

    pub fn termIs(self: *ArgList, idx: usize, ref: []const u8) bool {
        if (self.has(idx + 1)) {
            const targ = self.argList.get(idx);
            if (std.mem.eql(u8, targ.term, ref)) {
                return true;
            }
        }
        return false;
    }
};
