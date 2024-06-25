
## pass manager

```cpp
```

## clang/lib/CodeGen/BackendUtil.cpp

```cpp
void EmitAssemblyHelper::EmitAssembly(BackendAction Action,
                                      std::unique_ptr<raw_pwrite_stream> OS) {
  bool RequiresCodeGen = actionRequiresCodeGen(Action);
  CreateTargetMachine(RequiresCodeGen);

  if (RequiresCodeGen && !TM)
    return;
  if (TM)
    TheModule->setDataLayout(TM->createDataLayout());

  RunOptimizationPipeline(Action, OS, ThinLinkOS);
  RunCodegenPipeline(Action, OS, DwoOS);
}

void EmitAssemblyHelper::RunOptimizationPipeline(
    BackendAction Action, std::unique_ptr<raw_pwrite_stream> &OS,
    std::unique_ptr<llvm::ToolOutputFile> &ThinLinkOS) {

  LoopAnalysisManager LAM;
  FunctionAnalysisManager FAM;
  CGSCCAnalysisManager CGAM;
  ModuleAnalysisManager MAM;

  PassBuilder PB(TM.get(), PTO, PGOOpt, &PIC);

  // Register the target library analysis directly and give it a customized
  // preset TLI.
  std::unique_ptr<TargetLibraryInfoImpl> TLII(
      createTLII(TargetTriple, CodeGenOpts));
  FAM.registerPass([&] { return TargetLibraryAnalysis(*TLII); });

  // Register all the basic analyses with the managers.
  PB.registerModuleAnalyses(MAM);
  PB.registerCGSCCAnalyses(CGAM);
  PB.registerFunctionAnalyses(FAM);
  PB.registerLoopAnalyses(LAM);
  PB.crossRegisterProxies(LAM, FAM, CGAM, MAM);

  ModulePassManager MPM;

  if (!CodeGenOpts.DisableLLVMPasses) {
    if (CodeGenOpts.OptimizationLevel == 0) {
      MPM = PB.buildO0DefaultPipeline(Level, IsLTO || IsThinLTO);
    } else if (IsThinLTO) {
      MPM = PB.buildThinLTOPreLinkDefaultPipeline(Level);
    } else if (IsLTO) {
      MPM = PB.buildLTOPreLinkDefaultPipeline(Level);
    } else {
      MPM = PB.buildPerModuleDefaultPipeline(Level);
    }
  }

  switch (Action) {
  case Backend_EmitBC:
    if (CodeGenOpts.PrepareForThinLTO && !CodeGenOpts.DisableLLVMPasses) {
      MPM.addPass(ThinLTOBitcodeWriterPass(*OS, ThinLinkOS ? &ThinLinkOS->os()
                                                           : nullptr));
    } else {
      MPM.addPass(
          BitcodeWriterPass(*OS, CodeGenOpts.EmitLLVMUseLists, EmitLTOSummary));
    }
    break;
  case Backend_EmitLL:
    MPM.addPass(PrintModulePass(*OS, "", CodeGenOpts.EmitLLVMUseLists));
    break;
  }

  MPM.run(*TheModule, MAM);
}

void EmitAssemblyHelper::RunCodegenPipeline(
    BackendAction Action, std::unique_ptr<raw_pwrite_stream> &OS,
    std::unique_ptr<llvm::ToolOutputFile> &DwoOS) {
  // We still use the legacy PM to run the codegen pipeline since the new PM
  // does not work with the codegen pipeline.
  legacy::PassManager CodeGenPasses;

  switch (Action) {
  case Backend_EmitAssembly:
  case Backend_EmitMCNull:
  case Backend_EmitObj:
    CodeGenPasses.add(
        createTargetTransformInfoWrapperPass(getTargetIRAnalysis()));
    AddEmitPasses(CodeGenPasses, Action, *OS, DwoOS ? &DwoOS->os() : nullptr);
    break;
  default:
    return;
  }

  CodeGenPasses.run(*TheModule);
}

bool EmitAssemblyHelper::AddEmitPasses(legacy::PassManager &CodeGenPasses,
                                       BackendAction Action,
                                       raw_pwrite_stream &OS,
                                       raw_pwrite_stream *DwoOS) {
  // Add LibraryInfo.
  std::unique_ptr<TargetLibraryInfoImpl> TLII(
      createTLII(TargetTriple, CodeGenOpts));
  CodeGenPasses.add(new TargetLibraryInfoWrapperPass(*TLII));

  TM->addPassesToEmitFile(CodeGenPasses, OS, DwoOS, CGFT, /*DisableVerify=*/!CodeGenOpts.VerifyModule)
}
```

## llvm/lib/CodeGen/LLVMTargetMachine.cpp

```cpp
bool LLVMTargetMachine::addPassesToEmitFile(
    PassManagerBase &PM, raw_pwrite_stream &Out, raw_pwrite_stream *DwoOut,
    CodeGenFileType FileType, bool DisableVerify,
    MachineModuleInfoWrapperPass *MMIWP) {
  if (!MMIWP)
    MMIWP = new MachineModuleInfoWrapperPass(this);
  TargetPassConfig *PassConfig =
      addPassesToGenerateCode(*this, PM, DisableVerify, *MMIWP);
  if (!PassConfig)
    return true;

  if (TargetPassConfig::willCompleteCodeGenPipeline()) {
    if (addAsmPrinter(PM, Out, DwoOut, FileType, MMIWP->getMMI().getContext()))
      return true;
  } else {
    // MIR printing is redundant with -filetype=null.
    if (FileType != CGFT_Null)
      PM.add(createPrintMIRPass(Out));
  }

  PM.add(createFreeMachineFunctionPass());
  return false;
}

bool LLVMTargetMachine::addAsmPrinter(PassManagerBase &PM,
                                      raw_pwrite_stream &Out,
                                      raw_pwrite_stream *DwoOut,
                                      CodeGenFileType FileType,
                                      MCContext &Context) {
  Expected<std::unique_ptr<MCStreamer>> MCStreamerOrErr =
      createMCStreamer(Out, DwoOut, FileType, Context);
  if (auto Err = MCStreamerOrErr.takeError())
    return true;

  // Create the AsmPrinter, which takes ownership of AsmStreamer if successful.
  FunctionPass *Printer =
      getTarget().createAsmPrinter(*this, std::move(*MCStreamerOrErr));
  if (!Printer)
    return true;

  PM.add(Printer);
  return false;
}

static TargetPassConfig *
addPassesToGenerateCode(LLVMTargetMachine &TM, PassManagerBase &PM,
                        bool DisableVerify,
                        MachineModuleInfoWrapperPass &MMIWP) {
  // Targets may override createPassConfig to provide a target-specific
  // subclass.
  TargetPassConfig *PassConfig = TM.createPassConfig(PM);
  // Set PassConfig options provided by TargetMachine.
  PassConfig->setDisableVerify(DisableVerify);
  PM.add(PassConfig);
  PM.add(&MMIWP);

  if (PassConfig->addISelPasses())
    return nullptr;
  PassConfig->addMachinePasses();
  PassConfig->setInitialized();
  return PassConfig;
}

bool TargetPassConfig::addISelPasses() {
  if (TM->useEmulatedTLS())
    addPass(createLowerEmuTLSPass());

  addPass(createPreISelIntrinsicLoweringPass());
  PM->add(createTargetTransformInfoWrapperPass(TM->getTargetIRAnalysis()));
  addIRPasses();
  addCodeGenPrepare();
  addPassesToHandleExceptions();
  addISelPrepare();

  return addCoreISelPasses();
}

bool TargetPassConfig::addCoreISelPasses() {
  // Enable FastISel with -fast-isel, but allow that to be overridden.
  TM->setO0WantsFastISel(EnableFastISelOption != cl::BOU_FALSE);

  // Determine an instruction selector.
  enum class SelectorType { SelectionDAG, FastISel, GlobalISel };
  SelectorType Selector;

  if (EnableFastISelOption == cl::BOU_TRUE)
    Selector = SelectorType::FastISel;
  else if (EnableGlobalISelOption == cl::BOU_TRUE ||
           (TM->Options.EnableGlobalISel &&
            EnableGlobalISelOption != cl::BOU_FALSE))
    Selector = SelectorType::GlobalISel;
  else if (TM->getOptLevel() == CodeGenOpt::None && TM->getO0WantsFastISel())
    Selector = SelectorType::FastISel;
  else
    Selector = SelectorType::SelectionDAG;

  // Add instruction selector passes.
  if (Selector == SelectorType::GlobalISel) {
    if (addIRTranslator())
      return true;

    addPreLegalizeMachineIR();

    if (addLegalizeMachineIR())
      return true;

    // Before running the register bank selector, ask the target if it
    // wants to run some passes.
    addPreRegBankSelect();

    if (addRegBankSelect())
      return true;

    addPreGlobalInstructionSelect();

    if (addGlobalInstructionSelect())
      return true;

    // Pass to reset the MachineFunction if the ISel failed.
    addPass(createResetMachineFunctionPass(
        reportDiagnosticWhenGlobalISelFallback(), isGlobalISelAbortEnabled()));

    // Provide a fallback path when we do not want to abort on
    // not-yet-supported input.
    if (!isGlobalISelAbortEnabled() && addInstSelector())
      return true;

  } else if (addInstSelector())
    return true;

  // Expand pseudo-instructions emitted by ISel. Don't run the verifier before
  // FinalizeISel.
  addPass(&FinalizeISelID);
  return false;
}

void TargetPassConfig::addMachinePasses() {
  AddingMachinePasses = true;

  // Add passes that optimize machine instructions in SSA form.
  if (getOptLevel() != CodeGenOpt::None) {
    addMachineSSAOptimization();
  } else {
    // If the target requests it, assign local variables to stack slots relative
    // to one another and simplify frame index references where possible.
    addPass(&LocalStackSlotAllocationID);
  }

  if (TM->Options.EnableIPRA)
    addPass(createRegUsageInfoPropPass());

  // Run pre-ra passes.
  addPreRegAlloc();

  // Debugifying the register allocator passes seems to provoke some
  // non-determinism that affects CodeGen and there doesn't seem to be a point
  // where it becomes safe again so stop debugifying here.
  DebugifyIsSafe = false;

  // Run register allocation and passes that are tightly coupled with it,
  // including phi elimination and scheduling.
  if (getOptimizeRegAlloc())
    addOptimizedRegAlloc();
  else
    addFastRegAlloc();

  // Run post-ra passes.
  addPostRegAlloc();

  addPass(&RemoveRedundantDebugValuesID);

  addPass(&FixupStatepointCallerSavedID);

  // Insert prolog/epilog code.  Eliminate abstract frame index references...
  if (getOptLevel() != CodeGenOpt::None) {
    addPass(&PostRAMachineSinkingID);
    addPass(&ShrinkWrapID);
  }

  // Prolog/Epilog inserter needs a TargetMachine to instantiate. But only
  // do so if it hasn't been disabled, substituted, or overridden.
  if (!isPassSubstitutedOrOverridden(&PrologEpilogCodeInserterID))
      addPass(createPrologEpilogInserterPass());

  /// Add passes that optimize machine instructions after register allocation.
  if (getOptLevel() != CodeGenOpt::None)
    addMachineLateOptimization();

  // Expand pseudo instructions before second scheduling pass.
  addPass(&ExpandPostRAPseudosID);

  // Run pre-sched2 passes.
  addPreSched2();

  if (EnableImplicitNullChecks)
    addPass(&ImplicitNullChecksID);

  // Second pass scheduler.
  // Let Target optionally insert this pass by itself at some other
  // point.
  if (getOptLevel() != CodeGenOpt::None &&
      !TM->targetSchedulesPostRAScheduling()) {
    if (MISchedPostRA)
      addPass(&PostMachineSchedulerID);
    else
      addPass(&PostRASchedulerID);
  }

  // GC
  if (addGCPasses()) {
    if (PrintGCInfo)
      addPass(createGCInfoPrinter(dbgs()));
  }

  // Basic block placement.
  if (getOptLevel() != CodeGenOpt::None)
    addBlockPlacement();

  // Insert before XRay Instrumentation.
  addPass(&FEntryInserterID);

  addPass(&XRayInstrumentationID);
  addPass(&PatchableFunctionID);

  addPreEmitPass();

  if (TM->Options.EnableIPRA)
    // Collect register usage information and produce a register mask of
    // clobbered registers, to be used to optimize call sites.
    addPass(createRegUsageInfoCollector());

  addPass(&FuncletLayoutID);

  addPass(&StackMapLivenessID);
  addPass(&LiveDebugValuesID);

  if (TM->Options.EnableMachineOutliner && getOptLevel() != CodeGenOpt::None &&
      EnableMachineOutliner != RunOutliner::NeverOutline) {
    bool RunOnAllFunctions =
        (EnableMachineOutliner == RunOutliner::AlwaysOutline);
    bool AddOutliner =
        RunOnAllFunctions || TM->Options.SupportsDefaultOutlining;
    if (AddOutliner)
      addPass(createMachineOutlinerPass(RunOnAllFunctions));
  }

  // Machine function splitter uses the basic block sections feature. Both
  // cannot be enabled at the same time. Basic block sections takes precedence.
  // FIXME: In principle, BasicBlockSection::Labels and splitting can used
  // together. Update this check once we have addressed any issues.
  if (TM->getBBSectionsType() != llvm::BasicBlockSection::None) {
    if (TM->getBBSectionsType() == llvm::BasicBlockSection::List) {
      addPass(llvm::createBasicBlockSectionsProfileReaderPass(
          TM->getBBSectionsFuncListBuf()));
    }
    addPass(llvm::createBasicBlockSectionsPass());
  } else if (TM->Options.EnableMachineFunctionSplitter ||
             EnableMachineFunctionSplitter) {
    addPass(createMachineFunctionSplitterPass());
  }

  if (!DisableCFIFixup && TM->Options.EnableCFIFixup)
    addPass(createCFIFixup());

  // Add passes that directly emit MI after all other MI passes.
  addPreEmitPass2();

  AddingMachinePasses = false;
}

bool TargetPassConfig::addRegAssignAndRewriteFast() {
  addPass(createRegAllocPass(false));

  // Allow targets to change the register assignments after
  // fast register allocation.
  addPostFastRegAllocRewrite();
  return true;
}

/// Add the minimum set of target-independent passes that are required for
/// register allocation. No coalescing or scheduling.
void TargetPassConfig::addFastRegAlloc() {
  addPass(&PHIEliminationID);
  addPass(&TwoAddressInstructionPassID);

  addRegAssignAndRewriteFast();
}

/// Add standard target-independent passes that are tightly coupled with
/// optimized register allocation, including coalescing, machine instruction
/// scheduling, and register allocation itself.
void TargetPassConfig::addOptimizedRegAlloc() {
  addPass(&DetectDeadLanesID);

  addPass(&ProcessImplicitDefsID);

  // LiveVariables currently requires pure SSA form.
  //
  // FIXME: Once TwoAddressInstruction pass no longer uses kill flags,
  // LiveVariables can be removed completely, and LiveIntervals can be directly
  // computed. (We still either need to regenerate kill flags after regalloc, or
  // preferably fix the scavenger to not depend on them).
  // FIXME: UnreachableMachineBlockElim is a dependant pass of LiveVariables.
  // When LiveVariables is removed this has to be removed/moved either.
  // Explicit addition of UnreachableMachineBlockElim allows stopping before or
  // after it with -stop-before/-stop-after.
  addPass(&UnreachableMachineBlockElimID);
  addPass(&LiveVariablesID);

  // Edge splitting is smarter with machine loop info.
  addPass(&MachineLoopInfoID);
  addPass(&PHIEliminationID);

  // Eventually, we want to run LiveIntervals before PHI elimination.
  if (EarlyLiveIntervals)
    addPass(&LiveIntervalsID);

  addPass(&TwoAddressInstructionPassID);
  addPass(&RegisterCoalescerID);

  // The machine scheduler may accidentally create disconnected components
  // when moving subregister definitions around, avoid this by splitting them to
  // separate vregs before. Splitting can also improve reg. allocation quality.
  addPass(&RenameIndependentSubregsID);

  // PreRA instruction scheduling.
  addPass(&MachineSchedulerID);

  if (addRegAssignAndRewriteOptimized()) {
    // Perform stack slot coloring and post-ra machine LICM.
    addPass(&StackSlotColoringID);

    // Allow targets to expand pseudo instructions depending on the choice of
    // registers before MachineCopyPropagation.
    addPostRewrite();

    // Copy propagate to forward register uses and try to eliminate COPYs that
    // were not coalesced.
    addPass(&MachineCopyPropagationID);

    // Run post-ra machine LICM to hoist reloads / remats.
    //
    // FIXME: can this move into MachineLateOptimization?
    addPass(&MachineLICMID);
  }
}

bool TargetPassConfig::addRegAssignAndRewriteOptimized() {
  // Add the selected register allocation pass.
  addPass(createRegAllocPass(true));

  // Allow targets to change the register assignments before rewriting.
  addPreRewrite();

  // Finally rewrite virtual registers.
  addPass(&VirtRegRewriterID);

  // Regalloc scoring for ML-driven eviction - noop except when learning a new
  // eviction policy.
  addPass(createRegAllocScoringPass());
  return true;
}

/// Add passes that optimize machine instructions after register allocation.
void TargetPassConfig::addMachineLateOptimization() {
  // Branch folding must be run after regalloc and prolog/epilog insertion.
  addPass(&BranchFolderPassID);

  // Tail duplication.
  // Note that duplicating tail just increases code size and degrades
  // performance for targets that require Structured Control Flow.
  // In addition it can also make CFG irreducible. Thus we disable it.
  if (!TM->requiresStructuredCFG())
    addPass(&TailDuplicateID);

  // Copy propagation.
  addPass(&MachineCopyPropagationID);
}

/// Add passes that optimize machine instructions in SSA form.
void TargetPassConfig::addMachineSSAOptimization() {
  // Pre-ra tail duplication.
  addPass(&EarlyTailDuplicateID);

  // Optimize PHIs before DCE: removing dead PHI cycles may make more
  // instructions dead.
  addPass(&OptimizePHIsID);

  // This pass merges large allocas. StackSlotColoring is a different pass
  // which merges spill slots.
  addPass(&StackColoringID);

  // If the target requests it, assign local variables to stack slots relative
  // to one another and simplify frame index references where possible.
  addPass(&LocalStackSlotAllocationID);

  // With optimization, dead code should already be eliminated. However
  // there is one known exception: lowered code for arguments that are only
  // used by tail calls, where the tail calls reuse the incoming stack
  // arguments directly (see t11 in test/CodeGen/X86/sibcall.ll).
  addPass(&DeadMachineInstructionElimID);

  // Allow targets to insert passes that improve instruction level parallelism,
  // like if-conversion. Such passes will typically need dominator trees and
  // loop info, just like LICM and CSE below.
  addILPOpts();

  addPass(&EarlyMachineLICMID);
  addPass(&MachineCSEID);

  addPass(&MachineSinkingID);

  addPass(&PeepholeOptimizerID);
  // Clean-up the dead code that may have been generated by peephole
  // rewriting.
  addPass(&DeadMachineInstructionElimID);
}
```

### llvm/lib/Target/AArch64/AArch64TargetMachine.cpp

```cpp
void AArch64PassConfig::addIRPasses() {
  // Always expand atomic operations, we don't deal with atomicrmw or cmpxchg
  // ourselves.
  addPass(createAtomicExpandPass());

  // Expand any SVE vector library calls that we can't code generate directly.
  if (EnableSVEIntrinsicOpts && TM->getOptLevel() == CodeGenOpt::Aggressive)
    addPass(createSVEIntrinsicOptsPass());

  // Cmpxchg instructions are often used with a subsequent comparison to
  // determine whether it succeeded. We can exploit existing control-flow in
  // ldrex/strex loops to simplify this, but it needs tidying up.
  if (TM->getOptLevel() != CodeGenOpt::None && EnableAtomicTidy)
    addPass(createCFGSimplificationPass(SimplifyCFGOptions()
                                            .forwardSwitchCondToPhi(true)
                                            .convertSwitchRangeToICmp(true)
                                            .convertSwitchToLookupTable(true)
                                            .needCanonicalLoops(false)
                                            .hoistCommonInsts(true)
                                            .sinkCommonInsts(true)));

  // Run LoopDataPrefetch
  //
  // Run this before LSR to remove the multiplies involved in computing the
  // pointer values N iterations ahead.
  if (TM->getOptLevel() != CodeGenOpt::None) {
    if (EnableLoopDataPrefetch)
      addPass(createLoopDataPrefetchPass());
    if (EnableFalkorHWPFFix)
      addPass(createFalkorMarkStridedAccessesPass());
  }

  if (TM->getOptLevel() == CodeGenOpt::Aggressive && EnableGEPOpt) {
    // Call SeparateConstOffsetFromGEP pass to extract constants within indices
    // and lower a GEP with multiple indices to either arithmetic operations or
    // multiple GEPs with single index.
    addPass(createSeparateConstOffsetFromGEPPass(true));
    // Call EarlyCSE pass to find and remove subexpressions in the lowered
    // result.
    addPass(createEarlyCSEPass());
    // Do loop invariant code motion in case part of the lowered result is
    // invariant.
    addPass(createLICMPass());
  }

  TargetPassConfig::addIRPasses();

  addPass(createAArch64StackTaggingPass(
      /*IsOptNone=*/TM->getOptLevel() == CodeGenOpt::None));

  // Match interleaved memory accesses to ldN/stN intrinsics.
  if (TM->getOptLevel() != CodeGenOpt::None) {
    addPass(createInterleavedLoadCombinePass());
    addPass(createInterleavedAccessPass());
  }

  // Add Control Flow Guard checks.
  if (TM->getTargetTriple().isOSWindows())
    addPass(createCFGuardCheckPass());

  if (TM->Options.JMCInstrument)
    addPass(createJMCInstrumenterPass());
}

// Pass Pipeline Configuration
bool AArch64PassConfig::addPreISel() {
  // Run promote constant before global merge, so that the promoted constants
  // get a chance to be merged
  if (TM->getOptLevel() != CodeGenOpt::None && EnablePromoteConstant)
    addPass(createAArch64PromoteConstantPass());
  // FIXME: On AArch64, this depends on the type.
  // Basically, the addressable offsets are up to 4095 * Ty.getSizeInBytes().
  // and the offset has to be a multiple of the related size in bytes.
  if ((TM->getOptLevel() != CodeGenOpt::None &&
       EnableGlobalMerge == cl::BOU_UNSET) ||
      EnableGlobalMerge == cl::BOU_TRUE) {
    bool OnlyOptimizeForSize = (TM->getOptLevel() < CodeGenOpt::Aggressive) &&
                               (EnableGlobalMerge == cl::BOU_UNSET);

    // Merging of extern globals is enabled by default on non-Mach-O as we
    // expect it to be generally either beneficial or harmless. On Mach-O it
    // is disabled as we emit the .subsections_via_symbols directive which
    // means that merging extern globals is not safe.
    bool MergeExternalByDefault = !TM->getTargetTriple().isOSBinFormatMachO();

    // FIXME: extern global merging is only enabled when we optimise for size
    // because there are some regressions with it also enabled for performance.
    if (!OnlyOptimizeForSize)
      MergeExternalByDefault = false;

    addPass(createGlobalMergePass(TM, 4095, OnlyOptimizeForSize,
                                  MergeExternalByDefault));
  }

  return false;
}

void AArch64PassConfig::addCodeGenPrepare() {
  if (getOptLevel() != CodeGenOpt::None)
    addPass(createTypePromotionPass());
  TargetPassConfig::addCodeGenPrepare();
}

bool AArch64PassConfig::addInstSelector() {
  addPass(createAArch64ISelDag(getAArch64TargetMachine(), getOptLevel()));

  // For ELF, cleanup any local-dynamic TLS accesses (i.e. combine as many
  // references to _TLS_MODULE_BASE_ as possible.
  if (TM->getTargetTriple().isOSBinFormatELF() &&
      getOptLevel() != CodeGenOpt::None)
    addPass(createAArch64CleanupLocalDynamicTLSPass());

  return false;
}

bool AArch64PassConfig::addIRTranslator() {
  addPass(new IRTranslator(getOptLevel()));
  return false;
}

void AArch64PassConfig::addPreLegalizeMachineIR() {
  if (getOptLevel() == CodeGenOpt::None)
    addPass(createAArch64O0PreLegalizerCombiner());
  else {
    addPass(createAArch64PreLegalizerCombiner());
    if (EnableGISelLoadStoreOptPreLegal)
      addPass(new LoadStoreOpt());
  }
}

bool AArch64PassConfig::addLegalizeMachineIR() {
  addPass(new Legalizer());
  return false;
}

void AArch64PassConfig::addPreRegBankSelect() {
  bool IsOptNone = getOptLevel() == CodeGenOpt::None;
  if (!IsOptNone) {
    addPass(createAArch64PostLegalizerCombiner(IsOptNone));
    if (EnableGISelLoadStoreOptPostLegal)
      addPass(new LoadStoreOpt());
  }
  addPass(createAArch64PostLegalizerLowering());
}

bool AArch64PassConfig::addRegBankSelect() {
  addPass(new RegBankSelect());
  return false;
}

void AArch64PassConfig::addPreGlobalInstructionSelect() {
  addPass(new Localizer());
}

bool AArch64PassConfig::addGlobalInstructionSelect() {
  addPass(new InstructionSelect(getOptLevel()));
  if (getOptLevel() != CodeGenOpt::None)
    addPass(createAArch64PostSelectOptimize());
  return false;
}

void AArch64PassConfig::addMachineSSAOptimization() {
  // Run default MachineSSAOptimization first.
  TargetPassConfig::addMachineSSAOptimization();

  if (TM->getOptLevel() != CodeGenOpt::None)
    addPass(createAArch64MIPeepholeOptPass());
}

bool AArch64PassConfig::addILPOpts() {
  if (EnableCondOpt)
    addPass(createAArch64ConditionOptimizerPass());
  if (EnableCCMP)
    addPass(createAArch64ConditionalCompares());
  if (EnableMCR)
    addPass(&MachineCombinerID);
  if (EnableCondBrTuning)
    addPass(createAArch64CondBrTuning());
  if (EnableEarlyIfConversion)
    addPass(&EarlyIfConverterID);
  if (EnableStPairSuppress)
    addPass(createAArch64StorePairSuppressPass());
  addPass(createAArch64SIMDInstrOptPass());
  if (TM->getOptLevel() != CodeGenOpt::None)
    addPass(createAArch64StackTaggingPreRAPass());
  return true;
}

void AArch64PassConfig::addPreRegAlloc() {
  // Change dead register definitions to refer to the zero register.
  if (TM->getOptLevel() != CodeGenOpt::None && EnableDeadRegisterElimination)
    addPass(createAArch64DeadRegisterDefinitions());

  // Use AdvSIMD scalar instructions whenever profitable.
  if (TM->getOptLevel() != CodeGenOpt::None && EnableAdvSIMDScalar) {
    addPass(createAArch64AdvSIMDScalar());
    // The AdvSIMD pass may produce copies that can be rewritten to
    // be register coalescer friendly.
    addPass(&PeepholeOptimizerID);
  }
}

void AArch64PassConfig::addPostRegAlloc() {
  // Remove redundant copy instructions.
  if (TM->getOptLevel() != CodeGenOpt::None && EnableRedundantCopyElimination)
    addPass(createAArch64RedundantCopyEliminationPass());

  if (TM->getOptLevel() != CodeGenOpt::None && usingDefaultRegAlloc())
    // Improve performance for some FP/SIMD code for A57.
    addPass(createAArch64A57FPLoadBalancing());
}

void AArch64PassConfig::addPreSched2() {
  // Lower homogeneous frame instructions
  if (EnableHomogeneousPrologEpilog)
    addPass(createAArch64LowerHomogeneousPrologEpilogPass());
  // Expand some pseudo instructions to allow proper scheduling.
  addPass(createAArch64ExpandPseudoPass());
  // Use load/store pair instructions when possible.
  if (TM->getOptLevel() != CodeGenOpt::None) {
    if (EnableLoadStoreOpt)
      addPass(createAArch64LoadStoreOptimizationPass());
  }

  // The AArch64SpeculationHardeningPass destroys dominator tree and natural
  // loop info, which is needed for the FalkorHWPFFixPass and also later on.
  // Therefore, run the AArch64SpeculationHardeningPass before the
  // FalkorHWPFFixPass to avoid recomputing dominator tree and natural loop
  // info.
  addPass(createAArch64SpeculationHardeningPass());

  addPass(createAArch64IndirectThunks());
  addPass(createAArch64SLSHardeningPass());

  if (TM->getOptLevel() != CodeGenOpt::None) {
    if (EnableFalkorHWPFFix)
      addPass(createFalkorHWPFFixPass());
  }
}

void AArch64PassConfig::addPreEmitPass() {
  // Machine Block Placement might have created new opportunities when run
  // at O3, where the Tail Duplication Threshold is set to 4 instructions.
  // Run the load/store optimizer once more.
  if (TM->getOptLevel() >= CodeGenOpt::Aggressive && EnableLoadStoreOpt)
    addPass(createAArch64LoadStoreOptimizationPass());

  if (TM->getOptLevel() >= CodeGenOpt::Aggressive &&
      EnableAArch64CopyPropagation)
    addPass(createMachineCopyPropagationPass(true));

  addPass(createAArch64A53Fix835769());

  if (EnableBranchTargets)
    addPass(createAArch64BranchTargetsPass());

  // Relax conditional branch instructions if they're otherwise out of
  // range of their destination.
  if (BranchRelaxation)
    addPass(&BranchRelaxationPassID);

  if (TM->getTargetTriple().isOSWindows()) {
    // Identify valid longjmp targets for Windows Control Flow Guard.
    addPass(createCFGuardLongjmpPass());
    // Identify valid eh continuation targets for Windows EHCont Guard.
    addPass(createEHContGuardCatchretPass());
  }

  if (TM->getOptLevel() != CodeGenOpt::None && EnableCompressJumpTables)
    addPass(createAArch64CompressJumpTablesPass());

  if (TM->getOptLevel() != CodeGenOpt::None && EnableCollectLOH &&
      TM->getTargetTriple().isOSBinFormatMachO())
    addPass(createAArch64CollectLOHPass());
}

void AArch64PassConfig::addPreEmitPass2() {
  // SVE bundles move prefixes with destructive operations. BLR_RVMARKER pseudo
  // instructions are lowered to bundles as well.
  addPass(createUnpackMachineBundles(nullptr));
}
```

```cpp
// llvm/lib/Target/AArch64/AArch64ISelDAGToDAG.cpp

/// createAArch64ISelDag - This pass converts a legalized DAG into a
/// AArch64-specific DAG, ready for instruction scheduling.
FunctionPass *llvm::createAArch64ISelDag(AArch64TargetMachine &TM,
                                         CodeGenOpt::Level OptLevel) {
  return new AArch64DAGToDAGISel(TM, OptLevel);
}
```
