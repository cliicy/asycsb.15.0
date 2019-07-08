device=sfdv0n1
sfxcss=/dev/${device}
if [ "" != "echo ${device} | grep sfdv" ];then
    echo "sudo initcard ${sfxcss}"
    css_status=`locate css-status.sh`
    css_status_dir=${css_status%css-status.sh}
    echo "@@@@@ ${css_status_dir}"
    pushd ${css_status_dir}
    sudo sh ./initcard.sh --blk --cl --capacity=6400
    popd
else
    echo "sudo nvme format ${sfxcss}"
    sudo nvme format ${sfxcss}
fi

