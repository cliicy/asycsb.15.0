#!/bin/bash

#rcnts_3_2T="600000000 590000000 550000000 510000000 470000000 430000000 400000000"
rcnts_3_2T="400000000"
#rcnts_3_2T="40000"
#rcnts_6_4T="1200000000 937500000 875000000 812500000 750000000 687500000 625000000"
#rcnts_6_4T="1250000000"
#rcnts_6_4T="900000000"
rcnts_6_4T="1300000000"
rcnts_6_4T="1000000000"
#rcnts_6_4T="80000"
#rcnts_6_4T="500"
#rcount=500
maxetime=3600
#maxetime=60
loadmaxetime=14400
#host=192.168.4.139
host=10.1.131.5
port=3039
#disk="nvme0n1 sfd1n1"
#disk="sfdv0n1"
disk="$1"
#disk="nvme0n1"
threads=256
echo "disk=$1"

# $1=sfd1n1 or sfd0n1
BASE_PATH=$(cd `dirname $0`;pwd)
echo $BASE_PATH >/tmp/ll.log
pushd $BASE_PATH

for ds in ${disk};
do
    action=loadrun
    #action=run
    if [ "${action}" == "run" ]; then
        bload=0
    else
       bload=1
    fi
    disksize=`lsblk | grep -w ${ds}  |awk '{ print $4}'`
    echo ${disksize}
    if [ "${disksize}" == "2.9T" ]; then
        arr=${rcnts_3_2T}
        dp=2
    elif [ "${disksize}" == "5.8T" ]; then
        arr=${rcnts_6_4T}
        dp=3
    elif [ "${disksize}" == "6.3T" ]; then
        arr=${rcnts_6_4T}
        dp=3
    fi
    echo ${arr}
    for rcount in ${arr};
    do
        #workload_set="50_50_0_best_workloada 5_95_0_best_workloada"
        workload_set="50_50_0_best_workloada"
        for workload in ${workload_set};
        do
            echo "**** bload=${bload}"
            if [ "${bload}" == "1" ]; then
                echo "sh ./parteddevice.sh "${ds}" ${dp} rcount=${rcount} ++++++++++"
                sh ./gx_parteddevice.sh "${ds}" ${dp}
                action=load
                echo "./gx_loadrun.sh -a ${action} -n css_${ds} -b ${ds} -t ${threads} -r ${rcount} -c device -w n -g ${host} -p ${port} -l ${loadmaxetime} -o ./asycsb_cfg/${workload}  -e ${dp}"
                sh ./gx_loadrun.sh -a ${action} -n css_${ds} -b ${ds} -t ${threads} -r ${rcount} -c device -w n -g ${host} -p ${port} -l ${loadmaxetime} -o ./asycsb_cfg/${workload} -e ${dp}
                bload=0
            fi
            action=run
            echo "./gx_loadrun.sh -a ${action} -n css_${ds} -b ${ds} -t ${threads} -r ${rcount} -c device -w n -g ${host} -p ${port} -l ${maxetime} -o ./asycsb_cfg/${workload}  -e ${dp}"
            sh ./gx_loadrun.sh -a ${action} -n css_${ds} -b ${ds} -t ${threads} -r ${rcount} -c device -w n -g ${host} -p ${port} -l ${maxetime} -o ./asycsb_cfg/${workload} -e ${dp}
        done
    done
done

