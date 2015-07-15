#!/bin/bash
#About: Linux user info collector  several informations from all the users and print to a csv file. 
#Author: Wellington Silva    Date: 30/01/2015

hostname="$(uname -n)"

get_faillog ()
{
	user=$1
	(faillog -u $user  > /dev/null 2>&1 && faillog -u $user | tail -1 | while read a b c d e f; do echo "$b;$d $e;$f";done) || return 1
}

get_faillock ()
{
	user=$1
}

fail_test ()
{
	user=$1
	fail=$(which faillog > /dev/null 2>&1 && get_faillog $user) 
	echo "$fail"
}

rlogin_check()
{
	user=$1
	home=$2
	rlogin_state=$(grep disable /etc/xinetd.d/rsh 2> /dev/null | grep no  > /dev/null && echo enabled || echo disabled)
	if [ "$rlogin_state" == 'enabled' ]; then test -f $home/.rhosts && echo "rlogin enabled" || echo "rlogin disabled"; else echo "rlogin disabled";fi
}

passwd_file="$(cat /etc/passwd)"

echo "hostname;user;uid;gecos;shell;home;pgrp;groups;login;rlogin;loginretries;account_locked;minage;maxage;minlen;time_last_login;time_last_unsuccessful_login;host_last_login;host_last_unsuccessful_login;unsuccussful_login_count;date_pw_change;is_password_set"

echo "$passwd_file" |while read line; do
  user=$(echo "$line" | cut -d \: -f1)
  uid=$(echo "$line"  | cut -d \: -f3)
  gecos=$(echo "$line" | cut -d \: -f5)
  shell=$(echo "$line" | cut -d \: -f7)
  home=$(echo "$line" | cut -d \: -f6)
  login=$(echo $shell | egrep "false|nologin" > /dev/null 2>&1 && echo disable || echo enabled)
  pgrp="$(id -g -n $user)"
  groups="$(id -G -n $user)"
  chage_info=$(chage -l $user)
  minage=$(echo "$chage_info" | grep 'Minimum'|cut -d \: -f2)
  maxage=$(echo "$chage_info" | grep 'Maximum'|cut -d \: -f2)
  date_pw_change=$(echo "$chage_info" | grep 'Last'|cut -d \: -f2)
  last_info=$(last $user |grep -v 'wtmp begins' | head -1)
  host_last_login=$(echo "$last_info" | awk '{print $$2}')
  time_last_login=$(echo "$last_info" | awk '{print $1,$4,$5,$6,$7}')
  faillog=$(fail_test $user)
  time_last_unsuccessful_login=$(echo "$faillog" | cut -d \; -f 2)
  host_last_unsuccessful_login=$(echo "$faillog" | cut -d \; -f 3)
  unsuccussful_login_count=$(echo "$faillog" | cut -d \; -f 1)
  account_locked=$(passwd -S $user | awk '{print $2}' |grep L  > /dev/null 2>&1  && echo yes || echo no)
  minlen=$(grep -i PASS_MIN_LEN /etc/login.defs |grep -v ^\#| awk '{print $2}')
  loginretries=$(grep -i LOGIN_RETRIES /etc/login.defs | awk '{print $2}')
  is_password_set=$(passwd -S $user | awk '{print $2}' |grep P  > /dev/null 2>&1  && echo yes || echo no)
  rlogin=$(rlogin_check $user $home)
  echo "$hostname;$user;$uid;$gecos;$shell;$home;$pgrp;$groups;$login;$rlogin;$loginretries;$account_locked;$minage;$maxage;$minlen;$time_last_login;$time_last_unsuccessful_login;$host_last_login;$host_last_unsuccessful_login;$unsuccussful_login_count;$date_pw_change;$is_password_set"
done

