import Darwin;
import Foundation;

var ic: Int = 0;

class ConditionCodes {
    var z: UInt8;
    var s: UInt8;
    var p: UInt8;
    var cy: UInt8;
    var ac: UInt8;
    var pad: UInt8;

    init() {
        z = 0;
        s = 0;
        p = 0;
        cy = 0;
        ac = 0;
        pad = 0;
    }
};

class State8080 {
    var a: UInt8;
    var b: UInt8;
    var c: UInt8;
    var d: UInt8;
    var e: UInt8;
    var h: UInt8;
    var l: UInt8;
    var sp: UInt16;
    var pc: UInt16;
    var memory: [UInt8];
    var cc: ConditionCodes;
    var int_enabled: UInt8;

    init() {
        a = 0;
        b = 0;
        c = 0;
        d = 0;
        e = 0;
        h = 0;
        l = 0;
        sp = 0;
        pc = 0;
        memory = [UInt8](repeating: 0, count: 65536);
        cc = ConditionCodes();
        int_enabled = 0;
    }

    func incrementPC(amount: UInt16 = 1) -> Void {
        pc += amount;
    }

    func decrementPC(amount: UInt16 = 1) -> Void {
        pc -= amount;
    }
}

func UnimplementedInstruction(state: State8080) {
    print("Error: Unimplemented Instruction");
    state.decrementPC();
    let _ = Disassemble8080Op(codebuffer: state.memory, pc: Int(state.pc));
    print(String(format: "0x%02x", state.memory[Int(state.pc)]))
    print("");
    exit(1);
}

func CheckZFlag(answer: UInt16) -> UInt8 {
    if((answer & 0xff) == 0){
        return 1;
    }

    return 0;
}

func CheckSFlag(answer: UInt16) -> UInt8 {
    if ((answer & 0x80) != 0) {
        return 1;
    }
    return 0;
}

func CheckCYFlag(answer: UInt16) -> UInt8 {
    if (answer > 0xff) {
        return 1;
    }
    return 0;
}

func CheckPFlag16(answer: UInt16) -> UInt8 {
    var y: UInt16;
    y = answer ^ (answer >> 1);
    y = y ^ (y >> 2);
    y = y ^ (y >> 4);
    y = y ^ (y >> 8);
    y = y ^ (y >> 16);
    return UInt8(y & 0x1)
}

func CheckPFlag8(answer: UInt8) -> UInt8 {
    var y: UInt8;
    y = answer ^ (answer >> 1);
    y = y ^ (y >> 2);
    y = y ^ (y >> 4);
    y = y ^ (y >> 8);
    return UInt8(y & 0x1)
}

func ModifyFlags(state: State8080, answer: UInt16) -> Void {
    state.cc.z = CheckZFlag(answer: answer);
    state.cc.s = CheckSFlag(answer: answer);
    state.cc.cy = CheckCYFlag(answer: answer);
    state.cc.p = CheckPFlag16(answer: answer);
}

func LogicFlagsA(state: State8080) -> Void {
    state.cc.cy = 0;
    state.cc.ac = 0;
    state.cc.z = (state.a == 0) ? 1 : 0;
    state.cc.s = (0x80 == (state.a & 0x80)) ? 1 : 0;
    state.cc.p = CheckPFlag8(answer: state.a);
}

func Emulate8080Op(state: State8080) -> Void {
    let opcode: [UInt8] = Array(state.memory[Int(state.pc)...]);

    Disassemble8080Op(codebuffer: state.memory, pc: Int(state.pc));

    state.incrementPC()
    ic += 1;

    switch opcode[0] {
    case 0x00: break;
    case 0x01: 
        state.c = opcode[1];
        state.b = opcode[2];
        state.incrementPC(amount: 2);
        break;
    case 0x02: UnimplementedInstruction(state: state); break;
    case 0x03: UnimplementedInstruction(state: state); break;
    case 0x04: UnimplementedInstruction(state: state); break;
    case 0x05:
        var answer: UInt8;
        answer = (state.b == 0) ? 0xff : state.b - UInt8(1);
        state.cc.z = (answer == 0) ? 1 : 0;
        state.cc.s = (0x80 == (answer & 0x80)) ? 1 : 0;
        state.cc.p = CheckPFlag8(answer: answer);
        state.b = answer;
        break;
    case 0x06:
        state.b = opcode[1];
        state.incrementPC(amount: 1);
        break;
    case 0x07: UnimplementedInstruction(state: state); break;
    case 0x08: UnimplementedInstruction(state: state); break;
    case 0x09:
        let hl: UInt32 = (UInt32(state.h) << 8) | UInt32(state.l);
        let bc: UInt32 = (UInt32(state.b) << 8) | UInt32(state.c);
        let res: UInt32 = hl + bc;
        state.h = UInt8((res & 0xff00) >> 8);
        state.l = UInt8(res & 0xff);
        state.cc.cy = ((res & 0xffff0000) > 0) ? 1 : 0;
        break;
    case 0x0a: UnimplementedInstruction(state: state); break;
    case 0x0b: UnimplementedInstruction(state: state); break;
    case 0x0c: UnimplementedInstruction(state: state); break;
    case 0x0d:
        state.c = (state.c == 0) ? 0xff : state.c-1;
        break;
    case 0x0e:
        state.c = opcode[1];
        state.incrementPC(amount: 1);
        break;
    case 0x0f:
        let a: UInt8 = state.a;
        state.a = ((a & 1) << 7) | (a >> 1);
        state.cc.cy = (1 == (a&1)) ? 1: 0;
        break;
    case 0x10: UnimplementedInstruction(state: state); break;
    case 0x11:
        state.d = opcode[2];
        state.e = opcode[1];
        state.incrementPC(amount: 2);
        break;
    case 0x12: UnimplementedInstruction(state: state); break;
    case 0x13:
        let answer: UInt16 = ((UInt16(state.d) << 8) | UInt16(state.e)) + 1;
        state.e = UInt8(answer & 0xff);
        state.d = UInt8((answer >> 8) & 0xff);
        break;
    case 0x14: UnimplementedInstruction(state: state); break;
    case 0x15: UnimplementedInstruction(state: state); break;
    case 0x16: UnimplementedInstruction(state: state); break;
    case 0x17: UnimplementedInstruction(state: state); break;
    case 0x18: UnimplementedInstruction(state: state); break;
    case 0x19:
        let hl: UInt32 = (UInt32(state.h) << 8) | UInt32(state.l);
        let de: UInt32 = (UInt32(state.d) << 8) | UInt32(state.e);
        let res: UInt32 = hl + de;
        state.h = UInt8((res & 0xff00) >> 8);
        state.l = UInt8(res & 0xff);
        state.cc.cy = ((res & 0xffff0000) != 0) ? 1 : 0;
        break;
    case 0x1a:
        let adr: Int = Int((UInt16(state.d) << 8) | UInt16(state.e)); 
        state.a = state.memory[adr]
        break;
    case 0x1b: UnimplementedInstruction(state: state); break;
    case 0x1c: UnimplementedInstruction(state: state); break;
    case 0x1d: UnimplementedInstruction(state: state); break;
    case 0x1e: UnimplementedInstruction(state: state); break;
    case 0x1f: UnimplementedInstruction(state: state); break;
    case 0x20: UnimplementedInstruction(state: state); break;
    case 0x21:
        state.h = opcode[2];
        state.l = opcode[1];
        state.incrementPC(amount: 2);
        break;
    case 0x22: UnimplementedInstruction(state: state); break;
    case 0x23:
        let answer: UInt16 = ((UInt16(state.h) << 8) | UInt16(state.l)) + 1;
        state.l = UInt8(answer & 0xff);
        state.h = UInt8((answer >> 8) & 0xff);
        break;
    case 0x24: UnimplementedInstruction(state: state); break;
    case 0x25: UnimplementedInstruction(state: state); break;
    case 0x26:
        state.h = opcode[1];
        state.incrementPC(amount: 1);
        break;
    case 0x27: UnimplementedInstruction(state: state); break;
    case 0x28: UnimplementedInstruction(state: state); break;
    case 0x29:
        let hl: UInt32 = (UInt32(state.h) << 8) | UInt32(state.l);
        let res: UInt32 = hl + hl;
        state.h = UInt8((res & 0xff00) >> 8);
        state.l = UInt8(res & 0xff);
        state.cc.cy = ((res & 0xffff0000) != 0) ? 1 : 0;
        break;
    case 0x2a: UnimplementedInstruction(state: state); break;
    case 0x2b: UnimplementedInstruction(state: state); break;
    case 0x2c: UnimplementedInstruction(state: state); break;
    case 0x2d: UnimplementedInstruction(state: state); break;
    case 0x2e: UnimplementedInstruction(state: state); break;
    case 0x2f: UnimplementedInstruction(state: state); break;
    case 0x30: UnimplementedInstruction(state: state); break;
    case 0x31:
        state.sp = (UInt16(opcode[2]) << 8) | UInt16(opcode[1]);
        state.incrementPC(amount: 2);
        break;
    case 0x32:
        let adr: Int = Int((UInt16(opcode[2]) << 8) | UInt16(opcode[1]));
        state.memory[adr] = state.a;
        state.incrementPC(amount: 2);
        break;
    case 0x33: UnimplementedInstruction(state: state); break;
    case 0x34: UnimplementedInstruction(state: state); break;
    case 0x35: UnimplementedInstruction(state: state); break;
    case 0x36:
        let adr: Int = Int((UInt16(state.h) << 8) | UInt16(state.l));
        state.memory[adr] = opcode[1];
        state.incrementPC(amount: 1);
        break;
    case 0x37: UnimplementedInstruction(state: state); break;
    case 0x38: UnimplementedInstruction(state: state); break;
    case 0x39: UnimplementedInstruction(state: state); break;
    case 0x3a:
        let adr: Int = Int((UInt16(opcode[2]) << 8) | UInt16(opcode[1]));
        state.a = state.memory[adr];
        state.incrementPC(amount: 2);
        break;
    case 0x3b: UnimplementedInstruction(state: state); break;
    case 0x3c: UnimplementedInstruction(state: state); break;
    case 0x3d: UnimplementedInstruction(state: state); break;
    case 0x3e:
        state.a = opcode[1];
        state.incrementPC(amount: 1);
        break;
    case 0x3f: UnimplementedInstruction(state: state); break;
    case 0x40: UnimplementedInstruction(state: state); break;
    case 0x41: UnimplementedInstruction(state: state); break;
    case 0x42: UnimplementedInstruction(state: state); break;
    case 0x43: UnimplementedInstruction(state: state); break;
    case 0x44: UnimplementedInstruction(state: state); break;
    case 0x45: UnimplementedInstruction(state: state); break;
    case 0x46: UnimplementedInstruction(state: state); break;
    case 0x47: UnimplementedInstruction(state: state); break;
    case 0x48: UnimplementedInstruction(state: state); break;
    case 0x49: UnimplementedInstruction(state: state); break;
    case 0x4a: UnimplementedInstruction(state: state); break;
    case 0x4b: UnimplementedInstruction(state: state); break;
    case 0x4c: UnimplementedInstruction(state: state); break;
    case 0x4d: UnimplementedInstruction(state: state); break;
    case 0x4e: UnimplementedInstruction(state: state); break;
    case 0x4f: UnimplementedInstruction(state: state); break;
    case 0x50: UnimplementedInstruction(state: state); break;
    case 0x51: UnimplementedInstruction(state: state); break;
    case 0x52: UnimplementedInstruction(state: state); break;
    case 0x53: UnimplementedInstruction(state: state); break;
    case 0x54: UnimplementedInstruction(state: state); break;
    case 0x55: UnimplementedInstruction(state: state); break;
    case 0x56:
        let adr: Int = Int((UInt16(state.h) << 8) | UInt16(state.l));
        state.d = state.memory[adr];
        break;
    case 0x57: UnimplementedInstruction(state: state); break;
    case 0x58: UnimplementedInstruction(state: state); break;
    case 0x59: UnimplementedInstruction(state: state); break;
    case 0x5a: UnimplementedInstruction(state: state); break;
    case 0x5b: UnimplementedInstruction(state: state); break;
    case 0x5c: UnimplementedInstruction(state: state); break;
    case 0x5d: UnimplementedInstruction(state: state); break;
    case 0x5e:
        let adr: Int = Int((UInt16(state.h) << 8) | UInt16(state.l));
        state.e = state.memory[adr];
        break;
    case 0x5f: UnimplementedInstruction(state: state); break;
    case 0x60: UnimplementedInstruction(state: state); break;
    case 0x61: UnimplementedInstruction(state: state); break;
    case 0x62: UnimplementedInstruction(state: state); break;
    case 0x63: UnimplementedInstruction(state: state); break;
    case 0x64: UnimplementedInstruction(state: state); break;
    case 0x65: UnimplementedInstruction(state: state); break;
    case 0x66:
        let adr: Int = Int((UInt16(state.h) << 8) | UInt16(state.l));
        state.h = state.memory[adr];
        break;
    case 0x67: UnimplementedInstruction(state: state); break;
    case 0x68: UnimplementedInstruction(state: state); break;
    case 0x69: UnimplementedInstruction(state: state); break;
    case 0x6a: UnimplementedInstruction(state: state); break;
    case 0x6b: UnimplementedInstruction(state: state); break;
    case 0x6c: UnimplementedInstruction(state: state); break;
    case 0x6d: UnimplementedInstruction(state: state); break;
    case 0x6e: UnimplementedInstruction(state: state); break;
    case 0x6f:
        state.l = state.a;
        break;
    case 0x70: UnimplementedInstruction(state: state); break;
    case 0x71: UnimplementedInstruction(state: state); break;
    case 0x72: UnimplementedInstruction(state: state); break;
    case 0x73: UnimplementedInstruction(state: state); break;
    case 0x74: UnimplementedInstruction(state: state); break;
    case 0x75: UnimplementedInstruction(state: state); break;
    case 0x76: UnimplementedInstruction(state: state); break;
    case 0x77:
        let adr: Int = Int((UInt16(state.h) << 8) | UInt16(state.l)); 
        state.memory[adr] = state.a;
        break;
    case 0x78: UnimplementedInstruction(state: state); break;
    case 0x79: UnimplementedInstruction(state: state); break;
    case 0x7a:
        state.a = state.d;
        break;
    case 0x7b:
        state.a = state.e;
        break;
    case 0x7c:
        state.a = state.h;
        break;
    case 0x7d: UnimplementedInstruction(state: state); break;
    case 0x7e:
        let adr: Int = Int((UInt16(state.h) << 8) | UInt16(state.l));
        state.a = state.memory[adr];
        break;
    case 0x7f: UnimplementedInstruction(state: state); break;
    case 0x80: UnimplementedInstruction(state: state); break;
    case 0x81: UnimplementedInstruction(state: state); break;
    case 0x82: UnimplementedInstruction(state: state); break;
    case 0x83: UnimplementedInstruction(state: state); break;
    case 0x84: UnimplementedInstruction(state: state); break;
    case 0x85: UnimplementedInstruction(state: state); break;
    case 0x86: UnimplementedInstruction(state: state); break;
    case 0x87: UnimplementedInstruction(state: state); break;
    case 0x88: UnimplementedInstruction(state: state); break;
    case 0x89: UnimplementedInstruction(state: state); break;
    case 0x8a: UnimplementedInstruction(state: state); break;
    case 0x8b: UnimplementedInstruction(state: state); break;
    case 0x8c: UnimplementedInstruction(state: state); break;
    case 0x8d: UnimplementedInstruction(state: state); break;
    case 0x8e: UnimplementedInstruction(state: state); break;
    case 0x8f: UnimplementedInstruction(state: state); break;
    case 0x90: UnimplementedInstruction(state: state); break;
    case 0x91: UnimplementedInstruction(state: state); break;
    case 0x92: UnimplementedInstruction(state: state); break;
    case 0x93: UnimplementedInstruction(state: state); break;
    case 0x94: UnimplementedInstruction(state: state); break;
    case 0x95: UnimplementedInstruction(state: state); break;
    case 0x96: UnimplementedInstruction(state: state); break;
    case 0x97: UnimplementedInstruction(state: state); break;
    case 0x98: UnimplementedInstruction(state: state); break;
    case 0x99: UnimplementedInstruction(state: state); break;
    case 0x9a: UnimplementedInstruction(state: state); break;
    case 0x9b: UnimplementedInstruction(state: state); break;
    case 0x9c: UnimplementedInstruction(state: state); break;
    case 0x9d: UnimplementedInstruction(state: state); break;
    case 0x9e: UnimplementedInstruction(state: state); break;
    case 0x9f: UnimplementedInstruction(state: state); break;
    case 0xa0: UnimplementedInstruction(state: state); break;
    case 0xa1: UnimplementedInstruction(state: state); break;
    case 0xa2: UnimplementedInstruction(state: state); break;
    case 0xa3: UnimplementedInstruction(state: state); break;
    case 0xa4: UnimplementedInstruction(state: state); break;
    case 0xa5: UnimplementedInstruction(state: state); break;
    case 0xa6: UnimplementedInstruction(state: state); break;
    case 0xa7:
        state.a = state.a & state.a;
        LogicFlagsA(state: state);
        break;
    case 0xa8: UnimplementedInstruction(state: state); break;
    case 0xa9: UnimplementedInstruction(state: state); break;
    case 0xaa: UnimplementedInstruction(state: state); break;
    case 0xab: UnimplementedInstruction(state: state); break;
    case 0xac: UnimplementedInstruction(state: state); break;
    case 0xad: UnimplementedInstruction(state: state); break;
    case 0xae: UnimplementedInstruction(state: state); break;
    case 0xaf:
        state.a = state.a ^ state.a;
        LogicFlagsA(state: state);
        break;
    case 0xb0: UnimplementedInstruction(state: state); break;
    case 0xb1: UnimplementedInstruction(state: state); break;
    case 0xb2: UnimplementedInstruction(state: state); break;
    case 0xb3: UnimplementedInstruction(state: state); break;
    case 0xb4: UnimplementedInstruction(state: state); break;
    case 0xb5: UnimplementedInstruction(state: state); break;
    case 0xb6: UnimplementedInstruction(state: state); break;
    case 0xb7: UnimplementedInstruction(state: state); break;
    case 0xb8: UnimplementedInstruction(state: state); break;
    case 0xb9: UnimplementedInstruction(state: state); break;
    case 0xba: UnimplementedInstruction(state: state); break;
    case 0xbb: UnimplementedInstruction(state: state); break;
    case 0xbc: UnimplementedInstruction(state: state); break;
    case 0xbd: UnimplementedInstruction(state: state); break;
    case 0xbe: UnimplementedInstruction(state: state); break;
    case 0xbf: UnimplementedInstruction(state: state); break;
    case 0xc0: UnimplementedInstruction(state: state); break;
    case 0xc1:
        state.c = state.memory[Int(state.sp)];
        state.b = state.memory[Int(state.sp)+1];
        state.sp += 2;
        break;
    case 0xc2:
        if (state.cc.z == 0) {
            state.pc = (UInt16(opcode[2]) << 8) | UInt16(opcode[1]);
        } else {
            state.incrementPC(amount: 2)
        }
        break;
    case 0xc3:
        state.pc = (UInt16(opcode[2]) << 8) | UInt16(opcode[1]);
        break;
    case 0xc4: UnimplementedInstruction(state: state); break;
    case 0xc5:
        state.memory[Int(state.sp)-2] = state.c;
        state.memory[Int(state.sp)-1] = state.b;
        state.sp -= 2;
        break;
    case 0xc6:
        let answer: UInt16 = UInt16(state.a) + UInt16(opcode[1]);
        ModifyFlags(state: state, answer: answer);
        state.a = UInt8(answer & 0xff);
        break;
    case 0xc7: UnimplementedInstruction(state: state); break;
    case 0xc8: UnimplementedInstruction(state: state); break;
    case 0xc9:
        state.pc = UInt16(state.memory[Int(state.sp)]) | (UInt16(state.memory[Int(state.sp+1)]) << 8);
        state.sp += 2;
        break;
    case 0xca: UnimplementedInstruction(state: state); break;
    case 0xcb: UnimplementedInstruction(state: state); break;
    case 0xcc: UnimplementedInstruction(state: state); break;
    case 0xcd:
        let ret: UInt16 = state.pc+2;
        state.memory[Int(state.sp)-1] = UInt8((ret >> 8) & 0xff);
        state.memory[Int(state.sp)-2] = UInt8(ret & 0xff);
        state.sp = state.sp - 2;
        state.pc = (UInt16(opcode[2]) << 8) | UInt16(opcode[1]);
        break;
    case 0xce: UnimplementedInstruction(state: state); break;
    case 0xcf: UnimplementedInstruction(state: state); break;
    case 0xd0: UnimplementedInstruction(state: state); break;
    case 0xd1:
        state.e = state.memory[Int(state.sp)];
        state.d = state.memory[Int(state.sp+1)];
        state.sp += 2;
        break;
    case 0xd2: UnimplementedInstruction(state: state); break;
    case 0xd3:
        state.incrementPC(amount: 1);
        break;
    case 0xd4: UnimplementedInstruction(state: state); break;
    case 0xd5:
        state.memory[Int(state.sp)-2] = state.e;
        state.memory[Int(state.sp)-1] = state.d;
        state.sp -= 2;
        break;
    case 0xd6: UnimplementedInstruction(state: state); break;
    case 0xd7: UnimplementedInstruction(state: state); break;
    case 0xd8: UnimplementedInstruction(state: state); break;
    case 0xd9: UnimplementedInstruction(state: state); break;
    case 0xda: UnimplementedInstruction(state: state); break;
    case 0xdb: UnimplementedInstruction(state: state); break;
    case 0xdc: UnimplementedInstruction(state: state); break;
    case 0xdd: UnimplementedInstruction(state: state); break;
    case 0xde: UnimplementedInstruction(state: state); break;
    case 0xdf: UnimplementedInstruction(state: state); break;
    case 0xe0: UnimplementedInstruction(state: state); break;
    case 0xe1:
        state.l = state.memory[Int(state.sp)];
        state.h = state.memory[Int(state.sp)+1];
        state.sp += 2;
        break;
    case 0xe2: UnimplementedInstruction(state: state); break;
    case 0xe3: UnimplementedInstruction(state: state); break;
    case 0xe4: UnimplementedInstruction(state: state); break;
    case 0xe5:
        state.memory[Int(state.sp)-2] = state.l;
        state.memory[Int(state.sp)-1] = state.h;
        state.sp -= 2;
        break;
    case 0xe6:
        state.a = state.a & opcode[1];
        LogicFlagsA(state: state);
        state.incrementPC(amount: 1);
        break;
    case 0xe7: UnimplementedInstruction(state: state); break;
    case 0xe8: UnimplementedInstruction(state: state); break;
    case 0xe9: UnimplementedInstruction(state: state); break;
    case 0xea: UnimplementedInstruction(state: state); break;
    case 0xeb:
        let tmpH: UInt8 = state.h;
        let tmpL: UInt8 = state.l;
        state.h = state.d;
        state.l = state.e;
        state.d = tmpH;
        state.e = tmpL;
        break;
    case 0xec: UnimplementedInstruction(state: state); break;
    case 0xed: UnimplementedInstruction(state: state); break;
    case 0xee: UnimplementedInstruction(state: state); break;
    case 0xef: UnimplementedInstruction(state: state); break;
    case 0xf0: UnimplementedInstruction(state: state); break;
    case 0xf1:
        state.a = state.memory[Int(state.sp)+1];
        let psw: UInt8 = state.memory[Int(state.sp)];
        state.cc.z = (0x01 == (psw & 0x01)) ? 1 : 0;
        state.cc.s = (0x02 == (psw & 0x02)) ? 1 : 0;
        state.cc.p = (0x04 == (psw & 0x04)) ? 1 : 0;
        state.cc.cy = (0x08 == (psw & 0x08)) ? 1 : 0;
        state.cc.ac = (0x10 == (psw & 0x10)) ? 1 : 0;
        state.sp += 2;
        break;
    case 0xf2: UnimplementedInstruction(state: state); break;
    case 0xf3: UnimplementedInstruction(state: state); break;
    case 0xf4: UnimplementedInstruction(state: state); break;
    case 0xf5:
        state.memory[Int(state.sp)-1] = state.a;
        let psw: UInt8 = (state.cc.z | (state.cc.s << 1) | (state.cc.p << 2) | (state.cc.cy << 3) | (state.cc.ac << 4));
        state.memory[Int(state.sp)-2] = psw;
        state.sp -= 2;
        break;
    case 0xf6: UnimplementedInstruction(state: state); break;
    case 0xf7: UnimplementedInstruction(state: state); break;
    case 0xf8: UnimplementedInstruction(state: state); break;
    case 0xf9: UnimplementedInstruction(state: state); break;
    case 0xfa: UnimplementedInstruction(state: state); break;
    case 0xfb: 
        state.int_enabled = 1;
        break;
    case 0xfc: UnimplementedInstruction(state: state); break;
    case 0xfd: UnimplementedInstruction(state: state); break;
    case 0xfe:
        let x: UInt8 = (state.a  < opcode[1]) ? 0xff - (opcode[1] - state.a) : state.a - opcode[1];
        state.cc.z = (x == 0) ? 1 : 0;
        state.cc.s = (0x80 == (x & 0x80)) ? 1 : 0;
        state.cc.p = CheckPFlag8(answer: x);
        state.cc.cy = (state.a < opcode[1]) ? 1 : 0;
        state.incrementPC(amount: 1);
        break;
    case 0xff: UnimplementedInstruction(state: state); break;
    default:
        break;
    }
}

func Disassemble8080Op(codebuffer: [UInt8], pc: Int) -> Int {
    let code: Array<UInt8> = Array(codebuffer[pc...]);
    var opbytes: Int = 1;
    print(String(format: "%04x ", pc), terminator: "");
    switch code[0] {
    case 0x00: print("NOP", terminator: ""); break;
    case 0x01: print(String(format: "LXI    B,#$%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0x02: print("STAX   B", terminator: ""); break;
    case 0x03: print("INX    B", terminator: ""); break;
    case 0x04: print("INR    B", terminator: ""); break;
    case 0x05: print("DCR    B", terminator: ""); break;
    case 0x06: print(String(format: "MVI    B,#$%02x", code[1]), terminator: ""); opbytes=2; break;
    case 0x07: print("RLC", terminator: ""); break;
    case 0x08: print("NOP", terminator: ""); break;
    case 0x09: print("DAD    B", terminator: ""); break;
    case 0x0a: print("LDAX   B", terminator: ""); break;
    case 0x0b: print("DCX    B", terminator: ""); break;
    case 0x0c: print("INR    C", terminator: ""); break;
    case 0x0d: print("DCR    C", terminator: ""); break;
    case 0x0e: print(String(format: "MVI    C,#$%02x", code[1]), terminator: ""); opbytes=2; break;
    case 0x0f: print("RRC", terminator: ""); break;
    case 0x10: print("NOP", terminator: ""); break;
    case 0x11: print(String(format: "LXI    D,#$%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0x12: print("STAX   D", terminator: ""); break;
    case 0x13: print("INX    D", terminator: ""); break;
    case 0x14: print("INR    D", terminator: ""); break;
    case 0x15: print("DCR    D", terminator: ""); break;
    case 0x16: print(String(format: "MVI    D,#$%02x", code[1]), terminator: ""); opbytes=2; break;
    case 0x17: print("RAL", terminator: ""); break;
    case 0x18: print("NOP", terminator: ""); break;
    case 0x19: print("DAD    D", terminator: ""); break;
    case 0x1a: print("LDAX   D", terminator: ""); break;
    case 0x1b: print("DCX    D", terminator: ""); break;
    case 0x1c: print("INR    E", terminator: ""); break;
    case 0x1d: print("DCR    E", terminator: ""); break;
    case 0x1e: print(String(format: "MVI    E,#$%02x", code[1]), terminator: ""); opbytes=2; break;
    case 0x1f: print("RAR", terminator: ""); break;
    case 0x20: print("RIM", terminator: ""); break;
    case 0x21: print(String(format: "LXI    H,#$%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0x22: print(String(format: "SHLD   $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0x23: print("INX    H", terminator: ""); break;
    case 0x24: print("INR    H", terminator: ""); break;
    case 0x25: print("DCR    H", terminator: ""); break;
    case 0x26: print(String(format: "MVI    H,#$%02x", code[1]), terminator: ""); opbytes=2; break;
    case 0x27: print("DAA", terminator: ""); break;
    case 0x28: print("NOP", terminator: ""); break;
    case 0x29: print("DAD    H", terminator: ""); break;
    case 0x2a: print(String(format: "LHLD   $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0x2b: print("DCX    H", terminator: ""); break;
    case 0x2c: print("INR    L", terminator: ""); break;
    case 0x2d: print("DCR    L", terminator: ""); break;
    case 0x2e: print(String(format: "MVI    L,#$%02x", code[1]), terminator: ""); opbytes=2; break;
    case 0x2f: print("CMA", terminator: ""); break;
    case 0x30: print("SIM", terminator: ""); break;
    case 0x31: print(String(format: "LXI    SP,#$%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0x32: print(String(format: "STA    $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0x33: print("INX    SP", terminator: ""); break;
    case 0x34: print("INR    M", terminator: ""); break;
    case 0x35: print("DCR    M", terminator: ""); break;
    case 0x36: print(String(format: "MVI    M,#$%02x", code[1]), terminator: ""); opbytes=2; break;
    case 0x37: print("STC", terminator: ""); break;
    case 0x38: print("NOP", terminator: ""); break;
    case 0x39: print("DAD    SP", terminator: ""); break;
    case 0x3a: print(String(format: "LDA    $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0x3b: print("DCX    SP", terminator: ""); break;
    case 0x3c: print("INR    A", terminator: ""); break;
    case 0x3d: print("DCR    A", terminator: ""); break;
    case 0x3e: print(String(format: "MVI    A,#$%02x", code[1]), terminator: ""); opbytes=2; break;
    case 0x3f: print("CMC", terminator: ""); break;
    case 0x40: print("MOV    B,B", terminator: ""); break;
    case 0x41: print("MOV    B,C", terminator: ""); break;
    case 0x42: print("MOV    B,D", terminator: ""); break;
    case 0x43: print("MOV    B,E", terminator: ""); break;
    case 0x44: print("MOV    B,H", terminator: ""); break;
    case 0x45: print("MOV    B,L", terminator: ""); break;
    case 0x46: print("MOV    B,M", terminator: ""); break;
    case 0x47: print("MOV    B,A", terminator: ""); break;
    case 0x48: print("MOV    C,B", terminator: ""); break;
    case 0x49: print("MOV    C,C", terminator: ""); break;
    case 0x4a: print("MOV    C,D", terminator: ""); break;
    case 0x4b: print("MOV    C,E", terminator: ""); break;
    case 0x4c: print("MOV    C,H", terminator: ""); break;
    case 0x4d: print("MOV    C,L", terminator: ""); break;
    case 0x4e: print("MOV    C,M", terminator: ""); break;
    case 0x4f: print("MOV    C,A", terminator: ""); break;
    case 0x50: print("MOV    D,B", terminator: ""); break;
    case 0x51: print("MOV    D,C", terminator: ""); break;
    case 0x52: print("MOV    D,D", terminator: ""); break;
    case 0x53: print("MOV    D,E", terminator: ""); break;
    case 0x54: print("MOV    D,H", terminator: ""); break;
    case 0x55: print("MOV    D,L", terminator: ""); break;
    case 0x56: print("MOV    D,M", terminator: ""); break;
    case 0x57: print("MOV    D,A", terminator: ""); break;
    case 0x58: print("MOV    E,B", terminator: ""); break;
    case 0x59: print("MOV    E,C", terminator: ""); break;
    case 0x5a: print("MOV    E,D", terminator: ""); break;
    case 0x5b: print("MOV    E,E", terminator: ""); break;
    case 0x5c: print("MOV    E,H", terminator: ""); break;
    case 0x5d: print("MOV    E,L", terminator: ""); break;
    case 0x5e: print("MOV    E,M", terminator: ""); break;
    case 0x5f: print("MOV    E,A", terminator: ""); break;
    case 0x60: print("MOV    H,B", terminator: ""); break;
    case 0x61: print("MOV    H,C", terminator: ""); break;
    case 0x62: print("MOV    H,D", terminator: ""); break;
    case 0x63: print("MOV    H,E", terminator: ""); break;
    case 0x64: print("MOV    H,H", terminator: ""); break;
    case 0x65: print("MOV    H,L", terminator: ""); break;
    case 0x66: print("MOV    H,M", terminator: ""); break;
    case 0x67: print("MOV    H,A", terminator: ""); break;
    case 0x68: print("MOV    L,B", terminator: ""); break;
    case 0x69: print("MOV    L,C", terminator: ""); break;
    case 0x6a: print("MOV    L,D", terminator: ""); break;
    case 0x6b: print("MOV    L,E", terminator: ""); break;
    case 0x6c: print("MOV    L,H", terminator: ""); break;
    case 0x6d: print("MOV    L,L", terminator: ""); break;
    case 0x6e: print("MOV    L,M", terminator: ""); break;
    case 0x6f: print("MOV    L,A", terminator: ""); break;
    case 0x70: print("MOV    M,B", terminator: ""); break;
    case 0x71: print("MOV    M,C", terminator: ""); break;
    case 0x72: print("MOV    M,D", terminator: ""); break;
    case 0x73: print("MOV    M,E", terminator: ""); break;
    case 0x74: print("MOV    M,H", terminator: ""); break;
    case 0x75: print("MOV    M,L", terminator: ""); break;
    case 0x76: print("HLT", terminator: ""); break;
    case 0x77: print("MOV    M,A", terminator: ""); break;
    case 0x78: print("MOV    A,B", terminator: ""); break;
    case 0x79: print("MOV    A,C", terminator: ""); break;
    case 0x7a: print("MOV    A,D", terminator: ""); break;
    case 0x7b: print("MOV    A,E", terminator: ""); break;
    case 0x7c: print("MOV    A,H", terminator: ""); break;
    case 0x7d: print("MOV    A,L", terminator: ""); break;
    case 0x7e: print("MOV    A,M", terminator: ""); break;
    case 0x7f: print("MOV    A,A", terminator: ""); break;
    case 0x80: print("ADD    B", terminator: ""); break;
    case 0x81: print("ADD    C", terminator: ""); break;
    case 0x82: print("ADD    D", terminator: ""); break;
    case 0x83: print("ADD    E", terminator: ""); break;
    case 0x84: print("ADD    H", terminator: ""); break;
    case 0x85: print("ADD    L", terminator: ""); break;
    case 0x86: print("ADD    M", terminator: ""); break;
    case 0x87: print("ADD    A", terminator: ""); break;
    case 0x88: print("ADC    B", terminator: ""); break;
    case 0x89: print("ADC    C", terminator: ""); break;
    case 0x8a: print("ADC    D", terminator: ""); break;
    case 0x8b: print("ADC    E", terminator: ""); break;
    case 0x8c: print("ADC    H", terminator: ""); break;
    case 0x8d: print("ADC    L", terminator: ""); break;
    case 0x8e: print("ADC    M", terminator: ""); break;
    case 0x8f: print("ADC    A", terminator: ""); break;
    case 0x90: print("SUB    B", terminator: ""); break;
    case 0x91: print("SUB    C", terminator: ""); break;
    case 0x92: print("SUB    D", terminator: ""); break;
    case 0x93: print("SUB    E", terminator: ""); break;
    case 0x94: print("SUB    H", terminator: ""); break;
    case 0x95: print("SUB    L", terminator: ""); break;
    case 0x96: print("SUB    M", terminator: ""); break;
    case 0x97: print("SUB    A", terminator: ""); break;
    case 0x98: print("SBB    B", terminator: ""); break;
    case 0x99: print("SBB    C", terminator: ""); break;
    case 0x9a: print("SBB    D", terminator: ""); break;
    case 0x9b: print("SBB    E", terminator: ""); break;
    case 0x9c: print("SBB    H", terminator: ""); break;
    case 0x9d: print("SBB    L", terminator: ""); break;
    case 0x9e: print("SBB    M", terminator: ""); break;
    case 0x9f: print("SBB    A", terminator: ""); break;
    case 0xa0: print("ANA    B", terminator: ""); break;
    case 0xa1: print("ANA    C", terminator: ""); break;
    case 0xa2: print("ANA    D", terminator: ""); break;
    case 0xa3: print("ANA    E", terminator: ""); break;
    case 0xa4: print("ANA    H", terminator: ""); break;
    case 0xa5: print("ANA    L", terminator: ""); break;
    case 0xa6: print("ANA    M", terminator: ""); break;
    case 0xa7: print("ANA    A", terminator: ""); break;
    case 0xa8: print("XRA    B", terminator: ""); break;
    case 0xa9: print("XRA    C", terminator: ""); break;
    case 0xaa: print("XRA    D", terminator: ""); break;
    case 0xab: print("XRA    E", terminator: ""); break;
    case 0xac: print("XRA    H", terminator: ""); break;
    case 0xad: print("XRA    L", terminator: ""); break;
    case 0xae: print("XRA    M", terminator: ""); break;
    case 0xaf: print("XRA    A", terminator: ""); break;
    case 0xb0: print("ORA    B", terminator: ""); break;
    case 0xb1: print("ORA    C", terminator: ""); break;
    case 0xb2: print("ORA    D", terminator: ""); break;
    case 0xb3: print("ORA    E", terminator: ""); break;
    case 0xb4: print("ORA    H", terminator: ""); break;
    case 0xb5: print("ORA    L", terminator: ""); break;
    case 0xb6: print("ORA    M", terminator: ""); break;
    case 0xb7: print("ORA    A", terminator: ""); break;
    case 0xb8: print("CMP    B", terminator: ""); break;
    case 0xb9: print("CMP    C", terminator: ""); break;
    case 0xba: print("CMP    D", terminator: ""); break;
    case 0xbb: print("CMP    E", terminator: ""); break;
    case 0xbc: print("CMP    H", terminator: ""); break;
    case 0xbd: print("CMP    L", terminator: ""); break;
    case 0xbe: print("CMP    M", terminator: ""); break;
    case 0xbf: print("CMP    A", terminator: ""); break;
    case 0xc0: print("RNZ", terminator: ""); break;
    case 0xc1: print("POP    B", terminator: ""); break;
    case 0xc2: print(String(format: "JNZ    $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0xc3: print(String(format: "JMP    $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0xc4: print(String(format: "CNZ    $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0xc5: print("PUSH   B", terminator: ""); break;
    case 0xc6: print(String(format: "ADI    $%02x", code[1]), terminator: ""); opbytes=2; break;
    case 0xc7: print("RST    0", terminator: ""); break;
    case 0xc8: print("RZ", terminator: ""); break;
    case 0xc9: print("RET", terminator: ""); break;
    case 0xca: print(String(format: "JZ    $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0xcb: print("NOP", terminator: ""); break;
    case 0xcc: print(String(format: "CZ     $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0xcd: print(String(format: "CALL   $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0xce: print(String(format: "ACI    $%02x", code[1]), terminator: ""); opbytes=2; break;
    case 0xcf: print("RST    1", terminator: ""); break;
    case 0xd0: print("RNC", terminator: ""); break;
    case 0xd1: print("POP    D", terminator: ""); break;
    case 0xd2: print(String(format: "JNC    $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0xd3: print(String(format: "OUT    $%02x", code[1]), terminator: ""); opbytes=2; break;
    case 0xd4: print(String(format: "CNC    $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0xd5: print("PUSH   D", terminator: ""); break;
    case 0xd6: print(String(format: "SUI    $%02x", code[1]), terminator: ""); opbytes=2; break;
    case 0xd7: print("RST    2", terminator: ""); break;
    case 0xd8: print("RC", terminator: ""); break;
    case 0xd9: print("NOP", terminator: ""); break;
    case 0xda: print(String(format: "JC     $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0xdb: print(String(format: "IN     $%02x", code[1]), terminator: ""); opbytes=2; break;
    case 0xdc: print(String(format: "CC     $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0xdd: print("NOP", terminator: ""); break;
    case 0xde: print(String(format: "SBI    $%02x", code[1]), terminator: ""); opbytes=2; break;
    case 0xdf: print("RST    3", terminator: ""); break;
    case 0xe0: print("RPO", terminator: ""); break;
    case 0xe1: print("POP    H", terminator: ""); break;
    case 0xe2: print(String(format: "JPO    $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0xe3: print("XTHL", terminator: ""); break;
    case 0xe4: print(String(format: "CPO    $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0xe5: print("PUSH   H", terminator: ""); break;
    case 0xe6: print(String(format: "ANI    $%02x", code[1]), terminator: ""); opbytes=2; break;
    case 0xe7: print("RST    4", terminator: ""); break;
    case 0xe8: print("RPE", terminator: ""); break;
    case 0xe9: print("PCHL", terminator: ""); break;
    case 0xea: print(String(format: "JPE    $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0xeb: print("XCHG", terminator: ""); break;
    case 0xec: print(String(format: "CPE    $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0xed: print("NOP", terminator: ""); break;
    case 0xee: print(String(format: "XRI    $%02x", code[1]), terminator: ""); opbytes=2; break;
    case 0xef: print("RST     5", terminator: ""); break;
    case 0xf0: print("RP", terminator: ""); break;
    case 0xf1: print("POP    PSW", terminator: ""); break;
    case 0xf2: print(String(format: "JP    $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0xf3: print("DI", terminator: ""); break;
    case 0xf4: print(String(format: "CP    $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0xf5: print("PUSH   PSW", terminator: ""); break;
    case 0xf6: print(String(format: "ORI    $%02x", code[1]), terminator: ""); opbytes=2; break;
    case 0xf7: print("RST    6", terminator: ""); break;
    case 0xf8: print("RM", terminator: ""); break;
    case 0xf9: print("SPHL", terminator: ""); break;
    case 0xfa: print(String(format: "JM     $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0xfb: print("EI", terminator: ""); break;
    case 0xfc: print(String(format: "CM     $%02x%02x", code[2], code[1]), terminator: ""); opbytes=3; break;
    case 0xfd: print("NOP", terminator: ""); break;
    case 0xfe: print(String(format: "CPI    $%02x", code[1]), terminator: ""); opbytes=2; break;
    case 0xff: print("RST    7", terminator: ""); break;
    default:
        break;
    }

    print("\n", terminator: "");
    
    return opbytes;
}

func GetHex() -> [UInt8]? {
    let fileUrl: URL = URL(fileURLWithPath: "invaders.concatenated");

    do {
        let rawData: Data = try Data(contentsOf: fileUrl);

        return [UInt8](rawData);
    } catch {
        return nil;
    }
}

var state = State8080();

let hex: [UInt8] = GetHex() ?? [];
for index in 0...hex.count-1 {
    state.memory[index] = hex[index];
}

while (state.pc < state.memory.count) {
    Emulate8080Op(state: state);
}
