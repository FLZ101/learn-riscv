## sched

```
class SchedMachineModel

class ProcResource<int num>
class ProcResGroup<list<ProcResource> resources>

class SchedReadWrite;
class Sched<list<SchedReadWrite> schedrw>

// Define a scheduler resource associated with a def operand.
class SchedWrite : SchedReadWrite;

// Define a scheduler resource associated with a use operand.
class SchedRead  : SchedReadWrite;

class WriteSequence<list<SchedWrite> writes, int rep = 1> : SchedWrite

class ProcWriteResources<list<ProcResourceKind> resources>

class WriteRes<SchedWrite write, list<ProcResourceKind> resources>
  : ProcWriteResources<resources>

class SchedWriteRes<list<ProcResourceKind> resources> : SchedWrite,
  ProcWriteResources<resources>;

class ProcReadAdvance<int cycles, list<SchedWrite> writes = []>

class ReadAdvance<SchedRead read, int cycles, list<SchedWrite> writes = []>
  : ProcReadAdvance<cycles, writes>

class SchedReadAdvance<int cycles, list<SchedWrite> writes = []> : SchedRead,
  ProcReadAdvance<cycles, writes>;

// Define shared code that will be in the same scope as all
// SchedPredicates. Available variables are:
// (const MachineInstr *MI, const TargetSchedModel *SchedModel)
class PredicateProlog<code c> {
  code Code = c;
}

class MCSchedPredicate<MCInstPredicate P>

class SchedPredicate<code pred>

class SchedVar<SchedPredicateBase pred, list<SchedReadWrite> selected>

class SchedVariant<list<SchedVar> variants>

// A SchedWriteVariant is a single SchedWrite type that maps to a list
// of SchedWrite types under the conditions defined by its predicates.
//
// A Variadic write is expanded to cover multiple "def" operands. The
// SchedVariant's Expansion list is then interpreted as one write
// per-operand instead of the usual sequential writes feeding a single
// operand.
class SchedWriteVariant<list<SchedVar> variants> : SchedWrite,
  SchedVariant<variants>
```

## riscv

```
RISCVMCAsmInfo
```

```
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
```
