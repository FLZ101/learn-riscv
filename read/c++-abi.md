>  https://itanium-cxx-abi.github.io/cxx-abi/abi.html

## Exception Handling

**landing pad**: A section of user code intended to catch, or otherwise clean up after, an exception. It gains control from the exception runtime via the personality routine, and after doing the appropriate processing either merges into the normal user code or returns to the runtime by resuming or raising a new exception.

### Base ABI

This section defines the Unwind Library interface, expected to be provided by any Itanium psABI-compliant system. This is the interface on which the C++ ABI exception-handling facilities are built.

It is intended that nothing in this section be specific to C++, though some parts are clearly intended to support C++ features.

The unwinding library interface consists of at least the following routines:

* _Unwind_RaiseException,
* _Unwind_Resume,
* _Unwind_DeleteException,
* _Unwind_GetGR,
* _Unwind_SetGR,
* _Unwind_GetIP,
* _Unwind_SetIP,
* _Unwind_GetRegionStart,
* _Unwind_GetLanguageSpecificData,
* _Unwind_ForcedUnwind

In addition, two datatypes are defined (`_Unwind_Context` and `_Unwind_Exception`) to interface a calling runtime (such as the C++ runtime) and the above routines. All routines and interfaces behave as if defined `extern "C"`. In particular, the names are not mangled. All names defined as part of this interface have a `_Unwind_` prefix.

Lastly, a language and vendor specific personality routine will be stored by the compiler in the unwind descriptor for the stack frames requiring exception processing. The personality routine is called by the unwinder to handle language-specific tasks such as identifying the frame handling a particular exception.

#### Exception Handler Framework

There are two major reasons for unwinding the stack:

* exceptions, as defined by languages that support them (such as C++)
* "forced" unwinding (such as caused by longjmp or thread termination).

The interface described here tries to keep both similar. There is a major difference, however.

* In the case an exception is thrown, the stack is unwound while the exception propagates, but it is expected that the personality routine for each stack frame knows whether it wants to catch the exception or pass it through. This choice is thus delegated to the personality routine, which is expected to act properly for any type of exception, whether "native" or "foreign". Some guidelines for "acting properly" are given below.
* During "forced unwinding", on the other hand, an external agent is driving the unwinding. For instance, this can be the longjmp routine. This external agent, not each personality routine, knows when to stop unwinding. The fact that a personality routine is not given a choice about whether unwinding will proceed is indicated by the `_UA_FORCE_UNWIND` flag.

To accomodate these differences, two different routines are proposed. `_Unwind_RaiseException` performs exception-style unwinding, under control of the personality routines. `_Unwind_ForcedUnwind`, on the other hand, performs unwinding, but gives an external agent the opportunity to intercept calls to the personality routine. This is done using a proxy personality routine, that intercepts calls to the personality routine, letting the external agent override the defaults of the stack frame's personality routine.

As a consequence, it is not necessary for each personality routine to know about any of the possible external agents that may cause an unwind. For instance, the C++ personality routine need deal only with C++ exceptions (and possibly disguising foreign exceptions), but it does not need to know anything specific about unwinding done on behalf of longjmp or pthreads cancellation.

The standard ABI exception handling / unwind process begins with the raising of an exception, in one of the forms mentioned above. This call specifies an exception object and an exception class.

The runtime framework then starts a two-phase process:

* In the search phase, the framework repeatedly calls the personality routine, with the `_UA_SEARCH_PHASE` flag as described below, first for the current PC and register state, and then unwinding a frame to a new PC at each step, until the personality routine reports either success (a handler found in the queried frame) or failure (no handler) in all frames. It does not actually restore the unwound state, and the personality routine must access the state through the API.

* If the search phase reports failure, e.g. because no handler was found, it will call terminate() rather than commence phase 2

  If the search phase reports success, the framework restarts in the cleanup phase. Again, it repeatedly calls the personality routine, with the `_UA_CLEANUP_PHASE` flag as described below, first for the current PC and register state, and then unwinding a frame to a new PC at each step, until it gets to the frame with an identified handler. At that point, it restores the register state, and control is transferred to the user landing pad code.

#### Data Structures

```c
typedef enum {
  _URC_NO_REASON = 0,
  _URC_FOREIGN_EXCEPTION_CAUGHT = 1,
  _URC_FATAL_PHASE2_ERROR = 2,
  _URC_FATAL_PHASE1_ERROR = 3,
  _URC_NORMAL_STOP = 4,
  _URC_END_OF_STACK = 5,
  _URC_HANDLER_FOUND = 6,
  _URC_INSTALL_CONTEXT = 7,
  _URC_CONTINUE_UNWIND = 8
} _Unwind_Reason_Code;

typedef void (*_Unwind_Exception_Cleanup_Fn)(_Unwind_Reason_Code reason, struct _Unwind_Exception *exc);

struct _Unwind_Exception {
  uint64			 exception_class;
  _Unwind_Exception_Cleanup_Fn exception_cleanup;
  uint64			 private_1;
  uint64			 private_2;
};

struct _Unwind_Context;
```

#### Throwing an Exception

```c
_Unwind_Reason_Code _Unwind_RaiseException( struct _Unwind_Exception *exception_object );
```

_Unwind_RaiseException does not return, unless an error condition is found (such as no handler for the exception, bad stack format, etc.). In such a case, an _Unwind_Reason_Code value is returned. Possibilities are:

* _URC_END_OF_STACK: The unwinder encountered the end of the stack during phase 1, without finding a handler. The unwind runtime will not have modified the stack. The C++ runtime will normally call uncaught_exception() in this case.

* _URC_FATAL_PHASE1_ERROR: The unwinder encountered an unexpected error during phase 1, e.g. stack corruption. The unwind runtime will not have modified the stack. The C++ runtime will normally call terminate() in this case.

If the unwinder encounters an unexpected error during phase 2, it should return _URC_FATAL_PHASE2_ERROR to its caller. In C++, this will usually be __cxa_throw, which will call terminate().

The unwind runtime will likely have modified the stack (e.g. popped frames from it) or register context, or landing pad code may have corrupted them. As a result, the the caller of _Unwind_RaiseException can make no assumptions about the state of its stack or registers.

```c
typedef _Unwind_Reason_Code (*_Unwind_Stop_Fn)(int version,
  _Unwind_Action actions,
  uint64 exceptionClass,
  struct _Unwind_Exception *exceptionObject,
  struct _Unwind_Context *context,
  void *stop_parameter );

_Unwind_Reason_Code _Unwind_ForcedUnwind( struct _Unwind_Exception *exception_object,
  _Unwind_Stop_Fn stop,
  void *stop_parameter );
```

Forced unwinding is a single-phase process (phase 2 of the normal exception-handling process). The stop and stop_parameter parameters control the termination of the unwind process, instead of the usual personality routine query. The stop function parameter is called for each unwind frame, with the parameters described for the usual personality routine below, plus an additional stop_parameter.

When the stop function identifies the destination frame, it transfers control (according to its own, unspecified, conventions) to the user code as appropriate without returning, normally after calling _Unwind_DeleteException. If not, it should return an _Unwind_Reason_Code value as follows:

* _URC_NO_REASON: This is not the destination frame. The unwind runtime will call the frame's personality routine with the _UA_FORCE_UNWIND and _UA_CLEANUP_PHASE flags set in actions, and then unwind to the next frame and call the stop function again.
* _URC_END_OF_STACK: In order to allow _Unwind_ForcedUnwind to perform special processing when it reaches the end of the stack, the unwind runtime will call it after the last frame is rejected, with a NULL stack pointer in the context, and the stop function must catch this condition (i.e. by noticing the NULL stack pointer). It may return this reason code if it cannot handle end-of-stack.
* _URC_FATAL_PHASE2_ERROR: The stop function may return this code for other fatal conditions, e.g. stack corruption.

If the stop function returns any reason code other than _URC_NO_REASON, the stack state is indeterminate from the point of view of the caller of _Unwind_ForcedUnwind. Rather than attempt to return, therefore, the unwind library should return _URC_FATAL_PHASE2_ERROR to its caller.

The expected implementation of longjmp_unwind() is as follows. The setjmp() routine will have saved the state to be restored in its customary place, including the frame pointer. The longjmp_unwind() routine will call _Unwind_ForcedUnwind with a stop function that compares the frame pointer in the context record with the saved frame pointer. If equal, it will restore the setjmp() state as customary, and otherwise it will return _URC_NO_REASON or _URC_END_OF_STACK.

```c
void _Unwind_Resume (struct _Unwind_Exception *exception_object);
```

Resume propagation of an existing exception e.g. after executing cleanup code in a partially unwound stack. A call to this routine is inserted at the end of a landing pad that performed cleanup, but did not resume normal execution. It causes unwinding to proceed further.

_Unwind_Resume should not be used to implement rethrowing. To the unwinding runtime, the catch code that rethrows was a handler, and the previous unwinding session was terminated before entering it. Rethrowing is implemented by calling _Unwind_RaiseException again with the same exception object.

This is the only routine in the unwind library which is expected to be called directly by generated code: it will be called at the end of a landing pad in a "landing-pad" model.

```c
void _Unwind_DeleteException(struct _Unwind_Exception *exception_object);
```

#### Context Management

```c
uint64 _Unwind_GetGR(struct _Unwind_Context *context, int index);
```

This function returns the 64-bit value of the given general register. The register is identified by its index: 0 to 31 are for the fixed registers, and 32 to 127 are for the stacked registers.

```c
void _Unwind_SetGR(struct _Unwind_Context *context, int index, uint64 new_value);
```

```c
uint64 _Unwind_GetIP(struct _Unwind_Context *context);
```

```c
void _Unwind_SetIP(struct _Unwind_Context *context, uint64 new_value);
```

This function sets the value of the instruction pointer (IP) for the routine identified by the unwind context.

The behaviour is guaranteed only when this function is called for an unwind context representing a handler frame, for which the personality routine will return _URC_INSTALL_CONTEXT. In this case, control will be transferred to the given address, which should be the address of a landing pad.

```c
uint64 _Unwind_GetLanguageSpecificData(struct _Unwind_Context *context);
```

```c
uint64 _Unwind_GetRegionStart(struct _Unwind_Context *context);
```

This routine returns the address of the beginning of the procedure or code fragment described by the current unwind descriptor block.

#### Personality Routine

```c
_Unwind_Reason_Code(*__personality_routine)(
  int version,
  _Unwind_Action actions,
  uint64 exceptionClass,
  struct _Unwind_Exception *exceptionObject,
  struct _Unwind_Context *context);
```

The personality routine is the function in the C++ (or other language) runtime library which serves as an interface between the system unwind library and language-specific exception handling semantics. It is specific to the code fragment described by an unwind info block, and it is always referenced via the pointer in the unwind info block, and hence it has no psABI-specified name.

* actions

  * _UA_SEARCH_PHASE

    Indicates that the personality routine should check if the current frame contains a handler, and if so return _URC_HANDLER_FOUND, or otherwise return _URC_CONTINUE_UNWIND. _UA_SEARCH_PHASE cannot be set at the same time as _UA_CLEANUP_PHASE.

  * _UA_CLEANUP_PHASE

    Indicates that the personality routine should perform cleanup for the current frame. The personality routine can perform this cleanup itself, by calling nested procedures, and return _URC_CONTINUE_UNWIND. Alternatively, it can setup the registers (including the IP) for transferring control to a "landing pad", and return _URC_INSTALL_CONTEXT.

  * _UA_HANDLER_FRAME

    During phase 2, indicates to the personality routine that the current frame is the one which was flagged as the handler frame during phase 1. The personality routine is not allowed to change its mind between phase 1 and phase 2, i.e. it must handle the exception in this frame in phase 2.

  * _UA_FORCE_UNWIND

    During phase 2, indicates that no language is allowed to "catch" the exception. This flag is set while unwinding the stack for longjmp or during thread cancellation. User-defined code in a catch clause may still be executed, but the catch clause must resume unwinding with a call to _Unwind_Resume when finished.

If the personality routine determines that it should transfer control to a landing pad (in phase 2), it may set up registers (including IP) with suitable values for entering the landing pad (e.g. with landing pad parameters), by calling the context management routines above. It then returns _URC_INSTALL_CONTEXT.

The landing pad can either resume normal execution (as, for instance, at the end of a C++ catch), or resume unwinding by calling _Unwind_Resume and passing it the exceptionObject argument received by the personality routine. _Unwind_Resume will never return.

_Unwind_Resume should be called if and only if the personality routine did not return _Unwind_HANDLER_FOUND during phase 1.

The landing pad may receive arguments from the runtime, typically passed in registers set using _Unwind_SetGR by the personality routine.

The landing pad may receive other arguments, for instance a switch value indicating the type of the exception.

### C++ ABI

#### Data Structures

```c
struct __cxa_exception {
	std::type_info *	exceptionType;
	void (*exceptionDestructor) (void *);
	unexpected_handler	unexpectedHandler;
	terminate_handler	terminateHandler;
	__cxa_exception *	nextException;

	int			handlerCount;
	int			handlerSwitchValue;
	const char *		actionRecord;
	const char *		languageSpecificData;
	void *			catchTemp;
	void *			adjustedPtr;

	_Unwind_Exception	unwindHeader;
};
```

The exceptionType field encodes the type of the thrown exception. The exceptionDestructor field contains a function pointer to a destructor for the type being thrown, and may be NULL. These pointers must be stored in the exception object since non-polymorphic and built-in types can be thrown.

The fields unexpectedHandler and terminateHandler contain pointers to the unexpected and terminate handlers at the point where the exception is thrown.

The nextException field is used to create a linked list of exceptions (per thread)

The handlerSwitchValue, actionRecord, languageSpecificData, catchTemp, and adjustedPtr fields cache information that is best computed during pass 1, but useful during pass 2. By storing this information in the exception object, the cleanup phase can avoid re-examining action records. These fields are reserved for use of the personality routine for the stack frame containing the handler to be invoked.

By convention, a __cxa_exception pointer points at the C++ object representing the exception being thrown, immediately following the header. The header structure is accessed at a negative offset from the __cxa_exception pointer. This layout allows consistent treatment of exception objects from different languages (or different implementations of the same language), and allows future extensions of the header structure while maintaining binary compatibility.

Each thread in a C++ program has access to an object of the following class:

```c
struct __cxa_eh_globals {
	__cxa_exception *	caughtExceptions;
	unsigned int		uncaughtExceptions;
};
```

The caughtExceptions field is a list of the active exceptions, organized as a stack with the most recent first, linked through the nextException field of the exception header.

The uncaughtExceptions field is a count of uncaught exceptions, for use by the C++ library uncaught_exceptions() routine.

This information is maintained on a per-thread basis. Thus, caughtExceptions is a list of exceptions thrown and caught by the current thread, and uncaughtExceptions is a count of exceptions thrown and not yet caught by the current thread. (This includes rethrown exceptions, which may still have active handlers, but are not considered caught.)

The __cxa_eh_globals for the current thread can be obtained by using either of the APIs:

* `__cxa_eh_globals *__cxa_get_globals(void)`
* `__cxa_eh_globals *__cxa_get_globals_fast(void)`

#### Throwing an Exception

In broad outline, a possible implementation of the processing necessary to throw an exception includes the following steps:

* Call `__cxa_allocate_exception` to create an exception object
* Evaluate the thrown expression, and copy it into the buffer returned by __cxa_allocate_exception, possibly using a copy constructor. If evaluation of the thrown expression exits by throwing an exception, that exception will propagate instead of the expression itself. Cleanup code must ensure that `__cxa_free_exception` is called on the just allocated exception object. (If the copy constructor itself exits by throwing an exception, `terminate()` is called.)
* Call `__cxa_throw` to pass the exception to the runtime library. `__cxa_throw` never returns.

Based on this outline, throwing an object X as in:

```
throw X;
```

will produce code approximating the template:

```
	// Allocate -- never throws:
	temp1 = __cxa_allocate_exception(sizeof(X));

	// Construct the exception object:
	#if COPY_ELISION
	  [evaluate X into temp1]
	#else
	  [evaluate X into temp2]
	  copy-constructor(temp1, temp2)
	  // Landing Pad L1 if this throws
	#endif

	// Pass the exception object to unwind library:
	__cxa_throw(temp1, type_info<X>, destructor<X>); // Never returns

	// Landing pad for copy constructor:
	L1: __cxa_free_exception(temp1) // never throws
```

```c
void __cxa_throw (void *thrown_exception, std::type_info *tinfo, void (*dest) (void *) );
```

The arguments are:

* The address of the thrown exception object
* A std::type_info pointer, giving the static type of the throw argument as a std::type_info pointer, used for matching potential catch sites to the thrown exception
* A destructor pointer to be used eventually to destroy the object.

The __cxa_throw routine will do the following:

* Obtain the __cxa_exception header from the thrown exception object address, which can be computed as follows: `__cxa_exception *header = ((__cxa_exception *) thrown_exception - 1);`
* Save the current unexpected_handler and terminate_handler in the __cxa_exception header.
* Save the `tinfo` and `dest` arguments in the __cxa_exception header.
* Increment the uncaught_exception flag
* Call _Unwind_RaiseException in the system unwind library, Its argument is the pointer to the thrown exception, which __cxa_throw itself received as an argument.

__Unwind_RaiseException begins the process of stack unwinding. In special cases, such as an inability to find a handler, _Unwind_RaiseException may return. In that case, __cxa_throw will call terminate, assuming that there was no handler for the exception.

#### Catching an Exception

The personality routine is the function in the C++ runtime library which serves as an interface between the system unwind library and the C++ specific semantics.

```c
_Unwind_Reason_Code (*__personality_routine)
  (int version,
    _Unwind_Action actions,
    uint64 exceptionClass,
    struct _Unwind_Exception *exceptionObject,
    struct _Unwind_Context *context);
```

During the first phase, i.e. with actions including the bit _UA_SEARCH_PHASE, the personality routine should do nothing to update state, simply searching for a handler and returning _URC_HANDLER_FOUND when it finds one. During the second phase, i.e. with actions including the bit _UA_CLEANUP_PHASE, the personality routine may perform cleanup actions at intermediate frames, and must transfer to the handler found when actions includes the bit _UA_HANDLER_FRAME, which it does by setting up the context and returning _URC_INSTALL_CONTEXT.

If the exception is not a C++ exception, the C++ personality routine must not catch it, that is it should return _URC_CONTINUE_UNWIND in both phases, after performing any required cleanup actions in the second phase.

The Level I specification requires that the personality routine transfer control to a landing pad via the unwind library, enabling the latter to do any final cleanup. It does so by modifying the context record for the current frame, and letting the unwind library transfer control:

* Using _Unwind_SetIP to set the PC of the current stack frame to the address of the landing pad
* Using _Unwind_SetGR to set parameters to the landing pad in the general registers of the current stack frame
* Once the frame is set, returning _URC_INSTALL_CONTEXT to the unwind library, which does any cleanup required, installs the context, and transfers control to the landing pad

Note that any cleanup activity may be implemented as a landing pad that performs only cleanup tasks (no handlers), and calls _Unwind_Resume when done. In such cases, the personality routine should treat the cleanup landing pad as a handler.

The personality routine works only within the current frame; that is, it returns control to the unwind library for any processing required beyond this frame.

For purposes of this ABI, several things are considered exception handlers:

* A normal C++ handler, i.e. a catch clause.
* An unexpected() call, due to a violated exception specification.
* A terminate() call due to a throw.

Upon entry, a handler must call:

```c
void *__cxa_get_exception_ptr ( void *exceptionObject );
```

This routine returns the adjusted pointer to the exception object. (The adjusted pointer is typically computed by the personality routine during phase 1 and saved in the exception object.)

Following initialization of the catch parameter, a handler must call:

```c
void *__cxa_begin_catch ( void *exceptionObject );
```

This routine:

* Increment's the exception's handler count.
* Places the exception on the stack of currently-caught exceptions if it is not already there, linking the exception to the previous top of the stack.
* Decrements the uncaught_exception count.
* Returns the adjusted pointer to the exception object.

If the initialization of the catch parameter is trivial (e,g., there is no formal catch parameter, or the parameter has no copy constructor), the calls to __cxa_get_exception_ptr() and __cxa_begin_catch() may be combined into a single call to __cxa_begin_catch().

When the personality routine encounters a termination condition, it will call __cxa_begin_catch() to mark the exception as handled and then call terminate(), which shall not return to its caller.

Upon exit for any reason, a handler must call:

```c
void __cxa_end_catch ();
```

This routine:

* Locates the most recently caught exception and decrements its handler count.
* Removes the exception from the caught-exception stack, if the handler count goes to zero.
* Destroys the exception if the handler count goes to zero, and the exception was not re-thrown by throw.

Collaboration between __cxa_rethrow() and __cxa_end_catch() is necessary to handle the last point. Though implementation-defined, one possibility is for __cxa_rethrow() to set a flag in the handlerCount member of the exception header to mark an exception being rethrown.

If a landing pad is going to resume unwinding, e.g. because

* it contains no handlers, just cleanup actions;
* none of its catch handlers matches the exception; or
* the catch handler re-throws the exception,

then it shall do any required cleanup for the current frame before calling _Unwind_Resume to resume unwinding.

A handler for an arbitrary exception, including a terminate_handler or unwind_handler, has no way in standard C++ of determining the type of the exception without resorting to a complete enumeration, which is impractical at best. Since we use type_info for EH type matching, a user can access this information by calling:

```c
std::type_info *__cxa_current_exception_type ();
```

which returns the type of the first caught exception, or null if there are no caught exceptions. This routine is optional; a conforming ABI implementation need not provide it. However, if it is provided, it shall have the behavior specified here.

#### Rethrowing Exceptions

Rethrowing an exception is possible any time an exception is being handled. Most commonly, that means within a catch clause, but it is also possible to rethrow within an unexpected() or terminate() handler.

A catch handler rethrows the exception on top of the caughtExceptions stack by calling:

```c
void __cxa_rethrow ();
```

This routine marks the exception object on top of the caughtExceptions stack (in an implementation-defined way) as being rethrown. If the caughtExceptions stack is empty, it calls terminate(). It then returns to the handler that called it, which must call __cxa_end_catch(), perform any necessary cleanup, and finally call _Unwind_Resume() to continue unwinding.

#### Finishing and Destroying the Exception

An exception is considered handled:

* Immediately after initializing the parameter of the corresponding catch clause (or upon entry to a catch(...) clause).
* Upon entering unexpected() or terminate() due to a throw.

An exception is considered finished:

* When the corresponding catch clause exits (normally, by another throw, or by rethrow).
* When unexpected() exits (by throwing), after being entered due to a throw.

Because an exception can be rethrown and caught within a handler, there can be more than one handler active for an exception. The exception is destroyed when the last (outermost) handler exits by any means other than rethrow. The destruction occurs immediately after destruction of the catch clause parameter, if any.

This lifetime management is performed by the __cxa_begin_catch and __cxa_end_catch runtime functions, which keep track of what handlers exist for which exceptions. When __cxa_end_catch detects that an exception is no longer being thrown or handled, it destroys the exception and frees the memory allocated for it.

### Suggested Implementation

The stack unwind library runs two passes on the stack, as follows:

* Recover the program counter (PC) in the current stack frame.
* Using an unwind table, find information on how to handle exceptions that occur at that PC, and in particular, get the address of the personality routine for that address range.
* Call the personality routine. that will determine if an appropriate handler is found at that level of the stack (in pass 1), and that will determine which particular handler to invoke from the landing pad (in pass 2), as well as the arguments to pass to the landing pad. The personality routine passes this information back to the unwind library.
* In the second phase, the unwind library jumps to the landing pad corresponding to the call for each level of the stack being unwound. Landing pad parameters are set as indicated by the personality routine. The landing pad executes compensation code (generated by the back end) to restore the appropriate register and stack state.
* Some cleanup code generated by the front-end may then execute, corresponding to the exit of the try block. For instance, an automatic variable local to the try block would be destroyed here.
* The exception handler may select and execute user-defined code corresponding to C++ catch clauses and other handlers. The generated code may be similar to a switch statement, where the switch value is determined by the runtime based on the exception type, and passed in a landing pad argument.
* As soon as the runtime determines that the execution will go to a handler, the unwinding process is considered complete for the unwind library. A handler may still rethrow the current exception or a different exception, but a new unwind process will occur in both cases. Otherwise, after the code in a handler has executed, execution resumes at the end of the try block which defines this handler.
* If none of the possible handlers matches the exception being thrown, the runtime selects a switch value that does not match any switch statement. In that case, control passes through all switch statements, and goes to additional cleanup code, which will call all destructors that need to be called for the current stack frame. For instance, an automatic variable local to the outer block of the function would be destroyed here. This means that the handler must loop through any try blocks enclosing the original one in the process of cleaning up the frame, trying the switch value in each one.
* At the end of this current cleanup code, control is transferred back to the unwind library, to unwind one more stack frame.

For purposes of illustration, suppose we have a call site in a try-catch block such as:

```
try { foo(); }
catch (TYPE1) { ... }
catch (TYPE2) { buz(); }
bar();
```

This might be translated as follows:

```
// In "Normal" area:
foo(); // Call Attributes: Landing Pad L1, Action Record A1
goto E1;
...
E1: // End Label
bar();

// In "Exception" area;
L1: // Landing Pad label
[Back-end generated "compensation" code]
goto C1;

C1: // Cleanup label
[Front-end generated cleanup code, destructors, etc]
[corresponding to exit of try { } block]
goto S1;

S1: // Switch label
switch(SWITCH_VALUE_PAD_ARGUMENT)
{
    case 1: goto H1; // For TYPE1
    case 2: goto H2; // For TYPE2
    //...
    default: goto X1;
}

X1:
[Cleanup code corresponding to exit of scope]
[enclosing the try block]
_Unwind_Resume();

H1: // Handler label
adjusted_exception_ptr = __cxa_get_exception_ptr(exception);
[Initialize catch parameter]
__cxa_begin_catch(exception);
[User code]
goto R1;

H2:
adjusted_exception_ptr = __cxa_get_exception_ptr(exception);
[Initialize catch parameter]
__cxa_begin_catch(exception);
[User code]
buz(); // Call attributes: Landing pad L2, action record A2
goto R1;

R1: // Resume label:
__cxa_end_catch();
goto E1;

L2:
C2:
// Make sure we cleanup the current exception
__cxa_end_catch();

X2:
[Cleanup code corresponding to exit of scope]
[enclosing the try block]
_Unwind_Resume();
```

### .gcc_except_table

> https://www.airs.com/blog/archives/464 Airs – Ian Lance Taylor

The LSDA is found in the section `.gcc_except_table` (the personality function is just a function and lives in the .text section as usual). The personality function gets a pointer to it by calling _Unwind_GetLanguageSpecificData.

LSDA:

* landing pad base
* type table
* call-site table

call-site table entry:

* start address (offset from the landing pad base)
* length
* landing pad (offset from the landing pad base)
* v = 0 means no action. else v - 1 is index into the action table

The call-site table is sorted by the start address field. If the personality function finds that there is no entry for the current PC in the call-site table, then there is no exception information. This should not happen in normal operation, and in C++ will lead to a call to std::terminate. If there is an entry in the call-site table, but the landing pad is zero, then there is nothing to do: there are no destructors to run or exceptions to catch. This is a normal case, and the unwinder will simply continue. If the action record is zero, then there are destructors to run but no exceptions to catch. The personality function will arrange to run the destructors, and unwinding will continue.

action table entry:

* type filter. 0. index into the type table
* next

type table entry:

* pointer to a type information structure
