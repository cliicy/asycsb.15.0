#!/bin/bash

conf_dir=/etc/aerospike
default_conf=aerospike.conf
sfxd=("sfd2n1" "sfd0n1" "sfd1n1")
#daslog=/var/log/aerospike/aerospike.log
daslog=/opt/data/css/aerospike/aerospike.log

io_sec=5
#asrestart=1
asrestart=0
insertstart=1
oneY=100000000
exetime=3600

#ret=y means always use the configure file of workloads/workloada 
ret=y 
name_css_status=cssv-status.sh

function collect_sys_info() {
 # collect sys information, including
 # 1. cpu
 # 2. memory
 # 3. disk
 # 4. os
 local_output_dir=$1
 css_status=$2
 if [ "${local_output_dir}" == "" ]; 
 then
 local_output_dir=`pwd`
 fi
 
 if [ "${css_status}" == "" ]; 
 then
 css_status="css-status.sh"
 fi
 
 echo -e "\n[sys]" > ${local_output_dir}/sysinfo.txt
 cat /sys/class/dmi/id/sys_vendor \
 >> ${local_output_dir}/sysinfo.txt
 cat /sys/class/dmi/id/product_name \
 >> ${local_output_dir}/sysinfo.txt
 cat /sys/class/dmi/id/product_version \
 >> ${local_output_dir}/sysinfo.txt
 echo -e "\n[cpu]" >> ${local_output_dir}/sysinfo.txt
 lscpu >> ${local_output_dir}/sysinfo.txt
 echo -e "\n[memory]" >> ${local_output_dir}/sysinfo.txt
 free -h >> ${local_output_dir}/sysinfo.txt
 echo -e "\n[disk]" >> ${local_output_dir}/sysinfo.txt
 lsblk >> ${local_output_dir}/sysinfo.txt
 df -h >> ${local_output_dir}/sysinfo.txt
 echo -e "\n[nvme]" >> ${local_output_dir}/sysinfo.txt
 sudo nvme list >> ${local_output_dir}/sysinfo.txt
 echo -e "\n[os]" >> ${local_output_dir}/sysinfo.txt
 uname -a >> ${local_output_dir}/sysinfo.txt
 cat /etc/system-release >> ${local_output_dir}/sysinfo.txt
 echo -e "\n[css-status]" >> ${local_output_dir}/sysinfo.txt
 sudo ${css_status} >> ${local_output_dir}/sysinfo.txt
}

function prepare_conf()
{
    #asrestart=0 # only for test when don't need to restart aerospike server
    return # only for test  when don't need to restart aerospike server
    echo $1
    if [ "$1" = "all" ];then
       echo "will reset config file later: "
       sudo tune2fs -O has_journal /dev/$bldevice
       sudo mount /dev/$bldevice /opt/aerospike/data/
    else
       confpath=$conf_dir/sfx_aerospike/
       if [ "$recount" = "$oneY" ];then
           confpath=$confpath"1Y"
       fi
       echo "cp -P $confpath/$1_$default_conf $conf_dir/$default_conf"
       cp -P $confpath/$1_$default_conf $conf_dir/$default_conf
    fi
}


while getopts :a:b:e:l:n:m:d:h:c:w:t:r:o:s:g:p:i: vname 
do
    case "$vname" in
       a) #echo "$OPTARG: load | run | loadrun"
          action=$OPTARG
          ;;
       g) 
          echo $OPTARG
          host=$OPTARG
          ;;
       p)
          echo $OPTARG
          port=$OPTARG
          ;;
       e)
          echo $OPTARG
          parts=$OPTARG
          ;;
       i)
          echo $OPTARG
          insertstart=$OPTARG
          ;;
       w) #echo "$OPTARG: using the workloads/workloada totally? y|n"
          ret=$OPTARG 
          ;;
       t) #echo "threads=$OPTARG"
          thread=$OPTARG
          ;;
       r)
          recount=$OPTARG
          ;;
       l) echo $OPTARG 
          exetime=$OPTARG
          ;;
       c)
          device=$OPTARG
          prepare_conf $OPTARG 
          ;;

       n)
          echo "namespace: $OPTARG" 
          namespace=$OPTARG
          ;;
       b)
          echo "storage: $OPTARG" 
          bldevice=$OPTARG
          #bldevice=sfd0n1
          ;;
       m) echo $OPTARG
          ;;
       d) echo $OPTARG
          ;;
       o) echo "YCSB conf file path: $OPTARG"
          conf=$OPTARG
          ;;
       h) echo "-a for phrase: load | run | loadrun" 
          echo "-b : the name of storage"
          echo "-w : using the workloads/workloada totally? y|n"
          echo "-h for help"
          echo "-l: show|edit|add the logs information"
          echo "-n: show the name of namespace"
          echo "-d: set the name of namespace and also change the configuration value of datafile"
          echo "-e: for raw disk, parts means how many partitions needed to be fdisk or parted"
          echo "-m: set the name of namespace and also change the configuration value of memory-size"
          echo "-c: storage-engine: device|ext4|xfs"
          echo "-t: thread count: 100|50|200"
          echo "-r: recordcount: 50000000|100000000"
          echo "-g: host ip or name "
          echo "-o: YCSB conf file path: "
          ;;
       *) echo "Unknown option: $vname";;
esac
done

function is_aeroser_active()
{
    return  # test only
    echo "checking is_aeroser_active $1"
    tmpfile=$1
    sudo tail -f -n 0 $daslog  >> $tmpfile &
    while true
    do
        #echo "checking aerospike service is active or not......"
        grep "service ready: soon there will be cake!" $tmpfile
        if [ $? -eq 0 ];then
            echo "aerospike is active now!-----$2"
            break
        fi
        sleep 1
    done
}

function is_aeroser_stop()
{
    return
    echo "checking is_aeroser_stop $1"
    while true
    do
        grep "Active: inactive (dead)" $1
        if [ $? -eq 0 ];then
            echo "aerospike is stopped already!"
            break
        fi
        sleep 0.5
    done
}

function kill_sublogprocess()
{
    ps -ef | grep "tail -f -n 0" | awk {'print $2'} >ttr.txt
    cat ttr.txt | xargs sudo kill -9
}

function cls_data()
{
   fs=$1
   if [ $fs = "xfs" ];then
       echo "will clean the data from aerospike server"
       #service aerospike stop && rm -rf /opt/aerospike/xfsdata/*.dat
       sudo service aerospike stop
       sudo service aerospike status > asstatus.txt
       is_aeroser_stop asstatus.txt 
       sudo rm -rf /opt/aerospike/xfsdata/*.dat
       sudo umount /dev/${sfxd[2]}
       sudo mkfs -t xfs /dev/${sfxd[2]}
       sudo mount /dev/${sfxd[2]} /opt/aerospike/xfsdata
   fi
   if [ $fs = "ext4" ];then
       insertstart=0
       if [ "$asrestart" = "1" ];then
           sudo service aerospike stop
       fi
       sudo service aerospike status > asstatus.txt
       is_aeroser_stop asstatus.txt
       if [ "$insertstart" = "0" ];then
           echo "test"
           sudo rm -rf /opt/data/css/aerospike/*.dat
           echo "umount /dev/$bldevice"
           sudo umount /dev/$bldevice
           echo "mkfs.ext4 /dev/$bldevice"
           sudo mkfs.ext4 /dev/$bldevice
           echo "mount /dev/$bldevice /opt/data/css/aerospike"
           sudo mount /dev/$bldevice /opt/data/css/aerospike 
           sudo service aerospike start
       else
           echo "Don't need delete the old data and just insert loading" 
       fi
   fi
   if [ $fs = "device" ];then
       return #only for test
       echo "./parteddevice.sh /dev/$bldevice $parts"
       sh ./parteddevice.sh /dev/$bldevice $parts
   fi
}

flag=ycsb_
workload=`echo ${conf} | cut -d "/" -f3`
ns=`echo ${namespace} | cut -d "_" -f2`
#echo "99999999  ${ns} 99999999"

prefix=$flag`date +%Y%m%d_%H%M%S`_${workload%_workloada}_${parts}P_${ns}
echo "99999999  ${prefix} 99999999"
logctime=$flag`date +%Y%m%d_%H:%M:%S`
#root_dir=`pwd`
root_dir=/home/`whoami`/benchmark/aerospike
presult=$root_dir/$prefix
mkdir -p $presult/csv
cp -P $conf_dir/$default_conf $presult
dsfxmessage=/var/log/sfx_messages
running=$presult/$action


iostat2csv()
{
    echo "will save files in $presult to csv"
    #cpu_flag="avg-cpu:\s+%user\s+%nice\s+%system\s+%iowait\s+%steal\s+%idle"
    for f in `ls $presult/*.iostat`;
    do
        cat $f | grep -m 1 Device | sed -r 's/\s+/,/g' > $f.csv
        cat $f | grep ^$bldevice | sed -r 's/\s+/,/g' >> $f.csv

        # get cpu information to csv
        cpu_usage_fields="2,4,5,7"
        cat $f | grep -m 1 avg-cpu | sed -r 's/\s+/,/g' | cut -d , -f ${cpu_usage_fields} > ${f}_cpu.csv
        cat $f | grep -A 1 avg-cpu | grep -v -e -- -e avg-cpu | sed -r 's/\s+/,/g' | cut -d , -f ${cpu_usage_fields} >> ${f}_cpu.csv

        mv $f.csv $presult/csv/
        mv ${f}_cpu.csv $presult/csv/
        rm -rf ${f}.cpu
    done
}


result2csv()
{
    wl=$1
    rd=`echo $wl | cut -d "_" -f1`
    upd=`echo $wl | cut -d "_" -f2`
    inst=`echo $wl | cut -d "_" -f3`
    echo "$rd $upd $inst"

    echo "will save files in $presult to csv"
    for f in `ls $presult/*.result`;
    do
        cat $f | grep Throughput | sed -r 's/\s+//g' > ${f}.oa.csv
        cat $f | grep RunTime | sed -r 's/\s+//g' >> ${f}.oa.csv
        cat $f | grep Latency | sed -r 's/\s+//g' >> ${f}.oa.csv
        mv ${f}.oa.csv  $presult/csv/

        pct_lat="Max,Min,Avg,90,99,99.9,99.99"
        echo "ops/sec,${pct_lat} latency" > ${f}.csv
        cat $f | grep "current ops/sec" | sed -r 's/.*operations;\s([0-9.]+)\scurrent\sops.*Max=([0-9]+).*Min=([0-9.]+).*Avg=([0-9.]+).*90=([0-9.]+).*99=([0-9.]+).*99.9=([0-9.]+).*99.99=([0-9.]+).*/\1,\2,\3,\4,\5,\6,\7,\8/g' >> ${f}.csv

        cat $f | grep -iq "\[READ:"
        if [  $? == 0 ]; then
            pct_lat="Max-read,Min-read,Avg-read,90-read,99-read,99.9-read,99.99-read"
            echo "ops/sec,${pct_lat} latency" > ${f}.read.csv
        cat $f | grep "current ops/sec" | sed -r 's/.*operations;\s([0-9.]+)\scurrent\sops.*\[READ:.*Max=([0-9]+).*Min=([0-9.]+).*Avg=([0-9.]+).*90=([0-9.]+).*99=([0-9.]+).*99.9=([0-9.]+).*99.99=([0-9.]+)\]\s+\[.*/\1,\2,\3,\4,\5,\6,\7,\8/g' >> ${f}.read.csv
        fi

        cat $f | grep -iq "\[UPDATE:"
        if [  $? == 0 ]; then
            pct_lat="Max-update,Min-update,Avg-update,90-update,99-update,99.9-update,99.99-update"
            echo "ops/sec,${pct_lat} latency" > ${f}.update.csv
             if [ "${rd}" == "0" ]
            then
                cat $f | grep "current ops/sec" | sed -r 's/.*operations;\s([0-9.]+)\scurrent\sops.*\[UPDATE:.*Max=([0-9]+).*Min=([0-9.]+).*Avg=([0-9.]+).*90=([0-9.]+).*99=([0-9.]+).*99.9=([0-9.]+).*99.99=([0-9.]+)\]\s+\[.*/\1,\2,\3,\4,\5,\6,\7,\8/g' >> ${f}.update.csv
            else
                cat $f | grep "current ops/sec" | sed -r 's/.*operations;\s([0-9.]+)\scurrent\sops.*\[UPDATE:.*Max=([0-9]+).*Min=([0-9.]+).*Avg=([0-9.]+).*90=([0-9.]+).*99=([0-9.]+).*99.9=([0-9.]+).*99.99=([0-9.]+).*/\1,\2,\3,\4,\5,\6,\7,\8/g' >> ${f}.update.csv
            fi
        fi

        cat $f | grep -iq "\[INSERT:"
        if [  $? == 0 ]; then
            pct_lat="Max-insert,Min-insert,Avg-insert,90-insert,99-insert,99.9-insert,99.99-insert"
            echo "ops/sec,${pct_lat} latency" > ${f}.insert.csv
            cat $f | grep "current ops/sec" | sed -r 's/.*operations;\s([0-9.]+)\scurrent\sops.*\[INSERT:.*Max=([0-9]+).*Min=([0-9.]+).*Avg=([0-9.]+).*90=([0-9.]+).*99=([0-9.]+).*99.9=([0-9.]+).*99.99=([0-9.]+).*/\1,\2,\3,\4,\5,\6,\7,\8/g' >> ${f}.insert.csv
        fi

        mv ${f}*.csv  $presult/csv/
    done
}

flagjournal=journal.statue

function doload()
{
    device=$1
    io_sfx=$2
    echo device=$1 io_sfx=$2
    ppath=$running
    
    if [ "$device" = "ext4" ];then
        sudo dumpe2fs /dev/$2 | grep 'Filesystem features' | grep 'has_journal' | awk '{print $1 $2 $3}' > $flagjournal
        #cat $flagjournal
        if [ `grep "has_journal" $flagjournal` ];then
            echo "enable journal"
            #running=$running.has_journal
            ppath=$running.has_journal
        else
            echo "disabled journal"
            #running=${running/has_journal/no_journal}
            ppath=$running.no_journal
        fi
    fi

    as_log=$ppath.$device.as_log
    aslog_pid=$as_log.pid
    echo -e "$device aerospike log starts at: " $logctime "\n"  > $as_log
    sudo tail -f -n 0 $daslog  >> $as_log &
    echo $! > $aslog_pid

    sfxdriver_log=$ppath.$device.sfxd_message
    sfxdriver_pid=$sfxdriver_log.pid
    echo -e "$device sfxdriver_message starts at: " $logctime "\n"  > $sfxdriver_log
    sudo tail -f -n 0 $dsfxmessage  >> $sfxdriver_log &
    echo $! > $sfxdriver_pid

    iostat_log=$ppath.$device.iostat
    iostat_pid=$iostat_log.pid

    #iostat all of the sfdx devie, will change it later
    #lsblk | grep sfd | awk '{print "/dev/"$1}' | xargs iostat -txdm 1 >> $iostat_log &
    echo iostat -ctxdm /dev/$io_sfx $io_sec >> $iostat_log &
    iostat -ctxdm /dev/$io_sfx $io_sec >> $iostat_log &
    
    echo $! > $iostat_pid

    outfile=$ppath.$device.result

    #is_aeroser_active $as_log $action
    #asinfo -h $host -p $port -v service

    echo -e "$device $action phrase starts at:  "$logctime "\n"  > $outfile
    lsblk >> $outfile
    echo -e "\n"  >> $outfile
    #sudo css-status.sh >> $outfile
    collect_sys_info $presult ${name_css_status} 
    echo -e "\n"  >> $outfile
    asadm -h $host -p $port -e info >> $outfile
    echo -e "\n"  >> $outfile
    du -h /dev/$bldevice >> $outfile
    df -h /dev/$bldevice >> $outfile
    ls -lah /dev/$bldevice >> $outfile
    free -h >> $outfile
    #sudo netstat -nap | grep $port  >> $outfile
    echo -e "\n"  >> $outfile

    if [ "$ret" = "n" ];then
        echo "characterize parameters......namespace=$namespace threads=$thread  recordcount=$recount p=$port"
        if [ "$device" = "ext4" ];then
            echo ${conf}
        fi
        if [ "$device" = "device" ];then
            echo ${conf}
        fi
        echo "bin/ycsb load aerospike -P $conf -p as.host=$host -p as.port=$port -p as.namespace=$namespace -threads $thread -p recordcount=$recount -s >> $outfile 2>&1 " 
        ./bin/ycsb load aerospike -P ${conf} -p as.host=$host -p as.port=$port -p as.namespace=$namespace -threads $thread -p recordcount=$recount -s >> $outfile 2>&1
    elif [ "$ret" = "y" ];then
       echo "./bin/ycsb load aerospike -s -P ${conf} >> $outfile 2>&1.... $action"
       ./bin/ycsb load aerospike -s -P ${conf} >> $outfile 2>&1
    fi
    echo "66666666666  ${workload} cp -P $conf $presult/${workload}  666666"
    cp -P $conf $presult/${workload}
    cendtime=$flag`date +%Y%m%d_%H:%M:%S`
    
    echo -e "\n"  >> $outfile
    asadm -h $host -p $port -e info >> $outfile
    echo -e "\n"  >> $outfile
    du -h /dev/$bldevice >> $outfile
    df -h /dev/$bldevice >> $outfile
    ls -lah /dev/$bldevice >> $outfile
    free -h >> $outfile
    #sudo netstat -nap | grep $port  >> $outfile

    echo -e "\n$device $action phrase ends at: "$cendtime "\n"  >> $outfile &
    echo -e "\n$device sfxdriver_message ends at: "$cendtime "\n"  >> $sfxdriver_log &
    cat $aslog_pid | xargs sudo kill -9 &
    cat $iostat_pid | xargs sudo kill -9 &
    cat $sfxdriver_pid | xargs sudo kill -9 &
    rm -rf $presult/*pid
    iostat2csv
    result2csv ${workload} 
    kill_sublogprocess
}

function dorun()
{
    device=$1
    io_sfx=$2
    echo device=$1 io_sfx=$2
    action=run
    pp=$presult/$action
    #thread=60
    logctime=$flag`date +%Y%m%d_%H:%M:%S`

    if [ "$device" = "ext4" ];then
        sudo dumpe2fs /dev/$bldevice | grep 'Filesystem features' | grep 'has_journal' | awk '{print $1 $2 $3}' > $flagjournal
        if [ `grep "has_journal" $flagjournal` ];then
            echo "enable journal"
            pp=$pp.has_journal
        else
            echo "disabled journal"
            pp=$pp.no_journal
        fi
    fi

    as_log=$pp.$device.as_log
    aslog_pid=$as_log.pid
    echo -e "$device aerospike log starts at: " $logctime "\n"  > $as_log
    sudo tail -f -n 0 $daslog  >> $as_log &
    echo $! > $aslog_pid

    sfxdriver_log=$pp.$device.sfxd_message
    sfxdriver_pid=$sfxdriver_log.pid
    echo -e "$device sfxdriver_message starts at: " $logctime "\n"  > $sfxdriver_log
    sudo tail -f -n 0 $dsfxmessage  >> $sfxdriver_log &
    echo $! > $sfxdriver_pid

    iostat_log=$pp.$device.iostat
    iostat_pid=$iostat_log.pid

    #iostat all of the sfdx devie, will change it later
    #lsblk | grep sfd | awk '{print "/dev/"$1}' | xargs iostat -txdm 1 >> $iostat_log &
    echo iostat -ctxdm /dev/$io_sfx $io_sec >> $iostat_log &
    iostat -ctxdm /dev/$io_sfx $io_sec >> $iostat_log &

    echo $! > $iostat_pid

    outfile=$pp.$device.result


    echo -e "$device $action phrase starts at:  "$logctime "\n"  > $outfile

    lsblk >> $outfile
    echo -e "\n"  >> $outfile
    #sudo css-status.sh >> $outfile
    collect_sys_info $presult ${name_css_status} 
    echo -e "\n"  >> $outfile
    asadm -h $host -p $port -e info >> $outfile
    echo -e "\n"  >> $outfile
    du -h /dev/$bldevice >> $outfile
    df -h /dev/$bldevice >> $outfile
    ls -lah /dev/$bldevice >> $outfile
    free -h >> $outfile
    #sudo netstat -nap | grep $port  >> $outfile
    echo -e "\n"  >> $outfile

    if [ "$ret" = "n" ];then
        echo "bin/ycsb run aerospike -P ${conf} -p as.host=$host -p as.port=$port -p as.namespace=$namespace -threads $thread -p maxexecutiontime=$exetime -p recordcount=$recount -s >> $outfile 2>&1" >> $outfile
        ./bin/ycsb run aerospike -P ${conf} -p as.host=$host -p as.port=$port -p as.namespace=$namespace -threads $thread -p maxexecutiontime=$exetime -p recordcount=$recount -s >> $outfile 2>&1
    elif [ "$ret" = "y" ];then
        echo "bin/ycsb run aerospike -s -P ${conf} >> $outfile...... $action"
        ret=`./bin/ycsb run aerospike -s -P ${conf} >> $outfile 2>&1`
    fi

    echo "------- cp -P ${conf} $presult/${workload}-------"
    cp -P ${conf} $presult/${workload}
    cendtime=$flag`date +%Y%m%d_%H:%M:%S`
    
    echo -e "\n"  >> $outfile
    asadm -h $host -p $port -e info >> $outfile
    echo -e "\n"  >> $outfile
    du -h /dev/$bldevice >> $outfile
    df -h /dev/$bldevice >> $outfile
    ls -lah /dev/$bldevice >> $outfile
    free -h >> $outfile
#    sudo netstat -nap | grep $port  >> $outfile

    echo -e "\n$device $action phrase ends at: "$cendtime "\n"  >> $outfile &
    echo -e "\n$device sfxdriver_message ends at: "$cendtime "\n"  >> $sfxdriver_log &
    echo -e "\n$device aerospike log ends at: "$cendtime "\n"  >> $as_log &
    cat $iostat_pid | xargs sudo kill -9 &
    cat $sfxdriver_pid | xargs sudo kill -9 &
    cat $aslog_pid | xargs sudo kill -9 &
    rm -rf $presult/*pid
    iostat2csv
    result2csv ${workload}
    kill_sublogprocess
}

if [ "$action" = "loadrun" ];then
    #cls_data $device
    doload $device $bldevice
    dorun  $device $bldevice
elif [ "$action" = "load" ];then
    doload $device $bldevice
elif [ "$action" = "run" ];then
    dorun $device $bldevice
else
    echo "Run sudo bin/ycsb load aerospike -P workloads/workloada -p as.host=localhost -p as.namespace=$ -threads 100 -p recordcount=50000000 -s to star load phrase: " 
    echo "Run sudo ./bin/ycsb run aerospike -s -P workloads/workloada to start run phrase"
fi

