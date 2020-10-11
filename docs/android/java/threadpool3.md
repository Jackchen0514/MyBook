# Java线程池ThreadPoolExecutor使用和分析(三) - 终止线程池原理

## shutdown()  --  温柔的终止线程池

{%ace edit=true lang='java'%}

/**
 * Initiates an orderly shutdown in which previously submitted
 * tasks are executed, but no new tasks will be accepted.
 * Invocation has no additional effect if already shut down.
 * 开始一个有序的关闭，在关闭中，之前提交的任务会被执行（包含正在执行的，在阻塞队列中的），但新任务会被拒绝
 * 如果线程池已经shutdown，调用此方法不会有附加效应
 *
 * <p>This method does not wait for previously submitted tasks to
 * complete execution.  Use {@link #awaitTermination awaitTermination}
 * to do that.
 * 当前方法不会等待之前提交的任务执行结束，可以使用awaitTermination()
 *
 * @throws SecurityException {@inheritDoc}
 */
public void shutdown() {
    final ReentrantLock mainLock = this.mainLock;
    mainLock.lock(); //上锁

    try {
        //判断调用者是否有权限shutdown线程池
        checkShutdownAccess();

        //CAS+循环设置线程池状态为shutdown
        advanceRunState(SHUTDOWN);

        //中断所有空闲线程
        interruptIdleWorkers();

        onShutdown(); // hook for ScheduledThreadPoolExecutor
    }
    finally {
        mainLock.unlock(); //解锁
    }

    //尝试终止线程池
    tryTerminate();
}

{%endace%}

**shutdown()执行流程**：

1、上锁，mainLock是线程池的主锁，是可重入锁，当要操作workers set这个保持线程的HashSet时，需要先获取mainLock，还有当要处理largestPoolSize、completedTaskCount这类统计数据时需要先获取mainLock

2、判断调用者是否有权限shutdown线程池

3、使用CAS操作将线程池状态设置为shutdown，shutdown之后将不再接收新任务

4、中断所有空闲线程  interruptIdleWorkers()

5、onShutdown()，ScheduledThreadPoolExecutor中实现了这个方法，可以在shutdown()时做一些处理

6、解锁

7、尝试终止线程池  tryTerminate()

可以看到shutdown()方法最重要的几个步骤是：`更新线程池状态为shutdown`、`中断所有空闲线程`、`tryTerminated()尝试终止线程池`

那么，什么是空闲线程？interruptIdleWorkers() 是怎么中断空闲线程的？

{%ace edit=true lang='java'%}

/**
 * Interrupts threads that might be waiting for tasks (as
 * indicated by not being locked) so they can check for
 * termination or configuration changes. Ignores
 * SecurityExceptions (in which case some threads may remain
 * uninterrupted).
 * 中断在等待任务的线程(没有上锁的)，中断唤醒后，可以判断线程池状态是否变化来决定是否继续
 *
 * @param onlyOne If true, interrupt at most one worker. This is
 * called only from tryTerminate when termination is otherwise
 * enabled but there are still other workers.  In this case, at
 * most one waiting worker is interrupted to propagate shutdown
 * signals in case(以免) all threads are currently waiting.
 * Interrupting any arbitrary thread ensures that newly arriving
 * workers since shutdown began will also eventually exit.
 * To guarantee eventual termination, it suffices to always
 * interrupt only one idle worker, but shutdown() interrupts all
 * idle workers so that redundant workers exit promptly, not
 * waiting for a straggler task to finish.
 *
 * onlyOne如果为true，最多interrupt一个worker
 * 只有当终止流程已经开始，但线程池还有worker线程时,tryTerminate()方法会做调用onlyOne为true的调用
 * （终止流程已经开始指的是：shutdown状态 且 workQueue为空，或者 stop状态）
 * 在这种情况下，最多有一个worker被中断，为了传播shutdown信号，以免所有的线程都在等待
 * 为保证线程池最终能终止，这个操作总是中断一个空闲worker
 * 而shutdown()中断所有空闲worker，来保证空闲线程及时退出
 */
private void interruptIdleWorkers(boolean onlyOne) {
    final ReentrantLock mainLock = this.mainLock;
    mainLock.lock(); //上锁
    try {
        for (Worker w : workers) {
            Thread t = w.thread;

            if (!t.isInterrupted() && w.tryLock()) {
                try {
                    t.interrupt();
                } catch (SecurityException ignore) {
                } finally {
                    w.unlock();
                }
            }
            if (onlyOne)
                break;
        }
    } finally {
        mainLock.unlock(); //解锁
    }
}

{%endace%}

interruptIdleWorkers() 首先会获取mainLock锁，因为要迭代workers set，在中断每个worker前，需要做两个判断：

1、线程是否已经被中断，是就什么都不做

2、worker.tryLock() 是否成功

第二个判断比较重要，因为Worker类除了实现了可执行的Runnable，也继承了AQS，本身也是一把锁，具体可见 ThreadPoolExecutor内部类Worker解析

tryLock()调用了Worker自身实现的tryAcquire()方法，这也是AQS规定子类需要实现的尝试获取锁的方法

{%ace edit=true lang='java'%}

protected boolean tryAcquire(int unused) {
    if (compareAndSetState(0, 1)) {
        setExclusiveOwnerThread(Thread.currentThread());
        return true;
    }
    return false;
}

{%endace%}

tryAcquire()先尝试将AQS的state从0-->1，返回true代表上锁成功，并设置当前线程为锁的拥有者

可以看到compareAndSetState(0, 1)只尝试了一次获取锁，且不是每次state+1，而是0-->1，说明锁不是可重入的



但是为什么要worker.tryLock()获取worker的锁呢？

这就是Woker类存在的价值之一，控制线程中断

在runWorker()方法中每次获取到task，task.run()之前都需要worker.lock()上锁，运行结束后解锁，即正在运行任务的工作线程都是上了worker锁的

![image](https://images2015.cnblogs.com/blog/677054/201704/677054-20170411225458469-685583225.jpg)

在interruptIdleWorkers()中断之前需要先tryLock()获取worker锁，意味着正在运行的worker不能中断，因为worker.tryLock()失败，且锁是不可重入的

故shutdown()只有对能获取到worker锁的空闲线程（正在从workQueue中getTask()，此时worker没有加锁）发送中断信号

由此可以将worker划分为：
1、空闲worker：正在从workQueue阻塞队列中获取任务的worker
2、运行中worker：正在task.run()执行任务的worker

正阻塞在getTask()获取任务的worker在被中断后，会抛出InterruptedException，不再阻塞获取任务

捕获中断异常后，将继续循环到getTask()最开始的判断线程池状态的逻辑，当线程池是shutdown状态，且workQueue.isEmpty时，return null，进行worker线程退出逻辑



某些情况下，interruptIdleWorkers()时多个worker正在运行，不会对其发出中断信号，假设此时workQueue也不为空

那么当多个worker运行结束后，会到workQueue阻塞获取任务，获取到的执行任务，没获取到的，如果还是核心线程，会一直workQueue.take()阻塞住，线程无法终止，因为workQueue已经空了，且shutdown后不会接收新任务了

这就需要在shutdown()后，还可以发出中断信号

Doug Lea大神巧妙的在所有可能导致线程池产终止的地方安插了tryTerminated()尝试线程池终止的逻辑，并在其中判断如果线程池已经进入终止流程，没有任务等待执行了，但线程池还有线程，中断唤醒一个空闲线程

shutdown()的最后也调用了tryTerminated()方法，下面看看这个方法的逻辑：

{%ace edit=true lang='java'%}

/**
 * Transitions to TERMINATED state if either (SHUTDOWN and pool
 * and queue empty) or (STOP and pool empty).  If otherwise
 * eligible to terminate but workerCount is nonzero, interrupts an
 * idle worker to ensure that shutdown signals propagate. This
 * method must be called following any action that might make
 * termination possible -- reducing worker count or removing tasks
 * from the queue during shutdown. The method is non-private to
 * allow access from ScheduledThreadPoolExecutor.
 *
 * 在以下情况将线程池变为TERMINATED终止状态
 * shutdown 且 正在运行的worker 和 workQueue队列 都empty
 * stop 且  没有正在运行的worker
 *
 * 这个方法必须在任何可能导致线程池终止的情况下被调用，如：
 * 减少worker数量
 * shutdown时从queue中移除任务
 *
 * 这个方法不是私有的，所以允许子类ScheduledThreadPoolExecutor调用
 */
final void tryTerminate() {
    //这个for循环主要是和进入关闭线程池操作的CAS判断结合使用的
    for (;;) {
        int c = ctl.get();

        /**
         * 线程池是否需要终止
         * 如果以下3中情况任一为true，return，不进行终止
         * 1、还在运行状态
         * 2、状态是TIDYING、或 TERMINATED，已经终止过了
         * 3、SHUTDOWN 且 workQueue不为空
         */
        if (isRunning(c) ||
            runStateAtLeast(c, TIDYING) ||
            (runStateOf(c) == SHUTDOWN && ! workQueue.isEmpty()))
            return;

        /**
         * 只有shutdown状态 且 workQueue为空，或者 stop状态能执行到这一步
         * 如果此时线程池还有线程（正在运行任务，正在等待任务）
         * 中断唤醒一个正在等任务的空闲worker
         * 唤醒后再次判断线程池状态，会return null，进入processWorkerExit()流程
         */
        if (workerCountOf(c) != 0) { // Eligible to terminate 资格终止
            interruptIdleWorkers(ONLY_ONE); //中断workers集合中的空闲任务，参数为true，只中断一个
            return;
        }

        /**
         * 如果状态是SHUTDOWN，workQueue也为空了，正在运行的worker也没有了，开始terminated
         */
        final ReentrantLock mainLock = this.mainLock;
        mainLock.lock();
        try {
            //CAS：将线程池的ctl变成TIDYING（所有的任务被终止，workCount为0，为此状态时将会调用terminated()方法），期间ctl有变化就会失败，会再次for循环
            if (ctl.compareAndSet(c, ctlOf(TIDYING, 0))) {
                try {
                    terminated(); //需子类实现
                }
                finally {
                    ctl.set(ctlOf(TERMINATED, 0)); //将线程池的ctl变成TERMINATED
                    termination.signalAll(); //唤醒调用了 等待线程池终止的线程 awaitTermination()
                }
                return;
            }
        }
        finally {
            mainLock.unlock();
        }
        // else retry on failed CAS
        // 如果上面的CAS判断false，再次循环
    }
}

{%endace%}

tryTerminate() 执行流程：

1、判断线程池是否需要进入终止流程（只有当shutdown状态+workQueue.isEmpty 或 stop状态，才需要）

2、判断线程池中是否还有线程，有则 interruptIdleWorkers(ONLY_ONE) 尝试中断一个空闲线程（正是这个逻辑可以再次发出中断信号，中断阻塞在获取任务的线程）

3、如果状态是SHUTDOWN，workQueue也为空了，正在运行的worker也没有了，开始terminated
    会先上锁，将线程池置为tidying状态，之后调用需子类实现的 terminated()，最后线程池置为terminated状态，并唤醒所有等待线程池终止这个Condition的线程

## shutdownNow()  --  强硬的终止线程池

{%ace edit=true lang='java'%}

/**
 * Attempts to stop all actively executing tasks, halts the
 * processing of waiting tasks, and returns a list of the tasks
 * that were awaiting execution. These tasks are drained (removed)
 * from the task queue upon return from this method.
 * 尝试停止所有活动的正在执行的任务，停止等待任务的处理，并返回正在等待被执行的任务列表
 * 这个任务列表是从任务队列中排出（删除）的
 *
 * <p>This method does not wait for actively executing tasks to
 * terminate.  Use {@link #awaitTermination awaitTermination} to
 * do that.
 * 这个方法不用等到正在执行的任务结束，要等待线程池终止可使用awaitTermination()
 *
 * <p>There are no guarantees beyond best-effort attempts to stop
 * processing actively executing tasks.  This implementation
 * cancels tasks via {@link Thread#interrupt}, so any task that
 * fails to respond to interrupts may never terminate.
 * 除了尽力尝试停止运行中的任务，没有任何保证
 * 取消任务是通过Thread.interrupt()实现的，所以任何响应中断失败的任务可能永远不会结束
 *
 * @throws SecurityException {@inheritDoc}
 */
public List<Runnable> shutdownNow() {
    List<Runnable> tasks;
    final ReentrantLock mainLock = this.mainLock;
    mainLock.lock(); //上锁

    try {
        //判断调用者是否有权限shutdown线程池
        checkShutdownAccess();

        //CAS+循环设置线程池状态为stop
        advanceRunState(STOP);

        //中断所有线程，包括正在运行任务的
        interruptWorkers();

        tasks = drainQueue(); //将workQueue中的元素放入一个List并返回
    }
    finally {
        mainLock.unlock(); //解锁
    }

    //尝试终止线程池
    tryTerminate();

    return tasks; //返回workQueue中未执行的任务
}

{%endace%}

shutdownNow() 和 shutdown()的大体流程相似，差别是：

1、将线程池更新为stop状态

2、调用 interruptWorkers() 中断所有线程，包括正在运行的线程

3、将workQueue中待处理的任务移到一个List中，并在方法最后返回，说明shutdownNow()后不会再处理workQueue中的任务

**interruptWorkers()**

{%ace edit=true lang='java'%}

private void interruptWorkers() {
    final ReentrantLock mainLock = this.mainLock;
    mainLock.lock();
    try {
        for (Worker w : workers)
            w.interruptIfStarted();
    } finally {
        mainLock.unlock();
    }
}

{%endace%}

interruptWorkers() 很简单，循环对所有worker调用 interruptIfStarted()，其中会判断worker的AQS state是否大于0，即worker是否已经开始运作，再调用Thread.interrupt()

需要注意的是，对于运行中的线程调用Thread.interrupt()并不能保证线程被终止，task.run()内部可能捕获了InterruptException，没有上抛，导致线程一直无法结束

参数：
    timeout：超时时间
    unit：     timeout超时时间的单位
返回：
    true：线程池终止
    false：超过timeout指定时间
在发出一个shutdown请求后，在以下3种情况发生之前，awaitTermination()都会被阻塞
1、所有任务完成执行
2、到达超时时间
3、当前线程被中断

```
/**
 * Wait condition to support awaitTermination
 */
private final Condition termination = mainLock.newCondition();
```

awaitTermination() 循环的判断线程池是否terminated终止 或 是否已经超过超时时间，然后通过termination这个Condition阻塞等待一段时间

termination.awaitNanos() 是通过 LockSupport.parkNanos(this, nanosTimeout)实现的阻塞等待

阻塞等待过程中发生以下具体情况会解除阻塞（对上面3种情况的解释）：

1、如果发生了 termination.signalAll()（内部实现是 LockSupport.unpark()）会唤醒阻塞等待，且由于ThreadPoolExecutor只有在 tryTerminated()尝试终止线程池成功，将线程池更新为terminated状态后才会signalAll()，故awaitTermination()再次判断状态会return true退出

2、如果达到了超时时间 termination.awaitNanos() 也会返回，此时nano==0，再次循环判断return false，等待线程池终止失败

3、如果当前线程被 Thread.interrupt()，termination.awaitNanos()会上抛InterruptException，awaitTermination()继续上抛给调用线程，会以异常的形式解除阻塞

故终止线程池并需要知道其是否终止可以用如下方式：

{%ace edit=true lang='java'%}

executorService.shutdown();
try{
    while(!executorService.awaitTermination(500, TimeUnit.MILLISECONDS)) {
        LOGGER.debug("Waiting for terminate");
    }
}
catch (InterruptedException e) {
    //中断处理
}

{%endace%}

## 参考

http://www.cnblogs.com/trust-freedom/p/6693601.html