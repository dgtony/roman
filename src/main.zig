const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len < 2) {
        try printUsage();
        return;
    }

    for (args[1..]) |numeral| {
        const val = parse(numeral) catch |err| {
            std.log.err("bad numeral {s} ({})", .{numeral, err});
            continue;
        };
        std.log.info(" {s} => {d}", .{numeral, val});
    }
}

fn printUsage() !void {
    const usage =
        \\   Converter of Roman numerals.
        \\
        \\   Usage: provide numerals as CLI arguments, delimited by spaces.
        \\
    ;
    const stdout = std.io.getStdOut();
    try stdout.writeAll(@as([]const u8, usage));
}

const parsingErrs = error {
    NotRoman,
};

fn parse(lit: []const u8) parsingErrs!i64 {
    var result: i64 = 0;
    var curr_pos: usize = 0;
    var curr_char: u8 = lit[curr_pos];

    for (lit) |ch, i| {
        // TODO optimize: no need to repeatedly 
        // compute values for the same characters
        var ch_val = literal_value(ch) orelse 0;
        if (ch_val == 0) {
            return parsingErrs.NotRoman;
        }

        if (ch != curr_char) {
            const curr_val = literal_value(curr_char).?;
            if (ch_val > curr_val) {
                // backtrack
                var j: usize = i;
                while ( j > curr_pos ) : ( j -= 1 ) {
                    // subtract two times, compensating 
                    // previously added by mistake
                    result -= 2 * curr_val;
                }
            }
            curr_pos = i;
            curr_char = ch;
        }

        result += ch_val;
    }
    return result;
}

fn literal_value(ch: u8) ?u32 {
    return switch (ch) {
        'I', 'i' => 1,
        'V', 'v' => 5,
        'X', 'x' => 10,
        'L', 'l' => 50,
        'C', 'c' => 100,
        'D', 'd' => 500,
        'M', 'm' => 1000,
        else     => null
    };
}


test "numerals 0-100" {
    const numerals = [_][]const u8{
        "I","II","III","IV","V","VI","VII","VIII","IX","X",
        "XI", "XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX",
        "XXI","XXII","XXIII","XXIV","XXV","XXVI","XXVII","XXVIII","XXIX","XXX",
        "XXXI","XXXII","XXXIII","XXXIV","XXXV","XXXVI","XXXVII","XXXVIII","XXXIX","XL",
        "XLI","XLII","XLIII","XLIV","XLV","XLVI","XLVII","XLVIII","XLIX","L","LI",
        "LII","LIII","LIV","LV","LVI","LVII","LVIII","LIX","LX","LXI",
        "LXII","LXIII","LXIV","LXV","LXVI","LXVII","LXVIII","LXIX","LXX","LXXI",
        "LXXII","LXXIII","LXXIV","LXXV","LXXVI","LXXVII","LXXVIII","LXXIX","LXXX",
        "LXXXI","LXXXII","LXXXIII","LXXXIV","LXXXV","LXXXVI","LXXXVII","LXXXVIII","LXXXIX","XC",
        "XCI","XCII","XCIII","XCIV","XCV","XCVI","XCVII","XCVIII","XCIX","C",
    };

    for (numerals) |num, i| {
        const result = try parse(num);
        try std.testing.expectEqual(@intCast(i64, i+1), result);
    }
}
