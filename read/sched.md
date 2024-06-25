
## llvm/include/llvm/Target/TargetItinerary.td

```
// Itineraries are detailed reservation
// tables for each instruction class. They are most appropriate for
// in-order machine with complicated scheduling or bundling constraints.

// Processor functional unit - These values represent the function units
// available across all chip sets for the target.  Eg., IntUnit, FPUnit, ...
// These may be independent values for each chip set or may be shared across
// all chip sets of the target.  Each functional unit is treated as a resource
// during scheduling and has an affect instruction order based on availability
// during a time interval.
//
class FuncUnit;

// Pipeline bypass / forwarding - These values specifies the symbolic names of
// pipeline bypasses which can be used to forward results of instructions
// that are forwarded to uses.
class Bypass;
def NoBypass : Bypass;

class ReservationKind<bits<1> val> {
  int Value = val;
}
def Required : ReservationKind<0>;
def Reserved : ReservationKind<1>;

// Instruction stage - These values represent a non-pipelined step in
// the execution of an instruction.  Cycles represents the number of
// discrete time slots needed to complete the stage.  Units represent
// the choice of functional units that can be used to complete the
// stage.  Eg. IntUnit1, IntUnit2. TimeInc indicates how many cycles
// should elapse from the start of this stage to the start of the next
// stage in the itinerary.  For example:
//
// A stage is specified in one of two ways:
//
//   InstrStage<1, [FU_x, FU_y]>     - TimeInc defaults to Cycles
//   InstrStage<1, [FU_x, FU_y], 0>  - TimeInc explicit
//

class InstrStage<int cycles, list<FuncUnit> units,
                 int timeinc = -1,
                 ReservationKind kind = Required> {
  int Cycles          = cycles;       // length of stage in machine cycles
  list<FuncUnit> Units = units;       // choice of functional units
  int TimeInc         = timeinc;      // cycles till start of next stage
  int Kind            = kind.Value;   // kind of FU reservation
}

// Instruction itinerary - An itinerary represents a sequential series of steps
// required to complete an instruction.  Itineraries are represented as lists of
// instruction stages.

// Instruction itinerary classes - These values represent 'named' instruction
// itinerary.  Using named itineraries simplifies managing groups of
// instructions across chip sets.  An instruction uses the same itinerary class
// across all chip sets.  Thus a new chip set can be added without modifying
// instruction information.
//
class InstrItinClass;
def NoItinerary : InstrItinClass;

// NumMicroOps represents the number of micro-operations that each instruction
// in the class are decoded to. If the number is zero, then it means the
// instruction can decode into variable number of micro-ops and it must be
// determined dynamically. This directly relates to the itineraries
// global IssueWidth property, which constrains the number of microops
// that can issue per cycle.
//
// OperandCycles are optional "cycle counts". They specify the cycle after
// instruction issue the values which correspond to specific operand indices
// are defined or read. Bypasses are optional "pipeline forwarding paths", if
// a def by an instruction is available on a specific bypass and the use can
// read from the same bypass, then the operand use latency is reduced by one.
//
//  InstrItinData<IIC_iLoad_i , [InstrStage<1, [A9_Pipe1]>,
//                               InstrStage<1, [A9_AGU]>],
//                              [3, 1], [A9_LdBypass]>,
//  InstrItinData<IIC_iMVNr   , [InstrStage<1, [A9_Pipe0, A9_Pipe1]>],
//                              [1, 1], [NoBypass, A9_LdBypass]>,
//
// In this example, the instruction of IIC_iLoadi reads its input on cycle 1
// (after issue) and the result of the load is available on cycle 3. The result
// is available via forwarding path A9_LdBypass. If it's used by the first
// source operand of instructions of IIC_iMVNr class, then the operand latency
// is reduced by 1.
class InstrItinData<InstrItinClass Class, list<InstrStage> stages,
                    list<int> operandcycles = [],
                    list<Bypass> bypasses = [], int uops = 1> {
  InstrItinClass TheClass = Class;
  int NumMicroOps = uops;
  list<InstrStage> Stages = stages;
  list<int> OperandCycles = operandcycles;
  list<Bypass> Bypasses = bypasses;
}

// Processor itineraries - These values represent the set of all itinerary
// classes for a given chip set.
//
// Set property values to -1 to use the default.
// See InstrItineraryProps for comments and defaults.
class ProcessorItineraries<list<FuncUnit> fu, list<Bypass> bp,
                           list<InstrItinData> iid> {
  list<FuncUnit> FU = fu;
  list<Bypass> BP = bp;
  list<InstrItinData> IID = iid;
  // The packetizer automaton to use for this itinerary. By default all
  // itineraries for a target are bundled up into the same automaton. This only
  // works correctly when there are no conflicts in functional unit IDs between
  // itineraries. For example, given two itineraries A<[SLOT_A]>, B<[SLOT_B]>,
  // SLOT_A and SLOT_B will be assigned the same functional unit index, and
  // the generated packetizer will confuse instructions referencing these slots.
  //
  // To avoid this, setting PacketizerNamespace to non-"" will cause this
  // itinerary to be generated in a different automaton. The subtarget will need
  // to declare a method "create##Namespace##DFAPacketizer()".
  string PacketizerNamespace = "";
}

// NoItineraries - A marker that can be used by processors without schedule
// info. Subtargets using NoItineraries can bypass the scheduler's
// expensive HazardRecognizer because no reservation table is needed.
def NoItineraries : ProcessorItineraries<[], [], []>;

// Combo Function Unit data - This is a map of combo function unit names to
// the list of functional units that are included in the combination.
//
class ComboFuncData<FuncUnit ComboFunc, list<FuncUnit> funclist> {
  FuncUnit TheComboFunc = ComboFunc;
  list<FuncUnit> FuncList = funclist;
}

// Combo Function Units - This is a list of all combo function unit data.
class ComboFuncUnits<list<ComboFuncData> cfd> {
  list<ComboFuncData> CFD = cfd;
}
```

## llvm/lib/Target/Sparc/SparcSchedule.td

```
def IIC_iu_or_fpu_instr : InstrItinClass;
def IIC_iu_instr : InstrItinClass;
def IIC_fpu_normal_instr : InstrItinClass;
def IIC_fpu_fast_instr : InstrItinClass;
def IIC_jmp_or_call : InstrItinClass;
def IIC_ldd : InstrItinClass;
def IIC_st : InstrItinClass;
def IIC_std : InstrItinClass;
def IIC_iu_smul : InstrItinClass;
def IIC_iu_umul : InstrItinClass;
def IIC_iu_div : InstrItinClass;
def IIC_ticc : InstrItinClass;
def IIC_ldstub : InstrItinClass;
def IIC_fpu_muls : InstrItinClass;
def IIC_fpu_muld : InstrItinClass;
def IIC_fpu_divs : InstrItinClass;
def IIC_fpu_divd : InstrItinClass;
def IIC_fpu_sqrts : InstrItinClass;
def IIC_fpu_sqrtd : InstrItinClass;
def IIC_fpu_abs : InstrItinClass;
def IIC_fpu_movs : InstrItinClass;
def IIC_fpu_negs : InstrItinClass;
def IIC_smac_umac : InstrItinClass;
def IIC_fpu_stod : InstrItinClass;

def LEONIU : FuncUnit; // integer unit
def LEONFPU : FuncUnit; // floating-point unit

// Ref: http://www.atmel.com/Images/doc4226.pdf
// Rad-Hard 32 bit SPARC V8 Processor - AT697E
//   Table 2. Cycles per instruction

def LEON2Itineraries : ProcessorItineraries<
[LEONIU, LEONFPU], [], [
  InstrItinData<IIC_iu_or_fpu_instr, [InstrStage<1, [LEONIU, LEONFPU]>], [1, 1]>,
  InstrItinData<IIC_iu_instr, [InstrStage<1, [LEONIU]>], [1, 1]>,
  InstrItinData<IIC_fpu_normal_instr, [InstrStage<1, [LEONFPU]>], [7, 1]>,
  InstrItinData<IIC_fpu_fast_instr, [InstrStage<1, [LEONFPU]>], [7, 1]>,
  InstrItinData<IIC_jmp_or_call, [InstrStage<1, [LEONIU, LEONFPU]>], [2, 1]>,
  InstrItinData<IIC_ldd, [InstrStage<1, [LEONIU, LEONFPU]>], [2, 1]>,
  InstrItinData<IIC_st, [InstrStage<1, [LEONIU, LEONFPU]>], [2, 1]>,
  InstrItinData<IIC_std, [InstrStage<1, [LEONIU, LEONFPU]>], [3, 1]>,
  InstrItinData<IIC_iu_smul, [InstrStage<1, [LEONIU]>], [5, 1]>,
  InstrItinData<IIC_iu_umul, [InstrStage<1, [LEONIU]>], [5, 1]>,
  InstrItinData<IIC_iu_div, [InstrStage<1, [LEONIU]>], [35, 1]>,
  InstrItinData<IIC_ticc, [InstrStage<1, [LEONIU, LEONFPU]>], [4, 1]>,
  InstrItinData<IIC_ldstub, [InstrStage<1, [LEONIU, LEONFPU]>], [3, 1]>,
  InstrItinData<IIC_fpu_muls, [InstrStage<1, [LEONFPU]>], [16, 1]>,
  InstrItinData<IIC_fpu_muld, [InstrStage<1, [LEONFPU]>], [21, 1]>,
  InstrItinData<IIC_fpu_divs, [InstrStage<1, [LEONFPU]>], [20, 1]>,
  InstrItinData<IIC_fpu_divd, [InstrStage<1, [LEONFPU]>], [36, 1]>,
  InstrItinData<IIC_fpu_sqrts, [InstrStage<1, [LEONFPU]>], [37, 1]>,
  InstrItinData<IIC_fpu_sqrtd, [InstrStage<1, [LEONFPU]>], [65, 1]>,
  InstrItinData<IIC_fpu_abs, [InstrStage<1, [LEONFPU]>], [2, 1]>,
  InstrItinData<IIC_fpu_movs, [InstrStage<1, [LEONFPU]>], [2, 1]>,
  InstrItinData<IIC_fpu_negs, [InstrStage<1, [LEONFPU]>], [2, 1]>,
  InstrItinData<IIC_fpu_stod, [InstrStage<1, [LEONFPU]>], [2, 1]>
]>;
```

## llvm/include/llvm/Target/Target.td

```
class Instruction : InstructionEncoding {

  // This instruction is not expected to be queried for scheduling latencies
  // and therefore needs no scheduling information even for a complete
  // scheduling model.
  bit hasNoSchedulingInfo = false;

  InstrItinClass Itinerary = NoItinerary;// Execution steps used for scheduling.

  // Scheduling information from TargetSchedule.td.
  list<SchedReadWrite> SchedRW;
}
```

## llvm/lib/Target/Sparc/SparcInstrFormats.td

```
// Format 2 instructions
class F2<dag outs, dag ins, string asmstr, list<dag> pattern,
         InstrItinClass itin = NoItinerary>
   : InstSP<outs, ins, asmstr, pattern, itin> {
  bits<3>  op2;
  bits<22> imm22;
  let op          = 0;    // op = 0
  let Inst{24-22} = op2;
  let Inst{21-0}  = imm22;
}

// Specific F2 classes: SparcV8 manual, page 44
//
class F2_1<bits<3> op2Val, dag outs, dag ins, string asmstr, list<dag> pattern,
           InstrItinClass itin = NoItinerary>
   : F2<outs, ins, asmstr, pattern, itin> {
  bits<5>  rd;

  let op2         = op2Val;

  let Inst{29-25} = rd;
}
```

## llvm/lib/Target/Sparc/SparcInstrInfo.td

```
// Section B.9 - SETHI Instruction, p. 104
def SETHIi: F2_1<0b100,
                 (outs IntRegs:$rd), (ins i32imm:$imm22),
                 "sethi $imm22, $rd",
                 [(set i32:$rd, SETHIimm:$imm22)],
                 IIC_iu_instr>;
```

## llvm/include/llvm/Target/TargetSchedule.td

```
// Include legacy support for instruction itineraries.
include "llvm/Target/TargetItinerary.td"

// Define the SchedMachineModel and provide basic properties for
// coarse grained instruction cost model. Default values for the
// properties are defined in MCSchedModel. A value of "-1" in the
// target description's SchedMachineModel indicates that the property
// is not overriden by the target.
//
// Target hooks allow subtargets to associate LoadLatency and
// HighLatency with groups of opcodes.
//
// See MCSchedule.h for detailed comments.
class SchedMachineModel {
  int IssueWidth = -1; // Max micro-ops that may be scheduled per cycle.
  int MicroOpBufferSize = -1; // Max micro-ops that can be buffered.
  int LoopMicroOpBufferSize = -1; // Max micro-ops that can be buffered for
                                  // optimized loop dispatch/execution.
  int LoadLatency = -1; // Cycles for loads to access the cache.
  int HighLatency = -1; // Approximation of cycles for "high latency" ops.
  int MispredictPenalty = -1; // Extra cycles for a mispredicted branch.

  // Per-cycle resources tables.
  ProcessorItineraries Itineraries = NoItineraries;

  bit PostRAScheduler = false; // Enable Post RegAlloc Scheduler pass.

  // Subtargets that define a model for only a subset of instructions
  // that have a scheduling class (itinerary class or SchedRW list)
  // and may actually be generated for that subtarget must clear this
  // bit. Otherwise, the scheduler considers an unmodelled opcode to
  // be an error. This should only be set during initial bringup,
  // or there will be no way to catch simple errors in the model
  // resulting from changes to the instruction definitions.
  bit CompleteModel = true;

  // Indicates that we should do full overlap checking for multiple InstrRWs
  // defining the same instructions within the same SchedMachineModel.
  // FIXME: Remove when all in tree targets are clean with the full check
  // enabled.
  bit FullInstRWOverlapCheck = true;

  // A processor may only implement part of published ISA, due to either new ISA
  // extensions, (e.g. Pentium 4 doesn't have AVX) or implementation
  // (ARM/MIPS/PowerPC/SPARC soft float cores).
  //
  // For a processor which doesn't support some feature(s), the schedule model
  // can use:
  //
  // let<Predicate> UnsupportedFeatures = [HaveA,..,HaveY];
  //
  // to skip the checks for scheduling information when building LLVM for
  // instructions which have any of the listed predicates in their Predicates
  // field.
  list<Predicate> UnsupportedFeatures = [];

  bit NoModel = false; // Special tag to indicate missing machine model.
}

def NoSchedModel : SchedMachineModel {
  let NoModel = true;
  let CompleteModel = false;
}

// Define a kind of processor resource that may be common across
// similar subtargets.
class ProcResourceKind;

// Define a number of interchangeable processor resources. NumUnits
// determines the throughput of instructions that require the resource.
//
// An optional Super resource may be given to model these resources as
// a subset of the more general super resources. Using one of these
// resources implies using one of the super resources.
//
// ProcResourceUnits normally model a few buffered resources within an
// out-of-order engine. Buffered resources may be held for multiple
// clock cycles, but the scheduler does not pin them to a particular
// clock cycle relative to instruction dispatch.
//
// Setting BufferSize=0
// changes this to an in-order issue/dispatch resource. In this case,
// the scheduler counts down from the cycle that the instruction
// issues in-order, forcing a stall whenever a subsequent instruction
// requires the same resource until the number of ResourceCycles
// specified in WriteRes expire.
//
// Setting BufferSize=1 changes this to
// an in-order latency resource. In this case, the scheduler models
// producer/consumer stalls between instructions that use the
// resource.
//
// Examples (all assume an out-of-order engine):
//
// Use BufferSize = -1 for "issue ports" fed by a unified reservation
// station. Here the size of the reservation station is modeled by
// MicroOpBufferSize, which should be the minimum size of either the
// register rename pool, unified reservation station, or reorder
// buffer.
//
// Use BufferSize = 0 for resources that force "dispatch/issue
// groups". (Different processors define dispath/issue
// differently. Here we refer to stage between decoding into micro-ops
// and moving them into a reservation station.) Normally NumMicroOps
// is sufficient to limit dispatch/issue groups. However, some
// processors can form groups of with only certain combinations of
// instruction types. e.g. POWER7.
//
// Use BufferSize = 1 for in-order execution units. This is used for
// an in-order pipeline within an out-of-order core where scheduling
// dependent operations back-to-back is guaranteed to cause a
// bubble. e.g. Cortex-a9 floating-point.
//
// Use BufferSize > 1 for out-of-order executions units with a
// separate reservation station. This simply models the size of the
// reservation station.
//
// To model both dispatch/issue groups and in-order execution units,
// create two types of units, one with BufferSize=0 and one with
// BufferSize=1.
//
// SchedModel ties these units to a processor for any stand-alone defs
// of this class.
class ProcResourceUnits<ProcResourceKind kind, int num> {
  ProcResourceKind Kind = kind;
  int NumUnits = num;
  ProcResourceKind Super = ?;
  int BufferSize = -1;
  SchedMachineModel SchedModel = ?;
}

// EponymousProcResourceKind helps implement ProcResourceUnits by
// allowing a ProcResourceUnits definition to reference itself. It
// should not be referenced anywhere else.
def EponymousProcResourceKind : ProcResourceKind;

// Subtargets typically define processor resource kind and number of
// units in one place.
class ProcResource<int num> : ProcResourceKind,
  ProcResourceUnits<EponymousProcResourceKind, num>;

class ProcResGroup<list<ProcResource> resources> : ProcResourceKind {
  list<ProcResource> Resources = resources;
  SchedMachineModel SchedModel = ?;
  int BufferSize = -1;
}

// A target architecture may define SchedReadWrite types and associate
// them with instruction operands.
class SchedReadWrite;

// List the per-operand types that map to the machine model of an
// instruction. One SchedWrite type must be listed for each explicit
// def operand in order. Additional SchedWrite types may optionally be
// listed for implicit def operands.  SchedRead types may optionally
// be listed for use operands in order. The order of defs relative to
// uses is insignificant. This way, the same SchedReadWrite list may
// be used for multiple forms of an operation. For example, a
// two-address instruction could have two tied operands or single
// operand that both reads and writes a reg. In both cases we have a
// single SchedWrite and single SchedRead in any order.
class Sched<list<SchedReadWrite> schedrw> {
  list<SchedReadWrite> SchedRW = schedrw;
}

// Define a scheduler resource associated with a def operand.
class SchedWrite : SchedReadWrite;
def NoWrite : SchedWrite;

// Define a scheduler resource associated with a use operand.
class SchedRead  : SchedReadWrite;

// Define a SchedWrite that is modeled as a sequence of other
// SchedWrites with additive latency. This allows a single operand to
// be mapped the resources composed from a set of previously defined
// SchedWrites.
//
// If the final write in this sequence is a SchedWriteVariant marked
// Variadic, then the list of prior writes are distributed across all
// operands after resolving the predicate for the final write.
//
// SchedModel silences warnings but is ignored.
class WriteSequence<list<SchedWrite> writes, int rep = 1> : SchedWrite {
  list<SchedWrite> Writes = writes;
  int Repeat = rep;
  SchedMachineModel SchedModel = ?;
}

// SchedModel ties these resources to a processor.
class ProcWriteResources<list<ProcResourceKind> resources> {
  list<ProcResourceKind> ProcResources = resources;
  list<int> ResourceCycles = [];
  int Latency = 1;
  int NumMicroOps = 1;
  bit BeginGroup = false;
  bit EndGroup = false;
  // Allow a processor to mark some scheduling classes as unsupported
  // for stronger verification.
  bit Unsupported = false;
  // Allow a processor to mark some scheduling classes as single-issue.
  // SingleIssue is an alias for Begin/End Group.
  bit SingleIssue = false;
  // An instruction is allowed to retire out-of-order if RetireOOO is
  // true for at least one of its writes. This field is only used by
  // MCA for in-order subtargets, and is ignored for other targets.
  bit RetireOOO = false;
  SchedMachineModel SchedModel = ?;
}

// Define the resources and latency of a SchedWrite. This will be used
// directly by targets that have no itinerary classes. In this case,
// SchedWrite is defined by the target, while WriteResources is
// defined by the subtarget, and maps the SchedWrite to processor
// resources.
//
// If a target already has itinerary classes, SchedWriteResources can
// be used instead to define subtarget specific SchedWrites and map
// them to processor resources in one place. Then ItinRW can map
// itinerary classes to the subtarget's SchedWrites.
//
// ProcResources indicates the set of resources consumed by the write.
// Optionally, ResourceCycles indicates the number of cycles the
// resource is consumed. Each ResourceCycles item is paired with the
// ProcResource item at the same position in its list. ResourceCycles
// can be `[]`: in that case, all resources are consumed for a single
// cycle, regardless of latency, which models a fully pipelined processing
// unit. A value of 0 for ResourceCycles means that the resource must
// be available but is not consumed, which is only relevant for
// unbuffered resources.
//
// By default, each SchedWrite takes one micro-op, which is counted
// against the processor's IssueWidth limit. If an instruction can
// write multiple registers with a single micro-op, the subtarget
// should define one of the writes to be zero micro-ops. If a
// subtarget requires multiple micro-ops to write a single result, it
// should either override the write's NumMicroOps to be greater than 1
// or require additional writes. Extra writes can be required either
// by defining a WriteSequence, or simply listing extra writes in the
// instruction's list of writers beyond the number of "def"
// operands. The scheduler assumes that all micro-ops must be
// dispatched in the same cycle. These micro-ops may be required to
// begin or end the current dispatch group.
class WriteRes<SchedWrite write, list<ProcResourceKind> resources>
  : ProcWriteResources<resources> {
  SchedWrite WriteType = write;
}

// Directly name a set of WriteResources defining a new SchedWrite
// type at the same time. This class is unaware of its SchedModel so
// must be referenced by InstRW or ItinRW.
class SchedWriteRes<list<ProcResourceKind> resources> : SchedWrite,
  ProcWriteResources<resources>;

// SchedModel ties these resources to a processor.
class ProcReadAdvance<int cycles, list<SchedWrite> writes = []> {
  int Cycles = cycles;
  list<SchedWrite> ValidWrites = writes;
  // Allow a processor to mark some scheduling classes as unsupported
  // for stronger verification.
  bit Unsupported = false;
  SchedMachineModel SchedModel = ?;
}

// A processor may define a ReadAdvance associated with a SchedRead
// to reduce latency of a prior write by N cycles. A negative advance
// effectively increases latency, which may be used for cross-domain
// stalls.
//
// A ReadAdvance may be associated with a list of SchedWrites
// to implement pipeline bypass. The Writes list may be empty to
// indicate operands that are always read this number of Cycles later
// than a normal register read, allowing the read's parent instruction
// to issue earlier relative to the writer.
class ReadAdvance<SchedRead read, int cycles, list<SchedWrite> writes = []>
  : ProcReadAdvance<cycles, writes> {
  SchedRead ReadType = read;
}

// Directly associate a new SchedRead type with a delay and optional
// pipeline bypass. For use with InstRW or ItinRW.
class SchedReadAdvance<int cycles, list<SchedWrite> writes = []> : SchedRead,
  ProcReadAdvance<cycles, writes>;

// Define SchedRead defaults. Reads seldom need special treatment.
def ReadDefault : SchedRead;
def NoReadAdvance : SchedReadAdvance<0>;

// Define shared code that will be in the same scope as all
// SchedPredicates. Available variables are:
// (const MachineInstr *MI, const TargetSchedModel *SchedModel)
class PredicateProlog<code c> {
  code Code = c;
}

// Base class for scheduling predicates.
class SchedPredicateBase;

// A scheduling predicate whose logic is defined by a MCInstPredicate.
// This can directly be used by SchedWriteVariant definitions.
class MCSchedPredicate<MCInstPredicate P> : SchedPredicateBase {
  MCInstPredicate Pred = P;
  SchedMachineModel SchedModel = ?;
}

// Define a predicate to determine which SchedVariant applies to a
// particular MachineInstr. The code snippet is used as an
// if-statement's expression. Available variables are MI, SchedModel,
// and anything defined in a PredicateProlog.
//
// SchedModel silences warnings but is ignored.
class SchedPredicate<code pred> : SchedPredicateBase {
  SchedMachineModel SchedModel = ?;
  code Predicate = pred;
}

// Define a predicate to be typically used as the default case in a
// SchedVariant.  It the SchedVariant does not use any other predicate based on
// MCSchedPredicate, this is the default scheduling case used by llvm-mca.
def NoSchedPred : MCSchedPredicate<TruePred>;

// Associate a predicate with a list of SchedReadWrites. By default,
// the selected SchedReadWrites are still associated with a single
// operand and assumed to execute sequentially with additive
// latency. However, if the parent SchedWriteVariant or
// SchedReadVariant is marked "Variadic", then each Selected
// SchedReadWrite is mapped in place to the instruction's variadic
// operands. In this case, latency is not additive. If the current Variant
// is already part of a Sequence, then that entire chain leading up to
// the Variant is distributed over the variadic operands.
class SchedVar<SchedPredicateBase pred, list<SchedReadWrite> selected> {
  SchedPredicateBase Predicate = pred;
  list<SchedReadWrite> Selected = selected;
}

// SchedModel silences warnings but is ignored.
class SchedVariant<list<SchedVar> variants> {
  list<SchedVar> Variants = variants;
  bit Variadic = false;
  SchedMachineModel SchedModel = ?;
}

// A SchedWriteVariant is a single SchedWrite type that maps to a list
// of SchedWrite types under the conditions defined by its predicates.
//
// A Variadic write is expanded to cover multiple "def" operands. The
// SchedVariant's Expansion list is then interpreted as one write
// per-operand instead of the usual sequential writes feeding a single
// operand.
class SchedWriteVariant<list<SchedVar> variants> : SchedWrite,
  SchedVariant<variants> {
}

// A SchedReadVariant is a single SchedRead type that maps to a list
// of SchedRead types under the conditions defined by its predicates.
//
// A Variadic write is expanded to cover multiple "readsReg" operands as
// explained above.
class SchedReadVariant<list<SchedVar> variants> : SchedRead,
  SchedVariant<variants> {
}

// Map a set of opcodes to a list of SchedReadWrite types. This allows
// the subtarget to easily override specific operations.
//
// SchedModel ties this opcode mapping to a processor.
class InstRW<list<SchedReadWrite> rw, dag instrlist> {
  list<SchedReadWrite> OperandReadWrites = rw;
  dag Instrs = instrlist;
  SchedMachineModel SchedModel = ?;
  // Allow a subtarget to mark some instructions as unsupported.
  bit Unsupported = false;
}

// Map a set of itinerary classes to SchedReadWrite resources. This is
// used to bootstrap a target (e.g. ARM) when itineraries already
// exist and changing InstrInfo is undesirable.
//
// SchedModel ties this ItineraryClass mapping to a processor.
class ItinRW<list<SchedReadWrite> rw, list<InstrItinClass> iic> {
  list<InstrItinClass> MatchedItinClasses = iic;
  list<SchedReadWrite> OperandReadWrites = rw;
  SchedMachineModel SchedModel = ?;
}

// Alias a target-defined SchedReadWrite to a processor specific
// SchedReadWrite. This allows a subtarget to easily map a
// SchedReadWrite type onto a WriteSequence, SchedWriteVariant, or
// SchedReadVariant.
//
// SchedModel will usually be provided by surrounding let statement
// and ties this SchedAlias mapping to a processor.
class SchedAlias<SchedReadWrite match, SchedReadWrite alias> {
  SchedReadWrite MatchRW = match;
  SchedReadWrite AliasRW = alias;
  SchedMachineModel SchedModel = ?;
}

// Allow the definition of processor register files for register renaming
// purposes.
//
// Each processor register file declares:
//  - The set of registers that can be renamed.
//  - The number of physical registers which can be used for register renaming
//    purpose.
//  - The cost of a register rename.
//  - The set of registers that allow move elimination.
//  - The maximum number of moves that can be eliminated every cycle.
//  - Whether move elimination is limited to register moves whose input
//    is known to be zero.
//
// The cost of a rename is the number of physical registers allocated by the
// register alias table to map the new definition. By default, register can be
// renamed at the cost of a single physical register.  Note that register costs
// are defined at register class granularity (see field `Costs`).
//
// The set of registers that are subject to register renaming is declared using
// a list of register classes (see field `RegClasses`). An empty list of
// register classes means: all the logical registers defined by the target can
// be fully renamed.
//
// A register R can be renamed if its register class appears in the `RegClasses`
// set. When R is written, a new alias is allocated at the cost of one or more
// physical registers; as a result, false dependencies on R are removed.
//
// A sub-register V of register R is implicitly part of the same register file.
// However, V is only renamed if its register class is part of `RegClasses`.
// Otherwise, the processor keeps it (as well as any other different part
// of R) together with R, and a write of V always causes a compulsory read of R.
//
// This is what happens for example on AMD processors (at least from Bulldozer
// onwards), where AL and AH are not treated as independent from AX, and AX is
// not treated as independent from EAX. A write to AL has an implicity false
// dependency on the last write to EAX (or a portion of EAX).  As a consequence,
// a write to AL cannot go in parallel with a write to AH.
//
// There is no false dependency if the partial register write belongs to a
// register class that is in `RegClasses`.
// There is also no penalty for writes that "clear the content a super-register"
// (see MC/MCInstrAnalysis.h - method MCInstrAnalysis::clearsSuperRegisters()).
// On x86-64, 32-bit GPR writes implicitly zero the upper half of the underlying
// physical register, effectively removing any false dependencies with the
// previous register definition.
//
// TODO: This implementation assumes that there is no limit in the number of
// renames per cycle, which might not be true for all hardware or register
// classes. Also, there is no limit to how many times the same logical register
// can be renamed during the same cycle.
//
// TODO: we don't currently model merge penalties for the case where a write to
// a part of a register is followed by a read from a larger part of the same
// register. On some Intel chips, different parts of a GPR can be stored in
// different physical registers. However, there is a cost to pay for when the
// partial write is combined with the previous super-register definition.  We
// should add support for these cases, and correctly model merge problems with
// partial register accesses.
//
// Field MaxMovesEliminatedPerCycle specifies how many moves can be eliminated
// every cycle. A default value of zero for that field means: there is no limit
// to the number of moves that can be eliminated by this register file.
//
// An instruction MI is a candidate for move elimination if a call to
// method TargetSubtargetInfo::isOptimizableRegisterMove(MI) returns true (see
// llvm/CodeGen/TargetSubtargetInfo.h, and llvm/MC/MCInstrAnalysis.h).
//
// Subtargets can instantiate tablegen class IsOptimizableRegisterMove (see
// llvm/Target/TargetInstrPredicate.td) to customize the set of move elimination
// candidates. By default, no instruction is a valid move elimination candidate.
//
// A register move MI is eliminated only if:
//  - MI is a move elimination candidate.
//  - The destination register is from a register class that allows move
//    elimination (see field `AllowMoveElimination` below).
//  - Constraints on the move kind, and the maximum number of moves that can be
//    eliminated per cycle are all met.

class RegisterFile<int numPhysRegs, list<RegisterClass> Classes = [],
                   list<int> Costs = [], list<bit> AllowMoveElim = [],
                   int MaxMoveElimPerCy = 0, bit AllowZeroMoveElimOnly = false> {
  list<RegisterClass> RegClasses = Classes;
  list<int> RegCosts = Costs;
  list<bit> AllowMoveElimination = AllowMoveElim;
  int NumPhysRegs = numPhysRegs;
  int MaxMovesEliminatedPerCycle = MaxMoveElimPerCy;
  bit AllowZeroMoveEliminationOnly = AllowZeroMoveElimOnly;
  SchedMachineModel SchedModel = ?;
}

// Describe the retire control unit.
// A retire control unit specifies the size of the reorder buffer, as well as
// the maximum number of opcodes that can be retired every cycle.
// A value less-than-or-equal-to zero for field 'ReorderBufferSize' means: "the
// size is unknown". The idea is that external tools can fall-back to using
// field MicroOpBufferSize in SchedModel if the reorder buffer size is unknown.
// A zero or negative value for field 'MaxRetirePerCycle' means "no
// restrictions on the number of instructions retired per cycle".
// Models can optionally specify up to one instance of RetireControlUnit per
// scheduling model.
class RetireControlUnit<int bufferSize, int retirePerCycle> {
  int ReorderBufferSize = bufferSize;
  int MaxRetirePerCycle = retirePerCycle;
  SchedMachineModel SchedModel = ?;
}

// Base class for Load/StoreQueue.  It is used to identify processor resources
// which describe load/store queues in the LS unit.
class MemoryQueue<ProcResourceKind PR> {
  ProcResourceKind QueueDescriptor = PR;
  SchedMachineModel SchedModel = ?;
}

class LoadQueue<ProcResourceKind LDQueue> : MemoryQueue<LDQueue>;
class StoreQueue<ProcResourceKind STQueue> : MemoryQueue<STQueue>;
```

## llvm/include/llvm/Target/TargetInstrPredicate.td

```
// MCInstPredicate definitions are used by target scheduling models to describe
// constraints on instructions.
//
// Here is an example of an MCInstPredicate definition in TableGen:
//
// def MCInstPredicateExample : CheckAll<[
//    CheckOpcode<[BLR]>,
//    CheckIsRegOperand<0>,
//    CheckNot<CheckRegOperand<0, LR>>]>;
//
// The syntax for MCInstPredicate is declarative, and predicate definitions can
// be composed together in order to generate more complex constraints.
//
// The `CheckAll` from the example defines a composition of three different
// predicates.  Definition `MCInstPredicateExample` identifies instructions
// whose opcode is BLR, and whose first operand is a register different from
// register `LR`.
//
// Every MCInstPredicate class has a well-known semantic in tablegen. For
// example, `CheckOpcode` is a special type of predicate used to describe a
// constraint on the value of an instruction opcode.
//
// MCInstPredicate definitions are typically used by scheduling models to
// construct MCSchedPredicate definitions (see the definition of class
// MCSchedPredicate in llvm/Target/TargetSchedule.td).
// In particular, an MCSchedPredicate can be used instead of a SchedPredicate
// when defining the set of SchedReadVariant and SchedWriteVariant of a
// processor scheduling model.
//
// The `MCInstPredicateExample` definition above is equivalent (and therefore
// could replace) the following definition from a previous ExynosM3 model (see
// AArch64SchedExynosM3.td):
//
// def M3BranchLinkFastPred  : SchedPredicate<[{
//    MI->getOpcode() == AArch64::BLR &&
//    MI->getOperand(0).isReg() &&
//    MI->getOperand(0).getReg() != AArch64::LR}]>;
//
// The main advantage of using MCInstPredicate instead of SchedPredicate is
// portability: users don't need to specify predicates in C++. As a consequence
// of this, MCInstPredicate definitions are not bound to a particular
// representation (i.e. MachineInstr vs MCInst).
//
// Tablegen backends know how to expand MCInstPredicate definitions into actual
// C++ code that works on MachineInstr (and/or MCInst).
//
// Instances of class PredicateExpander (see utils/Tablegen/PredicateExpander.h)
// know how to expand a predicate. For each MCInstPredicate class, there must be
// an "expand" method available in the PredicateExpander interface.
//
// For example, a `CheckOpcode` predicate is expanded using method
// `PredicateExpander::expandCheckOpcode()`.
//
// New MCInstPredicate classes must be added to this file. For each new class
// XYZ, an "expandXYZ" method must be added to the PredicateExpander.
//
//===----------------------------------------------------------------------===//

// A generic machine instruction predicate.
class MCInstPredicate;

class MCTrue  : MCInstPredicate;   // A predicate that always evaluates to True.
class MCFalse : MCInstPredicate;   // A predicate that always evaluates to False.
def TruePred  : MCTrue;
def FalsePred : MCFalse;

// A predicate used to negate the outcome of another predicate.
// It allows to easily express "set difference" operations. For example, it
// makes it easy to describe a check that tests if an opcode is not part of a
// set of opcodes.
class CheckNot<MCInstPredicate P> : MCInstPredicate {
  MCInstPredicate Pred = P;
}

// This class is used as a building block to define predicates on instruction
// operands. It is used to reference a specific machine operand.
class MCOperandPredicate<int Index> : MCInstPredicate {
  int OpIndex = Index;
}

// Return true if machine operand at position `Index` is a register operand.
class CheckIsRegOperand<int Index> : MCOperandPredicate<Index>;

// Return true if machine operand at position `Index` is an immediate operand.
class CheckIsImmOperand<int Index> : MCOperandPredicate<Index>;

// A sequence of predicates. It is used as the base class for CheckAll, and
// CheckAny. It allows to describe compositions of predicates.
class CheckPredicateSequence<list<MCInstPredicate> Preds> : MCInstPredicate {
  list<MCInstPredicate> Predicates = Preds;
}

// Check that all of the predicates in `Preds` evaluate to true.
class CheckAll<list<MCInstPredicate> Sequence>
    : CheckPredicateSequence<Sequence>;

// Check that at least one of the predicates in `Preds` evaluates to true.
class CheckAny<list<MCInstPredicate> Sequence>
    : CheckPredicateSequence<Sequence>;
```

## llvm/lib/Target/AArch64/AArch64Schedule.td

```
def : PredicateProlog<[{
  const AArch64InstrInfo *TII =
    static_cast<const AArch64InstrInfo*>(SchedModel->getInstrInfo());
  (void)TII;
}]>;

def WriteI         : SchedWrite; // ALU
def WriteISReg     : SchedWrite; // ALU of Shifted-Reg
def WriteIEReg     : SchedWrite; // ALU of Extended-Reg
def ReadI          : SchedRead;  // ALU
def ReadISReg      : SchedRead;  // ALU of Shifted-Reg
def ReadIEReg      : SchedRead;  // ALU of Extended-Reg
def WriteExtr      : SchedWrite; // EXTR shifts a reg pair
def ReadExtrHi     : SchedRead;  // Read the high reg of the EXTR pair
def WriteIS        : SchedWrite; // Shift/Scale
def WriteID32      : SchedWrite; // 32-bit Divide
def WriteID64      : SchedWrite; // 64-bit Divide
def ReadID         : SchedRead;  // 32/64-bit Divide
def WriteIM32      : SchedWrite; // 32-bit Multiply
def WriteIM64      : SchedWrite; // 64-bit Multiply
def ReadIM         : SchedRead;  // 32/64-bit Multiply
def ReadIMA        : SchedRead;  // 32/64-bit Multiply Accumulate
def WriteBr        : SchedWrite; // Branch
def WriteBrReg     : SchedWrite; // Indirect Branch

def WriteLD        : SchedWrite; // Load from base addr plus immediate offset
def WriteST        : SchedWrite; // Store to base addr plus immediate offset
def WriteSTP       : SchedWrite; // Store a register pair.
def WriteAdr       : SchedWrite; // Address pre/post increment.

def WriteLDIdx : SchedWrite; // Load from a register index (maybe scaled).
def WriteSTIdx : SchedWrite; // Store to a register index (maybe scaled).
def ReadST     : SchedRead;  // Read the stored value.
def ReadAdrBase : SchedRead; // Read the base resister of a reg-offset LD/ST.

// Serialized two-level address load.
// EXAMPLE: LOADGot
def WriteLDAdr : WriteSequence<[WriteAdr, WriteLD]>;

// Serialized two-level address lookup.
// EXAMPLE: MOVaddr...
def WriteAdrAdr : WriteSequence<[WriteAdr, WriteAdr]>;

// The second register of a load-pair.
// LDP,LDPSW,LDNP,LDXP,LDAXP
def WriteLDHi : SchedWrite;

// Store-exclusive is a store followed by a dependent load.
def WriteSTX : WriteSequence<[WriteST, WriteLD]>;

def WriteSys     : SchedWrite; // Long, variable latency system ops.
def WriteBarrier : SchedWrite; // Memory barrier.
def WriteHint    : SchedWrite; // Hint instruction.

def WriteF       : SchedWrite; // General floating-point ops.
def WriteFCmp    : SchedWrite; // Floating-point compare.
def WriteFCvt    : SchedWrite; // Float conversion.
def WriteFCopy   : SchedWrite; // Float-int register copy.
def WriteFImm    : SchedWrite; // Floating-point immediate.
def WriteFMul    : SchedWrite; // Floating-point multiply.
def WriteFDiv    : SchedWrite; // Floating-point division.

def WriteVd  : SchedWrite; // 64bit Vector D ops.
def WriteVq  : SchedWrite; // 128bit Vector Q ops.
def WriteVLD : SchedWrite; // Vector loads.
def WriteVST : SchedWrite; // Vector stores.

def WriteAtomic : SchedWrite; // Atomic memory operations (CAS, Swap, LDOP)

// Read the unwritten lanes of the VLD's destination registers.
def ReadVLD : SchedRead;

// Sequential vector load and shuffle.
def WriteVLDShuffle     : WriteSequence<[WriteVLD, WriteVq]>;
def WriteVLDPairShuffle : WriteSequence<[WriteVLD, WriteVq, WriteVq]>;

// Store a shuffled vector.
def WriteVSTShuffle : WriteSequence<[WriteVq, WriteVST]>;
def WriteVSTPairShuffle : WriteSequence<[WriteVq, WriteVq, WriteVST]>;
```

## llvm/lib/Target/AArch64/AArch64InstrFormats.td

```
class BaseMulAccum<bit isSub, bits<3> opc, RegisterClass multype,
                       RegisterClass addtype, string asm,
                       list<dag> pattern>
  : I<(outs addtype:$Rd), (ins multype:$Rn, multype:$Rm, addtype:$Ra),
      asm, "\t$Rd, $Rn, $Rm, $Ra", "", pattern> {
}

multiclass MulAccum<bit isSub, string asm> {
  // MADD/MSUB generation is decided by MachineCombiner.cpp
  def Wrrr : BaseMulAccum<isSub, 0b000, GPR32, GPR32, asm, []>,
      Sched<[WriteIM32, ReadIM, ReadIM, ReadIMA]> {
    let Inst{31} = 0;
  }

  def Xrrr : BaseMulAccum<isSub, 0b000, GPR64, GPR64, asm, []>,
      Sched<[WriteIM64, ReadIM, ReadIM, ReadIMA]> {
    let Inst{31} = 1;
  }
}

class WideMulAccum<bit isSub, bits<3> opc, string asm,
                   SDNode AccNode, SDNode ExtNode>
  : BaseMulAccum<isSub, opc, GPR32, GPR64, asm,
    [(set GPR64:$Rd, (AccNode GPR64:$Ra,
                            (mul (ExtNode GPR32:$Rn), (ExtNode GPR32:$Rm))))]>,
    Sched<[WriteIM32, ReadIM, ReadIM, ReadIMA]> {
  let Inst{31} = 1;
}

class AuthBase<bits<1> M, dag oops, dag iops, string asm, string operands,
               list<dag> pattern>
  : I<oops, iops, asm, operands, "", pattern>, Sched<[]> {
  let isAuthenticated = 1;
  let Inst{31-25} = 0b1101011;
  let Inst{20-11} = 0b1111100001;
  let Inst{10} = M;
  let Inst{4-0} = 0b11111;
}

class AuthBranchTwoOperands<bits<1> op, bits<1> M, string asm>
  : AuthBase<M, (outs), (ins GPR64:$Rn, GPR64sp:$Rm), asm, "\t$Rn, $Rm", []> {
  bits<5> Rn;
  bits<5> Rm;
  let Inst{24-22} = 0b100;
  let Inst{21} = op;
  let Inst{9-5} = Rn;
  let Inst{4-0} = Rm;
}
```

## llvm/lib/Target/AArch64/AArch64InstrInfo.td

```
defm MADD : MulAccum<0, "madd">;
defm MSUB : MulAccum<1, "msub">;

def SMADDLrrr : WideMulAccum<0, 0b001, "smaddl", add, sext>;
def SMSUBLrrr : WideMulAccum<1, 0b001, "smsubl", sub, sext>;
def UMADDLrrr : WideMulAccum<0, 0b101, "umaddl", add, zext>;
def UMSUBLrrr : WideMulAccum<1, 0b101, "umsubl", sub, zext>;

// These pointer authentication instructions require armv8.3a
let Predicates = [HasPAuth] in {
  let isCall = 1, Defs = [LR], Uses = [SP] in {
    def BLRAA   : AuthBranchTwoOperands<1, 0, "blraa">;
    def BLRAB   : AuthBranchTwoOperands<1, 1, "blrab">;
  }
}
```

## llvm/lib/Target/AArch64/AArch64SchedA57.td

Cortex-A57 software optimization guide, 3.5 Divide and Multiply Instructions

> Multiply-accumulate pipelines support late-forwarding of accumulate operands from similar µops, allowing a typical sequence of multiply-accumulate µops to issue one every N cycles (accumulate latency N shown in parentheses).

```
def : ReadAdvance<ReadIMA,     2, [WriteIM32, WriteIM64]>;
```

## llvm/lib/Target/AArch64/AArch64SchedNeoverseN2.td

```

def NeoverseN2Model : SchedMachineModel {
  // Neoverse N2 Software Optimization Guide
  // The dispatch stage can process up to 5 MOPs per cycle and dispatch up to 10 µOPs per cycle, ...
  let IssueWidth            =  10; // Micro-ops dispatched at a time.
  // https://hc33.hotchips.org/assets/program/conference/day1/20210818_Hotchips_NeoverseN2.pdf
  // https://chipsandcheese.com/2023/09/11/hot-chips-2023-arms-neoverse-v2/
  // ROB size
  let MicroOpBufferSize     = 160; // Entries in micro-op re-order buffer.
  // Neoverse N2 Software Optimization Guide
  let LoadLatency           =   4; // Optimistic load latency.
  // same as IssueWidth
  let MispredictPenalty     =  10; // Extra cycles for mispredicted branch.
  let LoopMicroOpBufferSize =  16; // NOTE: Copied from Cortex-A57.
  let CompleteModel         =   1;

  list<Predicate> UnsupportedFeatures = SMEUnsupported.F;
}
```

```
// Define each kind of processor resource and number available on Neoverse N2.
// Instructions are first fetched and then decoded into internal macro-ops
// (MOPs). From there, the MOPs proceed through register renaming and dispatch
// stages. A MOP can be split into two micro-ops further down the pipeline
// after the decode stage. Once dispatched, micro-ops wait for their operands
// and issue out-of-order to one of thirteen issue pipelines. Each issue
// pipeline can accept one micro-op per cycle.

let SchedModel = NeoverseN2Model in {

// Define the (13) issue ports.
def N2UnitB   : ProcResource<2>;  // Branch 0/1
def N2UnitS   : ProcResource<2>;  // Integer single Cycle 0/1
def N2UnitM0  : ProcResource<1>;  // Integer multicycle 0
def N2UnitM1  : ProcResource<1>;  // Integer multicycle 1
def N2UnitL01 : ProcResource<2>;  // Load/Store 0/1
def N2UnitL2  : ProcResource<1>;  // Load 2
def N2UnitD   : ProcResource<2>;  // Store data 0/1
def N2UnitV0  : ProcResource<1>;  // FP/ASIMD 0
def N2UnitV1  : ProcResource<1>;  // FP/ASIMD 1

def N2UnitV : ProcResGroup<[N2UnitV0, N2UnitV1]>;  // FP/ASIMD 0/1
def N2UnitM : ProcResGroup<[N2UnitM0, N2UnitM1]>;  // Integer single/multicycle 0/1
def N2UnitL : ProcResGroup<[N2UnitL01, N2UnitL2]>; // Load/Store 0/1 and Load 2
def N2UnitI : ProcResGroup<[N2UnitS, N2UnitM0, N2UnitM1]>; // Integer single cycle 0/1 and single/multicycle 0/1

// No forwarding is provided for these types.
def : ReadAdvance<ReadI,       0>;

def : WriteRes<WriteLDHi,    []> { let Latency = 4; }

// Define customized scheduler read/write types specific to the Neoverse N2.

// Define generic 1 micro-op types
def N2Write_1cyc_1B   : SchedWriteRes<[N2UnitB]>   { let Latency = 1; }
def N2Write_1cyc_1I   : SchedWriteRes<[N2UnitI]>   { let Latency = 1; }
def N2Write_1cyc_1M   : SchedWriteRes<[N2UnitM]>   { let Latency = 1; }

def N2Write_20cyc_1M0 : SchedWriteRes<[N2UnitM0]>  { let Latency = 20;
                                                     let ResourceCycles = [20]; }
// SDIV, UDIV
// 1. Integer divides are performed using an iterative algorithm and block any subsequent divide operations until complete. Early termination is possible, depending upon the data values.
def : SchedAlias<WriteID32,  N2Write_12cyc_1M0>;
def : SchedAlias<WriteID64,  N2Write_20cyc_1M0>;

def : WriteRes<WriteIM32, [N2UnitM]> { let Latency = 2; }
def : WriteRes<WriteIM64, [N2UnitM]> { let Latency = 2; }

// Define generic 2 micro-op types

def N2Write_6cyc_1M0_1B : SchedWriteRes<[N2UnitM0, N2UnitB]> {
  let Latency     = 6;
  let NumMicroOps = 2;
}

// Branch and link, register, with pointer authentication
// Branch, register, with pointer authentication
// Branch, return, with pointer authentication
def : InstRW<[N2Write_6cyc_1M0_1B], (instrs BLRAA, BLRAAZ, BLRAB, BLRABZ, BRAA,
                                            BRAAZ, BRAB, BRABZ, RETAA, RETAB,
                                            ERETAA, ERETAB)>;
// 6 1 M0,B

// Define generic 27 micro-op types

def N2Write_11cyc_9L01_9S_9V : SchedWriteRes<[N2UnitL01, N2UnitL01, N2UnitL01,
                                              N2UnitL01, N2UnitL01, N2UnitL01,
                                              N2UnitL01, N2UnitL01, N2UnitL01,
                                              N2UnitS, N2UnitS, N2UnitS,
                                              N2UnitS, N2UnitS, N2UnitS,
                                              N2UnitS, N2UnitS, N2UnitS,
                                              N2UnitV, N2UnitV, N2UnitV,
                                              N2UnitV, N2UnitV, N2UnitV,
                                              N2UnitV, N2UnitV, N2UnitV]> {
  let Latency     = 11;
  let NumMicroOps = 27;
}

// Contiguous store four structures from four vectors, scalar + scalar
def : InstRW<[N2Write_11cyc_9L01_9S_9V], (instrs ST4H)>;
// 11 1/9 L01,S,V
```
