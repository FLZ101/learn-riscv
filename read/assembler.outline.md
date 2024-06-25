```cpp
LLVMInitializeRISCVTargetInfo();
  RegisterTarget<Triple::riscv32, /*HasJIT=*/true> X(
      getTheRISCV32Target(), "riscv32", "32-bit RISC-V", "RISCV");
  RegisterTarget<Triple::riscv64, /*HasJIT=*/true> Y(
      getTheRISCV64Target(), "riscv64", "64-bit RISC-V", "RISCV");

LLVMInitializeRISCVTargetMC();
  for (Target *T : {&getTheRISCV32Target(), &getTheRISCV64Target()}) {
    TargetRegistry::RegisterMCAsmInfo(*T, createRISCVMCAsmInfo);
    TargetRegistry::RegisterMCObjectFileInfo(*T, createRISCVMCObjectFileInfo);
    TargetRegistry::RegisterMCInstrInfo(*T, createRISCVMCInstrInfo);
    TargetRegistry::RegisterMCRegInfo(*T, createRISCVMCRegisterInfo);
    TargetRegistry::RegisterMCAsmBackend(*T, createRISCVAsmBackend);
    TargetRegistry::RegisterMCCodeEmitter(*T, createRISCVMCCodeEmitter);
    TargetRegistry::RegisterMCInstPrinter(*T, createRISCVMCInstPrinter);
    TargetRegistry::RegisterMCSubtargetInfo(*T, createRISCVMCSubtargetInfo);
    TargetRegistry::RegisterELFStreamer(*T, createRISCVELFStreamer);
    TargetRegistry::RegisterObjectTargetStreamer(
        *T, createRISCVObjectTargetStreamer);
    TargetRegistry::RegisterMCInstrAnalysis(*T, createRISCVInstrAnalysis);

    // Register the asm target streamer.
    TargetRegistry::RegisterAsmTargetStreamer(*T, createRISCVAsmTargetStreamer);
    // Register the null target streamer.
    TargetRegistry::RegisterNullTargetStreamer(*T,
                                               createRISCVNullTargetStreamer);
  }

LLVMInitializeRISCVAsmParser();
  RegisterMCAsmParser<RISCVAsmParser> X(getTheRISCV32Target());
  RegisterMCAsmParser<RISCVAsmParser> Y(getTheRISCV64Target());

LLVMInitializeRISCVDisassembler();
  // Register the disassembler for each target.
  TargetRegistry::RegisterMCDisassembler(getTheRISCV32Target(),
                                         createRISCVDisassembler);
  TargetRegistry::RegisterMCDisassembler(getTheRISCV64Target(),
                                         createRISCVDisassembler);
```

```cpp
MCTargetOptions MCOptions = mc::InitMCTargetOptionsFromFlags();

TheTarget = GetTarget(ProgName);

MRI(TheTarget->createMCRegInfo(TripleName))
MAI(TheTarget->createMCAsmInfo(*MRI, TripleName, MCOptions))
STI(TheTarget->createMCSubtargetInfo(TripleName, MCPU, FeaturesStr))

MCContext Ctx(TheTriple, MAI.get(), MRI.get(), STI.get(), &SrcMgr, &MCOptions);

MOFI(TheTarget->createMCObjectFileInfo(Ctx, PIC, LargeCodeModel))

MCII(TheTarget->createMCInstrInfo())

if (FileType == OFT_AssemblyFile)
  IP = TheTarget->createMCInstPrinter(Triple(TripleName), OutputAsmVariant, *MAI, *MCII, *MRI)

  MAB(TheTarget->createMCAsmBackend(*STI, *MRI, MCOptions))

  Str.reset(TheTarget->createAsmStreamer(Ctx, std::move(FOut), /*asmverbose*/ true,
    /*useDwarfDirectory*/ true, IP,
    std::move(CE), std::move(MAB), ShowInst))

else if (FileType == OFT_ObjectFile)

  MCCodeEmitter *CE = TheTarget->createMCCodeEmitter(*MCII, Ctx);
  MCAsmBackend *MAB = TheTarget->createMCAsmBackend(*STI, *MRI, MCOptions);
  Str.reset(TheTarget->createMCObjectStreamer(
    TheTriple, Ctx, std::unique_ptr<MCAsmBackend>(MAB),
    DwoOut ? MAB->createDwoObjectWriter(*OS, DwoOut->os())
            : MAB->createObjectWriter(*OS),
    std::unique_ptr<MCCodeEmitter>(CE), *STI, MCOptions.MCRelaxAll,
    MCOptions.MCIncrementalLinkerCompatible,
    /*DWARFMustBeAtTheEnd*/ false));

  if (NoExecStack)
    Str->initSections(true, *STI);

AssembleInput(ProgName, TheTarget, SrcMgr, Ctx, *Str, *MAI, *STI, *MCII, MCOptions);
```

## Components

### MCContext

### createRISCVMCAsmInfo

```cpp
class RISCVMCAsmInfo : public MCAsmInfoELF;

RISCVMCAsmInfo::RISCVMCAsmInfo(const Triple &TT) {
  CodePointerSize = CalleeSaveStackSlotSize = TT.isArch64Bit() ? 8 : 4;
  CommentString = "#";
  AlignmentIsInBytes = false;
  SupportsDebugInformation = true;
  ExceptionsType = ExceptionHandling::DwarfCFI;
  Data16bitsDirective = "\t.half\t";
  Data32bitsDirective = "\t.word\t";
};

class MCAsmInfoELF : public MCAsmInfo;
class MCAsmInfo {
  std::vector<MCCFIInstruction> InitialFrameState;

  bool UseIntegratedAssembler;

  bool ParseInlineAsmUsingAsmParser;

  /// Returns true if the exception handling method for the platform uses call
  /// frame information to unwind.
  bool usesCFIForEH() const {
    return (ExceptionsType == ExceptionHandling::DwarfCFI ||
            ExceptionsType == ExceptionHandling::ARM || usesWindowsCFI());
  }
};
```

### createRISCVMCObjectFileInfo

```cpp
class RISCVMCObjectFileInfo : public MCObjectFileInfo;

class MCObjectFileInfo {
  /// Section directive for standard text.
  MCSection *TextSection = nullptr;

  /// If exception handling is supported by the target, this is the section the
  /// Language Specific Data Area information is emitted to.
  MCSection *LSDASection = nullptr;

  MCSection *DwarfFrameSection = nullptr;

  MCSection *EHFrameSection = nullptr;
};

void MCObjectFileInfo::initMCObjectFileInfo(MCContext &MCCtx, bool PIC,
                                            bool LargeCodeModel) {
  PositionIndependent = PIC;
  Ctx = &MCCtx;

  Triple TheTriple = Ctx->getTargetTriple();
  switch (Ctx->getObjectFileType()) {
  case MCContext::IsELF:
    initELFMCObjectFileInfo(TheTriple, LargeCodeModel);
    break;
  }
}

void MCObjectFileInfo::initELFMCObjectFileInfo(const Triple &T, bool Large) {
  switch (T.getArch()) {
  default:
    FDECFIEncoding = dwarf::DW_EH_PE_pcrel | dwarf::DW_EH_PE_sdata4;
    break;
  }

  TextSection = Ctx->getELFSection(".text", ELF::SHT_PROGBITS,
                                   ELF::SHF_EXECINSTR | ELF::SHF_ALLOC);

  ReadOnlySection =
      Ctx->getELFSection(".rodata", ELF::SHT_PROGBITS, ELF::SHF_ALLOC);

  LSDASection = Ctx->getELFSection(".gcc_except_table", ELF::SHT_PROGBITS,
                                   ELF::SHF_ALLOC);

  DwarfLineSection = Ctx->getELFSection(".debug_line", DebugSecType, 0);

  DwarfFrameSection = Ctx->getELFSection(".debug_frame", DebugSecType, 0);

  EHFrameSection =
      Ctx->getELFSection(".eh_frame", EHSectionType, EHSectionFlags);
}
```
### createRISCVMCInstrInfo

```cpp
class MCInstrInfo {
  const MCInstrDesc *Desc;          // Raw array to allow static init'n

  const unsigned *InstrNameIndices; // Array for name indices in InstrNameData
  const char *InstrNameData;        // Instruction name string pool

  unsigned NumOpcodes;              // Number of entries in the desc array

  /// Initialize MCInstrInfo, called by TableGen auto-generated routines.
  /// *DO NOT USE*.
  void InitMCInstrInfo(const MCInstrDesc *D, const unsigned *NI, const char *ND,
                       const uint8_t *DF,
                       const ComplexDeprecationPredicate *CDI, unsigned NO) {
    Desc = D;
    InstrNameIndices = NI;
    InstrNameData = ND;
    NumOpcodes = NO;
  }

  /// Return the machine instruction descriptor that corresponds to the
  /// specified instruction opcode.
  const MCInstrDesc &get(unsigned Opcode) const {
    assert(Opcode < NumOpcodes && "Invalid opcode!");
    return Desc[Opcode];
  }

  /// Returns the name for the instructions with the given opcode.
  StringRef getName(unsigned Opcode) const {
    assert(Opcode < NumOpcodes && "Invalid opcode!");
    return StringRef(&InstrNameData[InstrNameIndices[Opcode]]);
  }
};
```

```cpp
// build/lib/Target/RISCV/RISCVGenInstrInfo.inc

extern const MCInstrDesc RISCVInsts[] = {
};

static inline void InitRISCVMCInstrInfo(MCInstrInfo *II) {
  II->InitMCInstrInfo(RISCVInsts, RISCVInstrNameIndices, RISCVInstrNameData, nullptr, nullptr, 13084);
}
```

```cpp
class MCInstrDesc {
  unsigned short Opcode;         // The opcode number
  unsigned short NumOperands;    // Num of args (may be more if variable_ops)
  unsigned char NumDefs;         // Num of args that are definitions
  unsigned char Size;            // Number of bytes in encoding.
  unsigned short SchedClass;     // enum identifying instr sched class
  uint64_t Flags;                // Flags identifying machine instr class
  uint64_t TSFlags;              // Target Specific Flag values
  const MCPhysReg *ImplicitUses; // Registers implicitly read by this instr
  const MCPhysReg *ImplicitDefs; // Registers implicitly defined by this instr
  const MCOperandInfo *OpInfo;   // 'NumOperands' entries about operands

  /// Return true if this instruction can have a variable number of
  /// operands.  In this case, the variable operands will be after the normal
  /// operands but before the implicit definitions and uses (if any are
  /// present).
  bool isVariadic() const { return Flags & (1ULL << MCID::Variadic); }

  /// Return true if this is a pseudo instruction that doesn't
  /// correspond to a real machine instruction.
  bool isPseudo() const { return Flags & (1ULL << MCID::Pseudo); }

  /// Return true if the instruction is a return.
  bool isReturn() const { return Flags & (1ULL << MCID::Return); }

  /// Return true if the instruction is an add instruction.
  bool isAdd() const { return Flags & (1ULL << MCID::Add); }

  /// Returns true if this is a conditional, unconditional, or
  /// indirect branch.  Predicates below can be used to discriminate between
  /// these cases, and the TargetInstrInfo::analyzeBranch method can be used to
  /// get more information.
  bool isBranch() const { return Flags & (1ULL << MCID::Branch); }

  /// Return true if this instruction could possibly read memory.
  /// Instructions with this flag set are not necessarily simple load
  /// instructions, they may load a value and modify it, for example.
  bool mayLoad() const { return Flags & (1ULL << MCID::MayLoad); }

  /// Return the number of bytes in the encoding of this instruction,
  /// or zero if the encoding size cannot be known from the opcode.
  unsigned getSize() const { return Size; }
};
```

### createRISCVMCRegisterInfo

```cpp
class MCRegisterInfo {
  /// DwarfLLVMRegPair - Emitted by tablegen so Dwarf<->LLVM reg mappings can be
  /// performed with a binary search.
  struct DwarfLLVMRegPair {
    unsigned FromReg;
    unsigned ToReg;

    bool operator<(DwarfLLVMRegPair RHS) const { return FromReg < RHS.FromReg; }
  };

  struct SubRegCoveredBits {
    uint16_t Offset;
    uint16_t Size;
  };

  const MCRegisterDesc *Desc;                 // Pointer to the descriptor array
  unsigned NumRegs;                           // Number of entries in the array
  MCRegister RAReg;                           // Return address register
  MCRegister PCReg;                           // Program counter register
  const MCRegisterClass *Classes;             // Pointer to the regclass array
  unsigned NumClasses;                        // Number of entries in the array
  unsigned NumRegUnits;                       // Number of regunits.
  const MCPhysReg (*RegUnitRoots)[2];         // Pointer to regunit root table.
  const MCPhysReg *DiffLists;                 // Pointer to the difflists array
  const LaneBitmask *RegUnitMaskSequences;    // Pointer to lane mask sequences
                                              // for register units.
  const char *RegStrings;                     // Pointer to the string table.
  const char *RegClassStrings;                // Pointer to the class strings.
  const uint16_t *SubRegIndices;              // Pointer to the subreg lookup
                                              // array.
  const SubRegCoveredBits *SubRegIdxRanges;   // Pointer to the subreg covered
                                              // bit ranges array.
  unsigned NumSubRegIndices;                  // Number of subreg indices.
  const uint16_t *RegEncodingTable;           // Pointer to array of register
                                              // encodings.

  unsigned L2DwarfRegsSize;
  unsigned EHL2DwarfRegsSize;
  unsigned Dwarf2LRegsSize;
  unsigned EHDwarf2LRegsSize;
  const DwarfLLVMRegPair *L2DwarfRegs;        // LLVM to Dwarf regs mapping
  const DwarfLLVMRegPair *EHL2DwarfRegs;      // LLVM to Dwarf regs mapping EH
  const DwarfLLVMRegPair *Dwarf2LRegs;        // Dwarf to LLVM regs mapping
  const DwarfLLVMRegPair *EHDwarf2LRegs;      // Dwarf to LLVM regs mapping EH
  DenseMap<MCRegister, int> L2SEHRegs;        // LLVM to SEH regs mapping
  DenseMap<MCRegister, int> L2CVRegs;         // LLVM to CV regs mapping

  /// Initialize MCRegisterInfo, called by TableGen
  /// auto-generated routines. *DO NOT USE*.
  void InitMCRegisterInfo(const MCRegisterDesc *D, unsigned NR, unsigned RA,
                          unsigned PC,
                          const MCRegisterClass *C, unsigned NC,
                          const MCPhysReg (*RURoots)[2],
                          unsigned NRU,
                          const MCPhysReg *DL,
                          const LaneBitmask *RUMS,
                          const char *Strings,
                          const char *ClassStrings,
                          const uint16_t *SubIndices,
                          unsigned NumIndices,
                          const SubRegCoveredBits *SubIdxRanges,
                          const uint16_t *RET) {
    Desc = D;
    NumRegs = NR;
    RAReg = RA;
    PCReg = PC;
    Classes = C;
    DiffLists = DL;
    RegUnitMaskSequences = RUMS;
    RegStrings = Strings;
    RegClassStrings = ClassStrings;
    NumClasses = NC;
    RegUnitRoots = RURoots;
    NumRegUnits = NRU;
    SubRegIndices = SubIndices;
    NumSubRegIndices = NumIndices;
    SubRegIdxRanges = SubIdxRanges;
    RegEncodingTable = RET;
  }
};
```

```cpp
/// MCRegisterDesc - This record contains information about a particular
/// register.  The SubRegs field is a zero terminated array of registers that
/// are sub-registers of the specific register, e.g. AL, AH are sub-registers
/// of AX. The SuperRegs field is a zero terminated array of registers that are
/// super-registers of the specific register, e.g. RAX, EAX, are
/// super-registers of AX.
///
struct MCRegisterDesc {
  uint32_t Name;      // Printable name for the reg (for debugging)
  uint32_t SubRegs;   // Sub-register set, described above
  uint32_t SuperRegs; // Super-register set, described above

  // Offset into MCRI::SubRegIndices of a list of sub-register indices for each
  // sub-register in SubRegs.
  uint32_t SubRegIndices;

  // RegUnits - Points to the list of register units. The low 4 bits holds the
  // Scale, the high bits hold an offset into DiffLists. See MCRegUnitIterator.
  uint32_t RegUnits;

  /// Index into list with lane mask sequences. The sequence contains a lanemask
  /// for every register unit.
  uint16_t RegUnitLaneMasks;
};
```

```cpp
// build/lib/Target/RISCV/RISCVGenRegisterInfo.inc

extern const MCRegisterDesc RISCVRegDesc[] = { // Descriptors
  { 24, 0, 0, 0, 0, 0 },
  { 2061, 8, 8, 2, 103937, 0 },
  { 2052, 8, 8, 2, 103937, 0 },
  { 2049, 8, 8, 2, 103937, 0 },
  { 1384, 8, 8, 2, 103937, 0 },
  { 1679, 8, 8, 2, 103937, 0 },
};

extern const MCRegisterClass RISCVMCRegisterClasses[] = {
  { FPR16, FPR16Bits, 804, 32, sizeof(FPR16Bits), RISCV::FPR16RegClassID, 16, 1, true },
  { AnyReg, AnyRegBits, 1049, 96, sizeof(AnyRegBits), RISCV::AnyRegRegClassID, 32, 1, false },
};

extern const MCPhysReg RISCVRegUnitRoots[][2] = {
  { RISCV::FFLAGS },
  { RISCV::FRM },
  { RISCV::VL },
  { RISCV::VLENB },
  { RISCV::VTYPE },
  { RISCV::VXRM },
  { RISCV::VXSAT },
  { RISCV::V0 },
  { RISCV::V1 },
  { RISCV::V2 },
  { RISCV::V3 },
  { RISCV::V4 },
  { RISCV::V5 },
};

extern const uint16_t RISCVSubRegIdxLists[] = {
  /* 0 */ 2, 1, 0,
  /* 3 */ 2, 3, 0,
  /* 6 */ 4, 5, 0,
  /* 9 */ 12, 4, 5, 13, 6, 7, 0,
};

static inline void InitRISCVMCRegisterInfo(MCRegisterInfo *RI, unsigned RA, unsigned DwarfFlavour = 0, unsigned EHFlavour = 0, unsigned PC = 0) {
  RI->InitMCRegisterInfo(RISCVRegDesc, 457, RA, PC, RISCVMCRegisterClasses, 76, RISCVRegUnitRoots, 103, RISCVRegDiffLists, RISCVLaneMaskLists, RISCVRegStrings, RISCVRegClassStrings, RISCVSubRegIdxLists, 52,
  RISCVSubRegIdxRanges, RISCVRegEncodingTable);

  RI->mapDwarfRegsToLLVMRegs(RISCVDwarfFlavour0Dwarf2L, RISCVDwarfFlavour0Dwarf2LSize, false);
}
```

### createRISCVMCSubtargetInfo

```cpp
/// Used to provide key value pairs for feature and CPU bit flags.
struct SubtargetFeatureKV {
  const char *Key;                      ///< K-V key string
  const char *Desc;                     ///< Help descriptor
  unsigned Value;                       ///< K-V integer value
  FeatureBitArray Implies;              ///< K-V bit mask
};

/// Used to provide key value pairs for feature and CPU bit flags.
struct SubtargetSubTypeKV {
  const char *Key;                      ///< K-V key string
  FeatureBitArray Implies;              ///< K-V bit mask
  FeatureBitArray TuneImplies;          ///< K-V bit mask
  const MCSchedModel *SchedModel;
};
```
```cpp
// build/lib/Target/RISCV/RISCVGenSubtargetInfo.inc

// Sorted (by key) array of values for CPU features.
extern const llvm::SubtargetFeatureKV RISCVFeatureKV[] = {
  { "64bit", "Implements RV64", RISCV::Feature64Bit, { { { 0x0ULL, 0x0ULL, 0x0ULL, 0x0ULL, } } } },
  { "a", "'A' (Atomic Instructions)", RISCV::FeatureStdExtA, { { { 0x0ULL, 0x0ULL, 0x0ULL, 0x0ULL, } } } },
  { "c", "'C' (Compressed Instructions)", RISCV::FeatureStdExtC, { { { 0x0ULL, 0x0ULL, 0x0ULL, 0x0ULL, } } } },
};

static const llvm::MCSchedModel SiFive7Model = {
  2, // IssueWidth
  0, // MicroOpBufferSize
  MCSchedModel::DefaultLoopMicroOpBufferSize,
  3, // LoadLatency
  MCSchedModel::DefaultHighLatency,
  3, // MispredictPenalty
  false, // PostRAScheduler
  false, // CompleteModel
  2, // Processor ID
  SiFive7ModelProcResources,
  SiFive7ModelSchedClasses,
  6,
  599,
  nullptr, // No Itinerary
  nullptr // No extra processor descriptor
};

// Sorted (by key) array of values for CPU subtype.
extern const llvm::SubtargetSubTypeKV RISCVSubTypeKV[] = {
 { "generic", { { { 0x0ULL, 0x0ULL, 0x0ULL, 0x0ULL, } } }, { { { 0x0ULL, 0x0ULL, 0x0ULL, 0x0ULL, } } }, &NoSchedModel },
 { "generic-rv32", { { { 0x0ULL, 0x0ULL, 0x0ULL, 0x0ULL, } } }, { { { 0x0ULL, 0x0ULL, 0x0ULL, 0x0ULL, } } }, &NoSchedModel },
 { "generic-rv64", { { { 0x1ULL, 0x0ULL, 0x0ULL, 0x0ULL, } } }, { { { 0x0ULL, 0x0ULL, 0x0ULL, 0x0ULL, } } }, &NoSchedModel },
 { "rocket-rv32", { { { 0x0ULL, 0x0ULL, 0x0ULL, 0x0ULL, } } }, { { { 0x0ULL, 0x0ULL, 0x0ULL, 0x0ULL, } } }, &RocketModel },
 { "rocket-rv64", { { { 0x1ULL, 0x0ULL, 0x0ULL, 0x0ULL, } } }, { { { 0x0ULL, 0x0ULL, 0x0ULL, 0x0ULL, } } }, &RocketModel },
 { "sifive-7-rv32", { { { 0x0ULL, 0x0ULL, 0x0ULL, 0x0ULL, } } }, { { { 0x0ULL, 0x100000000ULL, 0x0ULL, 0x0ULL, } } }, &SiFive7Model },
 { "sifive-7-rv64", { { { 0x1ULL, 0x0ULL, 0x0ULL, 0x0ULL, } } }, { { { 0x0ULL, 0x100000000ULL, 0x0ULL, 0x0ULL, } } }, &SiFive7Model },
};

/// Identify one of the processor resource kinds consumed by a particular
/// scheduling class for the specified number of cycles.
struct MCWriteProcResEntry {
  uint16_t ProcResourceIdx;
  uint16_t Cycles;
};

/// Specify the latency in cpu cycles for a particular scheduling class and def
/// index. -1 indicates an invalid latency. Heuristics would typically consider
/// an instruction with invalid latency to have infinite latency.  Also identify
/// the WriteResources of this def. When the operand expands to a sequence of
/// writes, this ID is the last write in the sequence.
struct MCWriteLatencyEntry {
  int16_t Cycles;
  uint16_t WriteResourceID;
};

/// Specify the number of cycles allowed after instruction issue before a
/// particular use operand reads its registers. This effectively reduces the
/// write's latency. Here we allow negative cycles for corner cases where
/// latency increases. This rule only applies when the entry's WriteResource
/// matches the write's WriteResource.
///
/// MCReadAdvanceEntries are sorted first by operand index (UseIdx), then by
/// WriteResourceIdx.
struct MCReadAdvanceEntry {
  unsigned UseIdx;
  unsigned WriteResourceID;
  int Cycles;
};

// Data tables for the new per-operand machine model.

// {ProcResourceIdx, Cycles}
extern const llvm::MCWriteProcResEntry RISCVWriteProcResTable[] = {
  { 0,  0}, // Invalid
  { 1,  1}, // #1
  { 2,  1}, // #2
  { 7,  1}, // #3
  { 5, 33}, // #4
  { 5, 34}, // #5
  { 3,  1}, // #6
  { 4, 20}, // #7
};

// {Cycles, WriteResourceID}
extern const llvm::MCWriteLatencyEntry RISCVWriteLatencyTable[] = {
  { 0,  0}, // Invalid
  { 1,  0}, // #1 WriteIALU_WriteIALU32_WriteJmp_WriteCSR_WriteFST64_WriteFST32_WriteJal_WriteJalr_WriteJmpReg_WriteNop_WriteSTD_WriteShiftImm_WriteSTW_WriteSTB_WriteAtomicSTD_WriteAtomicSTW_WriteSTH_WriteShiftReg_WriteShiftImm32_WriteShiftReg32
  { 1,  0}, // #2 WriteJalr
  { 2,  0}, // #3 WriteAtomicD_WriteAtomicW_WriteFLD64_WriteFLD32_WriteLDD_WriteLDW_WriteFClass64_WriteFClass32_WriteFCvtI64ToF64_WriteFCvtF32ToF64_WriteFCvtI32ToF64_WriteFCvtF64ToI64_WriteFCvtF32ToI64_WriteFCvtF64ToF32_WriteFCvtI64ToF32_WriteFCvtI32ToF32_WriteFCvtF64ToI32_WriteFCvtF32ToI32_WriteFCmp64_WriteFCmp32_WriteFMovI64ToF64_WriteFMovI32ToF32_WriteFMovF64ToI64_WriteFMovF32ToI32_WriteAtomicLDD_WriteAtomicLDW_WriteLDWU
  {33,  0}, // #4 WriteIDiv
  {34,  0}, // #5 WriteIDiv32
};

// {UseIdx, WriteResourceID, Cycles}
extern const llvm::MCReadAdvanceEntry RISCVReadAdvanceTable[] = {
  {0,  0,  0}, // Invalid
  {0,  0,  0}, // #1
  {1,  0,  0}, // #2
  {0,  0,  0}, // #3
  {1,  0,  0}, // #4
  {2,  0,  0} // #5
}; // RISCVReadAdvanceTable

struct RISCVGenMCSubtargetInfo : public MCSubtargetInfo {
}

static inline MCSubtargetInfo *createRISCVMCSubtargetInfoImpl(const Triple &TT, StringRef CPU, StringRef TuneCPU, StringRef FS) {
  return new RISCVGenMCSubtargetInfo(TT, CPU, TuneCPU, FS, RISCVFeatureKV, RISCVSubTypeKV,
                      RISCVWriteProcResTable, RISCVWriteLatencyTable, RISCVReadAdvanceTable,
                      nullptr, nullptr, nullptr);
}
```

```cpp
class MCSubtargetInfo {
  Triple TargetTriple;
  std::string CPU; // CPU being targeted.
  std::string TuneCPU; // CPU being tuned for.
  ArrayRef<SubtargetFeatureKV> ProcFeatures;  // Processor feature list
  ArrayRef<SubtargetSubTypeKV> ProcDesc;  // Processor descriptions

  // Scheduler machine model
  const MCWriteProcResEntry *WriteProcResTable;
  const MCWriteLatencyEntry *WriteLatencyTable;
  const MCReadAdvanceEntry *ReadAdvanceTable;
  const MCSchedModel *CPUSchedModel;

  const InstrStage *Stages;            // Instruction itinerary stages
  const unsigned *OperandCycles;       // Itinerary operand cycles
  const unsigned *ForwardingPaths;
  FeatureBitset FeatureBits;           // Feature bits for current CPU + FS
  std::string FeatureString;           // Feature string
};

MCSubtargetInfo::MCSubtargetInfo(const Triple &TT, StringRef C, StringRef TC,
                                 StringRef FS, ArrayRef<SubtargetFeatureKV> PF,
                                 ArrayRef<SubtargetSubTypeKV> PD,
                                 const MCWriteProcResEntry *WPR,
                                 const MCWriteLatencyEntry *WL,
                                 const MCReadAdvanceEntry *RA,
                                 const InstrStage *IS, const unsigned *OC,
                                 const unsigned *FP)
    : TargetTriple(TT), CPU(std::string(C)), TuneCPU(std::string(TC)),
      ProcFeatures(PF), ProcDesc(PD), WriteProcResTable(WPR),
      WriteLatencyTable(WL), ReadAdvanceTable(RA), Stages(IS),
      OperandCycles(OC), ForwardingPaths(FP) {
  InitMCProcessorInfo(CPU, TuneCPU, FS);
}

void MCSubtargetInfo::InitMCProcessorInfo(StringRef CPU, StringRef TuneCPU,
                                          StringRef FS) {
  FeatureBits = getFeatures(CPU, TuneCPU, FS, ProcDesc, ProcFeatures);
  FeatureString = std::string(FS);

  if (!TuneCPU.empty())
    CPUSchedModel = &getSchedModelForCPU(TuneCPU);
  else
    CPUSchedModel = &MCSchedModel::GetDefaultSchedModel();
}
```

### createRISCVAsmBackend

```cpp
class RISCVAsmBackend : public MCAsmBackend {
  const MCSubtargetInfo &STI;
  uint8_t OSABI;
  bool Is64Bit;
  bool ForceRelocs = false;
  const MCTargetOptions &TargetOptions;

public:
  RISCVAsmBackend(const MCSubtargetInfo &STI, uint8_t OSABI, bool Is64Bit,
                  const MCTargetOptions &Options)
      : MCAsmBackend(support::little), STI(STI), OSABI(OSABI), Is64Bit(Is64Bit),
        TargetOptions(Options) {
    RISCVFeatures::validate(STI.getTargetTriple(), STI.getFeatureBits());
  }
}
```

createRISCVMCCodeEmitter
createRISCVMCInstPrinter

createRISCVELFStreamer
createRISCVObjectTargetStreamer
createRISCVInstrAnalysis
createRISCVAsmTargetStreamer
createRISCVNullTargetStreamer

RISCVAsmParser

createRISCVDisassembler

## AssembleInput

```
```
