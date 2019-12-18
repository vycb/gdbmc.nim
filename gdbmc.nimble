# Package

version       = "0.9.1"
author        = "vycb"
description   = "This library is a wrapper to C GDBM one"
license       = "MIT"
srcDir        = "src"


skipFiles = @["deduplicate.nim,src"]

# Dependencies

requires "nim >= 1.0.4"


task test, "Runs the test suite":
  exec "nim c -d:nimDebugDlOpen -d:test -r gdbmc.nim"
