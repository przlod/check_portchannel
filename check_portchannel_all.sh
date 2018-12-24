#!/bin/bash
#
# Przemyslaw Lodyga <plodyga@gmail.com>
#
# Nagios portchannel check based on sh etherchannel summary
#

if [ $# -ne 2 ]; then
    echo "Usage: $0 switch [portchannel|all]"
    echo "* switch: IP of the switch"
    echo "* portchannel: interface number - in the form of PoXY"
    exit 2;
fi

tmp_file="/tmp/portchannels.txt";
switch_user="";
switch_pass=''


if [ $2 == "all" ]; then
  sshpass -p $switch_pass ssh $switch_user@$1 "sh etherchannel summary" | grep ^[0-9] > $tmp_file ; 
  
else

   sshpass -p $switch_pass ssh $switch_user@$1 "sh etherchannel summary" | grep "$2(" > $tmp_file ;

   if [ ! -s "$tmp_file" ]; then
      echo "UNKNOWN: Connection failed or ($2) port channel does not seem to exist"
      exit 3;
   fi
fi

exit_code=0

while IFS='' read -r line || [[ -n "$line" ]]; do

   interfaces=($(echo $line|awk -F ' ' '{print $2;for (i=4; i<NF; i++) print $i;}'));
   port_count=$((${#interfaces[@]} - 1));
   failed=0;

   for i in "${interfaces[@]}"; do
      if [[ $i =~ '^Po' ]]; then
         output="${output}\n${i}";
      elif [[ ! $i =~ 'P' ]]; then
         output="${output} $i"
         failed=$((failed + 1))
      else 
         output="${output} $i"
      fi
   
   done

   if [ $failed -eq $port_count ]; then
      exit_code=2
   elif [ $failed -ne 0 ]; then
      exit_code=1
   fi

done < "$tmp_file"

rm $tmp_file

if [ $exit_code -eq 0 ]; then
   output="OK: ${output}"
   #status=0;
elif [ $exit_code -eq 2 ]; then
   output="CRITICAL: ${output}"
   #status=2;
else
   output="WARNING: ${output}"
   #status=1
fi

printf "${output}";
exit $exit_code;



