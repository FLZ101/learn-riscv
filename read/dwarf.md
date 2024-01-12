## Call Frame Information

Debuggers often need to be able to view and modify the state of any subroutine activation that is on the call stack. An activation consists of:

* A code location that is within the subroutine. This location is either the place where the program stopped when the debugger got control (e.g. a breakpoint), or is a place where a subroutine made a call or was interrupted by an asynchronous event (e.g. a signal).

* An area of memory that is allocated on a stack called a “call frame.” The call frame is identified by an address on the stack. We refer to this address as the Canonical Frame Address or CFA. Typically, the CFA is defined to be the value of the stack pointer at the call site in the previous frame (which may be different from its value on entry to the current frame).

* A set of registers that are in use by the subroutine at the code location.

DWARF supports virtual unwinding by defining an architecture independent basis for recording how procedures save and restore registers during their lifetimes.

Abstractly, this mechanism describes a very large table that has the following structure:

```
LOC CFA R0 R1 ... RN
L0
L1
...
LN
```

The first column indicates an address for every location that contains code in a program. (In shared objects, this is an object-relative offset.) The remaining columns contain virtual unwinding rules that are associated with the indicated location.

The CFA column defines the rule which computes the Canonical Frame Address value; it may be either a register and a signed offset that are added together, or a DWARF expression that is evaluated.

The remaining columns are labeled by register number. This includes some registers that have special designation on some architectures such as the PC and the stack pointer register. (The actual mapping of registers for a particular architecture is defined by the augmenter.) The register columns contain rules that describe whether a given register has been saved and the rule to find the value for the register in the previous frame.

The register rules are:

* undefined
  A register that has this rule has no recoverable value in the previous frame. (By convention, it is not preserved by a callee.)
* same value
  This register has not been modified from the previous frame. (By convention, it is preserved by the callee, but the callee has not modified it.)
* offset(N)
  The previous value of this register is saved at the address CFA+N where CFA is the current CFA value and N is a signed offset.
* val_offset(N)
  The previous value of this register is the value CFA+N where CFA is the current CFA value and N is a signed offset.
* register(R)
  The previous value of this register is stored in another register numbered R.
* expression(E)
  The previous value of this register is located at the address produced by executing the DWARF expression E.
* val_expression(E)
  The previous value of this register is the value produced by executing the DWARF expression E.
* architectural
  The rule is defined externally to this specification by the augmenter.

The virtual unwind information is encoded in a self-contained section called .debug_frame.

If the range of code addresses for a function is not contiguous, there may be multiple CIEs and FDEs corresponding to the parts of that function.

A Common Information Entry holds information that is shared among many Frame Description Entries. There is at least one CIE in every non-empty .debug_frame section. A CIE contains the following fields, in order:

* length
* CIE_id
* version
* augmentation
  A null-terminated UTF-8 string that identifies the augmentation to this CIE or to the FDEs that use it.
* address_size
* segment_size
* code_alignment_factor
* data_alignment_factor
* return_address_register
  An unsigned LEB128 constant that indicates which column in the rule table represents the return address of the function. Note that this column might not correspond to an actual machine register.
* initial_instructions
  A sequence of rules that are interpreted to create the initial setting of each column in the table.

An FDE contains the following fields, in order:
* length
* CIE_pointer
  A constant offset into the .debug_frame section that denotes the CIE that is associated with this FDE.
* initial_location
  The address of the first location associated with this table entry. If the segment_size field of this FDE's CIE is non-zero, the initial location is preceded by a segment selector of the given length.
* address_range
  The number of bytes of program instructions described by this entry.
* instructions
  A sequence of table defining instructions that are described below.

Each call frame instruction is defined to take 0 or more operands. Some of the operands may be encoded as part of the opcode.

Row Creation Instructions:

* DW_CFA_set_loc
  The required action is to create a new table row using the specified address as the location.
* DW_CFA_advance_loc
  The required action is to create a new table row with a location value that is computed by taking the current entry’s location value and adding the value of `delta * code_alignment_factor`.
* DW_CFA_advance_loc1
* DW_CFA_advance_loc2
* DW_CFA_advance_loc4

CFA Definition Instructions:

* DW_CFA_def_cfa
  The DW_CFA_def_cfa instruction takes two unsigned LEB128 operands representing a register number and a (non-factored) offset. The required action is to define the current CFA rule to use the provided register and offset.
* DW_CFA_def_cfa_sf
  This instruction is identical to DW_CFA_def_cfa except that the second operand is signed and factored. The resulting offset is `factored_offset * data_alignment_factor`.
* DW_CFA_def_cfa_register
  The required action is to define the current CFA rule to use the provided register (but to keep the old offset). This operation is valid only if the current CFA rule is defined to use a register and offset.
* DW_CFA_def_cfa_offset
* DW_CFA_def_cfa_offset_sf
* DW_CFA_def_cfa_expression
  The DW_CFA_def_cfa_expression instruction takes a single operand encoded as a DW_FORM_exprloc value representing a DWARF expression. The required action is to establish that expression as the means by which the current CFA is computed.

Register Rule Instructions:

* DW_CFA_undefined
  The required action is to set the rule for the specified register to “undefined.”
* DW_CFA_same_value
* DW_CFA_offset
  The required action is to change the rule for the register indicated by the register number to be an offset(N) rule where the value of N is `factored_offset * data_alignment_factor`.
* DW_CFA_offset_extended
* DW_CFA_offset_extended_sf
* DW_CFA_val_offset
* DW_CFA_val_offset_sf
* DW_CFA_register
* DW_CFA_expression
  The value of the CFA is pushed on the DWARF evaluation stack prior to execution of the DWARF expression.
* DW_CFA_val_expression
* DW_CFA_restore
  The required action is to change the rule for the indicated register to the rule assigned to it by the initial_instructions in the CIE.
* DW_CFA_restore_extended

Row State Instructions:

* DW_CFA_remember_state
  The required action is to push the set of rules for every register onto an implicit stack.
* DW_CFA_restore_state
  The required action is to pop the set of rules off the implicit stack and place them in the current row.

Padding Instruction:

* DW_CFA_nop
  It is used as padding to make a CIE or FDE an appropriate size.

To determine the virtual unwind rule set for a given location (L1), one searches through the FDE headers looking at the  `initial_location` and `address_range` values to see if L1 is contained in the FDE. If so, then:

1. Initialize a register set by reading the  initial_instructions  field of the associated CIE
2. Read and process the FDE’s instruction sequence until a DW_CFA_advance_loc, DW_CFA_set_loc, or the end of the instruction stream is encountered.
3. If a DW_CFA_advance_loc or DW_CFA_set_loc instruction is encountered, then compute a new location value (L2). If L1 >= L2 then process the instruction and go back to step 2.
4. The end of the instruction stream can be thought of as a DW_CFA_set_loc (initial_location + address_range) instruction. Note that the FDE is ill-formed if L2 is less than L1.

The rules in the register set now apply to location L1.

If a Return Address register is defined in the virtual unwind table, and its rule is undefined (for example, by DW_CFA_undefined), then there is no return address and no call address, and the virtual unwind of stack activations is complete.

