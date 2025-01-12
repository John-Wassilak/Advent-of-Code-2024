const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

// this was fun, so much that I went down a bit of a rabbit hole learning zig.
// 'ziglings' is a must.
//
// the syntax is funky at first, likely because I'm not a rustacean,
// but once you go through it, it clicks.
//
// the fact that I can write entire functions without constant
// compile/trial/error seems like a good sign
//
// running:
//      zig run 12-09.zig

///////////////////////// part 1 //////////////////////////////////////////////

const DiskBlock = union(enum) {
    file: usize,
    free_space: bool, // not a fan but I couldnt figure out a void member
};

fn p1_parse_input(input: []const u8, alloc: Allocator) !ArrayList(DiskBlock) {
    var i: usize = 0;
    var out = std.ArrayList(DiskBlock).init(alloc);
    const stripped = std.mem.trim(u8, input, " \n");

    while (i < stripped.len) : (i += 2) {
        var size: u8 = stripped[i] - '0';

        while (size > 0) : (size -= 1) {
            try out.append(DiskBlock{ .file = (i / 2) });
        }

        if ((i + 1) < stripped.len) {
            size = stripped[i + 1] - '0';
            while (size > 0) : (size -= 1) {
                try out.append(DiskBlock{ .free_space = true });
            }
        }
    }
    return out;
}

fn p1_compact(disk: ArrayList(DiskBlock)) void {
    var rightmost_blk: usize = disk.items.len - 1;
    var leftmost_blk: usize = 0;
    var done = false;

    while (!done) {

        // find rightmost file block
        while (rightmost_blk > 0) : (rightmost_blk -= 1) {
            switch (disk.items[rightmost_blk]) {
                .file => break,
                .free_space => continue,
            }
        }

        // find leftmost free block
        while (leftmost_blk < disk.items.len) : (leftmost_blk += 1) {
            switch (disk.items[leftmost_blk]) {
                .file => continue,
                .free_space => break,
            }
        }

        // swap if still free on the left
        if (leftmost_blk > rightmost_blk) {
            done = true;
        } else {
            const temp: DiskBlock = disk.items[rightmost_blk];
            disk.items[rightmost_blk] = disk.items[leftmost_blk];
            disk.items[leftmost_blk] = temp;
        }
    }
}

fn p1_calc_checksum(disk: ArrayList(DiskBlock)) usize {
    var result: usize = 0;

    for (disk.items, 0..) |item, pos| {
        switch (item) {
            .file => |f| result += f * pos,
            .free_space => continue,
        }
    }

    return result;
}

///////////////////////////////// end part 1 //////////////////////////////////

///////////////////////////////// part 2 //////////////////////////////////////

// id rather just re-parse, this is how I started doing part 1 anyhow

const File = struct { id: usize, size: usize };

const FreeSpace = struct { size: usize };

const DiskObj = union(enum) { file: File, free_space: FreeSpace };

fn p2_parse_input(input: []const u8, alloc: Allocator) !ArrayList(DiskObj) {
    var i: usize = 0;
    var out = std.ArrayList(DiskObj).init(alloc);
    const stripped = std.mem.trim(u8, input, " \n");

    while (i < stripped.len) : (i += 2) {
        var size: u8 = stripped[i] - '0';

        try out.append(DiskObj{ .file = .{ .id = (i / 2), .size = size } });

        if ((i + 1) < stripped.len) {
            size = stripped[i + 1] - '0';
            try out.append(DiskObj{ .free_space = .{ .size = size } });
        }
    }
    return out;
}

fn p2_compact(disk: *ArrayList(DiskObj)) !void {
    var i: usize = disk.items.len - 1;

    // loop from right to left, to find files
    while (i > 0) : (i -= 1) {
        const obj = switch (disk.items[i]) {
            .file => |f| f,
            .free_space => continue,
        };

        // loop from left to right to find suitable free spot
        var j: usize = 0;
        while (j < disk.items.len and j < i) : (j += 1) {
            switch (disk.items[j]) {
                .file => continue,
                .free_space => |fs| if (fs.size == obj.size) { // swap
                    const temp = disk.items[i];
                    disk.items[i] = disk.items[j];
                    disk.items[j] = temp;
                    break;
                } else if (fs.size > obj.size) { // reduce free and insert file
                    const new_fs_size = fs.size - obj.size;

                    disk.items[j] = DiskObj{ .free_space = .{ .size = new_fs_size } };

                    // do this first so we don't lose track of things when inserting
                    disk.items[i] = DiskObj{ .free_space = .{ .size = obj.size } };
                    try disk.insert(j, DiskObj{ .file = obj });
                    break;
                } else continue,
            }
        }
    }
}

// my data model made this a pain in the ass
fn p2_calc_checksum(disk: ArrayList(DiskObj)) usize {
    var result: usize = 0;
    var position: usize = 0;

    for (disk.items) |item| {
        switch (item) {
            .file => |f| {
                var file_size = f.size;
                while (file_size > 0) : (file_size -= 1) {
                    result += f.id * position;
                    position += 1;
                }
            },
            .free_space => |fs| position += fs.size,
        }
    }

    return result;
}

///////////////////////// end p2 //////////////////////////////////////////////

pub fn get_input(alloc: Allocator) ![]u8 {
    const headers_max_size = 1024;
    const body_max_size = 65536;

    // not sure how to get around defining this
    var hbuffer: [headers_max_size]u8 = undefined;

    const url = try std.Uri.parse("https://adventofcode.com/2024/day/9/input");

    var client = std.http.Client{ .allocator = alloc };
    defer client.deinit();

    // get aoc cookie
    var env_map = try std.process.getEnvMap(alloc);
    defer env_map.deinit();
    const cookie = env_map.get("AOC_COOKIE") orelse unreachable;

    // setup request
    const headers: []const std.http.Header = &.{.{ .name = "COOKIE", .value = cookie }};
    const options = std.http.Client.RequestOptions{ .server_header_buffer = &hbuffer, .extra_headers = headers };
    var request = try client.open(std.http.Method.GET, url, options);
    defer request.deinit();

    // perform request
    try request.send();
    try request.finish();
    try request.wait();

    return try request.reader().readAllAlloc(alloc, body_max_size);
}

pub fn main() !void {

    // setup heap allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit(); // noice
    const allocator = arena.allocator();

    const input = try get_input(allocator);

    // p1
    const map = try p1_parse_input(input, allocator);
    p1_compact(map);
    const checksum = p1_calc_checksum(map);
    std.debug.print("Part 1 checksum: {d}\n", .{checksum});

    // p2
    var p2_map = try p2_parse_input(input, allocator);
    try p2_compact(&p2_map);
    const p2_checksum = p2_calc_checksum(p2_map);
    std.debug.print("Part 2 checksum: {d}\n", .{p2_checksum});
}
