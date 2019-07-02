#!/bin/bash

rcount=500000000
#rcount=500
maxetime=3600
#maxetime=60
host=192.168.11.52
port=3052
#disk="nvme0n1 sfd0n1"
disk="sfdv0n1"
#disk="nvme0n1"
threads=30
action=loadrun

for ds in ${disk};
do
    #partions="0 1 2 4 8"
    partions="0"
    bload=1
    for dp in ${partions};
    do
        echo "sh ./parteddevice.sh "${ds}" ${dp} ++++++++++"
        #sh ./parteddevice.sh "${disk}" ${dp} #for two namespaces together in the same aerospike.conf
        sh ./parteddevice.sh "${ds}" ${dp}
        
        workload_set="5_95_0_best_workloada 50_50_0_best_workloada"
        for workload in ${workload_set};
        do
            echo "**** bload=${bload}"
            if [ "${bload}" == "1" ]; then
                action=load
                echo "./loadrun.sh -a ${action} -n css_${ds} -b ${ds} -t 100 -r ${rcount} -c device -w n -g ${host} -p ${port} -l ${maxetime} -o ./asycsb_cfg/${workload}  -e ${dp}"
                ./loadrun.sh -a ${action} -n css_${ds} -b ${ds} -t ${threads} -r ${rcount} -c device -w n -g ${host} -p ${port} -l ${maxetime} -o ./asycsb_cfg/${workload} -e ${dp}
                bload=0
            fi
            action=run
            echo "./loadrun.sh -a ${action} -n css_${ds} -b ${ds} -t 100 -r ${rcount} -c device -w n -g ${host} -p ${port} -l ${maxetime} -o ./asycsb_cfg/${workload}  -e ${dp}"
            ./loadrun.sh -a ${action} -n css_${ds} -b ${ds} -t ${threads} -r ${rcount} -c device -w n -g ${host} -p ${port} -l ${maxetime} -o ./asycsb_cfg/${workload} -e ${dp}
        done
    done
done
