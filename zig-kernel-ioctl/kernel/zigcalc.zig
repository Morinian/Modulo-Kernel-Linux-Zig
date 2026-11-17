const std = @import("std");

// Substitui o panic padrao para evitar dependencias de OS/libc no kernel
pub const panic = std.debug.simple_panic;

pub const ZigCalcReq = extern struct {
    a: i32,
    b: i32,
    resultado: i32,
};

// Codigos errno negativos padrao do Linux
const ENOTTY: c_long = -25;
const EDOM: c_long = -33;
const ERANGE: c_long = -34;

fn iowr(magic: u8, nr: u8, comptime T: type) u32 {
    const dir: u32 = 3; // _IOC_READ (2) | _IOC_WRITE (1)
    const size: u32 = @sizeOf(T);
    return (dir << 30) | (size << 16) | (@as(u32, magic) << 8) | @as(u32, nr);
}

const ZIGCALC_IOC_SOMA = iowr('Z', 1, ZigCalcReq);
const ZIGCALC_IOC_SUB  = iowr('Z', 2, ZigCalcReq);
const ZIGCALC_IOC_MULT = iowr('Z', 3, ZigCalcReq);
const ZIGCALC_IOC_DIV  = iowr('Z', 4, ZigCalcReq);

pub export fn zig_soma(a: i32, b: i32, out: *i32) callconv(.c) c_long {
    const res = @addWithOverflow(a, b);
    if (res[1] != 0) return ERANGE;
    out.* = res[0];
    return 0;
}

pub export fn zig_sub(a: i32, b: i32, out: *i32) callconv(.c) c_long {
    const res = @subWithOverflow(a, b);
    if (res[1] != 0) return ERANGE;
    out.* = res[0];
    return 0;
}

pub export fn zig_mult(a: i32, b: i32, out: *i32) callconv(.c) c_long {
    const res = @mulWithOverflow(a, b);
    if (res[1] != 0) return ERANGE;
    out.* = res[0];
    return 0;
}

pub export fn zig_div(a: i32, b: i32, out: *i32) callconv(.c) c_long {
    if (b == 0) return EDOM;
    if (a == std.math.minInt(i32) and b == -1) return ERANGE;
    out.* = @divTrunc(a, b);
    return 0;
}

pub export fn zig_processar_ioctl(cmd: u32, req: *ZigCalcReq) callconv(.c) c_long {
    return switch (cmd) {
        ZIGCALC_IOC_SOMA => zig_soma(req.a, req.b, &req.resultado),
        ZIGCALC_IOC_SUB  => zig_sub(req.a, req.b, &req.resultado),
        ZIGCALC_IOC_MULT => zig_mult(req.a, req.b, &req.resultado),
        ZIGCALC_IOC_DIV  => zig_div(req.a, req.b, &req.resultado),
        else => ENOTTY,
    };
}
