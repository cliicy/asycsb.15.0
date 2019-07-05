#!/bin/bash


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

function aslog2csv()
{
    for f in `ls $presult/*.as_log`;
    do
        echo "device,used-bytes,free-wblocks,write,defrag-q,defrag-read,defrag-write" > ${f}.defrag.csv
        aslog_usage_fields="10,12,14,18,20,22,24"
        cat $f | grep defrag-write | awk '{gsub(":","",$0);gsub(",","|",$0);print $10",",$12",",$14",",$18",",$20",",$22",",$24}' >> ${f}.defrag.csv
        
        echo "free-kbytes,free-pct" > ${f}.sysmemory.csv
        aslog_usage_fields="11,13"
        cat $f | grep system-memory: | sed -r 's/\s+/,/g' | cut -d , -f ${aslog_usage_fields} >> ${f}.sysmemory.csv


        echo "used-bytes,avail-pct,cache-read-pct" > ${f}.availpct.csv
        aslog_usage_fields="12,14,16"
        cat $f | grep device-usage: | sed -r 's/\s+/,/g' | cut -d , -f ${aslog_usage_fields} >> ${f}.availpct.csv
    done
    mv *.csv $presult/csv/
}

presult=$1
aslog2csv
