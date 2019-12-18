# This library is a wrapper to C GDBM one  
The GNU dbm ('gdbm') is a library of database functions that use extendible hashing and works similarly to the standard UNIX 'dbm' functions.  
  
### Instal:  
    nimble install gdbmc
  
  
### Requirement:  
    sudo apt install libgdbm-dev
  
### Usage:  
```nim
    block test:
      const filename: string = "test.db"
      let
        db = Open(filename, "n")
      defer: Close(db)

      ## Inserts a key-value pair in the database
      let seqdata = @[("test2", "test2value"), ("test3", "test3value"), ("test4", "test4value"), ("test5", "test5value")]

      for seqitem in seqdata:
        (serr,errl) = Insert(db, seqitem[0], seqitem[1])

      ## Inserts or Updates a key-value pair in the database
      db["test6"] = "test6value"
      value = db["test6"]

      ## Returns of the most recent error encountered when operating on the database dbf
      errl = db.LastError()
      debugEcho "db[test6]=", value, " errl:", $errl

      ## Counts number of records in the database dbf
      let ucnt = db.Count()
      debugEcho "db.Count:", $ucnt

      for pair in db.keyValueIterator():
        stdout.writeLine(pair)

      for key in db.keyIterator():
        stdout.writeLine(key)
```

For ditails see `block test:` in gdbmc.nim  

### Example: memory efficient deduplication of a file  
```nim
    import gdbmc
    from system import quit
    from os import getFileInfo
    from re import re, replace
    from strutils import strip
    from md5 import getMD5

    block:
      let stdin_info = getFileInfo(stdin)
      if stdin_info.id.file == 9:
        echo "Use: cat file.txt|deduplicate"
        quit 1

    const filename: string = "/tmp/dedup-nim.db"
    let
      db = Open(filename, "n")
    defer: Close(db)
    var line = ""
    while stdin.readLine(line):
      line = line.strip.replace(re"(\s+)", " ")
      let md5line = getMD5(line)
      if md5line notin db:
        db[md5line] = ""
        echo line
```
  
### License  
[MIT License](https://opensource.org/licenses/MIT). You may use any compatible license (essentially any license) for your own programs developed with libgdbm


<!--
vim:ft=markdown:tabstop=2:expandtab:shiftwidth=2:softtabstop=2:foldmethod=marker:
-->
