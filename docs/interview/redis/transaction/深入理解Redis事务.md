# 深入理解Redis事务

```
Redis可以看成NoSQL类型的数据库系统, Redis也提供了事务, 但是和传统的关系型数据库的事务既有相似性, 也存在区别.因为Redis的架构基于操作系统的多路复用的IO接口,主处理流程是一个单线程,因此对于一个完整的命令, 其处理都是原子性的, 但是如果需要将多个命令作为一个不可分割的处理序列, 就需要使用事务.
```
Redis事务有如下一些特点:

- 事务中的命令序列执行的时候是原子性的,也就是说,其不会被其他客户端的命令中断. 这和传统的数据库的事务的属性是类似的.
- 尽管Redis事务中的命令序列是原子执行的, 但是事务中的命令序列执行可以部分成功,这种情况下,Redis事务不会执行回滚操作. 这和传统关系型数据库的事务是有区别的.
- 尽管Redis有`RDB`和`AOF`两种数据持久化机制, 但是其设计目标是高效率的cache系统. Redis事务只保证将其命令序列中的操作结果提交到内存中,不保证持久化到磁盘文件. 更进一步的, Redis事务和RDB持久化机制没有任何关系, 因为RDB机制是对内存数据结构的全量的快照.由于AOF机制是一种增量持久化,所以事务中的命令序列会提交到AOF的缓存中.但是AOF机制将其缓存写入磁盘文件是由其配置的实现策略决定的,和Redis事务没有关系.

**Redis事务API**
从宏观上来讲, Redis事务开始后, 会缓存后续的操作命令及其操作数据,当事务提交时,原子性的执行缓存的命令序列.

从版本`2.2`开始,Redis提供了一种乐观的锁机制, 配合这种机制,Redis事务提交时, 变成了事务的条件执行. 具体的说,如果乐观锁失败了,事务提交时, 丢弃事务中的命令序列,如果乐观锁成功了, 事务提交时,才会执行其命令序列.当然,也可以不使用乐观锁机制, 在事务提交时, 无条件执行事务的命令序列.

Redis事务涉及到`MULTI`, `EXEC`, `DISCARD`, `WATCH`和`UNWATCH`这五个命令:

- 事务开始的命令是`MULTI`, 该命令返回`OK`提示信息. Redis不支持事务嵌套,执行多次MULTI命令和执行一次是相同的效果.嵌套执行MULTI命令时,Redis只是返回错误提示信息.
- `EXEC`是事务的提交命令,事务中的命令序列将被执行(或者不被执行,比如乐观锁失败等).该命令将返回响应数组,其内容对应事务中的命令执行结果.
- `WATCH`命令是开始执行乐观锁,该命令的参数是`key`(可以有多个), Redis将执行WATCH命令的客户端对象和key进行关联,如果其他客户端修改了这些key,则执行WATCH命令的客户端将被设置乐观锁失败的标志.该命令必须在事务开始前执行,即在执行MULTI命令前执行WATCH命令,否则执行无效,并返回错误提示信息.
- `UNWATCH`命令将取消当前客户端对象的乐观锁key,该客户端对象的事务提交将变成无条件执行.
- `DISCARD`命令将结束事务,并且会丢弃全部的命令序列.

需要注意的是,`EXEC`命令和`DISCARD`命令结束事务时,会调用`UNWATCH`命令,取消该客户端对象上所有的乐观锁key.



**无条件提交**
如果不使用乐观锁, 则事务为无条件提交.下面是一个事务执行的例子:
```sh
multi
+OK
incr key1
+QUEUED
set key2 val2
+QUEUED
exec
*2
:1
+OK
```

当客户端开始事务后, 后续发送的命令将被Redis缓存起来,Redis向客户端返回响应提示字符串`QUEUED`.当执行EXEC提交事务时,缓存的命令依次被执行,返回命令序列的执行结果.



**事务的错误处理**
事务提交命令`EXEC`有可能会失败, 有三种类型的失败场景:

- 在事务提交之前,客户端执行的命令缓存失败.比如命令的语法错误(命令参数个数错误, 不支持的命令等等).如果发生这种类型的错误,Redis将向客户端返回包含错误提示信息的响应.
- 事务提交时,之前缓存的命令有可能执行失败.
- 由于乐观锁失败,事务提交时,将丢弃之前缓存的所有命令序列.



当发生第一种失败的情况下,客户端在执行事务提交命令EXEC时,将丢弃事务中所有的命令序列.下面是一个例子:


```sh
multi
+OK
incr num1 num2
-ERR wrong number of arguments for 'incr' command
set key1 val1
+QUEUED
exec
-EXECABORT Transaction discarded because of previous errors.
```

命令`incr num1 num2`并没有缓存成功, 因为`incr`命令只允许有一个参数,是个语法错误的命令.Redis无法成功缓存该命令,向客户端发送错误提示响应.接下来的`set key1 val1`命令缓存成功.最后执行事务提交的时候,因为发生过命令缓存失败,所以事务中的所有命令序列被丢弃.

如果事务中的所有命令序列都缓存成功,在提交事务的时候,缓存的命令中仍可能执行失败.但Redis不会对事务做任何回滚补救操作.下面是一个这样的例子:

```sh
multi
+OK
set key1 val1
+QUEUED
lpop key1
+QUEUED
incr num1
+QUEUED
exec
*3
+OK
-WRONGTYPE Operation against a key holding the wrong kind of value
:1
```

所有的命令序列都缓存成功,但是在提交事务的时候,命令`set key1 val1`和`incr num1`执行成功了,Redis保存了其执行结果,但是命令`lpop key1`执行失败了.

**乐观锁机制**
Redis事务和乐观锁一起使用时,事务将成为有条件提交.

关于乐观锁,需要注意的是:

- `WATCH`命令必须在`MULTI`命令之前执行. WATCH命令可以执行多次.
- `WATCH`命令可以指定乐观锁的多个`key`,如果在事务过程中,任何一个key被其他客户端改变,则当前客户端的乐观锁失败,事务提交时,将丢弃所有命令序列.
- 多个客户端的`WATCH`命令可以指定相同的`key`.
- `WATCH`命令指定乐观锁后,可以接着执行`MULTI`命令进入事务上下文,也可以在WATCH命令和MULTI命令之间执行其他命令. 具体使用方式取决于场景需求,不在事务中的命令将立即被执行.
- 如果`WATCH`命令指定的乐观锁的`key`,被当前客户端改变,在事务提交时,乐观锁不会失败.
- 如果`WATCH`命令指定的乐观锁的`key`具有超时属性,并且该key在WATCH命令执行后, 在事务提交命令EXEC执行前超时, 则乐观锁不会失败.如果该key被其他客户端对象修改,则乐观锁失败.



一个执行乐观锁机制的事务例子:
```sh
rpush list v1 v2 v3
:3
watch list
+OK
multi
+OK
lpop list
+QUEUED
exec
*1
$2
v1
```

下面是另一个例子,乐观锁被当前客户端改变, 事务提交成功:
```sh
watch num
+OK
multi
+OK
incr num
+QUEUED
exec
*1
:2
```
Redis事务和乐观锁配合使用时, 可以构造实现单个Redis命令不能完成的更复杂的逻辑.

**Redis事务的源码实现机制**

首先,事务开始的`MULTI`命令执行的函数为`multiCommand`, 其实现为(multi.c):

```c
void multiCommand(redisClient *c) {
    if (c->flags & REDIS_MULTI) {
        addReplyError(c,"MULTI calls can not be nested");
        return;
    }
    c->flags |= REDIS_MULTI;
    addReply(c,shared.ok);
}
```

该命令只是在当前客户端对象上加上`REDIS_MULTI`标志, 表示该客户端进入了事务上下文.

客户端进入事务上下文后,后续执行的命令将被缓存. 函数`processCommand`是Redis处理客户端命令的入口函数, 其实现为(redis.c):
```c
int processCommand(redisClient *c) {
    /* The QUIT command is handled separately. Normal command procs will
     * go through checking for replication and QUIT will cause trouble
     * when FORCE_REPLICATION is enabled and would be implemented in
     * a regular command proc. */
    if (!strcasecmp(c->argv[0]->ptr,"quit")) {
        addReply(c,shared.ok);
        c->flags |= REDIS_CLOSE_AFTER_REPLY;
        return REDIS_ERR;
    }

    /* Now lookup the command and check ASAP about trivial error conditions
     * such as wrong arity, bad command name and so forth. */
    c->cmd = c->lastcmd = lookupCommand(c->argv[0]->ptr);
    if (!c->cmd) {
        flagTransaction(c);
        addReplyErrorFormat(c,"unknown command '%s'",
            (char*)c->argv[0]->ptr);
        return REDIS_OK;
    } else if ((c->cmd->arity > 0 && c->cmd->arity != c->argc) ||
               (c->argc < -c->cmd->arity)) {
        flagTransaction(c);
        addReplyErrorFormat(c,"wrong number of arguments for '%s' command",
            c->cmd->name);
        return REDIS_OK;
    }

    /* Check if the user is authenticated */
    if (server.requirepass && !c->authenticated && c->cmd->proc != authCommand)
    {
        flagTransaction(c);
        addReply(c,shared.noautherr);
        return REDIS_OK;
    }

    /* Handle the maxmemory directive.
     *
     * First we try to free some memory if possible (if there are volatile
     * keys in the dataset). If there are not the only thing we can do
     * is returning an error. */
    if (server.maxmemory) {
        int retval = freeMemoryIfNeeded();
        /* freeMemoryIfNeeded may flush slave output buffers. This may result
         * into a slave, that may be the active client, to be freed. */
        if (server.current_client == NULL) return REDIS_ERR;

        /* It was impossible to free enough memory, and the command the client
         * is trying to execute is denied during OOM conditions? Error. */
        if ((c->cmd->flags & REDIS_CMD_DENYOOM) && retval == REDIS_ERR) {
            flagTransaction(c);
            addReply(c, shared.oomerr);
            return REDIS_OK;
        }
    }

    /* Don't accept write commands if there are problems persisting on disk
     * and if this is a master instance. */
    if (((server.stop_writes_on_bgsave_err &&
          server.saveparamslen > 0 &&
          server.lastbgsave_status == REDIS_ERR) ||
          server.aof_last_write_status == REDIS_ERR) &&
        server.masterhost == NULL &&
        (c->cmd->flags & REDIS_CMD_WRITE ||
         c->cmd->proc == pingCommand))
    {
        flagTransaction(c);
        if (server.aof_last_write_status == REDIS_OK)
            addReply(c, shared.bgsaveerr);
        else
            addReplySds(c,
                sdscatprintf(sdsempty(),
                "-MISCONF Errors writing to the AOF file: %s\r\n",
                strerror(server.aof_last_write_errno)));
        return REDIS_OK;
    }

    /* Don't accept write commands if there are not enough good slaves and
     * user configured the min-slaves-to-write option. */
    if (server.masterhost == NULL &&
        server.repl_min_slaves_to_write &&
        server.repl_min_slaves_max_lag &&
        c->cmd->flags & REDIS_CMD_WRITE &&
        server.repl_good_slaves_count < server.repl_min_slaves_to_write)
    {
        flagTransaction(c);
        addReply(c, shared.noreplicaserr);
        return REDIS_OK;
    }

    /* Don't accept write commands if this is a read only slave. But
     * accept write commands if this is our master. */
    if (server.masterhost && server.repl_slave_ro &&
        !(c->flags & REDIS_MASTER) &&
        c->cmd->flags & REDIS_CMD_WRITE)
    {
        addReply(c, shared.roslaveerr);
        return REDIS_OK;
    }

    /* Only allow SUBSCRIBE and UNSUBSCRIBE in the context of Pub/Sub */
    if (c->flags & REDIS_PUBSUB &&
        c->cmd->proc != pingCommand &&
        c->cmd->proc != subscribeCommand &&
        c->cmd->proc != unsubscribeCommand &&
        c->cmd->proc != psubscribeCommand &&
        c->cmd->proc != punsubscribeCommand) {
        addReplyError(c,"only (P)SUBSCRIBE / (P)UNSUBSCRIBE / QUIT allowed in this context");
        return REDIS_OK;
    }

    /* Only allow INFO and SLAVEOF when slave-serve-stale-data is no and
     * we are a slave with a broken link with master. */
    if (server.masterhost && server.repl_state != REDIS_REPL_CONNECTED &&
        server.repl_serve_stale_data == 0 &&
        !(c->cmd->flags & REDIS_CMD_STALE))
    {
        flagTransaction(c);
        addReply(c, shared.masterdownerr);
        return REDIS_OK;
    }

    /* Loading DB? Return an error if the command has not the
     * REDIS_CMD_LOADING flag. */
    if (server.loading && !(c->cmd->flags & REDIS_CMD_LOADING)) {
        addReply(c, shared.loadingerr);
        return REDIS_OK;
    }

    /* Lua script too slow? Only allow a limited number of commands. */
    if (server.lua_timedout &&
          c->cmd->proc != authCommand &&
          c->cmd->proc != replconfCommand &&
        !(c->cmd->proc == shutdownCommand &&
          c->argc == 2 &&
          tolower(((char*)c->argv[1]->ptr)[0]) == 'n') &&
        !(c->cmd->proc == scriptCommand &&
          c->argc == 2 &&
          tolower(((char*)c->argv[1]->ptr)[0]) == 'k'))
    {
        flagTransaction(c);
        addReply(c, shared.slowscripterr);
        return REDIS_OK;
    }

    /* Exec the command */
    if (c->flags & REDIS_MULTI &&
        c->cmd->proc != execCommand && c->cmd->proc != discardCommand &&
        c->cmd->proc != multiCommand && c->cmd->proc != watchCommand)
    {
        queueMultiCommand(c);
        addReply(c,shared.queued);
    } else {
        call(c,REDIS_CALL_FULL);
        if (listLength(server.ready_keys))
            handleClientsBlockedOnLists();
    }
    return REDIS_OK;
}
```

Line145:151当客户端处于事务上下文时, 如果接收的是非事务命令(MULTI, EXEC, WATCH, DISCARD), 则调用`queueMultiCommand`将命令缓存起来,然后向客户端发送成功响应.

在函数`processCommand`中, 在缓存命令之前, 如果检查到客户端发送的命令不存在,或者命令参数个数不正确等情况, 会调用函数`flagTransaction`标命令缓存失败.也就是说,函数`processCommand`中, 所有调用函数`flagTransaction`的条件分支,都是返回失败响应.

缓存命令的函数`queueMultiCommand`的实现为(multi.c):
```c
/* Add a new command into the MULTI commands queue */
void queueMultiCommand(redisClient *c) {
    multiCmd *mc;
    int j;

    c->mstate.commands = zrealloc(c->mstate.commands,
            sizeof(multiCmd)*(c->mstate.count+1));
    mc = c->mstate.commands+c->mstate.count;
    mc->cmd = c->cmd;
    mc->argc = c->argc;
    mc->argv = zmalloc(sizeof(robj*)*c->argc);
    memcpy(mc->argv,c->argv,sizeof(robj*)*c->argc);
    for (j = 0; j < c->argc; j++)
        incrRefCount(mc->argv[j]);
    c->mstate.count++;
}
```

在事务上下文中, 使用`multiCmd`结构来缓存命令, 该结构定义为(redis.h):
```c
/* Client MULTI/EXEC state */
typedef struct multiCmd {
    robj **argv;
    int argc;
    struct redisCommand *cmd;
} multiCmd;
```

其中`argv`字段指向命令的参数内存地址,`argc`为命令参数个数, `cmd`为命令描述结构, 包括名字和函数指针等.

命令参数的内存空间已经使用动态分配记录于客户端对象的`argv`字段了, `multiCmd`结构的`argv`字段指向客户端对象`redisClient`的`argv`即可.

无法缓存命令时, 调用函数`flagTransaction`,该函数的实现为(multi.c):
```c
/* Flag the transacation as DIRTY_EXEC so that EXEC will fail.
 * Should be called every time there is an error while queueing a command. */
void flagTransaction(redisClient *c) {
    if (c->flags & REDIS_MULTI)
        c->flags |= REDIS_DIRTY_EXEC;
}
```

该函数在客户端对象中设置`REDIS_DIRTY_EXEC`标志, 如果设置了这个标志, 事务提交时, 命令序列将被丢弃.

最后,在事务提交时, 函数`processCommand`中将调用`call(c,REDIS_CALL_FULL);`, 其实现为(redis.c):
```c

/* Call() is the core of Redis execution of a command */
void call(redisClient *c, int flags) {
    long long dirty, start, duration;
    int client_old_flags = c->flags;

    /* Sent the command to clients in MONITOR mode, only if the commands are
     * not generated from reading an AOF. */
    if (listLength(server.monitors) &&
        !server.loading &&
        !(c->cmd->flags & (REDIS_CMD_SKIP_MONITOR|REDIS_CMD_ADMIN)))
    {
        replicationFeedMonitors(c,server.monitors,c->db->id,c->argv,c->argc);
    }

    /* Call the command. */
    c->flags &= ~(REDIS_FORCE_AOF|REDIS_FORCE_REPL);
    redisOpArrayInit(&server.also_propagate);
    dirty = server.dirty;
    start = ustime();
    c->cmd->proc(c);
    duration = ustime()-start;
    dirty = server.dirty-dirty;
    if (dirty < 0) dirty = 0;

    /* When EVAL is called loading the AOF we don't want commands called
     * from Lua to go into the slowlog or to populate statistics. */
    if (server.loading && c->flags & REDIS_LUA_CLIENT)
        flags &= ~(REDIS_CALL_SLOWLOG | REDIS_CALL_STATS);

    /* If the caller is Lua, we want to force the EVAL caller to propagate
     * the script if the command flag or client flag are forcing the
     * propagation. */
    if (c->flags & REDIS_LUA_CLIENT && server.lua_caller) {
        if (c->flags & REDIS_FORCE_REPL)
            server.lua_caller->flags |= REDIS_FORCE_REPL;
        if (c->flags & REDIS_FORCE_AOF)
            server.lua_caller->flags |= REDIS_FORCE_AOF;
    }

    /* Log the command into the Slow log if needed, and populate the
     * per-command statistics that we show in INFO commandstats. */
    if (flags & REDIS_CALL_SLOWLOG && c->cmd->proc != execCommand) {
        char *latency_event = (c->cmd->flags & REDIS_CMD_FAST) ?
                              "fast-command" : "command";
        latencyAddSampleIfNeeded(latency_event,duration/1000);
        slowlogPushEntryIfNeeded(c->argv,c->argc,duration);
    }
    if (flags & REDIS_CALL_STATS) {
        c->cmd->microseconds += duration;
        c->cmd->calls++;
    }

    /* Propagate the command into the AOF and replication link */
    if (flags & REDIS_CALL_PROPAGATE) {
        int flags = REDIS_PROPAGATE_NONE;

        if (c->flags & REDIS_FORCE_REPL) flags |= REDIS_PROPAGATE_REPL;
        if (c->flags & REDIS_FORCE_AOF) flags |= REDIS_PROPAGATE_AOF;
        if (dirty)
            flags |= (REDIS_PROPAGATE_REPL | REDIS_PROPAGATE_AOF);
        if (flags != REDIS_PROPAGATE_NONE)
            propagate(c->cmd,c->db->id,c->argv,c->argc,flags);
    }

    /* Restore the old FORCE_AOF/REPL flags, since call can be executed
     * recursively. */
    c->flags &= ~(REDIS_FORCE_AOF|REDIS_FORCE_REPL);
    c->flags |= client_old_flags & (REDIS_FORCE_AOF|REDIS_FORCE_REPL);

    /* Handle the alsoPropagate() API to handle commands that want to propagate
     * multiple separated commands. */
    if (server.also_propagate.numops) {
        int j;
        redisOp *rop;

        for (j = 0; j < server.also_propagate.numops; j++) {
            rop = &server.also_propagate.ops[j];
            propagate(rop->cmd, rop->dbid, rop->argv, rop->argc, rop->target);
        }
        redisOpArrayFree(&server.also_propagate);
    }
    server.stat_numcommands++;
}
```

在函数`call`中通过执行`c->cmd->proc(c);`调用具体的命令函数.事务提交命令`EXEC`对应的执行函数为`execCommand`, 其实现为(multi.c):
```c
void execCommand(redisClient *c) {
    int j;
    robj **orig_argv;
    int orig_argc;
    struct redisCommand *orig_cmd;
    int must_propagate = 0; /* Need to propagate MULTI/EXEC to AOF / slaves? */

    if (!(c->flags & REDIS_MULTI)) {
        addReplyError(c,"EXEC without MULTI");
        return;
    }

    /* Check if we need to abort the EXEC because:
     * 1) Some WATCHed key was touched.
     * 2) There was a previous error while queueing commands.
     * A failed EXEC in the first case returns a multi bulk nil object
     * (technically it is not an error but a special behavior), while
     * in the second an EXECABORT error is returned. */
    if (c->flags & (REDIS_DIRTY_CAS|REDIS_DIRTY_EXEC)) {
        addReply(c, c->flags & REDIS_DIRTY_EXEC ? shared.execaborterr :
                                                  shared.nullmultibulk);
        discardTransaction(c);
        goto handle_monitor;
    }

    /* Exec all the queued commands */
    unwatchAllKeys(c); /* Unwatch ASAP otherwise we'll waste CPU cycles */
    orig_argv = c->argv;
    orig_argc = c->argc;
    orig_cmd = c->cmd;
    addReplyMultiBulkLen(c,c->mstate.count);
    for (j = 0; j < c->mstate.count; j++) {
        c->argc = c->mstate.commands[j].argc;
        c->argv = c->mstate.commands[j].argv;
        c->cmd = c->mstate.commands[j].cmd;

        /* Propagate a MULTI request once we encounter the first write op.
         * This way we'll deliver the MULTI/..../EXEC block as a whole and
         * both the AOF and the replication link will have the same consistency
         * and atomicity guarantees. */
        if (!must_propagate && !(c->cmd->flags & REDIS_CMD_READONLY)) {
            execCommandPropagateMulti(c);
            must_propagate = 1;
        }

        call(c,REDIS_CALL_FULL);

        /* Commands may alter argc/argv, restore mstate. */
        c->mstate.commands[j].argc = c->argc;
        c->mstate.commands[j].argv = c->argv;
        c->mstate.commands[j].cmd = c->cmd;
    }
    c->argv = orig_argv;
    c->argc = orig_argc;
    c->cmd = orig_cmd;
    discardTransaction(c);
    /* Make sure the EXEC command will be propagated as well if MULTI
     * was already propagated. */
    if (must_propagate) server.dirty++;

handle_monitor:
    /* Send EXEC to clients waiting data from MONITOR. We do it here
     * since the natural order of commands execution is actually:
     * MUTLI, EXEC, ... commands inside transaction ...
     * Instead EXEC is flagged as REDIS_CMD_SKIP_MONITOR in the command
     * table, and we do it here with correct ordering. */
    if (listLength(server.monitors) && !server.loading)
        replicationFeedMonitors(c,server.monitors,c->db->id,c->argv,c->argc);
}
```
LINE8:11检查`EXEC`命令和`MULTI`命令是否配对使用, 单独执行EXEC命令是没有意义的.

LINE19:24检查客户端对象是否具有`REDIS_DIRTY_CAS`或者`REDIS_DIRTY_EXEC`标志, 如果存在,则调用函数`discardTransaction`丢弃命令序列, 向客户端返回失败响应.

如果没有检查到任何错误,则先执行`unwatchAllKeys(c);`取消该客户端上所有的乐观锁key.

LINE32:52依次执行缓存的命令序列,这里有两点需要注意的是:



- 事务可能需要同步到`AOF`缓存或者`replica`备份节点中.如果事务中的命令序列都是读操作, 则没有必要向AOF和replica进行同步.如果事务的命令序列中包含写命令,则`MULTI`, `EXEC`和相关的写命令会向AOF和replica进行同步.根据LINE41:44的条件判断,执行`execCommandPropagateMulti(c);`保证`MULTI`命令同步, LINE59检查`EXEC`命令是否需要同步, 即`MULTI`命令和`EXEC`命令必须保证配对同步.`EXEC`命令的同步执行在函数的`call`中LINE62`propagate(c->cmd,c->db->id,c->argv,c->argc,flags);`, 具体的写入命令由各自的执行函数负责同步.
- 这里执行命令序列时, 通过执行`call(c,REDIS_CALL_FULL);`所以`call`函数是递归调用.



所以,综上所述, Redis事务其本质就是,以不可中断的方式依次执行缓存的命令序列,将结果保存到内存cache中.

事务提交时, 丢弃命令序列会调用函数`discardTransaction`, 其实现为(multi.c):

```c
void discardTransaction(redisClient *c) {
    freeClientMultiState(c);
    initClientMultiState(c);
    c->flags &= ~(REDIS_MULTI|REDIS_DIRTY_CAS|REDIS_DIRTY_EXEC);
    unwatchAllKeys(c);
}
```
该函数调用`freeClientMultiState`释放`multiCmd`对象内存.调用`initClientMultiState`复位客户端对象的缓存命令管理结构.调用`unwatchAllKeys`取消该客户端的乐观锁.

`WATCH`命令执行乐观锁, 其对应的执行函数为`watchCommand`, 其实现为(multi.c):
```c
void watchCommand(redisClient *c) {
    int j;

    if (c->flags & REDIS_MULTI) {
        addReplyError(c,"WATCH inside MULTI is not allowed");
        return;
    }
    for (j = 1; j < c->argc; j++)
        watchForKey(c,c->argv[j]);
    addReply(c,shared.ok);
}
```
进而调用函数`watchForKey`, 其实现为(multi.c):
```c


/* Watch for the specified key */
void watchForKey(redisClient *c, robj *key) {
    list *clients = NULL;
    listIter li;
    listNode *ln;
    watchedKey *wk;

    /* Check if we are already watching for this key */
    listRewind(c->watched_keys,&li);
    while((ln = listNext(&li))) {
        wk = listNodeValue(ln);
        if (wk->db == c->db && equalStringObjects(key,wk->key))
            return; /* Key already watched */
    }
    /* This key is not already watched in this DB. Let's add it */
    clients = dictFetchValue(c->db->watched_keys,key);
    if (!clients) {
        clients = listCreate();
        dictAdd(c->db->watched_keys,key,clients);
        incrRefCount(key);
    }
    listAddNodeTail(clients,c);
    /* Add the new key to the list of keys watched by this client */
    wk = zmalloc(sizeof(*wk));
    wk->key = key;
    wk->db = c->db;
    incrRefCount(key);
    listAddNodeTail(c->watched_keys,wk);
}
```
关于乐观锁的`key`, 既保存于其客户端对象的`watched_keys`链表中, 也保存于全局数据库对象的`watched_keys`哈希表中.

LINE10:14检查客户端对象的链表中是否已经存在该key, 如果已经存在, 则直接返回.LINE16在全局数据库中返回该key对应的客户端对象链表, 如果链表不存在, 说明其他客户端没有使用该key作为乐观锁, 如果链表存在, 说明其他客户端已经使用该key作为乐观锁. LINE22将当前客户端对象记录于该key对应的链表中. LINE28将该key记录于当前客户端的key链表中.



当前客户端执行乐观锁以后, 其他客户端的写入命令可能修改该key值.所有具有写操作属性的命令都会执行函数`signalModifiedKey`, 其实现为(db.c):

```c
void signalModifiedKey(redisDb *db, robj *key) {    touchWatchedKey(db,key);}

```

函数`touchWatchedKey`的实现为(multi.c):
```c


/* "Touch" a key, so that if this key is being WATCHed by some client the
 * next EXEC will fail. */
void touchWatchedKey(redisDb *db, robj *key) {
    list *clients;
    listIter li;
    listNode *ln;

    if (dictSize(db->watched_keys) == 0) return;
    clients = dictFetchValue(db->watched_keys, key);
    if (!clients) return;

    /* Mark all the clients watching this key as REDIS_DIRTY_CAS */
    /* Check if we are already watching for this key */
    listRewind(clients,&li);
    while((ln = listNext(&li))) {
        redisClient *c = listNodeValue(ln);

        c->flags |= REDIS_DIRTY_CAS;
    }
}
```
语句`if (dictSize(db->watched_keys) == 0) return;`检查全局数据库中的哈希表`watched_keys`是否为空, 如果为空,说明没有任何客户端执行`WATCH`命令, 直接返回.如果该哈希表不为空, 取回该key对应的客户端链表结构,并把该链表中的每个客户端对象设置`REDIS_DIRTY_CAS`标志. 前面在`EXEC`的执行命令中,进行过条件判断, 如果客户端对象具有这个标志, 则丢弃事务中的命令序列.



在执行`EXEC`, `DISCARD`, `UNWATCH`命令以及在客户端结束连接的时候,都会取消乐观锁, 最终都会执行函数`unwatchAllKeys`, 其实现为(multi.c):
```c


/* Unwatch all the keys watched by this client. To clean the EXEC dirty
 * flag is up to the caller. */
void unwatchAllKeys(redisClient *c) {
    listIter li;
    listNode *ln;

    if (listLength(c->watched_keys) == 0) return;
    listRewind(c->watched_keys,&li);
    while((ln = listNext(&li))) {
        list *clients;
        watchedKey *wk;

        /* Lookup the watched key -> clients list and remove the client
         * from the list */
        wk = listNodeValue(ln);
        clients = dictFetchValue(wk->db->watched_keys, wk->key);
        redisAssertWithInfo(c,NULL,clients != NULL);
        listDelNode(clients,listSearchKey(clients,c));
        /* Kill the entry at all if this was the only client */
        if (listLength(clients) == 0)
            dictDelete(wk->db->watched_keys, wk->key);
        /* Remove this watched key from the client->watched list */
        listDelNode(c->watched_keys,ln);
        decrRefCount(wk->key);
        zfree(wk);
    }
}
```
语句`if (listLength(c->watched_keys) == 0) return;`判断如果当前客户端对象的`watched_keys`链表为空,说明当前客户端没有执行`WATCH`命令,直接返回.如果该链表非空, 则依次遍历该链表中的key, 并从该链表中删除key, 同时,获得全局数据库中的哈希表`watched_keys`中该key对应的客户端链表, 删除当前客户端对象.

[原文地址](https://mp.weixin.qq.com/s/GT72uRg2tULITNXXaQa2zg)