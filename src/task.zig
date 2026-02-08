const std = @import("std");
const token = @import("token.zig");

pub const Operation = token.Operation;

pub const Type = enum {
    Undefined,
    Empty,
    Command,
    Conversion,
    Calculation,
};

pub const Task = struct {
    type: Type,
    fromValue: ?f64,
    fromUnit: ?[]u8,
    operation: Operation,
    toValue: ?f64,
    toUnit: ?[]u8,

    pub fn fromTokens(tokens: *token.TokenList) Task {
        const n = tokens.len();

        // [] -> Empty
        if (n == 0) {
            return Task{
                .type = .Empty,
                .fromValue = 0.0,
                .fromUnit = "",
                .operation = .Undefined,
                .toValue = 0.0,
                .toUnit = "",
            };
        }

        // [command] -> Command
        if (n == 1 and tokens.get(0).kind == .command) {
            const t0 = tokens.get(0);
            return Task{
                .type = .Command,
                .fromValue = t0.value,
                .fromUnit = t0.raw,
                .operation = .Undefined,
                .toValue = t0.value,
                .toUnit = t0.raw,
            };
        }

        // [number, unit, operator, unit] -> Conversion
        // e.g. "3m in ft", "3 m in ft", "3 meters in feet"
        if (n == 4 and
            tokens.get(0).kind == .number and
            tokens.get(1).kind == .unit and
            tokens.get(2).kind == .operator and
            tokens.get(3).kind == .unit)
        {
            return Task{
                .type = .Conversion,
                .fromValue = tokens.get(0).value,
                .fromUnit = tokens.get(1).raw,
                .operation = tokens.get(2).operation,
                .toValue = tokens.get(3).value,
                .toUnit = tokens.get(3).raw,
            };
        }

        // [number, unit, unit] -> Conversion (implicit operator)
        // e.g. "3m ft", "3 m ft"
        if (n == 3 and
            tokens.get(0).kind == .number and
            tokens.get(1).kind == .unit and
            tokens.get(2).kind == .unit)
        {
            // Check for percentage: [number, unit("%"), number-as-unit]
            // This shouldn't normally happen since numbers become .number tokens,
            // but handle defensively.
            if (std.mem.eql(u8, tokens.get(1).raw, "%")) {
                return Task{
                    .type = .Calculation,
                    .fromValue = tokens.get(0).value,
                    .fromUnit = tokens.get(1).raw,
                    .operation = .Of,
                    .toValue = tokens.get(2).value,
                    .toUnit = tokens.get(2).raw,
                };
            }
            return Task{
                .type = .Conversion,
                .fromValue = tokens.get(0).value,
                .fromUnit = tokens.get(1).raw,
                .operation = .Undefined,
                .toValue = tokens.get(2).value,
                .toUnit = tokens.get(2).raw,
            };
        }

        // [number, unit("%"), number] -> Calculation/Of
        // e.g. "10% 100", "22 % 100"
        if (n == 3 and
            tokens.get(0).kind == .number and
            tokens.get(1).kind == .unit and
            std.mem.eql(u8, tokens.get(1).raw, "%") and
            tokens.get(2).kind == .number)
        {
            return Task{
                .type = .Calculation,
                .fromValue = tokens.get(0).value,
                .fromUnit = tokens.get(1).raw,
                .operation = .Of,
                .toValue = tokens.get(2).value,
                .toUnit = "",
            };
        }

        // [number, unit("%"), operator, number] -> Calculation/Of
        // e.g. "10% of 100"
        if (n == 4 and
            tokens.get(0).kind == .number and
            tokens.get(1).kind == .unit and
            std.mem.eql(u8, tokens.get(1).raw, "%") and
            tokens.get(2).kind == .operator and
            tokens.get(3).kind == .number)
        {
            return Task{
                .type = .Calculation,
                .fromValue = tokens.get(0).value,
                .fromUnit = tokens.get(1).raw,
                .operation = tokens.get(2).operation,
                .toValue = tokens.get(3).value,
                .toUnit = "",
            };
        }

        // [number, operator, number] -> Calculation
        // e.g. "10 to 20" (percentage change), "10 of 50" (what % is X of Y)
        if (n == 3 and
            tokens.get(0).kind == .number and
            tokens.get(1).kind == .operator and
            tokens.get(2).kind == .number)
        {
            return Task{
                .type = .Calculation,
                .fromValue = tokens.get(0).value,
                .fromUnit = "",
                .operation = tokens.get(1).operation,
                .toValue = tokens.get(2).value,
                .toUnit = "",
            };
        }

        // No pattern matched
        return Task{
            .type = .Undefined,
            .fromValue = null,
            .fromUnit = null,
            .operation = .Undefined,
            .toValue = null,
            .toUnit = null,
        };
    }
};
