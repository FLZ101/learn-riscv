## `-mcpu=native`

```cpp
// clang/lib/Driver/ToolChains/CommonArgs.cpp

std::string tools::getCPUName(const Driver &D, const ArgList &Args,
                              const llvm::Triple &T, bool FromAs) {

  switch (T.getArch()) {
  default:
    return "";

  case llvm::Triple::aarch64:
  case llvm::Triple::aarch64_32:
  case llvm::Triple::aarch64_be:
    return aarch64::getAArch64TargetCPU(Args, T, A);

  case llvm::Triple::riscv32:
  case llvm::Triple::riscv64:
    if (const Arg *A = Args.getLastArg(options::OPT_mcpu_EQ))
      return A->getValue();
    return "";

  case llvm::Triple::x86:
  case llvm::Triple::x86_64:
    return x86::getX86TargetCPU(D, Args, T);
}
```

```cpp
// clang/lib/Driver/ToolChains/Arch/AArch64.cpp

std::string aarch64::getAArch64TargetCPU(const ArgList &Args,
                                         const llvm::Triple &Triple, Arg *&A) {
  std::string CPU;
  // If we have -mcpu, use that.
  if ((A = Args.getLastArg(options::OPT_mcpu_EQ))) {
    StringRef Mcpu = A->getValue();
    CPU = Mcpu.split("+").first.lower();
  }

  // Handle CPU name is 'native'.
  if (CPU == "native")
    return std::string(llvm::sys::getHostCPUName());

  if (CPU.size())
    return CPU;

  if (Triple.isTargetMachineMac() &&
      Triple.getArch() == llvm::Triple::aarch64) {
    // Apple Silicon macs default to M1 CPUs.
    return "apple-m1";
  }

  // arm64e requires v8.3a and only runs on apple-a12 and later CPUs.
  if (Triple.isArm64e())
    return "apple-a12";

  // Make sure we pick the appropriate Apple CPU if -arch is used or when
  // targetting a Darwin OS.
  if (Args.getLastArg(options::OPT_arch) || Triple.isOSDarwin())
    return Triple.getArch() == llvm::Triple::aarch64_32 ? "apple-s4"
                                                        : "apple-a7";

  return "generic";
}
```

```cpp
// llvm/lib/Support/Host.cpp

#elif defined(__linux__) && (defined(__arm__) || defined(__aarch64__))
StringRef sys::getHostCPUName() {
  std::unique_ptr<llvm::MemoryBuffer> P = getProcCpuinfoContent();
  StringRef Content = P ? P->getBuffer() : "";
  return detail::getHostCPUNameForARM(Content);
}

StringRef sys::detail::getHostCPUNameForARM(StringRef ProcCpuinfoContent) {
  // The cpuid register on arm is not accessible from user space. On Linux,
  // it is exposed through the /proc/cpuinfo file.

  // Read 32 lines from /proc/cpuinfo, which should contain the CPU part line
  // in all cases.
  SmallVector<StringRef, 32> Lines;
  ProcCpuinfoContent.split(Lines, "\n");

  // Look for the CPU implementer line.
  StringRef Implementer;
  StringRef Hardware;
  StringRef Part;
  for (unsigned I = 0, E = Lines.size(); I != E; ++I) {
    if (Lines[I].startswith("CPU implementer"))
      Implementer = Lines[I].substr(15).ltrim("\t :");
    if (Lines[I].startswith("Hardware"))
      Hardware = Lines[I].substr(8).ltrim("\t :");
    if (Lines[I].startswith("CPU part"))
      Part = Lines[I].substr(8).ltrim("\t :");
  }

  if (Implementer == "0x46") { // Fujitsu Ltd.
    return StringSwitch<const char *>(Part)
      .Case("0x001", "a64fx")
      .Default("generic");
  }
}
```
