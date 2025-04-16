const std = @import("std");
const arg = @import("arg.zig");

pub const Type = enum {
    Undefined,
    Command,
    Conversion,
    Calculation,
};

pub const Task = struct {
    type: Type,
    fromValue: ?f64,
    fromUnit: ?[]u8,
    toValue: ?f64,
    toUnit: ?[]u8,

    pub fn fromArgList(argList: *arg.ArgList) Task {
        if (argList.has(0)) {
            // TODO: Handle error
        } else if (argList.has(1)) {
            // Example: -h
            const arg1 = argList.get(0);
            return Task{
                .type = Type.Command,
                .fromValue = arg1.value,
                .fromUnit = arg1.term,
                .toValue = arg1.value,
                .toUnit = arg1.term,
            };
        } else if (argList.has(2)) {
            // Example: 3m ft
            const arg1 = argList.get(0);
            const arg2 = argList.get(1);
            return Task{
                .type = Type.Conversion,
                .fromValue = arg1.value,
                .fromUnit = arg1.term,
                .toValue = arg2.value,
                .toUnit = arg2.term,
            };
        } else if (argList.has(3)) {
            const arg1 = argList.get(0);
            const arg2 = argList.get(1);
            const arg3 = argList.get(2);

            if (std.mem.eql(u8, arg2.term, "in") or
                std.mem.eql(u8, arg2.term, "of"))
            {
                // Example: 22m in ft
                return Task{
                    .type = Type.Conversion,
                    .fromValue = arg1.value,
                    .fromUnit = arg1.term,
                    .toValue = arg3.value,
                    .toUnit = arg3.term,
                };
            } else {
                if (arg1.value != null and std.mem.eql(u8, arg1.term, "") and
                    arg2.value == null and !std.mem.eql(u8, arg2.term, ""))
                {
                    // Example: 22 m ft
                    return Task{
                        .type = Type.Conversion,
                        .fromValue = arg1.value,
                        .fromUnit = arg2.term,
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

            if (std.mem.eql(u8, arg3.term, "in") or
                std.mem.eql(u8, arg3.term, "of"))
            {
                // Example: 22 m in ft
                return Task{
                    .type = Type.Conversion,
                    .fromValue = arg1.value,
                    .fromUnit = arg2.term,
                    .toValue = arg4.value,
                    .toUnit = arg4.term,
                };
            }
        }

        return Task{
            .type = Type.Undefined,
            .fromValue = null,
            .fromUnit = null,
            .toValue = null,
            .toUnit = null,
        };
    }
};
