# adb命令
## 查看进程及Kill进程
```
adb shell kill [PID]       //杀死进程
adb 命令查看程序进程方便简洁高效
adb shell ps       //查看所有进程列表，Process Status
adb shell ps|grep <package_name>    //查看package_name程序进程
adb shell ps -x [PID]      //查看PID进程状态
adb shell top|grep <package_name> //实时监听程序进程的变化

eg:
adb shell ps -x 13699
USER           PID    PPID    VSIZE     RSS     WCHAN      PC               NAME
u0_a94    13699 1734  1653292 28404   ffffffff    00000000 S com.polysaas.mdm (u:6, s:6)
```