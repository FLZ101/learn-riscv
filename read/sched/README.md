```cpp
// PreRA instruction scheduling.
addPass(&MachineSchedulerID);
```

```cpp
/// MachineScheduler runs after coalescing and before register allocation.
class MachineScheduler : public MachineSchedulerBase {
}
```

```cpp
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
```

```cpp
/// PostMachineScheduler runs after shortly before code emission.
class PostMachineScheduler : public MachineSchedulerBase {
}
```

```cpp
class PostRAScheduler : public MachineFunctionPass {
}
```
