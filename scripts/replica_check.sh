#!/bin/bash
. /root/functions.sh  --source-only

subtract_arrays()
{
  local RETURN_ARRAY=()
  declare -a argAry1=("${!1}")

  declare -a argAry2=("${!2}")

  for i in "${argAry1[@]}"; do
    skip=
    for j in "${argAry2[@]}"; do
        [[ $i == $j ]] && { skip=1; break; }
    done
    [[ -n $skip ]] || RETURN_ARRAY+=("$i")
  done
  echo ${RETURN_ARRAY[@]}
}

join_arrays()
{
  local RETURN_ARRAY=()
  declare -a argAry1=("${!1}")

  declare -a argAry2=("${!2}")

  for ((i=0;i<${#argAry1[@]};++i)); do
    RETURN_ARRAY+=("${argAry1[i]}:${argAry2[i]}")
  done
  echo ${RETURN_ARRAY[@]}

}

while true
do
  echo "Start Checking" 
  find_marathon_replicas

  REPLICA_HOSTS_ARRAY=($(cat /root/CURRENT_REPLICA_HOSTS))
  REPLICA_PORTS_ARRAY=($(cat /root/CURRENT_REPLICA_PORTS))

  KNOWN_HOSTS=($(cat /root/KNOWN_REPLICA_HOSTS))
  KNOWN_PORTS=($(cat /root/KNOWN_REPLICA_PORTS))

  RHP=($(join_arrays REPLICA_HOSTS_ARRAY[@] REPLICA_PORTS_ARRAY[@]))
  KHP=($(join_arrays KNOWN_HOSTS[@] KNOWN_PORTS[@]))
  echo "RHP ${RHP[@]}" 
  echo "KHP ${KHP[@]}" 

  SORT_RH=(`echo ${RHP[@]} |  tr ' ' '\n' | sort`)
  SORT_NH=(`echo ${KHP[@]} |  tr ' ' '\n' | sort`)

  DELETE_REPLICAS=($(subtract_arrays SORT_NH[@] SORT_RH[@]))
  ADD_REPLICAS=($(subtract_arrays SORT_RH[@] SORT_NH[@]))

  for i in "${DELETE_REPLICAS[@]}"; do
    delete_replica "${i}"
    known_replicas
  done

  for i in "${ADD_REPLICAS[@]}"; do
    HOST=${i%:*}
    PORT=${i#*:}
    add_replica "${HOST}" "${PORT}"
    known_replicas
  done

  echo "DELETE ${DELETE_REPLICAS[@]}" 
  echo "ADD ${ADD_REPLICAS[@]}" 

  sleep 60

done