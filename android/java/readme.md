# Java基础

## 线程池

- ThreadPoolExecutor构造参数

```
public ThreadPoolExecutor(int corePoolSize,
                          int maximumPoolSize,
                          long keepAliveTime,
                          TimeUnit unit,
                          BlockingQueue<Runnable> workQueue,
                          ThreadFactory threadFactory,
                          RejectedExecutionHandler handler)
```

- 三种排队策略

   - SynchronousQueue
   - LinkedBlockingQueue
   - ArrayBlockingQueue

- threadFactory


- RejectedExecutionHandler

  - AbortPolicy
  - CallerRunsPolicy
  - DiscardOldestPolicy
  - DiscardPolicy

- ThreadPoolExecutor线程池执行流程

  - 少于corePoolSize
  - 大于等于corePoolSize，但队列workQueue未满
  - 大于等于corePoolSize，且队列workQueue已满，但线程池中的线程数量小于maximumPoolSize
  - 等于了maximumPoolSize，就用RejectedExecutionHandler来做拒绝处理

- Executors静态工厂创建几种常用的线程池

  - newFixedThreadPool
  - newSingleThreadExecutor
  - newCachedThreadPool
  - newScheduledThreadPool

