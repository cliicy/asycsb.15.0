#!/bin/bash
## $1 /dev/sfxxxx
## $2 2 or 4 or 6 how many partitions of disk will be parted

function is_as_stop()
{
    sleep_sec=3
    for i in {0..100};
    do
        if [ "" ==  "`ps aux | grep asd | grep -v grep`" ];
        then echo "stopped"; break;
        else echo "stopping aerospike - waited $((${i}*${sleep_sec})) second(s)"; sleep ${sleep_sec};
        fi
    done
}

function is_as_started()
{
    sleep_sec=3
    for i in {0..100};
    do
        if [ "" !=  "`ps aux | grep asd | grep -v grep`" ];
        then echo "started"; break;
        else echo "starting aerospike - waited $((${i}*${sleep_sec})) second(s)"; sleep ${sleep_sec};
        fi
    done
}


sudo service aerospike stop
is_as_stop
echo $1
for device in $1;
do
sfxcss=/dev/${device}
sudo umount ${sfxcss}

if [ "" != "echo ${device} | grep sfdv" ];then
    css_status=`locate css-status.sh`
    css_status_dir=${css_status%css-status.sh}
    pushd ${css_status_dir}
    sudo sh ./initcard.sh --blk --cl --capacity=6400
    popd    
else
    echo "sudo nvme format ${sfxcss}"
    sudo nvme format ${sfxcss}
fi
sleep 30

case $2 in 
       1) 
         echo "1 partion" 
         echo "mklabel gpt
mkpart primary 0% 100%
quit
" | sudo parted ${sfxcss}
         ;; 
       2) 
         echo "2 partion" 
         echo "mklabel gpt
mkpart primary 0% 50%
mkpart primary 50% 100%
quit
" | sudo parted ${sfxcss}
         ;; 
       3) 
         echo "3 partion" 
         echo "mklabel gpt
mkpart primary 0% 33%
mkpart primary 33% 66%
mkpart primary 66% 100%
quit
" | sudo parted ${sfxcss}
         ;; 
       4) 
         echo "4 partion" 
         echo "mklabel gpt
mkpart primary 0% 25%
mkpart primary 25% 50%
mkpart primary 50% 75%
mkpart primary 75% 100%
quit
" | sudo parted ${sfxcss}
         ;; 
       8) 
         echo "8 partion" 
         echo "mklabel gpt
mkpart primary 0% 12%
mkpart primary 12% 25%
mkpart primary 25% 37%
mkpart primary 37% 50%
mkpart primary 50% 62%
mkpart primary 62% 75%
mkpart primary 75% 87%
mkpart primary 87% 100%
quit
" | sudo parted ${sfxcss}
         ;; 
esac 
done

as_conf=${2}Part_${device}_aerospike.conf
echo cp ./aerospike_conf/${as_conf} /etc/aerospike/aerospike.conf
sudo cp -f `pwd`/aerospike_conf/${as_conf} /etc/aerospike/aerospike.conf
sudo service aerospike restart
is_as_started
sleep 120
