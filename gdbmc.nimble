# Package

version       = "0.9.9"
author        = "vycb"
description   = "This library is a wrapper to C GDBM one"
license       = "MIT"
srcDir        = "src"


skipFiles = @["deduplicate.nim,src"]

# Dependencies

requires "nim >= 1.2"


task test, "Runs the test suite":
  exec "nim c -d:INTALLED_GDBM_LIB -d:test -r gdbmc.nim"
