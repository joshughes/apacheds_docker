#!/bin/bash

test_replication () 
{
  REPLICATION=`ldapsearch -LLL \
    -h localhost \
    -p 10389 \
    -D "uid=admin,ou=system" \
    -w ${ADMIN_PASSWORD:=secret} \
    -b "ou=config" \
    -s sub "(${REPLCATION_SEARCH})"  \
    dn`
  echo "Replication is $REPLICATION"
}

send_ldif ()
{
  test_replication

  if [ ! -n "${REPLICATION}" ]; then
    envsubst < "/templates/${TEMPLATE}.ldif" > "/tmp/${TEMPLATE}.ldif"
    ldapmodify -c -a -f /tmp/${TEMPLATE}.ldif -h localhost -p 10389 -D "uid=admin,ou=system" -w ${ADMIN_PASSWORD}
  fi
}

enable_replication ()
{
  REPLCATION_SEARCH='ads-replReqHandler=org.apache.directory.server.ldap.replication.provider.SyncReplRequestHandler'
  TEMPLATE='replication_enabled'

  send_ldif
}

find_marathon_replicas ()
{
  echo "Checking Marathon "
  local TEST=`curl -s ${MARATHON_HOST}/v2/apps/${REPLICA_APP}/tasks`
  echo "Test is $TEST"
  if [ -n "${MARATHON_HOST}" ] && [ -n "${REPLICA_APP}" ]; then
    echo "Trying to get config from MARATHON_HOST ${MARATHON_HOST} and APP ${REPLICA_APP}"
    export REPLICA_HOSTS=`curl -s ${MARATHON_HOST}/v2/apps/${REPLICA_APP}/tasks | jq -r '.tasks[] | .host'`
    export REPLICA_PORTS=`curl -s ${MARATHON_HOST}/v2/apps/${REPLICA_APP}/tasks | jq -r '.tasks[] | .ports[0]'`
  fi
  echo "$REPLICA_HOSTS" > /root/CURRENT_REPLICA_HOSTS
  echo "$REPLICA_PORTS" > /root/CURRENT_REPLICA_PORTS
}

add_replica()
{
  echo "Adding replica $1 $2"
  export REPLICA_HOST=${1}
  export REPLICA_PORT=${2}
  TEMPLATE='setup_replication'
  REPLCATION_SEARCH="ads-replConsumerId=${1}:${2}"
  send_ldif
}

delete_replica()
{
  REPLCATION_SEARCH="ads-replConsumerId=${1}"
  test_replication
  if [ -n "${REPLICATION}" ]; then
    DN=`echo ${REPLICATION##dn:} | tr -d ' '`
    ldapdelete "${DN}" -p 10389 -h localhost -D "uid=admin,ou=system" -w ${ADMIN_PASSWORD}
  fi
  sleep 120 #Sleep here to try to avoid race condition with new replica coming up and needing to replicate
}

known_replicas()
{
  cp /root/CURRENT_REPLICA_HOSTS /root/KNOWN_REPLICA_HOSTS
  cp /root/CURRENT_REPLICA_PORTS /root/KNOWN_REPLICA_PORTS
}

setup_replication ()
{
  find_marathon_replicas
  known_replicas

  if [ ! -n "${RELICA_USER}"]; then
    export RELICA_USER="admin"
  fi

  if [ ! -n "$REPLICA_PASSWORD"]; then
    export REPLICA_PASSWORD="${ADMIN_PASSWORD}"
  fi

  REPLICA_HOSTS_ARRAY=($REPLICA_HOSTS)
  REPLICA_PORTS_ARRAY=($REPLICA_PORTS)

  for ((i=0;i<${#REPLICA_HOSTS_ARRAY[@]};++i)); do
    echo "replications ${REPLICA_HOSTS_ARRAY[i]} ${REPLICA_PORTS_ARRAY[i]}"
    add_replica "${REPLICA_HOSTS_ARRAY[i]}" "${REPLICA_PORTS_ARRAY[i]}"
  done
}
