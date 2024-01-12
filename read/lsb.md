
> LSB Core - Generic 5.0

## ELF

### Special Sections

* .ctors

  This section contains a list of global constructor function pointers.

* .dtors

* .eh_frame
* .eh_frame_hdr

* .got.plt
* .data.rel.ro

## DWARF

### DWARF Exception Header Encoding

The DWARF Exception Header Encoding is used to describe the type of data used in the .eh_frame and .eh_frame_hdr section. The upper 4 bits indicate how the value is to be applied. The lower 4 bits indicate the format of the data.

* DW_EH_PE_omit

## Exception Frames

When using languages that support exceptions, such as C++, additional information must be provided to the runtime environment that describes the call frames that must be unwound during the processing of an exception. This information is contained in the special sections .eh_frame and .eh_framehdr.

> The format of the .eh_frame section is similar in format and purpose to the .de- bug_frame section which is specified in DWARF Debugging Information Format, Version 4. Readers are advised that there are some subtle difference, and care should be taken when comparing the two sections.

### The .eh_frame section

The .eh_frame section shall contain 1 or more Call Frame Information (CFI) records. The number of records present shall be determined by size of the section as contained in the section header. Each CFI record contains a Common Information Entry (CIE) record followed by 1 or more Frame Description Entry (FDE) records.

The Common Information Entry Format:

* Augmentation String

  This value is a NUL terminated string that identifies the augmentation to the CIE or to the FDEs associated with this CIE. A zero length string indicates  that no augmentation data is present.

  * 'z'

    A 'z' may be present as the first character of the string. If present, the Augmentation Data field shall be present. The contents of the Augmentation  Data shall be intepreted according to other characters in the Augmentation String.

  * 'L'

    If present, it  indicates the presence of one argument in the Augmentation Data of the CIE, and a corresponding argument in the Augmentation Data of the FDE. The argument in the Augmentation Data of the CIE is 1-byte and represents the pointer encoding used for the argument in the Augmentation Data of the FDE, which is the address of a language-specific data area (LSDA). The size of the LSDA pointer is specified by the pointer encoding used.

  * 'P'

    If present, it indicates the presence of two arguments in the Augmentation Data of the CIE. The first argument is 1-byte and represents the pointer encoding used for the second argument, which is the address of a personality routine handler. The personality routine is used to handle language and vendor-specific tasks. The system unwind library interface accesses the language-specific exception handling semantics via the pointer to the personality routine. The personality routine does not have an ABI-specific name. The size of the personality routine pointer is specified by the pointer encoding used.

  * 'R'

    If present, The Augmentation Data shall include a 1 byte argument that represents the pointer encoding for the address pointers used in the FDE.

* Augmentation Data Length
* Augmentation Data

The Frame Description Entry Format:

* PC Begin
* PC Range
* Augmentation Length
* Augmentation Data
* Call Frame Instructions

### The .eh_frame_hdr section

The  .eh_frame_hdr  section contains additional information about the  .eh_frame section. A pointer to the start of the .eh_frame data, and optionally, a binary search table of pointers to the .eh_frame records are found in this section.

A binary search table containing fde_count entries. Each entry of the table consist of two encoded values, the initial location, and the address. The entries are sorted in an increasing order by the initial location value.

## Symbol Versioning

## Dynamic Linking

### Program Header

Linux Segment Types:

* PT_GNU_EH_FRAME
* PT_GNU_STACK
* PT_GNU_RELRO

### Dynamic Entries

