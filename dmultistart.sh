#!/bin/bash

#rcnts_3_2T="625000000 590000000 550000000 510000000 470000000 430000000 400000000"
rcnts_3_2T="50000 5000"
#rcnts_6_4T="1250000000 937500000 875000000 812500000 750000000 687500000 625000000"
rcnts_6_4T="500000 50000"
#rcount=500
maxetime=60
loadmaxetime=14400
host=192.168.10.202
port=3021
disk="sfd0n1 sfd1n1"
#disk="sfdv0n1"
#disk="nvme0n1"
threads=48
action=loadrun

for ds in ${disk};
do
    bload=1
    disksize=`lsblk | grep -w ${ds}  |awk '{ print $4}'`
    echo ${disksize}
    if [ "${disksize}" == "2.9T" ]; then
        arr=${rcnts_3_2T}
        dp=2
    elif [ "${disksize}" == "5.8T" ]; then
        arr=${rcnts_6_4T}
        dp=3
    fi
    echo ${arr}
    for rcount in ${arr};
    do
        workload_set="5_95_0_best_workloada 50_50_0_best_workloada"
        for workload in ${workload_set};
        do
            echo "**** bload=${bload}"
            if [ "${bload}" == "1" ]; then
                echo "sh ./parteddevice.sh "${ds}" ${dp} rcount=${rcount} ++++++++++"
                sh ./parteddevice.sh "${ds}" ${dp}
                action=load
                echo "./loadrun.sh -a ${action} -n css_${ds} -b ${ds} -t 100 -r ${rcount} -c device -w n -g ${host} -p ${port} -l ${loadmaxetime} -o ./asycsb_cfg/${workload}  -e ${dp}"
                sh ./loadrun.sh -a ${action} -n css_${ds} -b ${ds} -t ${threads} -r ${rcount} -c device -w n -g ${host} -p ${port} -l ${loadmaxetime} -o ./asycsb_cfg/${workload} -e ${dp}
                bload=0
            fi
            action=run
            echo "./loadrun.sh -a ${action} -n css_${ds} -b ${ds} -t 100 -r ${rcount} -c device -w n -g ${host} -p ${port} -l ${maxetime} -o ./asycsb_cfg/${workload}  -e ${dp}"
            sh ./loadrun.sh -a ${action} -n css_${ds} -b ${ds} -t ${threads} -r ${rcount} -c device -w n -g ${host} -p ${port} -l ${maxetime} -o ./asycsb_cfg/${workload} -e ${dp}
        done
    done
done
