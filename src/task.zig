const std = @import("std");
const arg = @import("arg.zig");

pub const Type = enum {
    Undefined,
    Empty,
    Command,
    Conversion,
    Calculation,
};

pub const Operation = enum {
    Undefined,
    In,
    To,
    // Only calculations
    Of, // percentage
    Plus, // +
    Minus, // -
    Times, // *
    By, // /
};

pub const Task = struct {
    type: Type,
    fromValue: ?f64,
    fromUnit: ?[]u8,
    operation: Operation,
    toValue: ?f64,
    toUnit: ?[]u8,

    pub fn getOperationFromString(str: []const u8) Operation {
        if (std.ascii.orderIgnoreCase(str, "in") == .eq) {
            return Operation.In;
        } else if (std.ascii.orderIgnoreCase(str, "to") == .eq) {
            return Operation.To;
        } else if (std.ascii.orderIgnoreCase(str, "of") == .eq) {
            return Operation.Of;
        } else {
            return Operation.Undefined;
        }
    }

    pub fn fromArgList(argList: *arg.ArgList) Task {
        var tp = Type.Conversion;
        var op = Operation.Undefined;

        if (argList.has(0)) {
            tp = Type.Empty;
            return Task{
                .type = tp,
                .fromValue = 0.0,
                .fromUnit = "",
                .operation = op,
                .toValue = 0.0,
                .toUnit = "",
            };
        } else if (argList.has(1)) {
            // Example: -h
            const arg1 = argList.get(0);
            tp = Type.Command;
            return Task{
                .type = tp,
                .fromValue = arg1.value,
                .fromUnit = arg1.term,
                .operation = op,
                .toValue = arg1.value,
                .toUnit = arg1.term,
            };
        } else if (argList.has(2)) {
            // Example: 3m ft
            //          10% 100
            const arg1 = argList.get(0);
            const arg2 = argList.get(1);
            if (std.mem.eql(u8, arg1.term, "%")) {
                tp = Type.Calculation;
                op = Operation.Of;
            }
            return Task{
                .type = tp,
                .fromValue = arg1.value,
                .fromUnit = arg1.term,
                .operation = op,
                .toValue = arg2.value,
                .toUnit = arg2.term,
            };
        } else if (argList.has(3)) {
            const arg1 = argList.get(0);
            const arg2 = argList.get(1);
            const arg3 = argList.get(2);

            op = Task.getOperationFromString(arg2.term);
            if (op != Operation.Undefined) {
                // Example: 22m in  ft
                //          10% of 100
                //           10 of 100
                if ((arg1.term.len == 0 and arg3.term.len == 0) or
                    (std.mem.eql(u8, arg1.term, "%") or std.mem.eql(u8, arg3.term, "%")))
                {
                    tp = Type.Calculation;
                }
                return Task{
                    .type = tp,
                    .fromValue = arg1.value,
                    .fromUnit = arg1.term,
                    .operation = op,
                    .toValue = arg3.value,
                    .toUnit = arg3.term,
                };
            } else {
                if (arg1.value != null and std.mem.eql(u8, arg1.term, "") and
                    arg2.value == null and !std.mem.eql(u8, arg2.term, ""))
                {
                    // Example: 22 m ft
                    // Example: 22 % 100
                    if (std.mem.eql(u8, arg2.term, "%")) {
                        tp = Type.Calculation;
                        op = Operation.Of;
                    }
                    return Task{
                        .type = tp,
                        .fromValue = arg1.value,
                        .fromUnit = arg2.term,
                        .operation = op,
                        .toValue = arg3.value,
                        .toUnit = arg3.term,
                    };
                }
            }
        } else if (argList.has(4)) {
            const arg1 = argList.get(0);
            const arg2 = argList.get(1);
            const arg3 = argList.get(2);
            const arg4 = argList.get(3);

            op = Task.getOperationFromString(arg3.term);
            if (op != Operation.Undefined) {
                // Example: 22 m in  ft
                //          10 % of 100
                if (std.mem.eql(u8, arg2.term, "%")) {
                    tp = Type.Calculation;
                }
                return Task{
                    .type = tp,
                    .fromValue = arg1.value,
                    .fromUnit = arg2.term,
                    .operation = op,
                    .toValue = arg4.value,
                    .toUnit = arg4.term,
                };
            }
        }

        return Task{
            .type = Type.Undefined,
            .fromValue = null,
            .fromUnit = null,
            .operation = Operation.Undefined,
            .toValue = null,
            .toUnit = null,
        };
    }
};
