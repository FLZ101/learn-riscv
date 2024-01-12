
> The RISC-V Instruction Set Manual

## RV32I Base Integer Instruction Set

```
XLEN = 32
x0 zero
x1 - x31
pc

R
I
S B
U J

addi
slti sltu
andi ori xori

sllt srli srai

lui
auipc

add sub
slt sltu
and or xor
sll srl sra

nop

jal
jalr

beq bne blt bltu bge bgeu

lw lh lhu lb lbu
sw sh shu sb sbu

fence

hint
```

## RV32E Base Integer Instruction Set

## RV64I Base Integer Instruction Set

```
XLEN = 64

addiw

ld
sd
```

Most integer computational instructions operate on XLEN-bit values. Additional instruction variants are provided to manipulate 32-bit values in RV64I, indicated by a ‘W’ suffi x to the opcode. These “*W” instructions ignore the upper 32 bits of their inputs and always produce 32-bit signed values, i.e. bits XLEN-1 through 31 are equal.

## “M” Standard Extension for Integer Multiplication and Division

```
mul
mulh
mulhu
mulhsu

div
divu
rem
remu
```

## “A” Standard Extension for Atomic Instructions

### RISC-V Assembly Programmer's Manual

* https://github.com/riscv-non-isa/riscv-asm-manual/blob/master/riscv-asm.md

