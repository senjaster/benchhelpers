#!/bin/bash

source ./loop_ssh.sh

default_benchbase_url='https://storage.yandexcloud.net/ydb-benchmark-builds/benchbase-ydb.tgz'
ssh_user="$USER"

usage() {
    echo "upload_benchbase.sh --hosts <hosts_file> [--package <benchbase-ydb>] [--package-url <url>] [--user <$ssh_user>]"
    echo "If you don't specify package and package-url, script will download benchbase from $benchbase_url"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --package)
            shift
            package=$1
            ;;
        --package-url)
            shift
            benchbase_url=$1
            ;;
        --hosts)
            shift
            hosts=$1
            ;;
        --user)
            shift
            ssh_user=$1
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    shift
done

if [[ -n "$package" && -n "$benchbase_url" ]]; then
    echo "You can't specify both package and package-url"
    usage
    exit 1
fi

if [[ -z "$package" && -z "$benchbase_url" ]]; then
    benchbase_url=$default_benchbase_url
fi

dst_home=$HOME
if [[ -n "$ssh_user" ]]; then
    host0=`sort -u "$hosts" | head -n 1`
    dst_home="`ssh -o StrictHostKeyChecking=no $ssh_user@$host0 'echo $HOME'`"
fi

if [[ -n "$package" ]]; then
    if [ ! -f "$package" ]; then
        echo "Package $package not found"
        exit 1
    fi

    loop-scp -u $ssh_user -h $hosts $package $dst_home
    if [ $? -ne 0 ]; then
        echo "Failed to upload package $package to hosts $hosts"
        exit 1
    fi
else
    package=`basename $benchbase_url`

    loop-ssh -u $ssh_user -h $hosts "wget -O $package $benchbase_url"
    if [ $? -ne 0 ]; then
        echo "Failed to download from $benchbase_url to hosts"
        exit 1
    fi
fi

loop-ssh -u $ssh_user -h $hosts "tar -xzf `basename $package`"
if [ $? -ne 0 ]; then
    echo "Failed to extract package $package on hosts $hosts"
    exit 1
fi
