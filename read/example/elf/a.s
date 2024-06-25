	.file	"a.c"
	.option nopic
	.attribute arch, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	1
	.globl	add
	.type	add, @function
add:
.LFB0:
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sd	s0,24(sp)
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	mv	a5,a0
	mv	a4,a1
	sw	a5,-20(s0)
	mv	a5,a4
	sw	a5,-24(s0)
	lui	a5,%hi(static_i.0)
	lw	a5,%lo(static_i.0)(a5)
	addiw	a5,a5,1
	sext.w	a4,a5
	lui	a5,%hi(static_i.0)
	sw	a4,%lo(static_i.0)(a5)
	lw	a5,-20(s0)
	mv	a4,a5
	lw	a5,-24(s0)
	addw	a5,a4,a5
	sext.w	a5,a5
	mv	a0,a5
	ld	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE0:
	.size	add, .-add
	.align	1
	.globl	fa
	.type	fa, @function
fa:
.LFB1:
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sd	ra,24(sp)
	sd	s0,16(sp)
	.cfi_offset 1, -8
	.cfi_offset 8, -16
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	lui	a5,%hi(add)
	addi	a5,a5,%lo(add)
	sd	a5,-24(s0)
	ld	a5,-24(s0)
	li	a1,20
	li	a0,10
	jalr	a5
	nop
	mv	a0,a5
	ld	ra,24(sp)
	.cfi_restore 1
	ld	s0,16(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE1:
	.size	fa, .-fa
	.section	.sdata,"aw"
	.align	2
	.type	static_g, @object
	.size	static_g, 4
static_g:
	.word	16
	.data
	.align	3
	.type	static_arr, @object
	.size	static_arr, 12
static_arr:
	.word	17
	.word	18
	.word	19
	.text
	.align	1
	.type	static_f, @function
static_f:
.LFB2:
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sd	ra,24(sp)
	sd	s0,16(sp)
	.cfi_offset 1, -8
	.cfi_offset 8, -16
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	mv	a5,a0
	sw	a5,-20(s0)
	lw	a4,-20(s0)
	lw	a5,-20(s0)
	mv	a1,a4
	mv	a0,a5
	call	add
	mv	a5,a0
	mv	a0,a5
	ld	ra,24(sp)
	.cfi_restore 1
	ld	s0,16(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE2:
	.size	static_f, .-static_f
	.globl	data_1
	.section	.sdata
	.align	2
	.type	data_1, @object
	.size	data_1, 4
data_1:
	.word	11
	.globl	data_2
	.data
	.align	3
	.type	data_2, @object
	.size	data_2, 12
data_2:
	.word	12
	.word	13
	.word	14
	.globl	data_3
	.align	3
	.type	data_3, @object
	.size	data_3, 32
data_3:
	.dword	data_1
	.dword	data_2
	.dword	static_g
	.dword	static_arr
	.globl	bss_1
	.section	.sbss,"aw",@nobits
	.align	2
	.type	bss_1, @object
	.size	bss_1, 4
bss_1:
	.zero	4
	.globl	bss_2
	.bss
	.align	3
	.type	bss_2, @object
	.size	bss_2, 40
bss_2:
	.zero	40
	.globl	str_1
	.section	.rodata
	.align	3
.LC0:
	.string	"wwc :-)"
	.section	.sdata
	.align	3
	.type	str_1, @object
	.size	str_1, 8
str_1:
	.dword	.LC0
	.align	2
	.type	static_i.0, @object
	.size	static_i.0, 4
static_i.0:
	.word	15
	.ident	"GCC: () 13.2.0"
	.section	.note.GNU-stack,"",@progbits
