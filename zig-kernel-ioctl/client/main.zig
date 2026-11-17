const std = @import("std");
const linux = std.os.linux;

const ZigCalcReq = extern struct {
    a: i32,
    b: i32,
    resultado: i32,
};

fn iowr(magic: u8, nr: u8, comptime T: type) u32 {
    const dir: u32 = 3; // _IOC_READ | _IOC_WRITE
    const size: u32 = @sizeOf(T);
    return (dir << 30) | (size << 16) | (@as(u32, magic) << 8) | @as(u32, nr);
}

const ZIGCALC_IOC_SOMA = iowr('Z', 1, ZigCalcReq);
const ZIGCALC_IOC_SUB  = iowr('Z', 2, ZigCalcReq);
const ZIGCALC_IOC_MULT = iowr('Z', 3, ZigCalcReq);
const ZIGCALC_IOC_DIV  = iowr('Z', 4, ZigCalcReq);

fn printStdout(msg: []const u8) void {
    _ = linux.write(1, msg.ptr, msg.len);
}

fn printStderr(msg: []const u8) void {
    _ = linux.write(2, msg.ptr, msg.len);
}

fn abrirDispositivo() ?i32 {
    const fd_rc = linux.open("/dev/zigcalc", .{ .ACCMODE = .RDWR }, 0);
    const fd_signed: isize = @bitCast(fd_rc);
    if (fd_signed < 0) {
        printStderr("Erro: nao foi possivel abrir /dev/zigcalc\n");
        return null;
    }
    return @intCast(fd_signed);
}

fn tratarErroIoctl(rc: usize) u8 {
    const signed_rc: isize = @bitCast(rc);
    const errno_val = -signed_rc;
    switch (errno_val) {
        33 => printStderr("Erro: divisão por zero\n"),          // EDOM
        34 => printStderr("Erro: transbordamento aritmético\n"), // ERANGE
        25 => printStderr("Erro: comando desconhecido\n"),       // ENOTTY
        14 => printStderr("Erro: ponteiro inválido\n"),          // EFAULT
        else => printStderr("Erro: falha na chamada ioctl\n"),
    }
    return 1;
}

pub fn main(init: std.process.Init.Minimal) u8 {
    var it = init.args.iterate();
    _ = it.next(); // ignora argv[0]

    const arg1 = it.next() orelse {
        printStderr("Uso: ./zigcalc <soma|sub|mult|div> <a> <b>\n");
        return 1;
    };

    const arg2 = it.next();

    // Modos auxiliares para validacao automatizada de EFAULT e ENOTTY
    if (arg2 == null) {
        if (std.mem.eql(u8, arg1, "--test-efault")) {
            const fd = abrirDispositivo() orelse return 1;
            defer _ = linux.close(fd);
            const rc = linux.ioctl(fd, ZIGCALC_IOC_SOMA, 0);
            const signed_rc: isize = @bitCast(rc);
            if (signed_rc < 0) return tratarErroIoctl(rc);
            return 0;
        }
        if (std.mem.eql(u8, arg1, "--test-enotty")) {
            const fd = abrirDispositivo() orelse return 1;
            defer _ = linux.close(fd);
            var dummy = ZigCalcReq{ .a = 1, .b = 1, .resultado = 0 };
            const rc = linux.ioctl(fd, 0xdeadbeef, @intFromPtr(&dummy));
            const signed_rc: isize = @bitCast(rc);
            if (signed_rc < 0) return tratarErroIoctl(rc);
            return 0;
        }
        printStderr("Uso: ./zigcalc <soma|sub|mult|div> <a> <b>\n");
        return 1;
    }

    const arg3 = it.next() orelse {
        printStderr("Uso: ./zigcalc <soma|sub|mult|div> <a> <b>\n");
        return 1;
    };

    if (it.next() != null) {
        printStderr("Uso: ./zigcalc <soma|sub|mult|div> <a> <b>\n");
        return 1;
    }

    const cmd: u32 = if (std.mem.eql(u8, arg1, "soma"))
        ZIGCALC_IOC_SOMA
    else if (std.mem.eql(u8, arg1, "sub"))
        ZIGCALC_IOC_SUB
    else if (std.mem.eql(u8, arg1, "mult"))
        ZIGCALC_IOC_MULT
    else if (std.mem.eql(u8, arg1, "div"))
        ZIGCALC_IOC_DIV
    else {
        printStderr("Erro: operacao desconhecida\n");
        return 1;
    };

    const a = std.fmt.parseInt(i32, arg2.?, 10) catch {
        printStderr("Erro: operando 'a' invalido para i32\n");
        return 1;
    };
    const b = std.fmt.parseInt(i32, arg3, 10) catch {
        printStderr("Erro: operando 'b' invalido para i32\n");
        return 1;
    };

    const fd = abrirDispositivo() orelse return 1;
    defer _ = linux.close(fd);

    var req = ZigCalcReq{
        .a = a,
        .b = b,
        .resultado = 0,
    };

    const ioctl_rc = linux.ioctl(fd, cmd, @intFromPtr(&req));
    const ioctl_signed: isize = @bitCast(ioctl_rc);
    if (ioctl_signed < 0) {
        return tratarErroIoctl(ioctl_rc);
    }

    var buf: [64]u8 = undefined;
    const out_msg = std.fmt.bufPrint(&buf, "Resultado: {d}\n", .{req.resultado}) catch return 1;
    printStdout(out_msg);
    return 0;
}
