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
        mv ${f}*.csv $presult/csv/
    done
}


presult=$1
bldevice=$2
iostat2csv
result2csv $3 
aslog2csv
