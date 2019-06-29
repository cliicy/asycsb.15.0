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
for ds in ${disk};
do
    #partions="0 1 2 4 8"
    partions="0"
    brestart=0
    for dp in ${partions};
    do
        echo "sh ./parteddevice.sh "${ds}" ${dp} ++++++++++"
        #sh ./parteddevice.sh "${disk}" ${dp} #for two namespaces together in the same aerospike.conf
        sh ./parteddevice.sh "${ds}" ${dp}
        brestart=1
        
        #workload_set="50_0_50_workloada 95_5_0_workloada 50_50_0_workloada 5_95_0_workloada"
        workload_set="50_0_50_best_workloada 50_50_0_best_workloada 5_95_0_best_workloada 95_5_0_best_workloada 50_0_50_normal_workloada 50_50_0_normal_workloada 5_95_0_normal_workloada 95_5_0_normal_workloada"
        for workload in ${workload_set};
        do
            echo "**** ${brestart}"
            if [ "${brestart}" == "0" ]; then
                sudo service aerospike stop
                sudo nvme format /dev/${ds}
                sudo service aerospike restart
                sleep 120
            fi
            echo "./loadrun.sh -a load -n css_${ds} -b ${ds} -t 100 -r ${rcount} -c device -w n -g ${host} -p ${port} -l ${maxetime} -o ./asycsb_cfg/${workload}  -e ${dp}"
            ./loadrun.sh -a load -n css_${ds} -b ${ds} -t 100 -r ${rcount} -c device -w n -g ${host} -p ${port} -l ${maxetime} -o ./asycsb_cfg/${workload} -e ${dp}
            brestart=0
        done
    done
done
