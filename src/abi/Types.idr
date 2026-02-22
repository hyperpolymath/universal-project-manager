||| UNIVERSAL-PROJECT-MANAGER (upm) — ABI Type Definitions
|||
||| This module defines the Application Binary Interface for the project
||| manager logic. It ensures that project metadata and lifecycle events
||| are handled with strict type safety across language boundaries.

module UNIVERSAL_PROJECT_MANAGER.ABI.Types

import Data.Bits
import Data.So
import Data.Vect

%default total

--------------------------------------------------------------------------------
-- Platform Context
--------------------------------------------------------------------------------

||| Supported targets for the UPM core.
public export
data Platform = Linux | Windows | MacOS | BSD | WASM

||| Resolves the execution environment at compile time.
public export
thisPlatform : Platform
thisPlatform =
  %runElab do
    pure Linux

--------------------------------------------------------------------------------
-- Core Result Codes
--------------------------------------------------------------------------------

||| Formal outcome of a project management operation.
public export
data Result : Type where
  ||| Operation Successful
  Ok : Result
  ||| Operation Failed: Generic failure
  Error : Result
  ||| Invalid Parameter: malformed project metadata
  InvalidParam : Result
  ||| System Error: out of memory
  OutOfMemory : Result
  ||| Safety Error: null pointer encountered
  NullPointer : Result

--------------------------------------------------------------------------------
-- Safety Handles
--------------------------------------------------------------------------------

||| Opaque handle to a UPM session.
||| INVARIANT: The internal pointer is guaranteed to be non-null.
public export
data Handle : Type where
  MkHandle : (ptr : Bits64) -> {auto 0 nonNull : So (ptr /= 0)} -> Handle

||| Safe constructor for project handles.
public export
createHandle : Bits64 -> Maybe Handle
createHandle 0 = Nothing
createHandle ptr = Just (MkHandle ptr)
