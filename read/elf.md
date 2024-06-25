
## system v abi 4.1

There are three main types of object files.

* A relocatable file
* An executable ile
* A shared object file

An ELF header resides at the beginning and holds a ‘‘road map’’ describing the ﬁle’s organization.

Sections hold the bulk of object ﬁle information for the linking view: instructions, data, symbol table, relocation information, and so on.

A program header table, if present, tells the system how to create a process image. Files used to build a process image (execute a program) must have a program header table; relocatable ﬁles do not need one.

A section header table contains information describing the ﬁle’s sections. Every section has an entry in the table; each entry gives information such as the section name, the section size, and so on.  Files used during linking must have a section header table; other object ﬁles may or may not have one.

### ELF Header

* e_ident
  * `e_ident[EI_CLASS]`
    * 0 - ELFCLASSNON
    * 1 - ELFCLASS32
    * 2 - ELFCLASS64
  * `e_ident[EI_DATA]`
    * 0 - ELFDATANONE
    * 1 - ELFDATA2LSB

      Encoding ELFDATA2LSB speciﬁes 2’s complement values, with the least signiﬁcant byte occupying the lowest address.
    * 2 - ELFDATA2MSB

      Encoding ELFDATA2MSB speciﬁes 2’s complement values, with the most signiﬁcant byte occupying the lowest address.
* e_type
  * ET_NONE
  * ET_REL
  * ET_EXEC
  * ET_DYN
  * ET_CORE
  * ET_LOPROC
  * ET_HIPROC
* e_machine
  * EM_NONE
  * EM_386
* e_version
* e_entry
* e_phoff

  This member holds the program header table’s ﬁle offset in bytes.
* e_shoff

  This member holds the section header table’s ﬁle offset in bytes.
* e_flags
* e_ehsize

  This member holds the ELF header’s size in bytes.
* e_phentsize

  This member holds the size in bytes of one entry in the ﬁle’s program header table; all entries are the same size.
* e_phnum

  This member holds the number of entries in the program header table.
* e_shentsize
* e_shnum
* e_shstrndx

  This member holds the section header table index of the entry associated with the section name string table.  If the ﬁle has no section name string table, this member holds the value SHN_UNDEF.

### Sections

Special Section Indexes:

* SHN_UNDEF
* SHN_LORESERVE
* SHN_LOPROC, SHN_HIPROC
* SHN_ABS

  symbols deﬁned relative to section number SHN_ABS have absolute values and are not affected by relocation.
* SHN_COMMON

  Symbols deﬁned relative to this section are common symbols, such as FORTRAN COMMON or unallocated C external variables.
* SHN_HIRESERVE

A section header has the following structure:

```c
typedef struct {
	Elf32_Word	sh_name;
	Elf32_Word	sh_type;
	Elf32_Word	sh_flags;
	Elf32_Addr	sh_addr;
	Elf32_Off	sh_offset;
	Elf32_Word	sh_size;
	Elf32_Word	sh_link;
	Elf32_Word	sh_info;
	Elf32_Word	sh_addralign;
	Elf32_Word	sh_entsize;
} Elf32_Shdr;
```

* sh_name
* sh_type
  * SHT_NULL
  * SHT_PROGBITS

    The section holds information deﬁned by the program, whose format and meaning are determined solely by the program.
  * SHT_SYMTAB, SHT_DYNSYM

    These sections hold a symbol table. Typically, SHT_SYMTAB provides symbols for link editing, though it may also be used for dynamic linking.  As a complete symbol table, it may contain many symbols unnecessary for dynamic linking.  Conse- quently, an object ﬁle may also contain a SHT_DYNSYM section, which holds a minimal set of dynamic linking symbols, to save space.
  * SHT_STRTAB

    The section holds a string table.
  * SHT_RELA

    The section holds relocation entries with explicit addends, such as type Elf32_Rela for the 32-bit class of object ﬁles.
  * SHT_HASH

    The section holds a symbol hash table. All objects participating in dynamic linking must contain a symbol hash table.
  * SHT_DYNAMIC

    The section holds information for dynamic linking.
  * SHT_NOTE

    The section holds information that marks the ﬁle in some way.
  * SHT_NOBITS

    A section of this type occupies no space in the ﬁle but otherwise resembles SHT_PROGBITS.  Although this section contains no bytes, the sh_offset member contains the conceptual ﬁle offset.
  * SHT_REL

    The section holds relocation entries without explicit addends,such as type Elf32_Rel for the 32-bit class of object ﬁles.
  * SHT_SHLIB
  * SHT_LOPROC
  * SHT_HIPROC
  * SHT_LOUSER
  * SHT_HIUSER

* sh_flags
  * SHF_WRITE

    The section contains data that should be writable during process execution.
  * SHF_ALLOC

    The section occupies memory during process execution.
  * SHF_EXECINSTR

    The section contains executable machine instructions.
  * SHF_MASKPROC

    All bits included in this mask are reserved for processorspeciﬁc semantics.
* sh_addr

  If the section will appear in the memory image of a process, this member gives the address at which the section’s ﬁrst byte should reside.
* sh_offset

  This member’s value gives the byte offset from the beginning of the ﬁle to the ﬁrst byte in the section.
* sh_size
* sh_link, sh_info
  * SHT_DYNAMIC

    sh_link: string table

  * SHT_HASH

    sh_link: symbol table

  * SHT_REL, SHT_RELA

    sh_link: symbol table

    sh_info: the section to which the relocation applies

  * SHT_SYMTAB, SHT_DYNSYM

    sh_link: symbol table

    sh_info: one greater than the symbol table index of the last local (STB_LOCAL) symbol

* sh_addralign
* sh_entsize

  Some sections hold a table of ﬁxed-size entries, such as a symbol table.  For such a section, this member gives the size in bytes of each entry.

### String Table

### Symbol Table

Index 0 both designates the ﬁrst entry in the table and serves as the undeﬁned symbol index.

A symbol table entry has the following format.

```c
typedef struct {
	Elf32_Word	st_name;
	Elf32_Addr	st_value;
	Elf32_Word	st_size;
	unsigned char	st_info;
	unsigned char	st_other;
	Elf32_Half	st_shndx;
} Elf32_Sym;
```

* st_name
  If the value is non-zero, it represents a string table index that gives the symbol name.  Otherwise, the symbol table entry has no name.
* st_value
* st_size
* st_info

  ```c
  #define ELF32_ST_BIND(i) ((i)>>4)
  #define ELF32_ST_TYPE(i) ((i)&0xf)
  #define ELF32_ST_INFO(b,t) (((b)<<4)+((t)&0xf))
  ```

* st_other
* st_shndx
  Every symbol table entry is "deﬁned" in relation to some section; this member holds the relevant section header table index.

A symbol’s binding determines the linkage visibility and behavior.

* STB_LOCAL
  Local symbols are not visible outside the object ﬁle containing their deﬁnition.  Local symbols of the same name may exist in multiple ﬁles without interfering with each other.
* STB_GLOBAL
  Global symbols are visible to all object ﬁles being combined.  One ﬁle’s deﬁnition of a global symbol will satisfy another ﬁle’s undeﬁned reference to the same global symbol.
* STB_WEAK
  Weak symbols resemble global symbols, but their deﬁnitions have lower precedence.

When the link editor combines several relocatable object ﬁles, it does not allow multiple deﬁnitions of STB_GLOBAL symbols with the same name.  On the other hand, if a deﬁned global symbol exists, the appearance of a weak symbol with the same name will not cause an error. The link editor honors the global deﬁnition and ignores the weak ones. Similarly, if a common symbol exists (that is, a symbol whose st_shndx ﬁeld holds SHN_COMMON), the appearance of a weak symbol with the same name will not cause an error. The link editor honors the common deﬁnition and ignores the weak ones.

When the link editor searches archive libraries, it extracts archive members that contain deﬁnitions of undefined global symbols. The member’s deﬁnition may be either a global or a weak symbol.  The link editor does not extract archive members to resolve undeﬁned weak symbols. Unresolved weak symbols have a zero value.

In each symbol table, all symbols with STB_LOCAL binding precede the weak and global symbols.

A symbol’s type provides a general classiﬁcation for the associated entity.

* STT_NONE
* STT_OBJECT

  The symbol is associated with a data object, such as a variable, an array, and so on.
* STT_FUNC

  The symbol is associated with a function or other executable code.
* STT_SECTION

  The symbol is associated with a section.
* STT_FILE

  Conventionally, the symbol’s name gives the name of the source ﬁle associated with the object ﬁle.

Symbol table entries for different object ﬁle types have slightly different interpretations for the st_value member.

* In relocatable ﬁles, st_value holds alignment constraints for a symbol whose section index is SHN_COMMON.
* In relocatable ﬁles, st_value holds a section offset for a deﬁned symbol. That is, st_value is an offset from the beginning of the section that st_shndx identiﬁes.
* In executable and shared object ﬁles, st_value holds a virtual address.

### Relocation

```c
typedef struct {
  Elf32_Addr r_offset;
  Elf32_Word r_info;
} Elf32_Rel;

typedef struct {
  Elf32_Addr r_offset;
  Elf32_Word r_info;
  Elf32_Sword r_addend;
};
```

* r_offset

  This member gives the location at which to apply the relocation action.  For a relocatable ﬁle, the value is the byte offset from the beginning of the section to the storage unit affected by the relocation. For an executable ﬁle or a shared object, the value is the virtual address of the storage unit affected by the relocation.

* r_info

  This member gives both the symbol table index with respect to which the relocation must be made, and the type of relocation to apply.

  ```c
  #define ELF32_R_SYN(i) ((i)>>8)
  #define ELF32_R_TYPE(i) ((unsigned char)(i))
  ```

* r_addend

  This member speciﬁes a constant addend used to compute the value to be stored into the relocatable ﬁeld.

Elf32_Rela entries contain an explicit addend. Entries of type Elf32_Rel store an implicit addend in the location to be modiﬁed.

### Program Header

```c
typedef struct {
  uint32_t   p_type;
  Elf32_Off  p_offset;
  Elf32_Addr p_vaddr;
  Elf32_Addr p_paddr;
  uint32_t   p_filesz;
  uint32_t   p_memsz;
  uint32_t   p_flags;
  uint32_t   p_align;
} Elf32_Phdr;
```

* p_type

  * PT_NULL
  * PT_LOAD

    Loadable segment entries in the program header table appear in ascending order, sorted on the p_vaddr member.

  * PT_DYNAMIC

    The array element speciﬁes dynamic linking information.

  * PT_INTERP

    The array element speciﬁes the location and size of a null- terminated path name to invoke as an interpreter.  This segment type is meaningful only for executable ﬁles (though it may occur for shared objects); it may not occur more than once in a ﬁle.  If it is present, it must precede any loadable segment entry.

  * PT_NOTE

    The array element speciﬁes the location and size of auxiliary information.

  * PT_SHLIB
  * PT_PHDR

    The array element, if present, speciﬁes the location and size of the program header table itself, both in the ﬁle and in the memory image of the program.  This segment type may not occur more than once in a ﬁle.  Moreover, it may occur only if the program header table is part of the memory image of the program.  If it is present, it must precede any loadable segment entry.

* p_offset

  This member gives the offset from the beginning of the ﬁle at which the ﬁrst byte of the segment resides.

* p_vaddr

  This member gives the virtual address at which the ﬁrst byte of the segment resides in memory.

* p_paddr
* p_filesz

  This member gives the number of bytes in the ﬁle image of the segment; it may be zero.

* p_memsz

  This member gives the number of bytes in the memory image of the segment; it may be zero.

* p_flags

  * PF_X
  * PF_W
  * PF_R

* p_align

The difference between the virtual address of any segment in memory and the corresponding virtual address in the ﬁle is thus a single constant value for any one executable or shared object in a given process.  This difference is the **base address**.  One use of the base address is to relocate the memory image of the program during dynamic linking.

An object ﬁle segment comprises one or more sections, though this fact is tran- sparent to the program header.  Whether the ﬁle segment holds one or many sections also is immaterial to program loading.

### Dynamic Linking

An executable ﬁle that participates in dynamic linking shall have one PT_INTERP program header element. During the function exec, the system retrieves a path name from the PT_INTERP segment and creates the initial process image from the interpreter ﬁle’s segments.  That is, instead of using the original executable ﬁle’s segment images, the system composes a memory image for the interpreter.  It then is the interpreter’s responsibility to receive control from the system and provide an environment for the application program.

An interpreter may be either a shared object or an executable ﬁle.

* A shared object (the normal case) is loaded as position-independent, with addresses that may vary from one process to another; the system creates its segments in the dynamic segment area used by the function mmap and related services. Consequently, a shared object interpreter typically will not conﬂict with the original executable ﬁle’s original segment addresses.

* An executable ﬁle is loaded at ﬁxed addresses; the system creates its segments using the virtual addresses from the program header table.  Consequently, an executable ﬁle interpreter’s virtual addresses may collide with the ﬁrst executable ﬁle; the interpreter is responsible for resolving conﬂicts.

When building an executable ﬁle that uses dynamic linking, the link editor adds a program header element of type PT_INTERP to an executable ﬁle, telling the system to invoke the dynamic linker as the program interpreter.

Exec and the dynamic linker cooperate to create the process image for the program, which entails the following actions:

* Adding the executable ﬁle’s memory segments to the process image;
* Adding shared object memory segments to the process image;
* Performing relocations for the executable ﬁle and its shared objects;
* Closing the ﬁle descriptor that was used to read the executable ﬁle, if one was given to the dynamic linker;
* Transferring control to the program, making it look as if the program had received control directly from the function exec

The link editor also constructs various data that assist the dynamic linker for executable and shared object ﬁles.

* A .dynamic section with type SHT_DYNAMIC holds various data. The structure residing at the beginning of the section holds the addresses of other dynamic linking information.
* The .hash section with type SHT_HASH holds a symbol hash table.
* The .got and .plt sections with type SHT_PROGBITS hold two separate tables: the global offset table and the procedure linkage table.

The dynamic linker relocates the memory image, updating absolute addresses before the application gains control. Although the absolute address values would be correct if the library were loaded at the addresses speciﬁed in the program header table, this normally is not the case.

If the process environment contains a variable named LD_BIND_NOW with a non-null value, the dynamic linker processes all relocation before transferring control to the program.  For example, all the following environment entries would specify this behavior.

The dynamic linker is permitted to evaluate procedure linkage table entries lazily, thus avoiding symbol resolution and relocation overhead for functions that are not called.

#### Dynamic Section

If an object ﬁle participates in dynamic linking, its program header table will have an element of type PT_DYNAMIC. This ‘‘segment’’ contains the .dynamic section. A special symbol, _DYNAMIC, labels the section, which contains an array of the following structures.

```c
typedef struct {
    Elf32_Sword    d_tag;
    union {
        Elf32_Word d_val;
        Elf32_Addr d_ptr;
    } d_un;
} Elf32_Dyn;
extern Elf32_Dyn _DYNAMIC[];
```

For each object with this type, d_tag controls the interpretation of d_un.

* DT_NULL
* DT_NEEDED

  This element holds the string table offset of a null-terminated string, giving the name of a needed library.  The offset is an index into the table recorded in the DT_STRTAB entry.
* DT_PLTRELSZ

  This element holds the total size, in bytes, of the relocation entries associated with the procedure linkage table.
* DT_PLT_GOT

  This element holds an address associated with the procedure linkage table and/or the global offset table.
* DT_HASH

  This element holds the address of the symbol hash table.
* DT_STRTAB

  This element holds the address of the string table.
* DT_SYMTAB

  This element holds the address of the symbol table.
* DT_RELA

  This element holds the address of a relocation table.
* DT_RELASZ

  This element holds the total size, in bytes, of the DT_RELA relocation table.
* DT_RELAENT

  This element holds the size, in bytes, of the DT_RELA relocation entry.

* DT_STRSZ

  This element holds the size, in bytes, of the string table.

* DT_SYMENT

  This element holds the size, in bytes, of a symbol table entry.

* DT_INIT

  This element holds the address of the initialization function.
* DT_FINI

  This element holds the address of the termination function.

* DT_SONAME

  This element holds the string table offset of a null-terminated string, giving the name of the shared object.

* DT_RPATH

* DT_SYMBOLIC

  This element’s presence in a shared object library alters the dynamic linker’s symbol resolution algorithm for references within the library.  Instead of starting a symbol search with the executable ﬁle, the dynamic linker starts from the shared object itself.  If the shared object fails to supply the referenced symbol, the dynamic linker then searches the executable ﬁle and other shared objects as usual.

* DT_REL
* DT_RELSZ
* DT_RELENT
* DT_PLTREL

  This member speciﬁes the type of relocation entry to which the procedure linkage table refers. The d_val member holds DT_REL or DT_RELA, as appropriate.  All relocations in a procedure linkage table must use the same relocation.

* DT_TEXTREL

  This member’s absence signiﬁes that no relocation entry should cause a modiﬁcation to a non-writable segment, as speciﬁed by the segment permissions in the program header table.  If this member is present, one or more relocation entries might request modiﬁcations to a non-writable segment, and the dynamic linker can prepare accordingly.

* DT_JMPREL

  If present, this entries’ d_ptr member holds the address of relocation entries associated solely with the procedure linkage table. Separating these relocation entries lets the dynamic linker ignore them during process initialization, if lazy binding is enabled.  If this entry is present, the related entries of types DT_PLTRELSZ and D T_PLTREL must also be present.

* DT_BIND_NOW

  If present in a shared object or executable, this entry instructs the dynamic linker to process all relocations for the object containing this entry before transferring control to the program.

#### Shared Object Dependencies

When the link editor processes an archive library, it extracts library members and copies them into the output object ﬁle.  These statically linked services are avail- able during execution without involving the dynamic linker.  Shared objects also provide services, and the dynamic linker must attach the proper shared object ﬁles to the process image for execution.

When the dynamic linker creates the memory segments for an object ﬁle, the dependencies (recorded in DT_NEEDED entries of the dynamic structure) tell what shared objects are needed to supply the program’s services.  By repeatedly con- necting referenced shared objects and their dependencies, the dynamic linker builds a complete process image.  When resolving symbolic references, the dynamic linker examines the symbol tables with a breadth-ﬁrst search.  That is, it ﬁrst looks at the symbol table of the executable program itself, then at the symbol tables of the DT_NEEDED entries (in order), then at the second level DT_NEEDED entries, and so on.  Shared object ﬁles must be readable by the process; other permissions are not required.

#### Hash Table

A hash table of Elf32_Word objects supports symbol table access.

#### Initialization and Termination Functions

After the dynamic linker has built the process image and performed the relocations, each shared object gets the opportunity to execute some initialization code. All shared object initializations happen before the executable ﬁle gains control.

Before the initialization code for any object A is called, the initialization code for any other objects that object A depends on are called.

Shared objects may have termination functions, which are executed with the function `atexit` mechanism after the base process begins its termination sequence.  The order in which the dynamic linker calls termination functions is the exact reverse order of their corresponding initialization functions.  If a shared object has a termination function, but no initialization function, the termination function will execute in the order it would have as if the shared object’s initialization function was present.  The dynamic linker ensures that it will not execute any initialization or termination functions more than once.

Shared objects designate their initialization and termination functions through the DT_INIT and DT_FINI entries in the dynamic structure. Typically, the code for these functions resides in the .init and .fini sections.

The dynamic linker is not responsible for calling the executable ﬁle’s .init section or registering the executable ﬁle’s .fini section with the function atexit. Termination functions speciﬁed by users via the atexit mechanism must be executed before any termination functions of shared objects.

## System V ABI Update

> https://www.sco.com/developers/gabi/latest/contents.html

### ELF Header

```c
typedef struct {
  unsigned char   e_ident[EI_NIDENT];
  Elf64_Half      e_type;
  Elf64_Half      e_machine;
  Elf64_Word      e_version;
  Elf64_Addr      e_entry;
  Elf64_Off       e_phoff;
  Elf64_Off       e_shoff;
  Elf64_Word      e_flags;
  Elf64_Half      e_ehsize;
  Elf64_Half      e_phentsize;
  Elf64_Half      e_phnum;
  Elf64_Half      e_shentsize;
  Elf64_Half      e_shnum;
  Elf64_Half      e_shstrndx;
} Elf64_Ehdr;
```

* e_machine

  * EM_RISCV
  * EM_CUDA
  * EM_AARCH64
  * EM_X86_64
  * EM_386

### Sections

```c
typedef struct {
	Elf64_Word	sh_name;
	Elf64_Word	sh_type;
	Elf64_Xword	sh_flags;
	Elf64_Addr	sh_addr;
	Elf64_Off	sh_offset;
	Elf64_Xword	sh_size;
	Elf64_Word	sh_link;
	Elf64_Word	sh_info;
	Elf64_Xword	sh_addralign;
	Elf64_Xword	sh_entsize;
} Elf64_Shdr;
```

### Symbol Table

```c
typedef struct {
	Elf64_Word	st_name;
	unsigned char	st_info;
	unsigned char	st_other;
	Elf64_Half	st_shndx;
	Elf64_Addr	st_value;
	Elf64_Xword	st_size;
} Elf64_Sym;
```

### Relocation

```c
typedef struct {
	Elf64_Addr	r_offset;
	Elf64_Xword	r_info;
} Elf64_Rel;

typedef struct {
	Elf64_Addr	r_offset;
	Elf64_Xword	r_info;
	Elf64_Sxword	r_addend;
} Elf64_Rela;
```

### Program Header

```c
typedef struct {
	Elf64_Word	p_type;
	Elf64_Word	p_flags;
	Elf64_Off	p_offset;
	Elf64_Addr	p_vaddr;
	Elf64_Addr	p_paddr;
	Elf64_Xword	p_filesz;
	Elf64_Xword	p_memsz;
	Elf64_Xword	p_align;
} Elf64_Phdr;
```

### Dynamic Linking

#### Dynamic Section

```c
typedef struct {
	Elf64_Sxword	d_tag;
   	union {
   		Elf64_Xword	d_val;
   		Elf64_Addr	d_ptr;
	} d_un;
} Elf64_Dyn;

extern Elf64_Dyn	_DYNAMIC[];
```
