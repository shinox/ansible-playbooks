#!/bin/sh
#
# MrM: 
# 25 Jul 2017
#
# WORK IN PROGRESS DO NOT USE UNLESS YOU ARE THE CREATOR !!!
# 
# -- Script add users from ../users.txt file to the server and 
#    creates ansible script so it can be populated to clients
# -- Gotchas:
#    1.) Check the uid:guid start from
#    2.) point to list with names and uid to start from
#    3.) Edit USER_GROUPS to include required outcome
#    4.) .yml ansible script is always generated but 
#        users already present in server configs are not updated,
#
PLAYBOOKS="/home/<USER_NAME>/ansible/playbooks"
# Get list from file then just apply to server and generate .yml "butter on bread"
FILE=$1

l_uid=$2
# Stamp when script run
DATE=`date +%H%M_%d%m%Y`

USER_GROUPS="hive"

## get length of an array
# groupslength=${#groups[@]}
#stafflength=${#staff[@]}

# Get header before loop
#read -d '' yml_header_block <<"YML_HEADER_BLOCK"
cat <<EOF >> $PLAYBOOKS/new_USER_users_$DATE.yml
---
- hosts: hive

  tasks:

EOF
#
##
#
lname=""
sname=""
i=0
while IFS= read -r lname;
do  
 #
 #
 #
 # sname=$(echo $lname | awk '$0=$0FS {print $5, tolower(substr($1,1,1)$NF)}' | sed -e 's/^ //g')
  sname=$(echo $lname | awk '$0=$0FS {print $5, tolower(substr($1,1,1)$NF)}')
  # the pass is ok but don't like it
  RPASS=$(openssl rand -base64 9)
  #
  echo "User: $i UID:GUID $l_uid:$l_uid : $lname : $sname :pw: $RPASS" | tee -a ../users_out_$DATE.txt 
  #
  if [ ! `id -u $sname 2>/dev/null || echo -1` -ge 0 ]; then
      echo "User not found will add:"
      groupadd -g $l_uid $sname
      useradd -g $l_uid -u $l_uid -c "$l_name" -m -s/bin/bash -G$USER_GROUPS $sname
      echo -e "$RPASS\n$RPASS" | passwd $sname
  else
      echo "User exists want to change pass to random?";
      echo "Pass will match .yml config";
      #
      # This line is culprit, the stdin is already taken by while do < redirect
      # hence need to address tty directly,     
      #
      read -n 1 -p "Y/n:" pass < /dev/tty
      case ${pass:0:1} in
          Y )
              echo "Changing pw:"
 #            echo -e "$RPASS\n$RPASS" | passwd $sname
              ;;
          * )
              echo "Leaving !!! UNCHANGED !!!"
              sleep 1
              ;;
      esac
     
  fi

# Create .yml script anyway cause we can
cat <<EOF >> $PLAYBOOKS/new_USER_users_$DATE.yml
  - name: create group for user: ${sname}
    group:
        name: ${sname}
        gid: ${l_uid}
        state: present

  - name: create new NIG account: ${sname}
    user:
        name=${sname}
        comment=${lname}
        password="{{ '${RPASS}' | password_hash('sha512') }}"
        shell=/bin/bash
        group=${sname}
        groups=${USER_GROUPS}
        uid=${l_uid}
        update_password=always
        state=present

EOF

sleep 1

  l_uid=$(($l_uid + 1))

i=$(($i +1 ))
lname=""
sname=""
#
done < $FILE
#
