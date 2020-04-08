type
  GDBM_EXCEPTION* = object of ValueError #{{{{{{

  GDBM_ERRORS* = enum
    GDBM_NO_ERROR #{{{
    GDBM_MALLOC_ERROR
    GDBM_BLOCK_SIZE_ERROR
    GDBM_FILE_OPEN_ERROR
    GDBM_FILE_WRITE_ERROR
    GDBM_FILE_SEEK_ERROR
    GDBM_FILE_READ_ERROR
    GDBM_BAD_MAGIC_NUMBER
    GDBM_CANT_BE_READER
    GDBM_CANT_BE_WRITER
    GDBM_READER_CANT_DELETE
    GDBM_READER_CANT_STORE
    GDBM_READER_CANT_REORGANIZE
    GDBM_UNKNOWN_ERROR
    GDBM_ITEM_NOT_FOUND
    GDBM_REORGANIZE_FAILED
    GDBM_CANNOT_REPLACE
    GDBM_ILLEGAL_DAT
    GDBM_OPT_ALREADY_SET
    GDBM_OPT_ILLEGAL
    GDBM_BYTE_SWAPPED
    GDBM_BAD_FILE_OFFSET
    GDBM_BAD_OPEN_FLAGS
    GDBM_FILE_STAT_ERROR
    GDBM_FILE_EOF
    GDBM_NO_DBNAME
    GDBM_ERR_FILE_OWNER
    GDBM_ERR_FILE_MODE
    GDBM_NEED_RECOVERY
    GDBM_BACKUP_FAILED
    GDBM_DIR_OVERFLOW #}}}
    #}}}

when defined USE_GDBMTOOL:
  import osproc, strutils #{{{
  type
    GdbmTool = object #{{{
      dbfile :string

  const
    CMDINIT = r"printf ""%s\n"" list| gdbmtool -n "
  #}}}

  ## initialize gdbm file on the disk
  proc InitGdbmTool*(md5file :string): GdbmTool =
  #{{{
    result.dbfile = md5file
    discard execCmdEx(CMDINIT & result.dbfile)
    return result  #}}}

  proc gdbmtool(db: GdbmTool, cmd: string): string =
    if db.dbfile.isEmptyOrWhitespace: #{{{
      raise newException(GDBM_EXCEPTION, $GDBM_FILE_OPEN_ERROR)

    let (resout, _) = execCmdEx(r"printf ""%s\n"" '" & cmd & "'| gdbmtool -f- " & db.dbfile & " 2>/dev/null")
    return resout #}}}

  proc Insert*(db: GdbmTool, key, value: string) =
    if db.dbfile.isEmptyOrWhitespace: #{{{
      raise newException(GDBM_EXCEPTION, $GDBM_FILE_OPEN_ERROR)

    discard db.gdbmtool("store " & key & " " & value)
    #}}}

  ## Fetches the value of the given key as a string
  proc Fetch*(db: GdbmTool, key: string): string =
    if db.dbfile.isEmptyOrWhitespace: #{{{
      result = ""
      raise newException(GDBM_EXCEPTION, $GDBM_FILE_OPEN_ERROR)

    result = db.gdbmtool("fetch " & key)
    return result.strip
    #debugEcho "Exists:", " vdatum:", vdatum.repr()   #}}}

  ## Fetches the value of the given key as a string
  proc `[]`*(db:GdbmTool, key: string): string = db.Fetch key

  ## Inserts or Updates a key-value pair in the database
  proc `[]=`*(db:GdbmTool, key , value: string) =
    db.Insert(key, value)

  ## Returns true or false, depending on whether the specified key exists in the {{{
  ## database }}}
  proc Exists*(db: GdbmTool, key: string): bool =
    if db.dbfile.isEmptyOrWhitespace: #{{{
      result = false
      raise newException(GDBM_EXCEPTION, $GDBM_FILE_OPEN_ERROR)

    let outp = db.Fetch(key)

    #debugEcho "Exists:", " vdatum:", vdatum.repr()
    result = if outp.isEmptyOrWhitespace: false else: true
    #}}}

  ## Searches in the db for a value. Returns false if the value does not exist, true otherwise.
  template contains*(db: GdbmTool, key: string): bool = db.Exists(key)

  when isMainModule:
    if defined(test): #{{{
      block test:
        const
          md5file = "/tmp/deduplicatemd5FileBashCache"
        let db = InitGdbmTool(md5file)
        db["test6"] = "test6value"
        var
          value = db["test6"]

        debugEcho "db[test6]=", value, ":"
        assert value == "test6value"

#         for pair in db.keyValueIterator():
#           stdout.writeLine(pair)
# 
#         for key in db.keyIterator():
#           stdout.writeLine(key)

        echo "when defined USE_GDBMTOOL All tests OK"
  #}}}
  #}}}when defined USE_GDBMTOOL

when defined INTALLED_GDBM_LIB:
  ## This library is a wrapper to C GDBM library. The GNU dbm ('gdbm') is a library of database functions that use extendible hashing and works similarly to the standard UNIX 'dbm' functions.{{{{{{
  ## License MIT.
#   {.passL: "-L/usr/lib/".}
  const
    ## Use --passL to add path to libgdbm.so. #{{{
    ## Example: nim c --passL:"-L/usr/lib/x86_64-linux-gnu/" ...
    LIBGDBM = "libgdbm.so.6" #"/usr/lib/x86_64-linux-gnu/libgdbm.so"
#     GDBMH = "<gdbm.h>"
    #}}}
  type
    DATUM* = object
      dptr*: cstring #{{{
      dsize*: cint #}}}
    gdbm_file_info {.final, incompleteStruct, importc: "struct gdbm_file_info"} = object
    GDBM_FILE* {.final, importc: "GDBM_FILE"} = ref gdbm_file_info
#     gdbm_file_info {.final, incompleteStruct, importc: "struct gdbm_file_info", header: GDBMH.} = object
#     GDBM_FILE* {.final, importc: "GDBM_FILE", header: GDBMH.} = ptr gdbm_file_info
    GDBM_OPEN_FLAGS* = enum
      GDBM_READER = 0.cint #{{{
      GDBM_WRITER
      GDBM_WRCREAT
      GDBM_NEWDB
      GDBM_OPENMASK = 7.cint
      GDBM_SYNC = 0x020.cint
      GDBM_NOLOCK = 0x040.cint #}}}

    GDBM_STORE_RESULT* = enum
      GDBM_STORE_DPTR_NULL = -1.cint #{{{
      GDBM_STORE_NO_ERROR
      GDBM_STORE_KEY_EXISTS #}}}

    GDBM_STORE_FLAG* = enum
      GDBM_INSERT = 0.cint ## Never replace old data with new. #{{{
      #[ ## Parameters to gdbm_store for simple insertion or replacement in the
        case that the key is already in the database. ]#
      GDBM_REPLACE = 1.cint # Always replace old data with new. #}}}

    Database* = object
      dbf*:  GDBM_FILE #{{{
      mode*: GDBM_OPEN_FLAGS #}}}

    DatabaseCfg* = object
      Mode*        :string #{{{
      BlockSize*   :cint
      Permissions* :cint #}}}
#}}}

  proc gdbm_open*(cs: cstring, bs:cint, m:GDBM_OPEN_FLAGS, p:cint, v:cstring):GDBM_FILE {.importc: "gdbm_open", dynlib: LIBGDBM.}
  #{{{
  var gdbm_version* {.importc: "gdbm_version", dynlib: LIBGDBM.} :cstring #{.header: "<gdbm.h>".}
  proc gdbm_close*(d:GDBM_FILE) {.importc: "gdbm_close", dynlib:LIBGDBM.}

  proc gdbm_reorganize*(d:GDBM_FILE) {.importc: "gdbm_reorganize", dynlib:LIBGDBM.}

  proc gdbm_sync*(d:GDBM_FILE) {.importc: "gdbm_sync", dynlib:LIBGDBM.}

  proc gdbm_store*(db:GDBM_FILE, dak:DATUM, dav:DATUM, fl:GDBM_STORE_FLAG): GDBM_STORE_RESULT {.importc: "gdbm_store", dynlib:LIBGDBM.}

  proc gdbm_exists*(df: GDBM_FILE, dat: DATUM): cint {.importc: "gdbm_exists", dynlib:LIBGDBM.}

  proc gdbm_count*(df: GDBM_FILE, pcount: var uint64): cint {.importc: "gdbm_count", dynlib:LIBGDBM.}

  proc gdbm_delete*(df: GDBM_FILE, dat: DATUM): cint {.importc: "gdbm_delete", dynlib:LIBGDBM.}

  proc gdbm_fetch*(df: GDBM_FILE, dat: DATUM): DATUM {.importc: "gdbm_fetch", dynlib:LIBGDBM.}

  proc gdbm_nextkey*(df: GDBM_FILE, dat: DATUM): DATUM {.importc: "gdbm_nextkey", dynlib:LIBGDBM.}

  proc gdbm_firstkey*(dbf: GDBM_FILE): DATUM {.importc: "gdbm_firstkey", dynlib:LIBGDBM.}

  proc gdbm_last_errno*(dbf: GDBM_FILE): GDBM_ERRORS {.importc: "gdbm_last_errno", dynlib:LIBGDBM.}
  #}}}

  ## Initializes gdbm with configuration DatabaseCfg #{{{
  ## For Example: DatabaseCfg(Mode: mode, BlockSize: 0, Permissions: 6564) #}}}
  proc OpenWithCfg*(filename: string, cfg: DatabaseCfg): Database =
  #   new result #{{{
    let cfilename:cstring = cstring(filename)
    # Convert a human-readable mode string into a LIBGDBM-usable constant.
    case cfg.Mode
    of "r":
      result.mode = GDBM_READER
    of "w":
      result.mode = GDBM_WRITER
    of "c":
      result.mode = GDBM_WRCREAT
    of "n":
      result.mode = GDBM_NEWDB
    of "s":
      result.mode = GDBM_SYNC
    of "nl":
      result.mode = GDBM_NOLOCK

    #   debugEcho "result:", result.repr," cfg:",cfg.repr

    result.dbf = gdbm_open(cfilename, cfg.BlockSize, result.mode, cfg.Permissions, nil)

    #debugEcho "OpenWithCfg:", result.repr, " DatabaseCfg:", cfg.repr #}}}

  ## Initializes gdbm system #{{{
  ## mode: GDBM_OPEN_FLAGS
  ## db = Open(filename, "n") #}}}
  proc Open*(filename: string, mode: string): Database =
    return OpenWithCfg(filename, DatabaseCfg(Mode: mode, BlockSize: 0, Permissions: 6564 ))

  ## Closes a database's internal file pointer.
  proc Close*(db: Database) =
    if db.dbf == nil: return #{{{
    gdbm_close(db.dbf) #}}}

  ## return the gdbm release build string
  template Version*(): string = $gdbm_version

  ## Returns of the most recent error encountered when operating on the database dbf
  proc LastError*(db:Database): GDBM_ERRORS = gdbm_last_errno(db.dbf)
  ## Internal helper method to hide the two constants GDBM_INSERT and {{{
  ## GDBM_REPLACE from the user.}}}

  ## Returns true or false, depending on whether the specified key exists in the {{{
  ## database }}}
  proc Exists*(db: Database, key: string): bool =
    if db.dbf == nil: #{{{
      result = false
      raise newException(GDBM_EXCEPTION, $GDBM_FILE_OPEN_ERROR)
    let
      kcs = cstring(key)
      datk = DATUM(dptr: kcs, dsize: key.len.cint)
    #debugEcho "Exists:", db.repr()," key:", datk.repr()

    let
      res = gdbm_exists(db.dbf, datk)
      #lerr = gdbm_last_errno(db.dbf)

    #debugEcho "Exists:", " vdatum:", vdatum.repr()
    if res == 1.cint:
      return true

    return false #}}}

  ## Searches in the db for a value. Returns false if the value does not exist, true otherwise.
  template contains*(db: Database, key: string): bool = db.Exists(key)

  ## inserts or replaces records in the database #{{{
  ## return tuple[sres:GDBM_STORE_RESULT, lerr:GDBM_ERRORS] #}}}
  proc update*(db:Database, key :string, value :string, flag: GDBM_STORE_FLAG): (GDBM_STORE_RESULT, GDBM_ERRORS) =
    ## Convert key and value into LIBGDBM's `datum` data structure. See the #{{{{{{
    ## C definition at the top for the implementation of C.mk_datum(string). #}}}
    if db.dbf == nil: return (GDBM_STORE_DPTR_NULL, GDBM_FILE_OPEN_ERROR)
    let
      kcs = cstring(key)
      vcs = cstring(value)
      datumk = DATUM(dptr: kcs, dsize: key.len.int32())
      datumv = DATUM(dptr: vcs, dsize: value.len.int32())
      sres = gdbm_store(db.dbf, datumk, datumv, flag)
      err = gdbm_last_errno(db.dbf)
    return (sres, err)
    #debugEcho "update:", $flag, db.repr(), datumk.repr(), datumv.repr(), " result:",$result, " errl:", $err #}}}

  ## Inserts a key-value pair into the database. If the database is opened #{{{
  ## in "r" mode, this will return an error. Also, if the key already exists in
  ## the database, and error will be returned. #}}}
  proc Insert*(db:Database, key: string, value: string): tuple[sres:GDBM_STORE_RESULT, lerr:GDBM_ERRORS] = update(db, key, value, GDBM_INSERT)

  ## Updates a key-value pair to use a new value, specified by the `value` string {{{
  ## parameter. An error will be returned if the database is opened in "r" mode. }}}
  proc Replace*(db:Database, key: string, value: string): tuple[sres:GDBM_STORE_RESULT, lerr:GDBM_ERRORS] = update(db, key, value, GDBM_REPLACE)

  ## Inserts or Updates a key-value pair in the database
  proc `[]=`*(db:Database, key: string, value: string) =
    let flag = if key in db: GDBM_REPLACE else: GDBM_INSERT #{{{
    discard update(db, key, value, flag) #}}}

  ## Fetches the value of the given key. If the key is not in the database, an #{{{
  ## error will be returned in err. Otherwise, value will be the value string
  ## that is keyed by `key`. #}}}
  proc Fetch*(db: Database, key: string): string =
    if db.dbf == nil: #{{{
      result =""
      raise newException(GDBM_EXCEPTION, $GDBM_FILE_OPEN_ERROR)
    let
      kcs = cstring(key)
      datk = DATUM(dptr: kcs, dsize: key.len.cint) #mk_datum(kcs)
    #debugEcho "Fetch:", db.repr()," key:", datk.repr()
      vdatum = gdbm_fetch(db.dbf, datk)
      #lerr = gdbm_last_errno(db.dbf)
    #debugEcho "Fetch:", " vdatum:", vdatum.repr()
    result = if vdatum.dptr == nil: "" else: $vdatum.dptr #}}}

  ## Fetches the value of the given key as a string
  proc `[]`*(db:Database, key: string): string = db.Fetch key

  ## Deletes the data associated with the given key, if it exists in the database dbf #{{{
  ## returns tuple[sres:bool, lerr:GDBM_ERRORS] #}}}
  proc Delete*(db: Database, key: string): (bool, GDBM_ERRORS) =
    if db.dbf == nil: #{{{
      return (false, GDBM_FILE_OPEN_ERROR)
    let
      kcs = cstring(key)
      datk = DATUM(dptr: kcs, dsize: key.len.cint)
    #debugEcho "Exists:", db.repr()," key:", datk.repr()

    let
      res = gdbm_delete(db.dbf, datk)
      lerr = db.LastError()

    #debugEcho "Exists:", " vdatum:", vdatum.repr()
    if res == -1:
      return (false, lerr)

    return (true, lerr) #}}}

  ## Counts number of records in the database dbf
  proc Count*(db: Database): uint64 =
    if db.dbf == nil: #{{{
      return 0'u64 #, GDBM_FILE_OPEN_ERROR)

    var
      pcount: uint64
      res = gdbm_count(db.dbf, pcount)
#     lerr = db.LastError()

    #debugEcho "Count:", " vdatum:", vdatum.repr()
    if res == -1:
      return 0'u64 #, lerr)

    return pcount #, lerr) #}}}

  ## Returns the firstkey in this gdbm.Database.{{{
  ## The traversal is ordered by gdbm‘s internal hash values, and won’t be sorted by the key values
  ## If there is not a key, an error will be returned in err. }}}
  proc FirstKey*(db: Database): string =
    let vdatum = gdbm_firstkey(db.dbf) #{{{
    result = if vdatum.dptr == nil: "" else: $vdatum.dptr #}}}

  ## This function continues the iteration over the keys in dbf, initiated by gdbm_firstkey. {{{
  ## The parameter prev holds the value returned from a previous call to gdbm_nextkey or gdbm_firstkey. }}}
  proc NextKey*(db: Database, key: string): string =
    if db.dbf == nil: #{{{
      raise newException(GDBM_EXCEPTION, $GDBM_FILE_OPEN_ERROR)
    let
      kcs = cstring(key)
      datk = DATUM(dptr: kcs, dsize: key.len.cint)
      vdatum = gdbm_nextkey(db.dbf, datk)

    result = if vdatum.dptr == nil: "" else: $vdatum.dptr #}}}

  ## Travers for a keys/values in Database
  iterator keyValueIterator*(db: Database): (string,string) =
    var key = db.FirstKey() #{{{
    if key.len > 0: yield (key, db[key])
    while key.len > 0:
      key = db.NextKey(key)
      if key.len > 0:
        yield (key, db[key])
      else:
        break #}}}

  ## Travers for a keys in Database
  iterator keyIterator*(db: Database): string =
    var key = db.FirstKey() #{{{
    if key.len > 0: yield key
    while key.len > 0:
      key = db.NextKey(key)
      if key.len > 0:
        yield key
      else:
        break #}}}

  ## Reorganizes the database for more efficient use of disk space. This method #{{{
  ## can be used if Delete(k) is called many times. #}}}
  proc Reorganize*(db: Database) = gdbm_reorganize(db.dbf)

  ## Synchronizes all pending database changes to the disk. TODO: note this is #{{{
  ## only needed in FAST mode, and FAST mode needs implemented! #}}}
  proc Sync*(db: Database) = gdbm_sync(db.dbf)

  when isMainModule:
    if defined(test): #{{{
      block test:
        const filename: string = "test.db"
        let
          db = Open(filename, "n")
        defer: Close(db)

        debugEcho Version()

        assert db.dbf != nil

        var
          (serr,errl) = Insert(db, "test1", "test1value")
          exists = db.Exists("test1")
          value = db.Fetch("test1")

        assert serr == GDBM_STORE_NO_ERROR
        assert errl == GDBM_NO_ERROR
        assert exists == true
        assert value == "test1value"
        assert "test1" in db

        (serr, errl) = Replace(db, "test1", "test1replaced")
        value = db.Fetch("test1")
        assert serr == GDBM_STORE_NO_ERROR
        assert value == "test1replaced"

        value = db.FirstKey()
        debugEcho "main: value=", value, " ", db.repr(), " store_error:", $serr, " errorl:", $errl, " value:",value.repr()
        assert value == "test1"

        let seqdata = @[("test2", "test2value"), ("test3", "test3value"), ("test4", "test4value"), ("test5", "test5value")]
        for seqitem in seqdata:
          (serr,errl) = Insert(db, seqitem[0], seqitem[1])

        value = db.FirstKey()
        echo "FirstKey: ", value, " seqdata.len=", $seqdata.len
        var cnt = 0
        while value.len > 0:
          value = db.NextKey(value)
          if value.len > 0:
            echo "NextKey:", value
            cnt += 1
          else:
            break

        assert cnt == seqdata.len

        debugEcho "Deleting test1"
        var (berr,berrl) = db.Delete("test1")
        assert berr == true
        assert berrl == GDBM_NO_ERROR

        let ucnt = db.Count()
        errl = db.LastError()
        assert errl == GDBM_NO_ERROR
        assert ucnt == seqdata.len.uint64

        debugEcho "Adding/retrieveing key by indexing"
        db["test6"] = "test6value"
        value = db["test6"]
        errl = db.LastError()
        debugEcho "db[test6]=", value, " errl:", $errl
        assert value == "test6value"
        assert errl == GDBM_NO_ERROR

        debugEcho "db.Count:", $db.Count

        for pair in db.keyValueIterator():
          stdout.writeLine(pair)

        for key in db.keyIterator():
          stdout.writeLine(key)

        echo "All tests OK" #}}}
  #}}}when defined INTALLED_GDBM_LIB


#vim:ft=nim:tabstop=2:expandtab:shiftwidth=2:softtabstop=2:foldmethod=marker:
