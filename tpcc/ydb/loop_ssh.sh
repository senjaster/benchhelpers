#!/bin/bash

# Minimal implementation of parallel-ssh and parallel-scp 

function loop-scp {

        usage="Usage: loop-scp --hosts <hosts_file> --user <user_name> <file_to_upload> <remote_path>"

        ssh_user=$USER

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

        while read host; do
                scp -o StrictHostKeyChecking=no "$file" $ssh_user@$host:$remote_path
                if [[ $? -ne 0 ]]; then
                        echo "Failed to copy $file file to $host"
                        exit 1
                fi
        done <<< $(sort -u "$hosts" | grep -v '^$')
}

function loop-ssh {
        usage="Usage: loop-ssh --user <user_name> --hosts <hosts_file> <command to execute on remote hosts>"

        ssh_user=$USER

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
                ignore_error=1
                ;;
                *)
                echo "Unknown parameter $1"
                echo $usage
                exit 1
                ;;
        esac
        shift
        done

        if [ $# -eq 0 ]; then
		echo "Command unspecified"
		exit 1
	fi

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

        while read host; do
                ssh -o StrictHostKeyChecking=no $ssh_user@$host "$cmd"
                if [[ $? -ne 0 && $ignore_error -ne 1 ]]; then
                        echo "Failed to run command $cmd on $host"
                        exit 1
                fi
        done <<< $(sort -u "$hosts" | grep -v '^$')
}
