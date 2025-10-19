const std = @import("std");
const expect = std.testing.expect;
const print = std.debug.print;

const in_buf = [_]u8{ 'h', 'e', 'l', 'l', 'o', ';', '\r', '\n' };
var out_buf: [1024 * 1024]u8 = undefined;
var map_buf: [1024 * 1024]Area = undefined;
var value_buf: [1024 * 1024]u8 = undefined;
var table_buf: [1028 * 1024]u8 = undefined;

const Area = enum {
   end,
   invalid,
   value,
   drop,
};

const State = struct {
   map: Area,
   value: u8,
   table: []u8,
};

test {
   var map = std.ArrayList(Area).initBuffer(&map_buf);
   var value = std.ArrayList(u8).initBuffer(&value_buf);
   //var table = std.ArrayList(u8).initBuffer(&table_buf); 

   while (true) {
      var reader = std.io.Reader.fixed(&in_buf);
      var writer = std.io.Writer.fixed(&out_buf);

      const bytes = try reader.peekDelimiterExclusive('\n');
      print("\\\\{s}\n", .{ bytes });

      map.clearRetainingCapacity();

      for (bytes) |c| {
         switch (c) {
            '\r' => {
               map.appendAssumeCapacity(Area.drop);
            },

            ';' => {
               map.appendAssumeCapacity(Area.end);
            },

            '0'...'9', 'a'...'z', 'A'...'Z' => {
               map.appendAssumeCapacity(Area.value);
            },

            else => {
               map.appendAssumeCapacity(Area.invalid);
            },
         }
      }

      const len = try reader.streamDelimiter(&writer, '\n');
      print("{d}", .{ len });

      const buffered = writer.buffered();
      try expect(buffered.len == len);

      for (buffered, 0..) |byte, i| {
         const area = map.items[i];

         switch (area) {
            .drop => { },

            .end => {
               print("\\\\{s}", .{ value.items });
               value.clearRetainingCapacity();
            },

            .value => {
               value.appendAssumeCapacity(byte);
            },

            .invalid => {
               if (byte != '\r') {
                  print("\\\\ERROR\\\\{c}", .{ byte });
               }
            },
         }
      }

      print("\n", .{ });
      break; 
   }
}
