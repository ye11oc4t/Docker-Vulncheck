#!/bin/sh
lang_check=`locale -a 2>/dev/null | grep "en_US" | egrep -i "(utf8|utf-8)"`

if [ "$lang_check" = " " ]; then
	lang_check="C"
fi

LANG="$lang_check"
LC_ALL="$lang_check"
LANGUAGE="$lang_check"
export LANG
export LC_ALL
export LANGUAGE

if [ "command -v netstat 2>/dev/null" != '' ] || [ "which netstat 2>/dev/null" != "" ]; then
	port_cmd="netstat"
else
	port_cmd="ss"
fi

if [ "command -v systemctl 2>/dev/null" != '' ] || [ "which systemctl 2>/dev/null" != "" ]; then
	systemctl_cmd="systemctl"
fi
RESULT_FILE="result_collect_`date +\"%Y%m%d%H%M\"`.txt"
#echo "[D00] : check"
echo "===========================[ root check START ]" > $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1

user=`id | grep "uid=0"`
if [ "$user" == "" ]; then
	echo "Not root"
	echo "Not root" >> $RESULT_FILE 2>&1
	exit 100
else 
	echo "root OK" >> $RESULT_FILE 2>&1
fi
echo "" >> $RESULT_FILE 2>&1
echo "===========================[ root check END ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1

echo "[Start Script]"
echo "=========================== Docker Security Check Script START ===========================" >> $RESULT_FILE 2>&1
echo "" >>$RESULT_FILE 2>&1
###############################################################################
# echo "Result : Good" >> $RESULT_FILE 2>&1
# echo "Result : Vulnerable" >> $RESULT_FILE 2>&1
# echo "Result : Review" >> $RESULT_FILE 2>&1

echo "[ D-01 ] : Check"
echo "===========================[ D-01 Docker latest patch START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
echo "1. Docker Version" >> $RESULT_FILE 2>&1
version=`docker version`
echo "$version" >> $RESULT_FILE 2>&1
if [ "$version" != "" ]; then
	docker_v=`docker version | grep 'Version' | grep -v 'grep' | awk -F":" '{print $2}' | awk -F"." 'NR<3 {print $1}'`
	echo "$docker_v" > version.txt
	echo `wc -l version.txt` > cnt.txt
	v_cnt=`awk '{print $1}' cnt.txt`
#	echo "$v_cnt"
	array=($docker_v)
#	echo ${array[1]}
	echo "" >> $RESULT_FILE 2>&1
	echo "Client : ${array[0]} Server : ${array[1]}" >> $RESULT_FILE 2>&1
	
	if [ "$v_cnt" = 2 ]; then
		if [ "${array[0]}" = "23" ] && [ "${array[1]}" = "23" ]; then
			echo "Result : Good" >> $RESULT_FILE 2>&1
		else
			echo "Result : Vulnerable" >> $RESULT_FILE 2>&1

		fi
	else
		echo "Result : Review" >>$RESULT_FILE 2>&1
	fi
else
	echo "Not Found Docker" >> $RESULT_FILE 2>&1
fi

rm -f version.txt
rm -f cnt.txt

echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-01 Docker latest patch END ]" >> $RESULT_FILE 2>&1
echo "[ D-01 ] : End"

echo "[ D-02 ] : Check"
echo "===========================[ D-02 /usr/bin/docker audit START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
daemon_flag=0
# 0 : good

if [ "which auditctl 2>/dev/null" == "" ]; then 
	echo "Not Found auditctl" >> $RESULT_FILE 2>&1
else
	echo "1. /usr/bin/docker audit" >> $RESULT_FILE 2>&1
	daemon_audit=`auditctl -l | grep /usr/bin/docker`
	if [ "$daemon_audit" == "" ]; then
		daemon_flag=`expr $daemon_flag + 1`
	else
		echo "$daemon_audit" >> $RESULT_FILE 2>&1
	fi
	
	echo "2. audit.rules file" >> $RESULT_FILE 2>&1
	if [ -f '/etc/audit/audit.rules' ]; then
		rules="/etc/audit/audit.rules"
		if [ "`cat $rules | grep /usr/bin/docker`" == "" ]; then
			daemon_flag=`expr $daemon_flag + 1`
		else
			echo "`cat $rules | grep /usr/bin/docker`" >> $RESULT_FILE 2>&1
		fi
	else 
		echo "Not Found /etc/audit/audit.rules" >> $RESULT_FILE 2>&1
	fi
#	echo "$daemon_flag"
	if [ "$daemon_flag" != 0 ]; then
		echo "Result : Vulnerable" >> $RESULT_FILE 2>&1
	else
		echo "Result : Good" >> $RESULT_FILE 2>&1
	fi
fi

echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-02 Docker daemon audit END ]" >> $RESULT_FILE 2>&1
echo "[ D-02 ] : End"

echo "[ D-03 ] : Check"
echo "===========================[ D-03 /var/lib/docker audit START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
if [ "which auditctl 2>/dev/null" == "" ]; then 
	echo "Not Found auditctl" >> $RESULT_FILE 2>&1
else
	echo "1. /var/lib/docker audit" >> $RESULT_FILE 2>&1
	var_flag=0
	var_audit=`auditctl -l | grep /var/lib/docker`
	
	if [ "$var_audit" == "" ]; then
		var_flag=`expr $var_audit + 1`
	else
		echo "$var_audit" >> $RESULT_FILE 2>&1
	fi
	
	echo "2. audit.rules file check" >> $RESULT_FILE 2>&1
	if [ -f '/etc/audit/audit.rules' ]; then
		rules="/etc/audit/audit.rules"
		if [ "`cat $rules | grep /var/lib/docker`" == "" ]; then
			var_flag=`expr $var_flag + 1`
		else
			echo "`cat $rules | grep /var/lib/docker`" >> $RESULT_FILE 2>&1
		fi
	else 
		echo "Not Found /etc/audit/audit.rules" >> $RESULT_FILE 2>&1
	fi
#	echo "$var_flag"
	if [ "$var_flag" != 0 ]; then
		echo "Result : Vulnerable" >> $RESULT_FILE 2>&1
	else
		echo "Result : Good" >> $RESULT_FILE 2>&1
	fi
fi
echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-03 /var/lib/docker audit END ]" >> $RESULT_FILE 2>&1
echo "[ D-03 ] : End"

echo "[ D-04 ] : Check"
echo "===========================[ D-04 /etc/docker audit START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
if [ "which auditctl 2>/dev/null" == "" ]; then 
	echo "Not Found auditctl" >> $RESULT_FILE 2>&1
else
	echo "1. /etc/docker audit " >> $RESULT_FILE 2>&1
	etc_flag=0
	etc_audit=`auditctl -l | grep /etc/docker`
	
	if [ "$etc_audit" == "" ]; then
		etc_flag=`expr $etc_flag + 1`
	else
		echo "$etc_audit" >> $RESULT_FILE 2>&1
	fi
	echo "2. audit.rules file check" >> $RESULT_FILE 2>&1
	if [ -f '/etc/audit/audit.rules' ]; then
		rules="/etc/audit/audit.rules"
		if [ "`cat $rules | grep /etc/docker`" == "" ]; then
			etc_flag=`expr $etc_flag + 1`
		else
			echo "`cat $rules | grep /etc/docker`" >> $RESULT_FILE 2>&1
		fi
	else 
		echo "Not Found /etc/audit/audit.rules" >> $RESULT_FILE 2>&1
	fi
#	echo "$etc_flag"
	if [ "$etc_flag" != 0 ]; then
		echo "Result : Vulnerable" >> $RESULT_FILE 2>&1
	else
		echo "Result : Good" >> $RESULT_FILE 2>&1
	fi
fi
echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-04 /etc/docker audit END ]" >> $RESULT_FILE 2>&1
echo "[ D-04 ] : End"

echo "[ D-05 ] : Check"
echo "===========================[ D-05 docker.service audit START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
if [ "which auditctl 2>/dev/null" == "" ]; then 
	echo "Not Found auditctl" >> $RESULT_FILE 2>&1
else
	echo "1. docker.service audit" >> $RESULT_FILE 2>&1
	echo "1-1. docker.service path check" >> $RESULT_FILE 2>&1
	
	service_flag=0
	service_path=`$systemctl_cmd  show -p FragmentPath docker.service | awk -F"=" '{print $2}'`
	if [ "$service_path" == "" ]; then
		echo "Not Found Path" >> $RESULT_FILE 2>&1
		not_path=-1
	fi
				
	echo "1-2. docker.service audit check" >> $RESULT_FILE 2>&1
	service_audit=`auditctl -l | grep "$service_path"`
	
	if [ "$service_audit" == "" ]; then
		service_flag=`expr $service_flag + 1`
	else
		echo "$service_audit" >> $RESULT_FILE 2>&1
	fi
	
	echo "2. audit.rules file check" >> $RESULT_FILE 2>&1
	if [ -f '/etc/audit/audit.rules' ]; then
		rules="/etc/audit/audit.rules"
		if [ "`cat $rules | grep docker.service`" == "" ]; then
			service_flag=`expr $service_flag + 1`
		else
			echo "`cat $rules | grep docket.service`" >> $RESULT_FILE 2>&1
		fi
	else 
		echo "Not Found /etc/audit/audit.rules" >> $RESULT_FILE 2>&1
	fi
#	echo "$service_flag"
	if [ "$not_path" == "-1" ]; then
		echo "Not Target" >> $RESULT_FILE 2>&1
	fi
	
	if [ "$service_flag" != 0 ]; then
		echo "Result : Vulnerable" >> $RESULT_FILE 2>&1
	else
		echo "Result : Good" >> $RESULT_FILE 2>&1
	fi	
fi
echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-05 docker.service END ]" >> $RESULT_FILE 2>&1
echo "[ D-05 ] : End"

echo "[ D-06 ] : Check"
echo "===========================[ D-06 docekr.socket audit START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
if [ "which auditctl 2>/dev/null" == "" ]; then 
	echo "Not Found auditctl" >> $RESULT_FILE 2>&1
else
	echo "1. docker.socket audit" >> $RESULT_FILE 2>&1
	echo "1-1. docker.socket path check" >> $RESULT_FILE 2>&1
	
	socket_flag=0
	socket_path=`$systemctl_cmd  show -p FragmentPath docker.socket | awk -F"=" '{print $2}'`
	if [ "$socket_path" == "" ]; then
		echo "Not Found Path" >> $RESULT_FILE 2>&1
		not_path=-1
	fi
	
	echo "1-2. docker.socket audit check" >> $RESULT_FILE 2>&1
	service_audit=`auditctl -l | grep "$socket_path"`
	
	if [ "$socket_audit" == "" ]; then
		socket_flag=`expr $socket_flag + 1`
	else
		echo "$socket_audit" >> $RESULT_FILE 2>&1
	fi
	echo "2. audit.rules file check" >> $RESULT_FILE 2>&1
	if [ -f '/etc/audit/audit.rules' ]; then
		rules="/etc/audit/audit.rules"
		if [ "`cat $rules | grep docker.socket`" == "" ]; then
			socket_flag=`expr $socket_flag + 1`
		else
			echo "`cat $rules | grep docker.socket`" >> $RESULT_FILE 2>&1
		fi
	else 
		echo "Not Found /etc/audit/audit.rules" >> $RESULT_FILE 2>&1
	fi
	
#	echo "$socket_flag"
	if [ "$not_path" == "-1" ]; then 
		echo "Not Target" >> $RESULT_FILE 2>&1
	fi
	if [ "$socket_flag" != 0 ]; then
		echo "Result : Vulnerable" >> $RESULT_FILE 2>&1
	else
		echo "Result : Good" >> $RESULT_FILE 2>&1
	fi
fi
echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-06 docker.socket END ]" >> $RESULT_FILE 2>&1
echo "[ D-06 ] : End"

echo "[ D-07 ] : Check"
echo "===========================[ D-07 /etc/default/docker audit START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1

if [ "which auditctl 2>/dev/null" == "" ]; then
	echo "Not Found auditctl" >> $RESULT_FILE 2>&1
else
	echo "1. /etc/default/docker audit " >> $RESULT_FILE 2>&1
	etc_flag=0
	etc_default_audit=`auditctl -l | grep /etc/default/docker`
	
	if [ "$etc_default_audit" == "" ]; then
		etc_flag=`expr $etc_flag + 1`
	else
		echo "$etc_default_audit" >> $RESULT_FILE 2>&1
	fi
	echo "2. audit.rules file check" >> $RESULT_FILE 2>&1
	if [ -f '/etc/audit/audit.rules' ]; then
		rules="/etc/audit/audit.rules"
		if [ "`cat $rules | grep /etc/default/docker`" == "" ]; then
			etc_flag=`expr $etc_flag + 1`
		else
			echo "`cat $rules | grep /etc/default/docker`" >> $RESULT_FILE 2>&1
		fi
	else 
		echo "Not Found /etc/default/audit/audit.rules" >> $RESULT_FILE 2>&1
	fi
#	echo "$etc_flag"
	if [ "$etc_flag" != 0 ]; then
		echo "Result : Vulnerable" >> $RESULT_FILE 2>&1
	else
		echo "Result : Good" >> $RESULT_FILE 2>&1
	fi
fi
echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-07 /etc/default/docker audit END ]" >> $RESULT_FILE 2>&1
echo "[ D-07 ] : End"

echo "[ D-08 ] : Check"
echo "===========================[ D-08 Restrict network traffic between containers START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1

echo "1. Restrict network trattic between containers check" >> $RESULT_FILE 2>&1
get_bridge=`docker network ls --quiet | xargs docker network inspect --format '{{ .Name }}:
{{ .Options }}'`
echo "$get_bridge" >> $RESULT_FILE 2>&1

if [[ "$get_bridge" =~ "network.bridge.enable_icc=false" ]]; then
  echo "The default Docker network is in use, but has restrictions." >> $RESULT_FILE 2>&1
  echo "Result: Good" >> $RESULT_FILE 2>&1
else
  echo "The default Docker network is in use and has no restrictions." >> $RESULT_FILE 2>&1
  echo "Result: Vulnerable" >> $RESULT_FILE 2>&1
fi
echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-08 Restrict network traffic between containers END ]" >> $RESULT_FILE 2>&1
echo "[ D-08 ] : End" 

echo "[ D-09 ] : Check"
echo "===========================[ D-09 docker.service file ownership START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1

echo "1. docker.service file path" >> $RESULT_FILE 2>&1
DOCKER_SERVICE_FILE=$(systemctl show -p FragmentPath docker.service | awk -F"=" '{print $2}')
if [ -e "$DOCKER_SERVICE_FILE" ]; then
	echo "$DOCKER_SERVICE_FILE" >> $RESULT_FILE 2>&1
	echo "2. docker.service file ownership" >> $RESULT_FILE 2>&1
   	ls -l $DOCKER_SERVICE_FILE >> $RESULT_FILE 2>&1
	owner_val=`stat -c '%U' $DOCKER_SERVICE_FILE`
	group_val=`stat -c '%G' $DOCKER_SERVICE_FILE`
	if [ "$owner_val:$group_val" = "root:root" ]; then
		echo "Result: Good" >> $RESULT_FILE 2>&1
	else
		echo "Result: Vulnerable" >> $RESULT_FILE 2>&1
	fi
else
    echo "docker.service file not found." >> $RESULT_FILE 2>&1
	echo "Result: Review" >> $RESULT_FILE 2>&1
fi

echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-09 docker.service file ownership END ]" >> $RESULT_FILE 2>&1
echo "[ D-09 ] : End"

echo "[ D-10 ] : Check"
echo "===========================[ D-10 docker.service file access permission START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1

echo "1. docker.service file path" >> $RESULT_FILE 2>&1
DOCKER_SERVICE_FILE=$(systemctl show -p FragmentPath docker.service | awk -F"=" '{print $2}')
if [ -e "$DOCKER_SERVICE_FILE" ]; then
	echo "$DOCKER_SERVICE_FILE" >> $RESULT_FILE 2>&1
	echo "2. docker.service file permission" >> $RESULT_FILE 2>&1
    ls -l $DOCKER_SERVICE_FILE >> $RESULT_FILE 2>&1
		permission_val=`stat -c '%a' $DOCKER_SERVICE_FILE`
		owner_perm_val=`echo "$permission_val" | awk '{ print substr($0, 1, 1) }'`
		group_perm_val=`echo "$permission_val" | awk '{ print substr($0, 2, 1) }'`
		other_perm_val=`echo "$permission_val" | awk '{ print substr($0, 3, 1) }'`
	if [ "$owner_perm_val" -le 6 ] && [ "$group_perm_val" -le 4 ] && [ "$other_perm_val" -le 4 ]; then
		echo "Result: Good" >> $RESULT_FILE 2>&1
	else
		echo "Result: Vulnerable" >> $RESULT_FILE 2>&1
	fi
else
   	echo "docker.service file not found." >> $RESULT_FILE 2>&1
	echo "Result: Review" >> $RESULT_FILE 2>&1
fi

echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-10 docker.service file access permission END ]" >> $RESULT_FILE 2>&1
echo "[ D-10 ] : End"

echo "[ D-11 ] : Check"
echo "===========================[ D-11 docker.socket file ownership START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
echo "1. docker.socket file path" >> $RESULT_FILE 2>&1
DOCKER_SOCK_FILE=$(systemctl show -p FragmentPath docker.socket | awk -F"=" '{print $2}')

if [ -e "$DOCKER_SOCK_FILE" ]; then
	echo "$DOCKER_SOCK_FILE" >> $RESULT_FILE 2>&1
	echo "2. docker.socket file ownership" >> $RESULT_FILE 2>&1
   	ls -l $DOCKER_SOCK_FILE >> $RESULT_FILE 2>&1
	owner_val=`stat -c '%U' $DOCKER_SOCK_FILE`
	group_val=`stat -c '%G' $DOCKER_SOCK_FILE`
  	if [ "$owner_val:$group_val" = "root:root" ]; then
		echo "Result: Good" >> $RESULT_FILE 2>&1
	else
		echo "Result: Vulnerable" >> $RESULT_FILE 2>&1
	fi
else
   	echo "docker.socket file not found." >> $RESULT_FILE 2>&1
	echo "Result: Review" >> $RESULT_FILE 2>&1
fi


echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-11 docker.socket file ownership END ]" >> $RESULT_FILE 2>&1
echo "[ D-11 ] : End"

echo "[ D-12 ] : Check"
echo "===========================[ D-12 docker.socket file access permission START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
echo "1. docker.socket file path" >> $RESULT_FILE 2>&1
DOCKER_SOCKET_FILE=$(systemctl show -p FragmentPath docker.socket | awk -F= '{print $2}')

if [ -e "$DOCKER_SOCKET_FILE" ]; then
	echo "$DOCKER_SOCKET_FILE" >> $RESULT_FILE 2>&1
	echo "2. docker.socket file permission" >> $RESULT_FILE 2>&1
	ls -l $DOCKER_SOCKET_FILE >> $RESULT_FILE 2>&1
	permission_val=`stat -c '%a' $DOCKER_SOCKET_FILE`
	owner_perm_val=`echo "$permission_val" | awk '{ print substr($0, 1, 1) }'`
	group_perm_val=`echo "$permission_val" | awk '{ print substr($0, 2, 1) }'`
	other_perm_val=`echo "$permission_val" | awk '{ print substr($0, 3, 1) }'`
	if [ "$owner_perm_val" -le 6 ] && [ "$group_perm_val" -le 4 ] && [ "$other_perm_val" -le 4 ]; then
		echo "Result: Good" >> $RESULT_FILE 2>&1
	else
		echo "Result: Vulnerable" >> $RESULT_FILE 2>&1
	fi
else
 	echo "docker.socket file not found." >> $RESULT_FILE 2>&1
	echo "Result: Review" >> $RESULT_FILE 2>&1
fi
echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-12 docker.socket file access perimission END ]" >> $RESULT_FILE 2>&1
echo "[ D-12 ] : End"

echo "[ D-13 ] : Check"
echo "===========================[ D-13 /etc/docker dir ownership START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1

echo "1. /etc/docker dir path" >> $RESULT_FILE 2>&1
DOCKER_DIR="/etc/docker"
if [ -d "$DOCKER_DIR" ]; then
	echo "$DOCKER_DIR" >> $RESULT_FILE 2>&1

	echo "2. /etc/docker dir ownership" >> $RESULT_FILE 2>&1
	ls -ld $DOCKER_DIR >> $RESULT_FILE 2>&1
	owner_perm_val=`stat -c '%U' $DOCKER_DIR`
	group_perm_val=`stat -c '%G' $DOCKER_DIR`
    if [ "$owner_perm_val:$group_perm_val" = "root:root" ]; then
		echo "Result: Good" >> $RESULT_FILE 2>&1
	else
		echo "Result: Vulnerable" >> $RESULT_FILE 2>&1
	fi
else
	echo "/etc/docker directory not found." >> $RESULT_FILE 2>&1
	echo "Result: Review" >> $RESULT_FILE 2>&1
fi

echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-13 /etc/docker dir ownership END ]" >> $RESULT_FILE 2>&1
echo "[ D-13 ] : End" 

echo "[ D-14 ] : Check"
echo "===========================[ D-14 /etc/docker dir access permission START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1

echo "1. /etc/docker dir path" >> $RESULT_FILE 2>&1
if [ -d "$DOCKER_DIR" ]; then
	echo "$DOCKER_DIR" >> $RESULT_FILE 2>&1
	echo "2. /etc/docker dir permission" >> $RESULT_FILE 2>&1
	ls -ld $DOCKER_DIR >> $RESULT_FILE 2>&1
	permission_val=`stat -c '%a' $DOCKER_DIR`
	owner_perm_val=`echo "$permission_val" | awk '{ print substr($0, 1, 1) }'`
	group_perm_val=`echo "$permission_val" | awk '{ print substr($0, 2, 1) }'`
	other_perm_val=`echo "$permission_val" | awk '{ print substr($0, 3, 1) }'`
	if [ "$owner_perm_val" -le 7 ] && [ "$group_perm_val" -le 5 ] && [ "$other_perm_val" -le 5 ]; then
		echo "Result: Good" >> $RESULT_FILE 2>&1
	else
		echo "Result: Vulnerable" >> $RESULT_FILE 2>&1
	fi
else
	echo "/etc/docker directory not found." >> $RESULT_FILE 2>&1
	echo "Result: Review" >> $RESULT_FILE 2>&1
fi


echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-14 /etc/docker dir access permission END ]" >> $RESULT_FILE 2>&1
echo "[ D-14 ] : End" 

echo "[ D-15 ] : Check"
echo "===========================[ D-15 /var/run/docker.sock file ownership START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1

echo "1. /var/run/docker.sock path" >> $RESULT_FILE 2>&1
DOCKER_SOCK_FILE="/var/run/docker.sock"

if [ -d "$DOCKER_DIR" ]; then
	if [ -e "$DOCKER_SOCK_FILE" ]; then
		echo "$DOCKER_SOCK_FILE" >> $RESULT_FILE 2>&1
		echo "2. /var/run/docker.sock file ownership" >> $RESULT_FILE 2>&1
    	ls -l $DOCKER_SOCK_FILE >> $RESULT_FILE 2>&1
		owner_perm_val=`stat -c '%U' $DOCKER_SOCK_FILE`
		group_perm_val=`stat -c '%G' $DOCKER_SOCK_FILE`
		if [ "$owner_perm_val:$group_perm_val" = "root:docker" ]; then
			echo "Result: Good" >> $RESULT_FILE 2>&1
		else
			echo "Result: Vulnerable" >> $RESULT_FILE 2>&1
		fi
	else
    	echo "/var/run/docker.sock file not found." >> $RESULT_FILE 2>&1
		echo "Result: Review" >> $RESULT_FILE 2>&1
	fi
fi

echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-15 /var/run/docker.sock file ownership END ]" >> $RESULT_FILE 2>&1
echo "[ D-15 ] : End" 

echo "[ D-16 ] : Check"
echo "===========================[ D-16 /var/run/docker.sock access permission START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1

echo "1. /var/run/docker.sock path" >> $RESULT_FILE 2>&1
if [ -e "$DOCKER_SOCK_FILE" ]; then
	echo "2. /var/run/docker.sock file permission" >> $RESULT_FILE 2>&1
	ls -l $DOCKER_SOCK_FILE >> $RESULT_FILE 2>&1
	permission_val=`stat -c '%a' $DOCKER_SOCK_FILE`
	owner_perm_val=`echo "$permission_val" | awk '{ print substr($0, 1, 1) }'`
	group_perm_val=`echo "$permission_val" | awk '{ print substr($0, 2, 1) }'`
	other_perm_val=`echo "$permission_val" | awk '{ print substr($0, 3, 1) }'`
	if [ "$owner_perm_val" -le 6 ] && [ "$group_perm_val" -le 6 ] && [ "$other_perm_val" -le 0 ]; then
		echo "Result: Good" >> $RESULT_FILE 2>&1
	else
		echo "Result: Vulnerable" >> $RESULT_FILE 2>&1
	fi
else
	echo "/var/run/docker.sock file not found." >> $RESULT_FILE 2>&1
	echo "Result: Review" >> $RESULT_FILE 2>&1
fi
echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-16 /var/run/docker.sock access permission END ]" >> $RESULT_FILE 2>&1
echo "[ D-16 ] : End"

echo "[ D-17 ] : Check"
echo "===========================[ D-17 daemon.json file ownership START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1

echo "1. daemon.json file path" >> $RESULT_FILE 2>&1
DOCKER_DAEMON="/etc/docker/daemon.json"
if [ -e "$DOCKER_DAEMON" ]; then
	echo "2. daemon.json file ownership" >> $RESULT_FILE 2>&1
   	ls -l $DOCKER_DAEMON >> $RESULT_FILE 2>&1
	owner_perm_val=`stat -c '%U' $DOCKER_DAEMON`
	group_perm_val=`stat -c '%G' $DOCKER_DAEMON`
 	if [ "$owner_perm_val:$group_perm_val" = "root:root" ]; then
		echo "Result: Good" >> $RESULT_FILE 2>&1
	else
		echo "Result: Vulnerable" >> $RESULT_FILE 2>&1
	fi
else
   	echo "daemon.json file not found." >> $RESULT_FILE 2>&1
	echo "Result: Good" >> $RESULT_FILE 2>&1
fi

echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-17 daemon.json file ownership END ]" >> $RESULT_FILE 2>&1
echo "[ D-17 ] : End"

echo "[ D-18 ] : Check"
echo "===========================[ D-18 daemon.json access permission START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
echo "1. daemon.json file path" >> $RESULT_FILE 2>&1
if [ -e "$DOCKER_DAEMON" ]; then
	echo "$DOCKER_DAEMON" >> $RESULT_FILE 2>&1
	
	echo "2. daemon.json file permission" >> $RESULT_FILE 2>&1
	ls -l $DOCKER_DAEMON >> $RESULT_FILE 2>&1
	permission_val=`stat -c '%a' $DOCKER_DAEMON`
	owner_perm_val=`echo "$permission_val" | awk '{ print substr($0, 1, 1) }'`
	group_perm_val=`echo "$permission_val" | awk '{ print substr($0, 2, 1) }'`
	other_perm_val=`echo "$permission_val" | awk '{ print substr($0, 3, 1) }'`
	if [ "$owner_perm_val" -le 6 ] && [ "$group_perm_val" -le 4 ] && [ "$other_perm_val" -le 4 ]; then
		echo "Result: Good" >> $RESULT_FILE 2>&1
	else
		echo "Result: Vulnerable" >> $RESULT_FILE 2>&1
	fi
else
	echo "daemon.json file not found." >> $RESULT_FILE 2>&1
	echo "Result: Good" >> $RESULT_FILE 2>&1
fi

echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-18 daemon.json access permission END ]" >> $RESULT_FILE 2>&1
echo "[ D-18 ] : End"

echo "[ D-19 ] : Check"
echo "===========================[ D-19 /etc/default/docker file ownership START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1

echo "1. /etc/default/docker path" >> $RESULT_FILE 2>&1
DOCKER_DEFAULT="/etc/default/docker"

if [ -e "$DOCKER_DEFAULT" ]; then
	echo "$DOCKER_DEFAULT" >> $RESULT_FILE 2>&1
	echo "2. /etc/default/docker permission" >> $RESULT_FILE 2>&1
	ls -l $DOCKER_DEFAULT >> $RESULT_FILE 2>&1
	owner_val=`stat -c '%U' $DOCKER_DEFAULT`
	group_val=`stat -c '%G' $DOCKER_DEFAULT`
	 if [ "$owner_val:$group_val" = "root:root" ]; then
		echo "Result: Good" >> $RESULT_FILE 2>&1
	else
		echo "Result: Vulnerable" >> $RESULT_FILE 2>&1
	fi
else
    echo "/etc/default/docker file not found." >> $RESULT_FILE 2>&1
	echo "Result: Review" >> $RESULT_FILE 2>&1
fi

echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-19 /etc/default/docker file ownership END ]" >> $RESULT_FILE 2>&1
echo "[ D-19 ] : End"

echo "[ D-20 ] : Check"
echo "===========================[ D-20 /etc/default/docker file access permission START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1

echo "1. /etc/default/docker path" >> $RESULT_FILE 2>&1
#DOCKER_DEFAULT_ACCESS=$(/etc/default/docker)
if [ -e "$DOCKER_DEFAULT" ]; then
	echo "$DOCKER_DEFAULT" >> $RESULT_FILE 2>&1
	echo "2. /etc/default/docker permission" >> $RESULT_FILE 2>&1
	ls -l $DOCKER_DEFAULT >> $RESULT_FILE 2>&1
	permission_val=`stat -c '%a' $DOCKER_DEFAULT`
	owner_perm_val=`echo "$permission_val" | awk '{ print substr($0, 1, 1) }'`
	group_perm_val=`echo "$permission_val" | awk '{ print substr($0, 2, 1) }'`
	other_perm_val=`echo "$permission_val" | awk '{ print substr($0, 3, 1) }'`
	if [ "$owner_perm_val" -le 6 ] && [ "$group_perm_val" -le 4 ] && [ "$other_perm_val" -le 4 ]; then
		echo "Result: Good" >> $RESULT_FILE 2>&1
	else
		echo "Result: Vulnerable" >> $RESULT_FILE 2>&1
	fi
else
	echo "docker /etc/default/docker not found." >> $RESULT_FILE 2>&1
	echo "Result: Review" >> $RESULT_FILE 2>&1
fi

echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-20 /etc/default/docker file access permission END]" >> $RESULT_FILE 2>&1
echo "[ D-20 ] : End"

echo "[ D-21 ] : Check"    
echo "===========================[ D-21 SSH permission START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1

echo "1. SSH Active" >> $RESULT_FILE 2>&1
INSTANCE_CNT=0
SSHD=`$systemctl_cmd status sshd | grep "Active" | awk -F":" '{print substr($2,2,6)}'`

if [ "$SSHD" == "active" ]; then
	echo "SSH active" >> $RESULT_FILE 2>&1
	echo "Result : Vulnerable" >> $RESULT_FILE 2>&1
else
	echo "2. Running containers list" >> $RESULT_FILE 2>&1
	DOCKER_RUNNING_INSTANCE=$(docker ps --quiet)
	echo "$DOCKER_RUNNING_INSTANCE" >> $RESULT_FILE 2>&1

	if [ "$DOCKER_RUNNING_INSTANCE" != "" ]; then
		echo "3. Running container service" >> $RESULT_FILE 2>&1
		for var in $DOCKER_RUNNING_INSTANCE
		do 
			DOCKER_SSH_PROCESS=$(docker exec $var ps -el)
			echo "$DOCKER_SSH_PROCESS" >> $RESULT_FILE 2>&1
			INSTANCE_CNT=`expr $INSTANCE_CNT + 1`
		done
		if [ "$INSTANCE_CNT" = "${#array[*]}" ]; then
			echo "Result : Good" >> $RESULT_FILE 2>&1
		else
			echo "Result : Review" >> $RESULT_FILE 2>&1
		fi
	else
    	echo "docker running instance not found." >> $RESULT_FILE 2>&1
		echo "Result: Review" >> $RESULT_FILE 2>&1
	fi
fi
echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-21 SSH permittion END ]" >> $RESULT_FILE 2>&1
echo "[ D-21 ] : End"

echo "[ D-22 ] : Check"
echo "===========================[ D-22 Host OS access control START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1

echo "1. Docker container list" >> $RESULT_FILE 2>&1
DOCKER_CONTAINER=$(docker ps -a)
echo "$DOCKER_CONTAINER" >> $RESULT_FILE 2>&1
if [ "$DOCKER_CONTAINER" != "" ]; then
	
	echo "2. Docker container mapped dir list" >> $RESULT_FILE 2>&1
	DOCKER_CONTAINER_MAPPED_DIRECTORY=$(docker ps --quiet --all | xargs docker inspect --format 'Volumes={{.Mounts}}' ) 
	echo "$DOCKER_CONTAINER_MAPPED_DIRECTORY" > dir.txt 2>&1
	Host_cnt=0

	while IFS= read -r line
	do
		if [[ "$line" =~ (/boot|/dev|/etc|/lib|/proc|/sys|/usr) ]]; then
			Host_cnt=`expr $Host_cnt + 1`
		fi
	done < dir.txt
#	echo "$Host_cnt"

	echo "$DOCKER_CONTAINER_MAPPED_DIRECTORY" >> $RESULT_FILE 2>&1
	if [ "$Host_cnt" == "0" ]; then
		echo "Result : Good" >> $RESULT_FILE 2>&1
	else
		echo "Result : Vulnerable" >> $RESULT_FILE 2>&1
	fi

else
	echo "Docker container not found" >> $REUSLT_FILE 2>&1
	echo "Result : Review" >> $RESULT_FILE 2>&1
fi

rm -f dir.txt
echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-22 Host OS access control END ]" >> $RESULT_FILE 2>&1
echo "[ D-22 ] : End"

echo "[ D-23 ] : Check"
echo "===========================[ D-23 Authentication-Authorization control START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
echo "1. docker gruop user" >> $RESULT_FILE 2>&1
get_group_ps=`getent group docker`
if [ "$get_group_ps" != "" ]; then
	echo "$get_group_ps" >> $RESULT_FILE 2>&1
	echo "Result : Review" >> $RESULT_FILE 2>&1
else
	echo "NOT FOUND" >> $RESULT_FILE 2>&1
fi

echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-23 Authentication-Authorization control END ]" >> $RESULT_FILE 2>&1
echo "[ D-23 ] : End"

echo "[ D-24 ] : Check"
echo "===========================[ D-24 SSL/TLS appliance START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
echo "1. tlsverify check" >> $RESULT_FILE 2>&1
get_ps=`ps -ef | grep dockerd | grep -i "tlsverify"`
echo "$get_ps" >> $RESULT_FILE 2>&1
#echo "$get_ps"
if [ "$get_ps" != "" ]; then
	echo "--tlsverify --tlscacert --tlscert --tlskey USE" >> $RESULT_FILE 2>&1
	echo "Result : GOOD" >> $RESULT_FILE 2>&1
else
	echo "--tlsverify --tlscacert --tlscert --tlskey USE NOT FOUND" >> $RESULT_FILE 2>&1
	echo "Result : Vulnerable" >> $RESULT_FILE 2>&1
fi

echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-24 SSL/TLS appliance END ]" >> $RESULT_FILE 2>&1
echo "[ D-24 ] : End"

echo "[ D-25 ] : Check"
echo "===========================[ D-25 Container permission control START ]" >> $RESULT_FILE 2>&1
echo "1. no-new-privileges check" >> $RESULT_FILE 2>&1
get_ps=`ps -ef | grep dockerd | egrep -i "no-new-privileges"`

if [ "$get_ps" != "" ]; then
	echo "$get_ps" >> $RESULT_FILE 2>&1
	echo "Result : GOOD" >> $RESULT_FILE 2>&1
else
	echo "no-new-privileges NOT FOUND" >> $RESULT_FILE 2>&1
	echo "Result : Vulnerable" >> $RESULT_FILE 2>&1
fi

echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-25 Container permission control END ]" >> $RESULT_FILE 2>&1
echo "[ D-25 ] : End"

echo "[ D-26 ] : Check"
echo "===========================[ D-26 Authentication control START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1

echo "1. Swarm check" >> $RESULT_FILE 2>&1
get_ps=`docker info | grep "Swarm" | awk '{ print $2 }'`
get_ps1=`docker info | grep "Swarm"`

if [ "$get_ps" = "inactive" ]; then
	echo "$get_ps1" >> $RESULT_FILE 2>&1
	echo "Result : Good" >> $RESULT_FILE 2>&1
else 
	echo "$get_ps1" >> $RESULT_FILE 2>&1
	echo "Result : Vulnerable" >> $RESULT_FILE 2>&1
fi

#get_Swarm_Manager=`docker info --format '{{.Swarm.Managers}}'`
#echo "root node" >> $RESULT_FILE 2>&1
#echo "$get_Swarm_Manager" >> $RESULT_FILE 2>&1

#get_s_key=`docker swarm unlock-key`

#if [ "$get_s_key" == "no unlock key is set" ]; then
#	echo "no unlock key is set" >> $RESULT_FILE 2>&1
#fi

echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-26 Authentication control START ]" >> $RESULT_FILE 2>&1
echo "[ D-26 ] : End"

echo "[ D-27 ] : Check"
echo "===========================[ D-27 SSL/TLS appliance START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
val=0
flag=0
echo "1. tlsverity check" >> $RESULT_FILE 2>&1
get_ps=`ps -ef | grep dockerd | grep -i "tlsverity"`
echo "$get_ps" >> $RESULT_FILE 2>&1
if [ "$get_ps" != "" ]; then
	echo "--tlsverify --tlscacer --tlscert --tlskey USE" >> $RESULT_FILE 2>&1
	val=`expr $val + 1`
	flag=`expr $flag + 1`
else
	echo "--tlsverify --tlscacer --tlscert --tlskey NOT USE" >> $RESULT_FILE 2>&1
	echo "Result : Vulnerable" >> $RESULT_FILE 2>&1
fi
if [ "$val" = 1 ]; then
	echo "2. SSL/TLS appliance" >> $RESULT_FILE 2>&1
	get_network=`docker network ls --filter driver=overlay --quiet | xargs docker network inspect --format '{{.Name}} {{ .Options }}' | grep "encrypted"`
	if [ "$val" = 0 ]; then
		if [ "$get_network" != "" ]; then
			echo "$get_network" >> $RESULT_FILE 2>&1
			#echo "Result : Good" >> $RESULT_FILE 2>&1
		else
			echo "SSL/TLS inactive" >> $RESULT_FILE 2>&1
			echo "Result : vulnerable" >> $RESULT_FILE 2>&1
		fi
	fi
fi

if [ "$val" = 2 ]; then
	echo "2. SSL/TLS appliance" >> $RESULT_FILE 2>&1
	get_ExpiryDuration=`docker info | grep "Expiry Duration"`
	if [ $get_ExpiryDuration != "" ]; then
		echo $get_ExpiryDuration >> $RESULT_FILE 2>&1
		flag=`expr $flag + 1`
		echo "Expiry Duration Review " >> $RESULT_FILE 2>&1
	else
		echo "Result : Vulneralbe" >> $RESULT_FILE 2>&1
	fi
fi

if [ "$flag" = 3 ]; then
	echo "RESULT : Good" >> $RESULT_FILE 2>&1
fi
#echo "$val"
#echo "$flag"
echo "" >> $RESULT_FILE 2>&1
echo "===========================[ D-27 SSL/TLS appliance START ]" >> $RESULT_FILE 2>&1
echo "[ D-27 ] : End"
echo "" >> $RESULT_FILE 2>&1
echo "=========================== Docker Security Check Script END ===========================" >> $RESULT_FILE 2>&1
