#!/bin/bash

disk="sfdv0n1"
rcount=1000
dp=3
for ds in ${disk};
do
    echo "sh ./parteddevice.sh "${ds}" ${dp} rcount=${rcount} ++++++++++"
    sh ./parteddevice.sh "${ds}" ${dp}
done
