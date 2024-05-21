# android-cpu-mem
通过循环执行 top, dumpsys meminfo, free来输出某个应用以及系统的内存和CPU,并将结果保存到.csv文件,可以通过Excel绘制图表直观展示应用性能
脚本可以同时统计多个app和系统本身的内存cpu使用数据

脚本通过的测试环境:

**Android P(9) API 28**

> top --version: toybox 0.7.6-android
>
> awk version 20121220

**Android S(12) API 31**

> adb shell top --version
>
> top --version: toybox 0.8.4-android
>
> awk version 20210215

## 输出样例

| seconds | user_cpu | sys_cpu | com.android.systemui-MEM | com.android.systemui-CPU | sys_mem |
| ------- | -------- | ------- | ------------------------ | ------------------------ | ------- |
| 1       | 58%      | 139%    | 80133                    | 0.0                      | 3768308 |
| 2       | 65%      | 57%     | 80101                    | 0.0                      | 3770012 |
| 3       | 43%      | 162%    | 79976                    | 0.0                      | 3766488 |
| 4       | 74%      | 100%    | 79989                    | 0.0                      | 3771724 |
| 5       | 107%     | 86%     | 79951                    | 0.0                      | 3774908 |
| 6       | 57%      | 146%    | 79948                    | 0.0                      | 3771672 |
| 7       | 74%      | 50%     | 79949                    | 0.0                      | 3773032 |

## 使用

### 修改参数

修改必要的参数,比如要监听的应用包名 `PACKAGE_LIST`,文件输出路径 `OUTPUT_PATH`,监控时间 `TOTAL_TIME_SECONDS`

### 运行并获取结果

```
#推送到系统目录
adb push sysui-settings-mem-cpu.sh /sdcard
#执行脚本
adb shell sh /sdcard/sysui-settings-mem-cpu.sh
#以下是输出类容
#监控的应用包名
packages: com.android.settings com.android.systemui
#表头字段
FIELDS: seconds,user_cpu,sys_cpu,com.android.settings-MEM,com.android.systemui-MEM,com.android.settings-CPU,com.android.systemui-CPU,sys_mem
#过滤的正则表达式
EXPR: $12 == "com.android.settings" || $12 == "com.android.systemui" || /%user/ && $12 !~ /awk/  
#文件输出路径
output path: /sdcard/cpu-mem.csv
```
## 更多

更多解析参考  [Android 性能统计](https://blog.dailys.top/#/info?blogOid=95)
