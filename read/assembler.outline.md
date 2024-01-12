```
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

```
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

class MCAsmInfoELF {
  std::vector<MCCFIInstruction> InitialFrameState;

  bool UseIntegratedAssembler;

  bool ParseInlineAsmUsingAsmParser;
};
```

createRISCVMCObjectFileInfo
createRISCVMCInstrInfo
createRISCVMCRegisterInfo
createRISCVAsmBackend
createRISCVMCCodeEmitter
createRISCVMCInstPrinter
createRISCVMCSubtargetInfo

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

