#!/usr/bin/bash
###################################需要修改的参数#########################################
#记录总时间,单位s
TOTAL_TIME_SECONDS=300
#统计一次后休眠x秒,统计内存用的dumpsys meminfo 耗时较长
SLEEP_TIME=1
#要统计的进程包名,默认包含系统cpu和内存,请注意:使用空格隔开
PACKAGE_LIST=("com.android.settings" "com.android.systemui")
#输出路径
OUTPUT_PATH="/sdcard/cpu-mem.csv"
###################################需要修改的参数#########################################

#表头:系统cpu, 用户cpu
TABLE_HEADER="seconds,user_cpu,sys_cpu"
#匹配多个进程包名的表达式
EXPR=""
#内存字段
for package in ${PACKAGE_LIST[@]};
do
    TABLE_HEADER=$TABLE_HEADER","$package"-MEM"
    if [[ -z $EXPR ]];
    then
        EXPR="\$12 == \"$package\""
    else
        EXPR="$EXPR || \$12 == \"$package\""
    fi
done
#CPU字段
for package in ${PACKAGE_LIST[@]}
do
    TABLE_HEADER=$TABLE_HEADER","$package"-CPU"
done

echo "packages: ${PACKAGE_LIST[*]}"
#系统内存
TABLE_HEADER=$TABLE_HEADER",sys_mem"
echo "FIELDS: "$TABLE_HEADER;
#排除awk进程本身,user匹配系统cpu行
EXPR="$EXPR || /%user/ && \$12 !~ /awk/  "
# EXPR="$EXPR"
echo "EXPR: $EXPR"
echo "output path: $OUTPUT_PATH"

echo $TABLE_HEADER >> $OUTPUT_PATH
i=0
while (( i<$TOTAL_TIME_SECONDS))
do
    echo "$i/$TOTAL_TIME_SECONDS"
    ((i++))
    SYSTEM_MEM=`free -k |grep Mem |awk -v FS=" " '{print $3}'`
    #读取PSS内存
    for j in "${!PACKAGE_LIST[@]}";
    do
        PSS_MEM[$j]=$(dumpsys meminfo --package "${PACKAGE_LIST[$j]}" |grep TOTAL |awk -v FS=" " -v OFS="," '(NR==1){print $2} ')
        #echo "${PACKAGE_LIST[$j]} - ${PSS_MEM[$j]}"
    done
    top -b -d 1 -n 1 | \
    awk -v FS=" " -v OFS="," -v proc_list="${PACKAGE_LIST[*]}" -v mem_list="${PSS_MEM[*]}" \
    'BEGIN{ 
        #print proc_list","mem_list
        len=split(proc_list,procs," "); 
        split(mem_list,pss_mem, " ")
    } \
    '"$EXPR"'{ 
        if($2 ~ "user"){ 
            #sys_cpu=$4; 
            #user_cpu=$2;
            split($4,sys_cpu_l,"%");
            sys_cpu=sys_cpu_l[1]"%";
            split($2,user_cpu_l,"%");
            user_cpu=user_cpu_l[1]"%";
            #print "System cpu: "sys_cpu","user_cpu;
        } 
        else{ 
            #top 12列为包名,9列CPU, 10列内存百分比
            CPU[$12]=$9;
            MEM[$12]=$10;
        } 
        #print;
    }END{ 
     	mem=""; 
    	cpu=""; 
        #按进程数组顺序输出到一行,i从1开始
        for(i=1; i<=len; i++){
            if(i < len){ 
                #这里用PSS内存
                mem=mem""pss_mem[i]",";
                cpu=cpu""CPU[procs[i]]","; 
            } 
            else { 
                mem=mem""pss_mem[i];
                cpu=cpu""CPU[procs[i]]; 
            } 
        }
        print "'$i',"user_cpu","sys_cpu","mem","cpu",'$SYSTEM_MEM'" 
    }' >> $OUTPUT_PATH
    #清除内存单位K
    #sed -i 's/K,/,/g' $OUTPUT_PATH
    sleep $SLEEP_TIME
done


