#!/bin/bash

shopt -s expand_aliases

path_win="c:\downloads"
path_linux=$(cygpath "$path_win")
path_base="/"$(basename $path_linux)
path_dir=$(dirname $path_linux)

alias ERROR='color 1 "[$(date) err][${BASH_SOURCE} $FUNCNAME:$LINENO]"'
alias WARN='color 4 "[$(date) warn][${BASH_SOURCE} $FUNCNAME:$LINENO]"'
alias INFO='color 6 "[$(date) info][${BASH_SOURCE} $FUNCNAME:$LINENO]"'
alias DEBUG='color 8 "[$(date) debug][${BASH_SOURCE} $FUNCNAME:$LINENO]"'
function color() { 
	echo -ne "\e[1;3$((${1:-0} % 8))m"
	shift
	echo -e "$@\e[0m"
}

function ipfs_func(){
	file=$1
	action=$2
	is_dir=${3:0:5}
	need_ipns=$4
	# 把本地路径转换成ipfs路径
	ipfs_path=${file/$path_dir/""}
	ipfs_path_base=$path_base
	DEBUG dir=$is_dir
        DEBUG action=$action
	case $action in
		MOVED_FROM* | DELETE*)
			INFO ipfs files rm $ipfs_path
			ipfs files rm $ipfs_path || {
				ERROR "ipfs files rm $ipfs_path FAILED!"
				return $?
			}
			;;
		#DELETE*)
		#	INFO ipfs files rm $ipfs_path
		#	;;
		CREATE* | MOVED_TO* )
			if [ x$is_dir == x"ISDIR" ]
			then
				INFO ipfs files mkdir $ipfs_path
				ipfs files mkdir $ipfs_path
			else
				INFO "ipfs files write --create $ipfs_path \$(cygpath -w $file)"
		                ipfs files write --create $ipfs_path $(cygpath -w $file)
			fi
			need_ipns=0
			;;
		MODIFY*)
			[ x$is_dir == x"ISDIR" ] || {
				# 目录修改，啥也做不了
				INFO ipfs files rm $ipfs_path
				ipfs files rm $ipfs_path
				INFO "ipfs files write --create $ipfs_path \$(cygpath -w $file)"
				ipfs files write --create $ipfs_path $(cygpath -w $file)
			}
			;;
		#MOVED_TO*)
		#	INFO ipfs files write --create $ipfs_path $file
		#	;;
	esac
	[[ $need_ipns == 0 ]] && return 0
	hash=$(ipfs files stat $ipfs_path_base | head -1) && {
		# 更新ipns
		ipfs name publish $hash &
	}
	return $?
}

function main(){
	find $path_linux | \
	while read file
	do
		echo $file
		[ -d $file ] && {
			ipfs_func $file CREATE ISDIR 0
		} || {
			ipfs_func $file CREATE '-' 0
		}
	done
	hash=$(ipfs files stat $path_base | head -1) && {
	        # 更新ipns
	        ipfs name publish $hash &
	}
	inotifywait -mr  --format '%w,%f,%e' -e modify,delete,create,move "$path_win" |\
	while read -r line
	do
		#DEBUG "$line"
		  path=$(echo -n "$line" | awk -F"," '{print $1}')
 		  file=$(echo -n "$line" | awk -F"," '{print $2}')
		action=$(echo -n "$line" | awk -F"," '{print $3}')
		is_dir=$(echo -n "$line" | awk -F"," '{print $4}')
		path=$(cygpath "$path")
		is_dir=${is_dir:=}
		#echo $path/$file $action
		ipfs_func "$path/$file" $action ${is_dir:="-"} 1
	done
}
main
