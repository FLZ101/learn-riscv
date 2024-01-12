
## main

```cpp
static cl::opt<std::string> TripleName("triple");
static cl::opt<std::string> ArchName("arch");
static cl::opt<std::string> MCPU("mcpu");

static cl::list<std::string>
    MAttrs("mattr", cl::CommaSeparated,
           cl::desc("Target specific attributes (-mattr=help for details)"),
           cl::value_desc("a1,+a2,-a3,..."), cl::cat(MCCategory));

static cl::opt<ActionType> Action(
    cl::desc("Action to perform:"), cl::init(AC_Assemble),
    cl::values(clEnumValN(AC_AsLex, "as-lex", "Lex tokens from a .s file"),
               clEnumValN(AC_Assemble, "assemble",
                          "Assemble a .s file (default)"),
               clEnumValN(AC_Disassemble, "disassemble",
                          "Disassemble strings of hex bytes"),
               clEnumValN(AC_MDisassemble, "mdis",
                          "Marked up disassembly of strings of hex bytes")),
    cl::cat(MCCategory));

main() {
  llvm::InitializeAllTargetInfos(); {
    LLVMInitializeRISCVTargetInfo();
  }
  llvm::InitializeAllTargetMCs(); {
    LLVMInitializeRISCVTargetMC();
  }
  llvm::InitializeAllAsmParsers(); {
    LLVMInitializeRISCVAsmParser();
  }
  llvm::InitializeAllDisassemblers(); {
    LLVMInitializeRISCVDisassembler();
  }

  const MCTargetOptions MCOptions = mc::InitMCTargetOptionsFromFlags();

  const char *ProgName = argv[0];
  const Target *TheTarget = GetTarget(ProgName);

  // Now that GetTarget() has (potentially) replaced TripleName, it's safe to
  // construct the Triple object.
  Triple TheTriple(TripleName);

  SourceMgr SrcMgr;

  std::unique_ptr<MCRegisterInfo> MRI(TheTarget->createMCRegInfo(TripleName));
  std::unique_ptr<MCAsmInfo> MAI(
      TheTarget->createMCAsmInfo(*MRI, TripleName, MCOptions));

  std::unique_ptr<MCSubtargetInfo> STI(
      TheTarget->createMCSubtargetInfo(TripleName, MCPU, FeaturesStr));

  MCContext Ctx(TheTriple, MAI.get(), MRI.get(), STI.get(), &SrcMgr,
                &MCOptions);
  std::unique_ptr<MCObjectFileInfo> MOFI(
      TheTarget->createMCObjectFileInfo(Ctx, PIC, LargeCodeModel));
  Ctx.setObjectFileInfo(MOFI.get());

  std::unique_ptr<MCInstrInfo> MCII(TheTarget->createMCInstrInfo());

  if (FileType == OFT_AssemblyFile) {
    IP = TheTarget->createMCInstPrinter(Triple(TripleName), OutputAsmVariant,
                                      *MAI, *MCII, *MRI);

    std::unique_ptr<MCAsmBackend> MAB(
        TheTarget->createMCAsmBackend(*STI, *MRI, MCOptions));

    Str.reset(
        TheTarget->createAsmStreamer(Ctx, std::move(FOut), /*asmverbose*/ true,
                                     /*useDwarfDirectory*/ true, IP,
                                     std::move(CE), std::move(MAB), ShowInst));
  } else if (FileType == OFT_ObjectFile) {
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
  }

  AssembleInput(ProgName, TheTarget, SrcMgr, Ctx, *Str, *MAI, *STI, *MCII, MCOptions);
}

class MCTargetOptions {
  bool MCRelaxAll : 1;
  bool ShowMCEncoding : 1;

  int DwarfVersion = 0;

  std::string ABIName;
  std::string AssemblyLanguage;
};

static const Target *GetTarget(const char *ProgName) {
  // Figure out the target triple.
  if (TripleName.empty())
    TripleName = sys::getDefaultTargetTriple();
  Triple TheTriple(Triple::normalize(TripleName));

  // Get the target specific parser.
  std::string Error;
  const Target *TheTarget = TargetRegistry::lookupTarget(ArchName, TheTriple, Error);
  if (!TheTarget)
    return nullptr;

  // Update the triple name and return the found target.
  TripleName = TheTriple.getTriple();
  return TheTarget;
}
```

## TargetRegistry

```cpp
template <Triple::ArchType TargetArchType = Triple::UnknownArch,
          bool HasJIT = false>
struct RegisterTarget {
  RegisterTarget(Target &T, const char *Name, const char *Desc,
                 const char *BackendName) {
    TargetRegistry::RegisterTarget(T, Name, Desc, BackendName, &getArchMatch,
                                   HasJIT);
  }

  static bool getArchMatch(Triple::ArchType Arch) {
    return Arch == TargetArchType;
  }
};

void TargetRegistry::RegisterTarget(Target &T, const char *Name,
                                    const char *ShortDesc,
                                    const char *BackendName,
                                    Target::ArchMatchFnTy ArchMatchFn,
                                    bool HasJIT) {
  // Add to the list of targets.
  T.Next = FirstTarget;
  FirstTarget = &T;

  T.Name = Name;
  T.ShortDesc = ShortDesc;
  T.BackendName = BackendName;
  T.ArchMatchFn = ArchMatchFn;
  T.HasJIT = HasJIT;
}
```

```cpp
/// @param T - The target being registered.
/// @param Fn - A function to construct a MCAsmInfo for the target.
static void TargetRegistry::RegisterMCAsmInfo(Target &T, Target::MCAsmInfoCtorFnTy Fn) {
  T.MCAsmInfoCtorFn = Fn;
}
```

```cpp
template <class MCAsmParserImpl> struct RegisterMCAsmParser {
  RegisterMCAsmParser(Target &T) {
    TargetRegistry::RegisterMCAsmParser(T, &Allocator);
  }

private:
  static MCTargetAsmParser *Allocator(const MCSubtargetInfo &STI,
                                      MCAsmParser &P, const MCInstrInfo &MII,
                                      const MCTargetOptions &Options) {
    return new MCAsmParserImpl(STI, P, MII, Options);
  }
};

static void RegisterMCAsmParser(Target &T, Target::MCAsmParserCtorTy Fn) {
  T.MCAsmParserCtorFn = Fn;
}
```

## AsmStreamer

```cpp
MCStreamer *createAsmStreamer(MCContext &Ctx,
                              std::unique_ptr<formatted_raw_ostream> OS,
                              bool IsVerboseAsm, bool UseDwarfDirectory,
                              MCInstPrinter *InstPrint,
                              std::unique_ptr<MCCodeEmitter> &&CE,
                              std::unique_ptr<MCAsmBackend> &&TAB,
                              bool ShowInst) const {
  formatted_raw_ostream &OSRef = *OS;
  MCStreamer *S = llvm::createAsmStreamer(
      Ctx, std::move(OS), IsVerboseAsm, UseDwarfDirectory, InstPrint,
      std::move(CE), std::move(TAB), ShowInst);
  createAsmTargetStreamer(*S, OSRef, InstPrint, IsVerboseAsm);
  return S;
}
```

## AssembleInput

```cpp
std::unique_ptr<MCAsmParser> Parser(
  createMCAsmParser(SrcMgr, Ctx, Str, MAI));
std::unique_ptr<MCTargetAsmParser> TAP(
  TheTarget->createMCAsmParser(STI, *Parser, MCII, MCOptions));

Parser->setTargetParser(*TAP);
int Res = Parser->Run(NoInitialTextSection);
```

```cpp
MCAsmParser *llvm::createMCAsmParser(SourceMgr &SM, MCContext &C,
                                     MCStreamer &Out, const MCAsmInfo &MAI,
                                     unsigned CB) {
  if (C.getTargetTriple().isSystemZ() && C.getTargetTriple().isOSzOS())
    return new HLASMAsmParser(SM, C, Out, MAI, CB);

  return new AsmParser(SM, C, Out, MAI, CB);
}
```

## AsmParser

```cpp
bool AsmParser::Run(bool NoInitialTextSection, bool NoFinalize) {
}
```

