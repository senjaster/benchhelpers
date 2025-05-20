#!/bin/bash

# Minimal implementation of parallel-ssh and parallel-scp 

function loop-scp {

        usage="Usage: loop-scp --hosts <hosts_file> --user <user_name> <file_to_upload> <remote_path>"

        while [ $# -gt 2 ]; do
        case "$1" in
                -h|--hosts)
                shift
                local hosts=$1
                ;;
                -u|--user)
                shift
                local ssh_user=$1
                ;;
                *)
                echo "Unknown parameter $1"
                echo "$usage"
                exit 1
                ;;
        esac
        shift
        done

        if [ $# -le 1 ]; then
                echo "Provide file name and remote path"
                echo "$usage"
                exit 1
        fi

        local file=$1
        local remote_path=$2

        if [ -z "$hosts" ]; then
                echo "Hosts file name not specified"
                echo "$usage"
                exit 1
        fi

        if [ ! -f "$hosts" ]; then
                echo "Hosts file $hosts not found"
                echo "$usage"
                exit 1
        fi

        if [ -z "$ssh_user" ]; then
                echo "User name not specified"
                echo "$usage"
                exit 1
        fi

        if [ ! -f "$file" ]; then
           echo "File $file not found"
           echo "$usage"
           exit 1
        fi

        IFS=$'\n'        
        for host in $(sort -u "$hosts"); do
                scp -o StrictHostKeyChecking=no "$file" $ssh_user@$host:$remote_path
        done
}

function loop-ssh {
        usage="Usage: loop-ssh --user <user_name> --hosts <hosts_file> <command to execute on remote hosts>"

        while [ $# -gt 1 ]; do
        case "$1" in
                -h|--hosts)
                shift
                local hosts=$1
                ;;
                -u|--user)
                shift
                local ssh_user=$1
                ;;
                -i)
                # ignore -i
                shift
                ;;
                *)
                echo "Unknown parameter $1"
                echo $usage
                exit 1
                ;;
        esac
        shift
        done

        local cmd=$1

        if [ -z "$hosts" ]; then
                echo "Hosts file name not specified"
                echo $usage
                exit 1
        fi

        if [ ! -f "$hosts" ]; then
                echo "Hosts file $hosts not found"
                echo $usage
                exit 1
        fi

        if [ -z "$ssh_user" ]; then
                echo "User name not specified"
                echo $usage
                exit 1
        fi

        IFS=$'\n'

        for host in $(sort -u "$hosts"); do
           ssh -o StrictHostKeyChecking=no $ssh_user@$host "$cmd"
        done
}

echo "!!!!!!!"
loop-scp -u arsbir -h tpcc.hosts -x README.md ""
loop-ssh -u arsbir -h tpcc.hosts "ls -l"
loop-ssh --user arsbir --hosts tpcc.hosts "rm README.md" 