struct Foo {
  int i;
  Foo(int i) : i(i) {}
};

__attribute__((noinline)) int g(int *x) {
  *x *= 2;
  if (*x > 10)
    throw Foo(5);
  return 100;
}

__attribute__((noinline)) int f(int *x) {
  ++*x;
  try {
    return g(x);
  } catch (Foo &f) {
    return f.i;
  }
}

int main() {
  int x = 3;
  return f(&x);
}

/*

000000ac 000000000000001c 00000000 CIE
  Version:               1
  Augmentation:          "zPLR"
  Code alignment factor: 1
  Data alignment factor: -8
  Return address column: 16
  Augmentation data:     03 50 25 40 00 03 1b
  DW_CFA_def_cfa: r7 (rsp) ofs 8
  DW_CFA_offset: r16 (rip) at cfa-8
  DW_CFA_nop
  DW_CFA_nop

Augmentation:
  P personality routine 0x00402550
  L LSDA

------

0000000000402550 <__gxx_personality_v0>:
  402550:	f3 0f 1e fa          	endbr64
  402554:	41 57                	push   %r15
  402556:	41 56                	push   %r14
  402558:	41 55                	push   %r13

------

000000cc 0000000000000024 00000024 FDE cie=000000ac pc=0000000000401774..00000000004017d0
  Augmentation data:     b0 fd 40 00
  DW_CFA_advance_loc: 1 to 0000000000401775
  DW_CFA_def_cfa_offset: 16
  DW_CFA_offset: r6 (rbp) at cfa-16
  DW_CFA_advance_loc: 3 to 0000000000401778
  DW_CFA_def_cfa_register: r6 (rbp)
  DW_CFA_advance_loc: 5 to 000000000040177d
  DW_CFA_offset: r3 (rbx) at cfa-24
  DW_CFA_advance_loc1: 82 to 00000000004017cf
  DW_CFA_def_cfa: r7 (rsp) ofs 8
  DW_CFA_nop
  DW_CFA_nop
  DW_CFA_nop

Augmentation:
  LSDA 0x0040fdb0

------

	.globl	_Z1fPi
	.type	_Z1fPi, @function
_Z1fPi:
.LFB4:
	.loc 1 13 41
	.cfi_startproc
	.cfi_personality 0x3,__gxx_personality_v0
	.cfi_lsda 0x3,.LLSDA4
	pushq	%rbp	#
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16

------

	.section	.gcc_except_table,"a",@progbits
	.align 4
.LLSDA4:
	.byte	0xff
	.byte	0x3
	.uleb128 .LLSDATT4-.LLSDATTD4
.LLSDATTD4:
	.byte	0x1
	.uleb128 .LLSDACSE4-.LLSDACSB4
.LLSDACSB4:
	.uleb128 .LEHB0-.LFB4
	.uleb128 .LEHE0-.LEHB0
	.uleb128 .L9-.LFB4
	.uleb128 0x1
	.uleb128 .LEHB1-.LFB4
	.uleb128 .LEHE1-.LEHB1
	.uleb128 0
	.uleb128 0
.LLSDACSE4:
	.byte	0x1
	.byte	0
	.align 4
	.long	_ZTI3Foo
.LLSDATT4:

*/
