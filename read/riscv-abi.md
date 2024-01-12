## ELF

### Code models

#### Medium low code model

```
# Load value from a symbol
lui  a0, %hi(symbol)
lw   a0, %lo(symbol)(a0)

# Store value to a symbol
lui  a0, %hi(symbol)
sw   a1, %lo(symbol)(a0)

# Calculate address
lui  a0, %hi(symbol)
addi a0, a0, %lo(symbol)
```

#### Medium any code model

```
         # Load value from a symbol
.Ltmp0:  auipc a0, %pcrel_hi(symbol)
         lw    a0, %pcrel_lo(.Ltmp0)(a0)
         # Store value to a symbol
.Ltmp1:  auipc a0, %pcrel_hi(symbol)
         sw    a1, %pcrel_lo(.Ltmp1)(a0)
         # Calculate address
.Ltmp2:  auipc a0, %pcrel_hi(symbol)
         addi  a0, a0, %pcrel_lo(.Ltmp2)
```

#### Medium position independent code model

This model is similar to the medium any code model, but uses the global offset table (GOT) for non-local symbol addresses.

```
         # Load value from a local symbol
.Ltmp0:  auipc a0, %pcrel_hi(symbol)
         lw    a0, %pcrel_lo(.Ltmp0)(a0)

         # Store value to a local symbol
.Ltmp1:  auipc a0, %pcrel_hi(symbol)
         sw    a1, %pcrel_lo(.Ltmp1)(a0)

         # Calculate address of a local symbol
.Ltmp2:  auipc a0, %pcrel_hi(symbol)
         addi  a0, a0, %pcrel_lo(.Ltmp2)

         # Calculate address of non-local symbol
.Ltmp3:  auipc  a0, %got_pcrel_hi(symbol)
         l[w|d] a0, a0, %pcrel_lo(.Ltmp3)
```

### File Header

* e_flags

  * EF_RISCV_RVC

    When linking objects which specify EF_RISCV_RVC, the linker is permitted to use RVC instructions such as C.JAL in the linker relaxation process.

  * EF_RISCV_FLOAT_ABI

  * EF_RISCV_RVE

  * EF_RISCV_TSO


### Relocations

R_RISCV_:

* 32

  Both. S + A

* 64

  Both. S + A

* RELATIVE

  Dynamic. B + A. Adjust a link address (A) to its load address (B + A)

* COPY

  Dynamic. Must be in executable; not allowed in shared library

* JUMP_SLOT

  Dynamic. Indicates the symbol associated with a PLT entry

* BRANCH

  Static. S + A - P. 12-bit PC-relative branch offset

* JAL

  S + A - P. 20-bit PC-relative jump offset

* CALL_PLT

  S + A - P. 32-bit PC-relative function call, macros call, tail (PIC)

* GOT_HI20

  G + GOT + A - P. High 20 bits of 32-bit PC-relative GOT access, %got_pcrel_hi(symbol)

* PCREL_HI20, PCREL_LO12_I, PCREL_LO12_S

* HI20, LO12_I, LO12_S

* ...

Variables used in relocation calculation:

* A. Addend field in the relocation entry associated with the symbol

* B. Base address of a shared object loaded into memory

* G. Offset of the symbol into the GOT (Global Offset Table)

* GOT. Address of the GOT (Global Offset Table)

* P. Position of the relocation

* S. Value of the symbol in the symbol table

* V. Value at the position of the relocation

* GP. Value of __global_pointer$ symbol

#### Absolute Addresses

32-bit absolute addresses in position dependent code are loaded with a pair of instructions which have an associated pair of relocations: R_RISCV_HI20 plus R_RISCV_LO12_I or R_RISCV_LO12_S.

```
lui  a0, %hi(symbol)     # R_RISCV_HI20 (symbol)
addi a0, a0, %lo(symbol) # R_RISCV_LO12_I (symbol)
```

#### Global Offset Table

For position independent code in dynamically linked objects, each shared object contains a GOT (Global Offset Table), which contains addresses of global symbols (objects and functions) referred to by the dynamically linked shared object. The GOT in each shared library is filled in by the dynamic linker during program loading, or on the first call to extern functions.

To avoid dynamic relocations within the text segment of position independent code the GOT is used for  indirection.  Instead  of  code  loading  virtual  addresses  directly,  as  can  be  done  in  static  code, addresses are loaded from the GOT. This allows runtime binding to external objects and functions at the expense of a slightly higher runtime overhead for access to extern objects and functions.

The PLT (Program Linkage Table) exists to allow function calls between dynamically linked shared
objects.  Each  dynamic  object  has  its  own  GOT  (Global  Offset  Table)  and  PLT  (Program  Linkage
Table).

The first entry of a shared object PLT is a special entry that calls `_dl_runtime_resolve` to resolve the GOT offset for the called function. The `_dl_runtime_resolve` function in the dynamic loader resolves the GOT offsets lazily on the first call to any function, except when LD_BIND_NOW is set in which case the  GOT  entries  are  populated  by  the  dynamic  linker  before  the  executable  is  started.  Lazy resolution of GOT entries is intended to speed up program loading by deferring symbol resolution to the first time the function is called. The first entry in the PLT occupies two 16 byte entries:

```
1:  auipc  t2, %pcrel_hi(.got.plt)
    sub    t1, t1, t3               # shifted .got.plt offset + hdr size + 12
    l[w|d] t3, %pcrel_lo(1b)(t2)    # _dl_runtime_resolve
    addi   t1, t1, -(hdr size + 12) # shifted .got.plt offset
    addi   t0, t2, %pcrel_lo(1b)    # &.got.plt
    srli   t1, t1, log2(16/PTRSIZE) # .got.plt offset
    l[w|d] t0, PTRSIZE(t0)          # link map
    jr     t3
```

Subsequent function entry stubs in the PLT take up 16 bytes and load a function pointer from the GOT.  On  the  first  call  to  a  function,  the  entry  redirects  to  the  first  PLT  entry  which  calls `_dl_runtime_resolve` and fills in the GOT entry for subsequent calls to the function:

```
1:  auipc   t3, %pcrel_hi(function@.got.plt)
    l[w|d]  t3, %pcrel_lo(1b)(t3)
    jalr    t1, t3
    nop
```

#### Linker Relaxation

## DWARF

### DWARF Register Numbers


