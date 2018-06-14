# 深入理解线程池 -- ThreadPoolExecutor

## 线程池的重要性

线程是一个程序员一定会涉及到的一个概念，但是线程的创建和切换都是代价比较大的。所以，我们有没有一个好的方案能做到线程的复用呢？这就涉及到一个概念——线程池。合理的使用线程池能够带来3个很明显的好处：

- 降低资源消耗：通过重用已经创建的线程来降低线程创建和销毁的消耗
- 提高响应速度：任务到达时不需要等待线程创建就可以立即执行。
- 提高线程的可管理性：线程池可以统一管理、分配、调优和监控。

## Java多线程支持--ThreadPoolExecutor

java的线程池支持主要通过ThreadPoolExecutor来实现，我们使用的ExecutorService的各种线程池策略都是基于ThreadPoolExecutor实现的，所以ThreadPoolExecutor十分重要。要弄明白各种线程池策略，必须先弄明白ThreadPoolExecutor。

### 实现原理

首先看一个线程池的流程图：

![image](https://upload-images.jianshu.io/upload_images/2177145-33c7b5ff75cf2bf7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700)

- 调用ThreadPoolExecutor的execute提交线程，首先检查CorePool，如果CorePool内的线程小于CorePoolSize，新创建线程执行任务。
- 如果当前CorePool内的线程大于等于CorePoolSize，那么将线程加入到BlockingQueue。
- 如果不能加入BlockingQueue，在小于MaxPoolSize的情况下创建线程执行任务。
- 如果线程数大于等于MaxPoolSize，那么执行拒绝策略。

### 线程池的创建

{%ace edit=true lang='java'%}
    public ThreadPoolExecutor(int corePoolSize,
                              int maximumPoolSize,
                              long keepAliveTime,
                              TimeUnit unit,
                              BlockingQueue<Runnable> workQueue,
                              ThreadFactory threadFactory,
                              RejectedExecutionHandler handler) {
        if (corePoolSize < 0 ||
            maximumPoolSize <= 0 ||
            maximumPoolSize < corePoolSize ||
            keepAliveTime < 0)
            throw new IllegalArgumentException();
        if (workQueue == null || threadFactory == null || handler == null)
            throw new NullPointerException();
        this.corePoolSize = corePoolSize;
        this.maximumPoolSize = maximumPoolSize;
        this.workQueue = workQueue;
        this.keepAliveTime = unit.toNanos(keepAliveTime);
        this.threadFactory = threadFactory;
        this.handler = handler;
    }
{%endace%}

描述下上述参数：

|参数|描述|
|:--|:--|
|corePoolSize|核心线程池大小|
|maximumPoolSize|线程池最大容量大小|
|keepAliveTime|线程池空闲时，线程存活的时间|
|TimeUnit|时间单位|
|ThreadFactory|线程工厂|
|BlockingQueue|任务队列|
|RejectedExecutionHandler|线程拒绝策略|

### 线程提交

ThreadPoolExecutor的构造方法如上所示，但是只是做一些参数的初始化，ThreadPoolExecutor被初始化好之后便可以提交线程任务，线程的提交方法主要是execute和submit。这里主要说execute，submit会在后续的博文中分析。

{%ace edit=true lang='java'%}

    public void execute(Runnable command) {
        if (command == null)
            throw new NullPointerException();
        /*
         * Proceed in 3 steps:
         * 1.
         * 如果当前的线程数小于核心线程池的大小，根据现有的线程作为第一个Worker运行的线程，
         * 新建一个Worker，addWorker自动的检查当前线程池的状态和Worker的数量，
         * 防止线程池在不能添加线程的状态下添加线程
         *
         * 2.
         *  如果线程入队成功，然后还是要进行double-check的，因为线程池在入队之后状态是可能会发生变化的
         *
         * 3.
         * 如果task不能入队(队列满了)，这时候尝试增加一个新线程，如果增加失败那么当前的线程池状态变化了或者线程池已经满了
         * 然后拒绝task
        int c = ctl.get();
        //当前的Worker的数量小于核心线程池大小时，新建一个Worker。
        if (workerCountOf(c) < corePoolSize) {
            if (addWorker(command, true))
                return;
            c = ctl.get();
        }
        if (isRunning(c) && workQueue.offer(command)) {
            int recheck = ctl.get();
            if (! isRunning(recheck) && remove(command))//recheck防止线程池状态的突变，如果突变，那么将reject线程，防止workQueue中增加新线程
                reject(command);
            else if (workerCountOf(recheck) == 0)//上下两个操作都有addWorker的操作，但是如果在workQueue.offer的时候Worker变为0，
                                                //那么将没有Worker执行新的task，所以增加一个Worker.
                addWorker(null, false);
        }
        //如果workQueue满了，那么这时候可能还没到线程池的maxnum，所以尝试增加一个Worker
        else if (!addWorker(command, false))
            reject(command);//如果Worker数量到达上限，那么就拒绝此线程
    }
{%endace%}

- **核心方法：addWorker**

Worker的增加和Task的获取以及终止都是在此方法中实现的，也就是这一个方法里面包含了很多东西。在addWorker方法中提到了Status的概念，Status是线程池的核心概念，这里我们先看一段关于status的注释：



这里需要明确几个概念：

1.Worker和Task的区别，Worker是当前线程池中的线程，而task虽然是runnable，但是并没有真正执行，只是被Worker调用了run方法，后面会看到这部分的实现。

2.maximumPoolSize和corePoolSize的区别：这个概念很重要，maximumPoolSize为线程池最大容量，也就是说线程池最多能起多少Worker。corePoolSize是核心线程池的大小，当corePoolSize满了时，
同时workQueue full（ArrayBolckQueue是可能满的） 那么此时允许新建Worker去处理workQueue中的Task，但是不能超过maximumPoolSize。超过corePoolSize之外的线程会在空闲超时后终止。


## 参考

【1】 https://www.jianshu.com/p/ade771d2c9c0

【2】 https://juejin.im/entry/58fada5d570c350058d3aaad

【3】 https://www.cnblogs.com/trust-freedom/p/6594270.html

【4】 https://blog.csdn.net/owen_william/article/details/70664716