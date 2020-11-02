redis_commands <- function(command) {
  list(
    ACL_LOAD = function() {
      command(list("ACL", "LOAD"))
    },
    ACL_SAVE = function() {
      command(list("ACL", "SAVE"))
    },
    ACL_LIST = function() {
      command(list("ACL", "LIST"))
    },
    ACL_USERS = function() {
      command(list("ACL", "USERS"))
    },
    ACL_GETUSER = function(username) {
      assert_scalar2(username)
      command(list("ACL", "GETUSER", username))
    },
    ACL_SETUSER = function(username, rule = NULL) {
      assert_scalar2(username)
      command(list("ACL", "SETUSER", username, rule))
    },
    ACL_DELUSER = function(username) {
      command(list("ACL", "DELUSER", username))
    },
    ACL_CAT = function(categoryname = NULL) {
      assert_scalar_or_null2(categoryname)
      command(list("ACL", "CAT", categoryname))
    },
    ACL_GENPASS = function(bits = NULL) {
      assert_scalar_or_null2(bits)
      command(list("ACL", "GENPASS", bits))
    },
    ACL_WHOAMI = function() {
      command(list("ACL", "WHOAMI"))
    },
    ACL_LOG = function(count_or_RESET = NULL) {
      assert_scalar_or_null2(count_or_RESET)
      command(list("ACL", "LOG", count_or_RESET))
    },
    ACL_HELP = function() {
      command(list("ACL", "HELP"))
    },
    APPEND = function(key, value) {
      assert_scalar2(key)
      assert_scalar2(value)
      command(list("APPEND", key, value))
    },
    AUTH = function(password, username = NULL) {
      assert_scalar_or_null2(username)
      assert_scalar2(password)
      command(list("AUTH", username, password))
    },
    BGREWRITEAOF = function() {
      command(list("BGREWRITEAOF"))
    },
    BGSAVE = function(schedule = NULL) {
      assert_match_value_or_null(schedule, c("SCHEDULE"))
      command(list("BGSAVE", schedule))
    },
    BITCOUNT = function(key, start = NULL, end = NULL) {
      assert_scalar2(key)
      assert_scalar_or_null2(start)
      assert_scalar_or_null2(end)
      command(list("BITCOUNT", key, start, end))
    },
    BITFIELD = function(key, GET = NULL, SET = NULL, INCRBY = NULL, OVERFLOW = NULL) {
      assert_scalar2(key)
      assert_length_or_null(GET, 2L)
      assert_length_or_null(SET, 3L)
      assert_length_or_null(INCRBY, 3L)
      assert_match_value_or_null(OVERFLOW, c("WRAP", "SAT", "FAIL"))
      command(list("BITFIELD", key, cmd_command("GET", GET, TRUE), cmd_command("SET", SET, TRUE), cmd_command("INCRBY", INCRBY, TRUE), cmd_command("OVERFLOW", OVERFLOW, FALSE)))
    },
    BITOP = function(operation, destkey, key) {
      assert_scalar2(operation)
      assert_scalar2(destkey)
      command(list("BITOP", operation, destkey, key))
    },
    BITPOS = function(key, bit, start = NULL, end = NULL) {
      assert_scalar2(key)
      assert_scalar2(bit)
      assert_scalar_or_null2(start)
      assert_scalar_or_null2(end)
      command(list("BITPOS", key, bit, start, end))
    },
    BLPOP = function(key, timeout) {
      assert_scalar2(timeout)
      command(list("BLPOP", key, timeout))
    },
    BRPOP = function(key, timeout) {
      assert_scalar2(timeout)
      command(list("BRPOP", key, timeout))
    },
    BRPOPLPUSH = function(source, destination, timeout) {
      assert_scalar2(source)
      assert_scalar2(destination)
      assert_scalar2(timeout)
      command(list("BRPOPLPUSH", source, destination, timeout))
    },
    BLMOVE = function(source, destination, wherefrom, whereto, timeout) {
      assert_scalar2(source)
      assert_scalar2(destination)
      assert_match_value(wherefrom, c("LEFT", "RIGHT"))
      assert_match_value(whereto, c("LEFT", "RIGHT"))
      assert_scalar2(timeout)
      command(list("BLMOVE", source, destination, wherefrom, whereto, timeout))
    },
    BZPOPMIN = function(key, timeout) {
      assert_scalar2(timeout)
      command(list("BZPOPMIN", key, timeout))
    },
    BZPOPMAX = function(key, timeout) {
      assert_scalar2(timeout)
      command(list("BZPOPMAX", key, timeout))
    },
    CLIENT_CACHING = function(mode) {
      stop("Do not use CLIENT CACHING; not supported with this client")
    },
    CLIENT_ID = function() {
      command(list("CLIENT", "ID"))
    },
    CLIENT_KILL = function(ip_port = NULL, ID = NULL, TYPE = NULL, USER = NULL, ADDR = NULL, SKIPME = NULL) {
      assert_scalar_or_null2(ip_port)
      assert_scalar_or_null2(ID)
      assert_match_value_or_null(TYPE, c("normal", "master", "slave", "pubsub"))
      assert_scalar_or_null2(USER)
      assert_scalar_or_null2(ADDR)
      assert_scalar_or_null2(SKIPME)
      command(list("CLIENT", "KILL", ip_port, cmd_command("ID", ID, FALSE), cmd_command("TYPE", TYPE, FALSE), cmd_command("USER", USER, FALSE), cmd_command("ADDR", ADDR, FALSE), cmd_command("SKIPME", SKIPME, FALSE)))
    },
    CLIENT_LIST = function(TYPE = NULL) {
      assert_match_value_or_null(TYPE, c("normal", "master", "replica", "pubsub"))
      command(list("CLIENT", "LIST", cmd_command("TYPE", TYPE, FALSE)))
    },
    CLIENT_GETNAME = function() {
      command(list("CLIENT", "GETNAME"))
    },
    CLIENT_GETREDIR = function() {
      stop("Do not use CLIENT GETREDIR; not supported with this client")
    },
    CLIENT_PAUSE = function(timeout) {
      assert_scalar2(timeout)
      command(list("CLIENT", "PAUSE", timeout))
    },
    CLIENT_REPLY = function(reply_mode) {
      stop("Do not use CLIENT REPLY; not supported with this client")
    },
    CLIENT_SETNAME = function(connection_name) {
      assert_scalar2(connection_name)
      command(list("CLIENT", "SETNAME", connection_name))
    },
    CLIENT_TRACKING = function(status, REDIRECT = NULL, PREFIX = NULL, BCAST = NULL, OPTIN = NULL, OPTOUT = NULL, NOLOOP = NULL) {
      stop("Do not use CLIENT TRACKING; not supported with this client")
    },
    CLIENT_UNBLOCK = function(client_id, unblock_type = NULL) {
      assert_scalar2(client_id)
      assert_match_value_or_null(unblock_type, c("TIMEOUT", "ERROR"))
      command(list("CLIENT", "UNBLOCK", client_id, unblock_type))
    },
    CLUSTER_ADDSLOTS = function(slot) {
      command(list("CLUSTER", "ADDSLOTS", slot))
    },
    CLUSTER_BUMPEPOCH = function() {
      command(list("CLUSTER", "BUMPEPOCH"))
    },
    CLUSTER_COUNT_FAILURE_REPORTS = function(node_id) {
      assert_scalar2(node_id)
      command(list("CLUSTER", "COUNT-FAILURE-REPORTS", node_id))
    },
    CLUSTER_COUNTKEYSINSLOT = function(slot) {
      assert_scalar2(slot)
      command(list("CLUSTER", "COUNTKEYSINSLOT", slot))
    },
    CLUSTER_DELSLOTS = function(slot) {
      command(list("CLUSTER", "DELSLOTS", slot))
    },
    CLUSTER_FAILOVER = function(options = NULL) {
      assert_match_value_or_null(options, c("FORCE", "TAKEOVER"))
      command(list("CLUSTER", "FAILOVER", options))
    },
    CLUSTER_FLUSHSLOTS = function() {
      command(list("CLUSTER", "FLUSHSLOTS"))
    },
    CLUSTER_FORGET = function(node_id) {
      assert_scalar2(node_id)
      command(list("CLUSTER", "FORGET", node_id))
    },
    CLUSTER_GETKEYSINSLOT = function(slot, count) {
      assert_scalar2(slot)
      assert_scalar2(count)
      command(list("CLUSTER", "GETKEYSINSLOT", slot, count))
    },
    CLUSTER_INFO = function() {
      command(list("CLUSTER", "INFO"))
    },
    CLUSTER_KEYSLOT = function(key) {
      assert_scalar2(key)
      command(list("CLUSTER", "KEYSLOT", key))
    },
    CLUSTER_MEET = function(ip, port) {
      assert_scalar2(ip)
      assert_scalar2(port)
      command(list("CLUSTER", "MEET", ip, port))
    },
    CLUSTER_MYID = function() {
      command(list("CLUSTER", "MYID"))
    },
    CLUSTER_NODES = function() {
      command(list("CLUSTER", "NODES"))
    },
    CLUSTER_REPLICATE = function(node_id) {
      assert_scalar2(node_id)
      command(list("CLUSTER", "REPLICATE", node_id))
    },
    CLUSTER_RESET = function(reset_type = NULL) {
      assert_match_value_or_null(reset_type, c("HARD", "SOFT"))
      command(list("CLUSTER", "RESET", reset_type))
    },
    CLUSTER_SAVECONFIG = function() {
      command(list("CLUSTER", "SAVECONFIG"))
    },
    CLUSTER_SET_CONFIG_EPOCH = function(config_epoch) {
      assert_scalar2(config_epoch)
      command(list("CLUSTER", "SET-CONFIG-EPOCH", config_epoch))
    },
    CLUSTER_SETSLOT = function(slot, subcommand, node_id = NULL) {
      assert_scalar2(slot)
      assert_match_value(subcommand, c("IMPORTING", "MIGRATING", "STABLE", "NODE"))
      assert_scalar_or_null2(node_id)
      command(list("CLUSTER", "SETSLOT", slot, subcommand, node_id))
    },
    CLUSTER_SLAVES = function(node_id) {
      assert_scalar2(node_id)
      command(list("CLUSTER", "SLAVES", node_id))
    },
    CLUSTER_REPLICAS = function(node_id) {
      assert_scalar2(node_id)
      command(list("CLUSTER", "REPLICAS", node_id))
    },
    CLUSTER_SLOTS = function() {
      command(list("CLUSTER", "SLOTS"))
    },
    COMMAND = function() {
      command(list("COMMAND"))
    },
    COMMAND_COUNT = function() {
      command(list("COMMAND", "COUNT"))
    },
    COMMAND_GETKEYS = function(cmd) {
      command(c(list("COMMAND", "GETKEYS"), cmd))
    },
    COMMAND_INFO = function(command_name) {
      command(list("COMMAND", "INFO", command_name))
    },
    CONFIG_GET = function(parameter) {
      assert_scalar2(parameter)
      command(list("CONFIG", "GET", parameter))
    },
    CONFIG_REWRITE = function() {
      command(list("CONFIG", "REWRITE"))
    },
    CONFIG_SET = function(parameter, value) {
      assert_scalar2(parameter)
      assert_scalar2(value)
      command(list("CONFIG", "SET", parameter, value))
    },
    CONFIG_RESETSTAT = function() {
      command(list("CONFIG", "RESETSTAT"))
    },
    DBSIZE = function() {
      command(list("DBSIZE"))
    },
    DEBUG_OBJECT = function(key) {
      assert_scalar2(key)
      command(list("DEBUG", "OBJECT", key))
    },
    DEBUG_SEGFAULT = function() {
      command(list("DEBUG", "SEGFAULT"))
    },
    DECR = function(key) {
      assert_scalar2(key)
      command(list("DECR", key))
    },
    DECRBY = function(key, decrement) {
      assert_scalar2(key)
      assert_scalar2(decrement)
      command(list("DECRBY", key, decrement))
    },
    DEL = function(key) {
      command(list("DEL", key))
    },
    DISCARD = function() {
      command(list("DISCARD"))
    },
    DUMP = function(key) {
      assert_scalar2(key)
      command(list("DUMP", key))
    },
    ECHO = function(message) {
      assert_scalar2(message)
      command(list("ECHO", message))
    },
    EVAL = function(script, numkeys, key, arg) {
      assert_scalar2(script)
      assert_scalar2(numkeys)
      command(list("EVAL", script, numkeys, key, arg))
    },
    EVALSHA = function(sha1, numkeys, key, arg) {
      assert_scalar2(sha1)
      assert_scalar2(numkeys)
      command(list("EVALSHA", sha1, numkeys, key, arg))
    },
    EXEC = function() {
      command(list("EXEC"))
    },
    EXISTS = function(key) {
      command(list("EXISTS", key))
    },
    EXPIRE = function(key, seconds) {
      assert_scalar2(key)
      assert_scalar2(seconds)
      command(list("EXPIRE", key, seconds))
    },
    EXPIREAT = function(key, timestamp) {
      assert_scalar2(key)
      assert_scalar2(timestamp)
      command(list("EXPIREAT", key, timestamp))
    },
    FLUSHALL = function(async = NULL) {
      assert_match_value_or_null(async, c("ASYNC"))
      command(list("FLUSHALL", async))
    },
    FLUSHDB = function(async = NULL) {
      assert_match_value_or_null(async, c("ASYNC"))
      command(list("FLUSHDB", async))
    },
    GEOADD = function(key, longitude, latitude, member) {
      assert_scalar2(key)
      longitude <- cmd_interleave(longitude, latitude, member)
      command(list("GEOADD", key, longitude))
    },
    GEOHASH = function(key, member) {
      assert_scalar2(key)
      command(list("GEOHASH", key, member))
    },
    GEOPOS = function(key, member) {
      assert_scalar2(key)
      command(list("GEOPOS", key, member))
    },
    GEODIST = function(key, member1, member2, unit = NULL) {
      assert_scalar2(key)
      assert_scalar2(member1)
      assert_scalar2(member2)
      assert_match_value_or_null(unit, c("m", "km", "ft", "mi"))
      command(list("GEODIST", key, member1, member2, unit))
    },
    GEORADIUS = function(key, longitude, latitude, radius, unit, withcoord = NULL, withdist = NULL, withhash = NULL, COUNT = NULL, order = NULL, STORE = NULL, STOREDIST = NULL) {
      assert_scalar2(key)
      assert_scalar2(longitude)
      assert_scalar2(latitude)
      assert_scalar2(radius)
      assert_match_value(unit, c("m", "km", "ft", "mi"))
      assert_match_value_or_null(withcoord, c("WITHCOORD"))
      assert_match_value_or_null(withdist, c("WITHDIST"))
      assert_match_value_or_null(withhash, c("WITHHASH"))
      assert_scalar_or_null2(COUNT)
      assert_match_value_or_null(order, c("ASC", "DESC"))
      assert_scalar_or_null2(STORE)
      assert_scalar_or_null2(STOREDIST)
      command(list("GEORADIUS", key, longitude, latitude, radius, unit, withcoord, withdist, withhash, cmd_command("COUNT", COUNT, FALSE), order, cmd_command("STORE", STORE, FALSE), cmd_command("STOREDIST", STOREDIST, FALSE)))
    },
    GEORADIUSBYMEMBER = function(key, member, radius, unit, withcoord = NULL, withdist = NULL, withhash = NULL, COUNT = NULL, order = NULL, STORE = NULL, STOREDIST = NULL) {
      assert_scalar2(key)
      assert_scalar2(member)
      assert_scalar2(radius)
      assert_match_value(unit, c("m", "km", "ft", "mi"))
      assert_match_value_or_null(withcoord, c("WITHCOORD"))
      assert_match_value_or_null(withdist, c("WITHDIST"))
      assert_match_value_or_null(withhash, c("WITHHASH"))
      assert_scalar_or_null2(COUNT)
      assert_match_value_or_null(order, c("ASC", "DESC"))
      assert_scalar_or_null2(STORE)
      assert_scalar_or_null2(STOREDIST)
      command(list("GEORADIUSBYMEMBER", key, member, radius, unit, withcoord, withdist, withhash, cmd_command("COUNT", COUNT, FALSE), order, cmd_command("STORE", STORE, FALSE), cmd_command("STOREDIST", STOREDIST, FALSE)))
    },
    GET = function(key) {
      assert_scalar2(key)
      command(list("GET", key))
    },
    GETBIT = function(key, offset) {
      assert_scalar2(key)
      assert_scalar2(offset)
      command(list("GETBIT", key, offset))
    },
    GETRANGE = function(key, start, end) {
      assert_scalar2(key)
      assert_scalar2(start)
      assert_scalar2(end)
      command(list("GETRANGE", key, start, end))
    },
    GETSET = function(key, value) {
      assert_scalar2(key)
      assert_scalar2(value)
      command(list("GETSET", key, value))
    },
    HDEL = function(key, field) {
      assert_scalar2(key)
      command(list("HDEL", key, field))
    },
    HELLO = function(protover, AUTH = NULL, SETNAME = NULL) {
      stop("Do not use HELLO; RESP3 not supported with this client")
    },
    HEXISTS = function(key, field) {
      assert_scalar2(key)
      assert_scalar2(field)
      command(list("HEXISTS", key, field))
    },
    HGET = function(key, field) {
      assert_scalar2(key)
      assert_scalar2(field)
      command(list("HGET", key, field))
    },
    HGETALL = function(key) {
      assert_scalar2(key)
      command(list("HGETALL", key))
    },
    HINCRBY = function(key, field, increment) {
      assert_scalar2(key)
      assert_scalar2(field)
      assert_scalar2(increment)
      command(list("HINCRBY", key, field, increment))
    },
    HINCRBYFLOAT = function(key, field, increment) {
      assert_scalar2(key)
      assert_scalar2(field)
      assert_scalar2(increment)
      command(list("HINCRBYFLOAT", key, field, increment))
    },
    HKEYS = function(key) {
      assert_scalar2(key)
      command(list("HKEYS", key))
    },
    HLEN = function(key) {
      assert_scalar2(key)
      command(list("HLEN", key))
    },
    HMGET = function(key, field) {
      assert_scalar2(key)
      command(list("HMGET", key, field))
    },
    HMSET = function(key, field, value) {
      assert_scalar2(key)
      field <- cmd_interleave(field, value)
      command(list("HMSET", key, field))
    },
    HSET = function(key, field, value) {
      assert_scalar2(key)
      field <- cmd_interleave(field, value)
      command(list("HSET", key, field))
    },
    HSETNX = function(key, field, value) {
      assert_scalar2(key)
      assert_scalar2(field)
      assert_scalar2(value)
      command(list("HSETNX", key, field, value))
    },
    HSTRLEN = function(key, field) {
      assert_scalar2(key)
      assert_scalar2(field)
      command(list("HSTRLEN", key, field))
    },
    HVALS = function(key) {
      assert_scalar2(key)
      command(list("HVALS", key))
    },
    INCR = function(key) {
      assert_scalar2(key)
      command(list("INCR", key))
    },
    INCRBY = function(key, increment) {
      assert_scalar2(key)
      assert_scalar2(increment)
      command(list("INCRBY", key, increment))
    },
    INCRBYFLOAT = function(key, increment) {
      assert_scalar2(key)
      assert_scalar2(increment)
      command(list("INCRBYFLOAT", key, increment))
    },
    INFO = function(section = NULL) {
      assert_scalar_or_null2(section)
      command(list("INFO", section))
    },
    LOLWUT = function(VERSION = NULL) {
      assert_scalar_or_null2(VERSION)
      res <- command(list("LOLWUT", cmd_command("VERSION", VERSION, FALSE)))
      message(trimws(res))
      invisible(res)
    },
    KEYS = function(pattern) {
      assert_scalar2(pattern)
      command(list("KEYS", pattern))
    },
    LASTSAVE = function() {
      command(list("LASTSAVE"))
    },
    LINDEX = function(key, index) {
      assert_scalar2(key)
      assert_scalar2(index)
      command(list("LINDEX", key, index))
    },
    LINSERT = function(key, where, pivot, element) {
      assert_scalar2(key)
      assert_match_value(where, c("BEFORE", "AFTER"))
      assert_scalar2(pivot)
      assert_scalar2(element)
      command(list("LINSERT", key, where, pivot, element))
    },
    LLEN = function(key) {
      assert_scalar2(key)
      command(list("LLEN", key))
    },
    LPOP = function(key) {
      assert_scalar2(key)
      command(list("LPOP", key))
    },
    LPOS = function(key, element, RANK = NULL, COUNT = NULL, MAXLEN = NULL) {
      assert_scalar2(key)
      assert_scalar2(element)
      assert_scalar_or_null2(RANK)
      assert_scalar_or_null2(COUNT)
      assert_scalar_or_null2(MAXLEN)
      command(list("LPOS", key, element, cmd_command("RANK", RANK, FALSE), cmd_command("COUNT", COUNT, FALSE), cmd_command("MAXLEN", MAXLEN, FALSE)))
    },
    LPUSH = function(key, element) {
      assert_scalar2(key)
      command(list("LPUSH", key, element))
    },
    LPUSHX = function(key, element) {
      assert_scalar2(key)
      command(list("LPUSHX", key, element))
    },
    LRANGE = function(key, start, stop) {
      assert_scalar2(key)
      assert_scalar2(start)
      assert_scalar2(stop)
      command(list("LRANGE", key, start, stop))
    },
    LREM = function(key, count, element) {
      assert_scalar2(key)
      assert_scalar2(count)
      assert_scalar2(element)
      command(list("LREM", key, count, element))
    },
    LSET = function(key, index, element) {
      assert_scalar2(key)
      assert_scalar2(index)
      assert_scalar2(element)
      command(list("LSET", key, index, element))
    },
    LTRIM = function(key, start, stop) {
      assert_scalar2(key)
      assert_scalar2(start)
      assert_scalar2(stop)
      command(list("LTRIM", key, start, stop))
    },
    MEMORY_DOCTOR = function() {
      command(list("MEMORY", "DOCTOR"))
    },
    MEMORY_HELP = function() {
      command(list("MEMORY", "HELP"))
    },
    MEMORY_MALLOC_STATS = function() {
      command(list("MEMORY", "MALLOC-STATS"))
    },
    MEMORY_PURGE = function() {
      command(list("MEMORY", "PURGE"))
    },
    MEMORY_STATS = function() {
      command(list("MEMORY", "STATS"))
    },
    MEMORY_USAGE = function(key, SAMPLES = NULL) {
      assert_scalar2(key)
      assert_scalar_or_null2(SAMPLES)
      command(list("MEMORY", "USAGE", key, cmd_command("SAMPLES", SAMPLES, FALSE)))
    },
    MGET = function(key) {
      command(list("MGET", key))
    },
    MIGRATE = function(host, port, key, destination_db, timeout, copy = NULL, replace = NULL, AUTH = NULL, AUTH2 = NULL, KEYS = NULL) {
      assert_scalar2(host)
      assert_scalar2(port)
      assert_match_value(key, c("key", ""))
      assert_scalar2(destination_db)
      assert_scalar2(timeout)
      assert_match_value_or_null(copy, c("COPY"))
      assert_match_value_or_null(replace, c("REPLACE"))
      assert_scalar_or_null2(AUTH)
      assert_scalar_or_null2(AUTH2)
      command(list("MIGRATE", host, port, key, destination_db, timeout, copy, replace, cmd_command("AUTH", AUTH, FALSE), cmd_command("AUTH2", AUTH2, FALSE), cmd_command("KEYS", KEYS, TRUE)))
    },
    MODULE_LIST = function() {
      command(list("MODULE", "LIST"))
    },
    MODULE_LOAD = function(path, arg = NULL) {
      assert_scalar2(path)
      command(list("MODULE", "LOAD", path, arg))
    },
    MODULE_UNLOAD = function(name) {
      assert_scalar2(name)
      command(list("MODULE", "UNLOAD", name))
    },
    MONITOR = function() {
      command(list("MONITOR"))
    },
    MOVE = function(key, db) {
      assert_scalar2(key)
      assert_scalar2(db)
      command(list("MOVE", key, db))
    },
    MSET = function(key, value) {
      key <- cmd_interleave(key, value)
      command(list("MSET", key))
    },
    MSETNX = function(key, value) {
      key <- cmd_interleave(key, value)
      command(list("MSETNX", key))
    },
    MULTI = function() {
      command(list("MULTI"))
    },
    OBJECT = function(subcommand, arguments = NULL) {
      assert_scalar2(subcommand)
      command(list("OBJECT", subcommand, arguments))
    },
    PERSIST = function(key) {
      assert_scalar2(key)
      command(list("PERSIST", key))
    },
    PEXPIRE = function(key, milliseconds) {
      assert_scalar2(key)
      assert_scalar2(milliseconds)
      command(list("PEXPIRE", key, milliseconds))
    },
    PEXPIREAT = function(key, milliseconds_timestamp) {
      assert_scalar2(key)
      assert_scalar2(milliseconds_timestamp)
      command(list("PEXPIREAT", key, milliseconds_timestamp))
    },
    PFADD = function(key, element) {
      assert_scalar2(key)
      command(list("PFADD", key, element))
    },
    PFCOUNT = function(key) {
      command(list("PFCOUNT", key))
    },
    PFMERGE = function(destkey, sourcekey) {
      assert_scalar2(destkey)
      command(list("PFMERGE", destkey, sourcekey))
    },
    PING = function(message = NULL) {
      assert_scalar_or_null2(message)
      command(list("PING", message))
    },
    PSETEX = function(key, milliseconds, value) {
      assert_scalar2(key)
      assert_scalar2(milliseconds)
      assert_scalar2(value)
      command(list("PSETEX", key, milliseconds, value))
    },
    PSUBSCRIBE = function(pattern) {
      stop("Do not use PSUBSCRIBE(); see subscribe() instead (lower-case)")
    },
    PUBSUB = function(subcommand, argument = NULL) {
      assert_scalar2(subcommand)
      command(list("PUBSUB", subcommand, argument))
    },
    PTTL = function(key) {
      assert_scalar2(key)
      command(list("PTTL", key))
    },
    PUBLISH = function(channel, message) {
      assert_scalar2(channel)
      assert_scalar2(message)
      command(list("PUBLISH", channel, message))
    },
    PUNSUBSCRIBE = function(pattern = NULL) {
      command(list("PUNSUBSCRIBE", pattern))
    },
    QUIT = function() {
      command(list("QUIT"))
    },
    RANDOMKEY = function() {
      command(list("RANDOMKEY"))
    },
    READONLY = function() {
      command(list("READONLY"))
    },
    READWRITE = function() {
      command(list("READWRITE"))
    },
    RENAME = function(key, newkey) {
      assert_scalar2(key)
      assert_scalar2(newkey)
      command(list("RENAME", key, newkey))
    },
    RENAMENX = function(key, newkey) {
      assert_scalar2(key)
      assert_scalar2(newkey)
      command(list("RENAMENX", key, newkey))
    },
    RESTORE = function(key, ttl, serialized_value, replace = NULL, absttl = NULL, IDLETIME = NULL, FREQ = NULL) {
      assert_scalar2(key)
      assert_scalar2(ttl)
      assert_scalar2(serialized_value)
      assert_match_value_or_null(replace, c("REPLACE"))
      assert_match_value_or_null(absttl, c("ABSTTL"))
      assert_scalar_or_null2(IDLETIME)
      assert_scalar_or_null2(FREQ)
      command(list("RESTORE", key, ttl, serialized_value, replace, absttl, cmd_command("IDLETIME", IDLETIME, FALSE), cmd_command("FREQ", FREQ, FALSE)))
    },
    ROLE = function() {
      command(list("ROLE"))
    },
    RPOP = function(key) {
      assert_scalar2(key)
      command(list("RPOP", key))
    },
    RPOPLPUSH = function(source, destination) {
      assert_scalar2(source)
      assert_scalar2(destination)
      command(list("RPOPLPUSH", source, destination))
    },
    LMOVE = function(source, destination, wherefrom, whereto) {
      assert_scalar2(source)
      assert_scalar2(destination)
      assert_match_value(wherefrom, c("LEFT", "RIGHT"))
      assert_match_value(whereto, c("LEFT", "RIGHT"))
      command(list("LMOVE", source, destination, wherefrom, whereto))
    },
    RPUSH = function(key, element) {
      assert_scalar2(key)
      command(list("RPUSH", key, element))
    },
    RPUSHX = function(key, element) {
      assert_scalar2(key)
      command(list("RPUSHX", key, element))
    },
    SADD = function(key, member) {
      assert_scalar2(key)
      command(list("SADD", key, member))
    },
    SAVE = function() {
      command(list("SAVE"))
    },
    SCARD = function(key) {
      assert_scalar2(key)
      command(list("SCARD", key))
    },
    SCRIPT_DEBUG = function(mode) {
      assert_match_value(mode, c("YES", "SYNC", "NO"))
      command(list("SCRIPT", "DEBUG", mode))
    },
    SCRIPT_EXISTS = function(sha1) {
      command(list("SCRIPT", "EXISTS", sha1))
    },
    SCRIPT_FLUSH = function() {
      command(list("SCRIPT", "FLUSH"))
    },
    SCRIPT_KILL = function() {
      command(list("SCRIPT", "KILL"))
    },
    SCRIPT_LOAD = function(script) {
      assert_scalar2(script)
      command(list("SCRIPT", "LOAD", script))
    },
    SDIFF = function(key) {
      command(list("SDIFF", key))
    },
    SDIFFSTORE = function(destination, key) {
      assert_scalar2(destination)
      command(list("SDIFFSTORE", destination, key))
    },
    SELECT = function(index) {
      assert_scalar2(index)
      command(list("SELECT", index))
    },
    SET = function(key, value, expiration = NULL, condition = NULL, get = NULL) {
      assert_scalar2(key)
      assert_scalar2(value)
      assert_match_value_or_null(expiration, c("EX seconds", "PX milliseconds", "KEEPTTL"))
      assert_match_value_or_null(condition, c("NX", "XX"))
      assert_match_value_or_null(get, c("GET"))
      command(list("SET", key, value, expiration, condition, get))
    },
    SETBIT = function(key, offset, value) {
      assert_scalar2(key)
      assert_scalar2(offset)
      assert_scalar2(value)
      command(list("SETBIT", key, offset, value))
    },
    SETEX = function(key, seconds, value) {
      assert_scalar2(key)
      assert_scalar2(seconds)
      assert_scalar2(value)
      command(list("SETEX", key, seconds, value))
    },
    SETNX = function(key, value) {
      assert_scalar2(key)
      assert_scalar2(value)
      command(list("SETNX", key, value))
    },
    SETRANGE = function(key, offset, value) {
      assert_scalar2(key)
      assert_scalar2(offset)
      assert_scalar2(value)
      command(list("SETRANGE", key, offset, value))
    },
    SHUTDOWN = function(save_mode = NULL) {
      assert_match_value_or_null(save_mode, c("NOSAVE", "SAVE"))
      command(list("SHUTDOWN", save_mode))
    },
    SINTER = function(key) {
      command(list("SINTER", key))
    },
    SINTERSTORE = function(destination, key) {
      assert_scalar2(destination)
      command(list("SINTERSTORE", destination, key))
    },
    SISMEMBER = function(key, member) {
      assert_scalar2(key)
      assert_scalar2(member)
      command(list("SISMEMBER", key, member))
    },
    SMISMEMBER = function(key, member) {
      assert_scalar2(key)
      command(list("SMISMEMBER", key, member))
    },
    SLAVEOF = function(host, port) {
      assert_scalar2(host)
      assert_scalar2(port)
      command(list("SLAVEOF", host, port))
    },
    REPLICAOF = function(host, port) {
      assert_scalar2(host)
      assert_scalar2(port)
      command(list("REPLICAOF", host, port))
    },
    SLOWLOG = function(subcommand, argument = NULL) {
      assert_scalar2(subcommand)
      assert_scalar_or_null2(argument)
      command(list("SLOWLOG", subcommand, argument))
    },
    SMEMBERS = function(key) {
      assert_scalar2(key)
      command(list("SMEMBERS", key))
    },
    SMOVE = function(source, destination, member) {
      assert_scalar2(source)
      assert_scalar2(destination)
      assert_scalar2(member)
      command(list("SMOVE", source, destination, member))
    },
    SORT = function(key, BY = NULL, LIMIT = NULL, GET = NULL, order = NULL, sorting = NULL, STORE = NULL) {
      assert_scalar2(key)
      assert_scalar_or_null2(BY)
      assert_length_or_null(LIMIT, 2L)
      assert_match_value_or_null(order, c("ASC", "DESC"))
      assert_match_value_or_null(sorting, c("ALPHA"))
      assert_scalar_or_null2(STORE)
      command(list("SORT", key, cmd_command("BY", BY, FALSE), cmd_command("LIMIT", LIMIT, TRUE), cmd_command("GET", GET, FALSE), order, sorting, cmd_command("STORE", STORE, FALSE)))
    },
    SPOP = function(key, count = NULL) {
      assert_scalar2(key)
      assert_scalar_or_null2(count)
      command(list("SPOP", key, count))
    },
    SRANDMEMBER = function(key, count = NULL) {
      assert_scalar2(key)
      assert_scalar_or_null2(count)
      command(list("SRANDMEMBER", key, count))
    },
    SREM = function(key, member) {
      assert_scalar2(key)
      command(list("SREM", key, member))
    },
    STRALGO = function(algorithm, algo_specific_argument) {
      assert_match_value(algorithm, c("LCS"))
      command(list("STRALGO", algorithm, algo_specific_argument))
    },
    STRLEN = function(key) {
      assert_scalar2(key)
      command(list("STRLEN", key))
    },
    SUBSCRIBE = function(channel) {
      stop("Do not use SUBSCRIBE(); see subscribe() instead (lower-case)")
    },
    SUNION = function(key) {
      command(list("SUNION", key))
    },
    SUNIONSTORE = function(destination, key) {
      assert_scalar2(destination)
      command(list("SUNIONSTORE", destination, key))
    },
    SWAPDB = function(index1, index2) {
      assert_scalar2(index1)
      assert_scalar2(index2)
      command(list("SWAPDB", index1, index2))
    },
    SYNC = function() {
      command(list("SYNC"))
    },
    PSYNC = function(replicationid, offset) {
      stop("Do not use PSYNC; not supported with this client")
    },
    TIME = function() {
      command(list("TIME"))
    },
    TOUCH = function(key) {
      command(list("TOUCH", key))
    },
    TTL = function(key) {
      assert_scalar2(key)
      command(list("TTL", key))
    },
    TYPE = function(key) {
      assert_scalar2(key)
      command(list("TYPE", key))
    },
    UNSUBSCRIBE = function(channel = NULL) {
      command(list("UNSUBSCRIBE", channel))
    },
    UNLINK = function(key) {
      command(list("UNLINK", key))
    },
    UNWATCH = function() {
      command(list("UNWATCH"))
    },
    WAIT = function(numreplicas, timeout) {
      assert_scalar2(numreplicas)
      assert_scalar2(timeout)
      command(list("WAIT", numreplicas, timeout))
    },
    WATCH = function(key) {
      command(list("WATCH", key))
    },
    ZADD = function(key, score, member, condition = NULL, comparison = NULL, change = NULL, increment = NULL) {
      assert_scalar2(key)
      assert_match_value_or_null(condition, c("NX", "XX"))
      assert_match_value_or_null(comparison, c("GT", "LT"))
      assert_match_value_or_null(change, c("CH"))
      assert_match_value_or_null(increment, c("INCR"))
      score <- cmd_interleave(score, member)
      command(list("ZADD", key, condition, comparison, change, increment, score))
    },
    ZCARD = function(key) {
      assert_scalar2(key)
      command(list("ZCARD", key))
    },
    ZCOUNT = function(key, min, max) {
      assert_scalar2(key)
      assert_scalar2(min)
      assert_scalar2(max)
      command(list("ZCOUNT", key, min, max))
    },
    ZINCRBY = function(key, increment, member) {
      assert_scalar2(key)
      assert_scalar2(increment)
      assert_scalar2(member)
      command(list("ZINCRBY", key, increment, member))
    },
    ZINTER = function(numkeys, key, WEIGHTS = NULL, AGGREGATE = NULL, withscores = NULL) {
      assert_scalar2(numkeys)
      assert_match_value_or_null(AGGREGATE, c("SUM", "MIN", "MAX"))
      assert_match_value_or_null(withscores, c("WITHSCORES"))
      command(list("ZINTER", numkeys, key, cmd_command("WEIGHTS", WEIGHTS, TRUE), cmd_command("AGGREGATE", AGGREGATE, FALSE), withscores))
    },
    ZINTERSTORE = function(destination, numkeys, key, WEIGHTS = NULL, AGGREGATE = NULL) {
      assert_scalar2(destination)
      assert_scalar2(numkeys)
      assert_match_value_or_null(AGGREGATE, c("SUM", "MIN", "MAX"))
      command(list("ZINTERSTORE", destination, numkeys, key, cmd_command("WEIGHTS", WEIGHTS, TRUE), cmd_command("AGGREGATE", AGGREGATE, FALSE)))
    },
    ZLEXCOUNT = function(key, min, max) {
      assert_scalar2(key)
      assert_scalar2(min)
      assert_scalar2(max)
      command(list("ZLEXCOUNT", key, min, max))
    },
    ZPOPMAX = function(key, count = NULL) {
      assert_scalar2(key)
      assert_scalar_or_null2(count)
      command(list("ZPOPMAX", key, count))
    },
    ZPOPMIN = function(key, count = NULL) {
      assert_scalar2(key)
      assert_scalar_or_null2(count)
      command(list("ZPOPMIN", key, count))
    },
    ZRANGE = function(key, start, stop, withscores = NULL) {
      assert_scalar2(key)
      assert_scalar2(start)
      assert_scalar2(stop)
      assert_match_value_or_null(withscores, c("WITHSCORES"))
      command(list("ZRANGE", key, start, stop, withscores))
    },
    ZRANGEBYLEX = function(key, min, max, LIMIT = NULL) {
      assert_scalar2(key)
      assert_scalar2(min)
      assert_scalar2(max)
      assert_length_or_null(LIMIT, 2L)
      command(list("ZRANGEBYLEX", key, min, max, cmd_command("LIMIT", LIMIT, TRUE)))
    },
    ZREVRANGEBYLEX = function(key, max, min, LIMIT = NULL) {
      assert_scalar2(key)
      assert_scalar2(max)
      assert_scalar2(min)
      assert_length_or_null(LIMIT, 2L)
      command(list("ZREVRANGEBYLEX", key, max, min, cmd_command("LIMIT", LIMIT, TRUE)))
    },
    ZRANGEBYSCORE = function(key, min, max, withscores = NULL, LIMIT = NULL) {
      assert_scalar2(key)
      assert_scalar2(min)
      assert_scalar2(max)
      assert_match_value_or_null(withscores, c("WITHSCORES"))
      assert_length_or_null(LIMIT, 2L)
      command(list("ZRANGEBYSCORE", key, min, max, withscores, cmd_command("LIMIT", LIMIT, TRUE)))
    },
    ZRANK = function(key, member) {
      assert_scalar2(key)
      assert_scalar2(member)
      command(list("ZRANK", key, member))
    },
    ZREM = function(key, member) {
      assert_scalar2(key)
      command(list("ZREM", key, member))
    },
    ZREMRANGEBYLEX = function(key, min, max) {
      assert_scalar2(key)
      assert_scalar2(min)
      assert_scalar2(max)
      command(list("ZREMRANGEBYLEX", key, min, max))
    },
    ZREMRANGEBYRANK = function(key, start, stop) {
      assert_scalar2(key)
      assert_scalar2(start)
      assert_scalar2(stop)
      command(list("ZREMRANGEBYRANK", key, start, stop))
    },
    ZREMRANGEBYSCORE = function(key, min, max) {
      assert_scalar2(key)
      assert_scalar2(min)
      assert_scalar2(max)
      command(list("ZREMRANGEBYSCORE", key, min, max))
    },
    ZREVRANGE = function(key, start, stop, withscores = NULL) {
      assert_scalar2(key)
      assert_scalar2(start)
      assert_scalar2(stop)
      assert_match_value_or_null(withscores, c("WITHSCORES"))
      command(list("ZREVRANGE", key, start, stop, withscores))
    },
    ZREVRANGEBYSCORE = function(key, max, min, withscores = NULL, LIMIT = NULL) {
      assert_scalar2(key)
      assert_scalar2(max)
      assert_scalar2(min)
      assert_match_value_or_null(withscores, c("WITHSCORES"))
      assert_length_or_null(LIMIT, 2L)
      command(list("ZREVRANGEBYSCORE", key, max, min, withscores, cmd_command("LIMIT", LIMIT, TRUE)))
    },
    ZREVRANK = function(key, member) {
      assert_scalar2(key)
      assert_scalar2(member)
      command(list("ZREVRANK", key, member))
    },
    ZSCORE = function(key, member) {
      assert_scalar2(key)
      assert_scalar2(member)
      command(list("ZSCORE", key, member))
    },
    ZUNION = function(numkeys, key, WEIGHTS = NULL, AGGREGATE = NULL, withscores = NULL) {
      assert_scalar2(numkeys)
      assert_match_value_or_null(AGGREGATE, c("SUM", "MIN", "MAX"))
      assert_match_value_or_null(withscores, c("WITHSCORES"))
      command(list("ZUNION", numkeys, key, cmd_command("WEIGHTS", WEIGHTS, TRUE), cmd_command("AGGREGATE", AGGREGATE, FALSE), withscores))
    },
    ZMSCORE = function(key, member) {
      assert_scalar2(key)
      command(list("ZMSCORE", key, member))
    },
    ZUNIONSTORE = function(destination, numkeys, key, WEIGHTS = NULL, AGGREGATE = NULL) {
      assert_scalar2(destination)
      assert_scalar2(numkeys)
      assert_match_value_or_null(AGGREGATE, c("SUM", "MIN", "MAX"))
      command(list("ZUNIONSTORE", destination, numkeys, key, cmd_command("WEIGHTS", WEIGHTS, TRUE), cmd_command("AGGREGATE", AGGREGATE, FALSE)))
    },
    SCAN = function(cursor, MATCH = NULL, COUNT = NULL, TYPE = NULL) {
      assert_scalar2(cursor)
      assert_scalar_or_null2(MATCH)
      assert_scalar_or_null2(COUNT)
      assert_scalar_or_null2(TYPE)
      command(list("SCAN", cursor, cmd_command("MATCH", MATCH, FALSE), cmd_command("COUNT", COUNT, FALSE), cmd_command("TYPE", TYPE, FALSE)))
    },
    SSCAN = function(key, cursor, MATCH = NULL, COUNT = NULL) {
      assert_scalar2(key)
      assert_scalar2(cursor)
      assert_scalar_or_null2(MATCH)
      assert_scalar_or_null2(COUNT)
      command(list("SSCAN", key, cursor, cmd_command("MATCH", MATCH, FALSE), cmd_command("COUNT", COUNT, FALSE)))
    },
    HSCAN = function(key, cursor, MATCH = NULL, COUNT = NULL) {
      assert_scalar2(key)
      assert_scalar2(cursor)
      assert_scalar_or_null2(MATCH)
      assert_scalar_or_null2(COUNT)
      command(list("HSCAN", key, cursor, cmd_command("MATCH", MATCH, FALSE), cmd_command("COUNT", COUNT, FALSE)))
    },
    ZSCAN = function(key, cursor, MATCH = NULL, COUNT = NULL) {
      assert_scalar2(key)
      assert_scalar2(cursor)
      assert_scalar_or_null2(MATCH)
      assert_scalar_or_null2(COUNT)
      command(list("ZSCAN", key, cursor, cmd_command("MATCH", MATCH, FALSE), cmd_command("COUNT", COUNT, FALSE)))
    },
    XINFO = function(CONSUMERS = NULL, GROUPS = NULL, STREAM = NULL, help = NULL) {
      assert_length_or_null(CONSUMERS, 2L)
      assert_scalar_or_null2(GROUPS)
      assert_scalar_or_null2(STREAM)
      assert_match_value_or_null(help, c("HELP"))
      command(list("XINFO", cmd_command("CONSUMERS", CONSUMERS, TRUE), cmd_command("GROUPS", GROUPS, FALSE), cmd_command("STREAM", STREAM, FALSE), help))
    },
    XADD = function(key, ID, field, value) {
      assert_scalar2(key)
      assert_scalar2(ID)
      field <- cmd_interleave(field, value)
      command(list("XADD", key, ID, field))
    },
    XTRIM = function(key, strategy, count, approx = NULL) {
      assert_scalar2(key)
      assert_match_value(strategy, c("MAXLEN"))
      assert_match_value_or_null(approx, c("~"))
      assert_scalar2(count)
      command(list("XTRIM", key, strategy, approx, count))
    },
    XDEL = function(key, ID) {
      assert_scalar2(key)
      command(list("XDEL", key, ID))
    },
    XRANGE = function(key, start, end, COUNT = NULL) {
      assert_scalar2(key)
      assert_scalar2(start)
      assert_scalar2(end)
      assert_scalar_or_null2(COUNT)
      command(list("XRANGE", key, start, end, cmd_command("COUNT", COUNT, FALSE)))
    },
    XREVRANGE = function(key, end, start, COUNT = NULL) {
      assert_scalar2(key)
      assert_scalar2(end)
      assert_scalar2(start)
      assert_scalar_or_null2(COUNT)
      command(list("XREVRANGE", key, end, start, cmd_command("COUNT", COUNT, FALSE)))
    },
    XLEN = function(key) {
      assert_scalar2(key)
      command(list("XLEN", key))
    },
    XREAD = function(streams, key, id, COUNT = NULL, BLOCK = NULL) {
      assert_scalar_or_null2(COUNT)
      assert_scalar_or_null2(BLOCK)
      assert_match_value(streams, c("STREAMS"))
      command(list("XREAD", cmd_command("COUNT", COUNT, FALSE), cmd_command("BLOCK", BLOCK, FALSE), streams, key, id))
    },
    XGROUP = function(CREATE = NULL, SETID = NULL, DESTROY = NULL, CREATECONSUMER = NULL, DELCONSUMER = NULL) {
      assert_length_or_null(CREATE, 3L)
      assert_length_or_null(SETID, 3L)
      assert_length_or_null(DESTROY, 2L)
      assert_length_or_null(CREATECONSUMER, 3L)
      assert_length_or_null(DELCONSUMER, 3L)
      command(list("XGROUP", cmd_command("CREATE", CREATE, TRUE), cmd_command("SETID", SETID, TRUE), cmd_command("DESTROY", DESTROY, TRUE), cmd_command("CREATECONSUMER", CREATECONSUMER, TRUE), cmd_command("DELCONSUMER", DELCONSUMER, TRUE)))
    },
    XREADGROUP = function(GROUP, streams, key, ID, COUNT = NULL, BLOCK = NULL, noack = NULL) {
      assert_length(GROUP, 2L)
      assert_scalar_or_null2(COUNT)
      assert_scalar_or_null2(BLOCK)
      assert_match_value_or_null(noack, c("NOACK"))
      assert_match_value(streams, c("STREAMS"))
      command(list("XREADGROUP", cmd_command("GROUP", GROUP, TRUE), cmd_command("COUNT", COUNT, FALSE), cmd_command("BLOCK", BLOCK, FALSE), noack, streams, key, ID))
    },
    XACK = function(key, group, ID) {
      assert_scalar2(key)
      assert_scalar2(group)
      command(list("XACK", key, group, ID))
    },
    XCLAIM = function(key, group, consumer, min_idle_time, ID, IDLE = NULL, TIME = NULL, RETRYCOUNT = NULL, force = NULL, justid = NULL) {
      assert_scalar2(key)
      assert_scalar2(group)
      assert_scalar2(consumer)
      assert_scalar2(min_idle_time)
      assert_scalar_or_null2(IDLE)
      assert_scalar_or_null2(TIME)
      assert_scalar_or_null2(RETRYCOUNT)
      assert_match_value_or_null(force, c("FORCE"))
      assert_match_value_or_null(justid, c("JUSTID"))
      command(list("XCLAIM", key, group, consumer, min_idle_time, ID, cmd_command("IDLE", IDLE, FALSE), cmd_command("TIME", TIME, FALSE), cmd_command("RETRYCOUNT", RETRYCOUNT, FALSE), force, justid))
    },
    XPENDING = function(key, group, start = NULL, end = NULL, count = NULL, consumer = NULL) {
      assert_scalar2(key)
      assert_scalar2(group)
      assert_scalar_or_null2(start)
      assert_scalar_or_null2(end)
      assert_scalar_or_null2(count)
      assert_scalar_or_null2(consumer)
      command(list("XPENDING", key, group, start, end, count, consumer))
    },
    LATENCY_DOCTOR = function() {
      command(list("LATENCY", "DOCTOR"))
    },
    LATENCY_GRAPH = function(event) {
      assert_scalar2(event)
      command(list("LATENCY", "GRAPH", event))
    },
    LATENCY_HISTORY = function(event) {
      assert_scalar2(event)
      command(list("LATENCY", "HISTORY", event))
    },
    LATENCY_LATEST = function() {
      command(list("LATENCY", "LATEST"))
    },
    LATENCY_RESET = function(event = NULL) {
      command(list("LATENCY", "RESET", event))
    },
    LATENCY_HELP = function() {
      command(list("LATENCY", "HELP"))
    })
}
cmd_since <- numeric_version(c(
  ACL_CAT = "6.0.0",
  ACL_DELUSER = "6.0.0",
  ACL_GENPASS = "6.0.0",
  ACL_GETUSER = "6.0.0",
  ACL_HELP = "6.0.0",
  ACL_LIST = "6.0.0",
  ACL_LOAD = "6.0.0",
  ACL_LOG = "6.0.0",
  ACL_SAVE = "6.0.0",
  ACL_SETUSER = "6.0.0",
  ACL_USERS = "6.0.0",
  ACL_WHOAMI = "6.0.0",
  APPEND = "2.0.0",
  AUTH = "1.0.0",
  BGREWRITEAOF = "1.0.0",
  BGSAVE = "1.0.0",
  BITCOUNT = "2.6.0",
  BITFIELD = "3.2.0",
  BITOP = "2.6.0",
  BITPOS = "2.8.7",
  BLMOVE = "6.2.0",
  BLPOP = "2.0.0",
  BRPOP = "2.0.0",
  BRPOPLPUSH = "2.2.0",
  BZPOPMAX = "5.0.0",
  BZPOPMIN = "5.0.0",
  CLIENT_CACHING = "6.0.0",
  CLIENT_GETNAME = "2.6.9",
  CLIENT_GETREDIR = "6.0.0",
  CLIENT_ID = "5.0.0",
  CLIENT_KILL = "2.4.0",
  CLIENT_LIST = "2.4.0",
  CLIENT_PAUSE = "2.9.50",
  CLIENT_REPLY = "3.2.0",
  CLIENT_SETNAME = "2.6.9",
  CLIENT_TRACKING = "6.0.0",
  CLIENT_UNBLOCK = "5.0.0",
  CLUSTER_ADDSLOTS = "3.0.0",
  CLUSTER_BUMPEPOCH = "3.0.0",
  CLUSTER_COUNT_FAILURE_REPORTS = "3.0.0",
  CLUSTER_COUNTKEYSINSLOT = "3.0.0",
  CLUSTER_DELSLOTS = "3.0.0",
  CLUSTER_FAILOVER = "3.0.0",
  CLUSTER_FLUSHSLOTS = "3.0.0",
  CLUSTER_FORGET = "3.0.0",
  CLUSTER_GETKEYSINSLOT = "3.0.0",
  CLUSTER_INFO = "3.0.0",
  CLUSTER_KEYSLOT = "3.0.0",
  CLUSTER_MEET = "3.0.0",
  CLUSTER_MYID = "3.0.0",
  CLUSTER_NODES = "3.0.0",
  CLUSTER_REPLICAS = "5.0.0",
  CLUSTER_REPLICATE = "3.0.0",
  CLUSTER_RESET = "3.0.0",
  CLUSTER_SAVECONFIG = "3.0.0",
  CLUSTER_SET_CONFIG_EPOCH = "3.0.0",
  CLUSTER_SETSLOT = "3.0.0",
  CLUSTER_SLAVES = "3.0.0",
  CLUSTER_SLOTS = "3.0.0",
  COMMAND = "2.8.13",
  COMMAND_COUNT = "2.8.13",
  COMMAND_GETKEYS = "2.8.13",
  COMMAND_INFO = "2.8.13",
  CONFIG_GET = "2.0.0",
  CONFIG_RESETSTAT = "2.0.0",
  CONFIG_REWRITE = "2.8.0",
  CONFIG_SET = "2.0.0",
  DBSIZE = "1.0.0",
  DEBUG_OBJECT = "1.0.0",
  DEBUG_SEGFAULT = "1.0.0",
  DECR = "1.0.0",
  DECRBY = "1.0.0",
  DEL = "1.0.0",
  DISCARD = "2.0.0",
  DUMP = "2.6.0",
  ECHO = "1.0.0",
  EVAL = "2.6.0",
  EVALSHA = "2.6.0",
  EXEC = "1.2.0",
  EXISTS = "1.0.0",
  EXPIRE = "1.0.0",
  EXPIREAT = "1.2.0",
  FLUSHALL = "1.0.0",
  FLUSHDB = "1.0.0",
  GEOADD = "3.2.0",
  GEODIST = "3.2.0",
  GEOHASH = "3.2.0",
  GEOPOS = "3.2.0",
  GEORADIUS = "3.2.0",
  GEORADIUSBYMEMBER = "3.2.0",
  GET = "1.0.0",
  GETBIT = "2.2.0",
  GETRANGE = "2.4.0",
  GETSET = "1.0.0",
  HDEL = "2.0.0",
  HELLO = "6.0.0",
  HEXISTS = "2.0.0",
  HGET = "2.0.0",
  HGETALL = "2.0.0",
  HINCRBY = "2.0.0",
  HINCRBYFLOAT = "2.6.0",
  HKEYS = "2.0.0",
  HLEN = "2.0.0",
  HMGET = "2.0.0",
  HMSET = "2.0.0",
  HSCAN = "2.8.0",
  HSET = "2.0.0",
  HSETNX = "2.0.0",
  HSTRLEN = "3.2.0",
  HVALS = "2.0.0",
  INCR = "1.0.0",
  INCRBY = "1.0.0",
  INCRBYFLOAT = "2.6.0",
  INFO = "1.0.0",
  KEYS = "1.0.0",
  LASTSAVE = "1.0.0",
  LATENCY_DOCTOR = "2.8.13",
  LATENCY_GRAPH = "2.8.13",
  LATENCY_HELP = "2.8.13",
  LATENCY_HISTORY = "2.8.13",
  LATENCY_LATEST = "2.8.13",
  LATENCY_RESET = "2.8.13",
  LINDEX = "1.0.0",
  LINSERT = "2.2.0",
  LLEN = "1.0.0",
  LMOVE = "6.2.0",
  LOLWUT = "5.0.0",
  LPOP = "1.0.0",
  LPOS = "6.0.6",
  LPUSH = "1.0.0",
  LPUSHX = "2.2.0",
  LRANGE = "1.0.0",
  LREM = "1.0.0",
  LSET = "1.0.0",
  LTRIM = "1.0.0",
  MEMORY_DOCTOR = "4.0.0",
  MEMORY_HELP = "4.0.0",
  MEMORY_MALLOC_STATS = "4.0.0",
  MEMORY_PURGE = "4.0.0",
  MEMORY_STATS = "4.0.0",
  MEMORY_USAGE = "4.0.0",
  MGET = "1.0.0",
  MIGRATE = "2.6.0",
  MODULE_LIST = "4.0.0",
  MODULE_LOAD = "4.0.0",
  MODULE_UNLOAD = "4.0.0",
  MONITOR = "1.0.0",
  MOVE = "1.0.0",
  MSET = "1.0.1",
  MSETNX = "1.0.1",
  MULTI = "1.2.0",
  OBJECT = "2.2.3",
  PERSIST = "2.2.0",
  PEXPIRE = "2.6.0",
  PEXPIREAT = "2.6.0",
  PFADD = "2.8.9",
  PFCOUNT = "2.8.9",
  PFMERGE = "2.8.9",
  PING = "1.0.0",
  PSETEX = "2.6.0",
  PSUBSCRIBE = "2.0.0",
  PSYNC = "2.8.0",
  PTTL = "2.6.0",
  PUBLISH = "2.0.0",
  PUBSUB = "2.8.0",
  PUNSUBSCRIBE = "2.0.0",
  QUIT = "1.0.0",
  RANDOMKEY = "1.0.0",
  READONLY = "3.0.0",
  READWRITE = "3.0.0",
  RENAME = "1.0.0",
  RENAMENX = "1.0.0",
  REPLICAOF = "5.0.0",
  RESTORE = "2.6.0",
  ROLE = "2.8.12",
  RPOP = "1.0.0",
  RPOPLPUSH = "1.2.0",
  RPUSH = "1.0.0",
  RPUSHX = "2.2.0",
  SADD = "1.0.0",
  SAVE = "1.0.0",
  SCAN = "2.8.0",
  SCARD = "1.0.0",
  SCRIPT_DEBUG = "3.2.0",
  SCRIPT_EXISTS = "2.6.0",
  SCRIPT_FLUSH = "2.6.0",
  SCRIPT_KILL = "2.6.0",
  SCRIPT_LOAD = "2.6.0",
  SDIFF = "1.0.0",
  SDIFFSTORE = "1.0.0",
  SELECT = "1.0.0",
  SET = "1.0.0",
  SETBIT = "2.2.0",
  SETEX = "2.0.0",
  SETNX = "1.0.0",
  SETRANGE = "2.2.0",
  SHUTDOWN = "1.0.0",
  SINTER = "1.0.0",
  SINTERSTORE = "1.0.0",
  SISMEMBER = "1.0.0",
  SLAVEOF = "1.0.0",
  SLOWLOG = "2.2.12",
  SMEMBERS = "1.0.0",
  SMISMEMBER = "6.2.0",
  SMOVE = "1.0.0",
  SORT = "1.0.0",
  SPOP = "1.0.0",
  SRANDMEMBER = "1.0.0",
  SREM = "1.0.0",
  SSCAN = "2.8.0",
  STRALGO = "6.0.0",
  STRLEN = "2.2.0",
  SUBSCRIBE = "2.0.0",
  SUNION = "1.0.0",
  SUNIONSTORE = "1.0.0",
  SWAPDB = "4.0.0",
  SYNC = "1.0.0",
  TIME = "2.6.0",
  TOUCH = "3.2.1",
  TTL = "1.0.0",
  TYPE = "1.0.0",
  UNLINK = "4.0.0",
  UNSUBSCRIBE = "2.0.0",
  UNWATCH = "2.2.0",
  WAIT = "3.0.0",
  WATCH = "2.2.0",
  XACK = "5.0.0",
  XADD = "5.0.0",
  XCLAIM = "5.0.0",
  XDEL = "5.0.0",
  XGROUP = "5.0.0",
  XINFO = "5.0.0",
  XLEN = "5.0.0",
  XPENDING = "5.0.0",
  XRANGE = "5.0.0",
  XREAD = "5.0.0",
  XREADGROUP = "5.0.0",
  XREVRANGE = "5.0.0",
  XTRIM = "5.0.0",
  ZADD = "1.2.0",
  ZCARD = "1.2.0",
  ZCOUNT = "2.0.0",
  ZINCRBY = "1.2.0",
  ZINTER = "6.2.0",
  ZINTERSTORE = "2.0.0",
  ZLEXCOUNT = "2.8.9",
  ZMSCORE = "6.2.0",
  ZPOPMAX = "5.0.0",
  ZPOPMIN = "5.0.0",
  ZRANGE = "1.2.0",
  ZRANGEBYLEX = "2.8.9",
  ZRANGEBYSCORE = "1.0.5",
  ZRANK = "2.0.0",
  ZREM = "1.2.0",
  ZREMRANGEBYLEX = "2.8.9",
  ZREMRANGEBYRANK = "2.0.0",
  ZREMRANGEBYSCORE = "1.2.0",
  ZREVRANGE = "1.2.0",
  ZREVRANGEBYLEX = "2.8.9",
  ZREVRANGEBYSCORE = "2.2.0",
  ZREVRANK = "2.0.0",
  ZSCAN = "2.8.0",
  ZSCORE = "1.2.0",
  ZUNION = "6.2.0",
  ZUNIONSTORE = "2.0.0"))
