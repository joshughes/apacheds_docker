#!/bin/bash
. /root/functions.sh  --source-only

/etc/init.d/apacheds-2.0.0-M19-default start
/etc/init.d/xinetd start

sleep 10

if [ -n "${ADMIN_PASSWORD}" ]; then
  envsubst < "/templates/admin_password.ldif" > "/tmp/admin_password.ldif"
  ldapmodify -c -a -f /tmp/admin_password.ldif -h localhost -p 10389 -D "uid=admin,ou=system" -w secret
else
  export ADMIN_PASSWORD='secret'
fi

if [ -n "${NIS_ENABLED}" ]; then
  ldapmodify -c -a -f /ldifs/enable_nis.ldif -h localhost -p 10389 -D "uid=admin,ou=system" -w ${ADMIN_PASSWORD}
fi

if [ -n "${DOMAIN_NAME}" ] && [ -n "${DOMAIN_SUFFIX}" ]; then
  envsubst < "/templates/partition.ldif" > "/tmp/partition.ldif"
  ldapmodify -c -a -f /tmp/partition.ldif -h localhost -p 10389 -D "uid=admin,ou=system" -w ${ADMIN_PASSWORD}
  ldapdelete "ads-partitionId=example,ou=partitions,ads-directoryServiceId=default,ou=config" -r -p 10389 -h localhost -D "uid=admin,ou=system" -w ${ADMIN_PASSWORD}
  ldapdelete "dc=example,dc=com" -p 10389 -h localhost -D "uid=admin,ou=system" -r -w ${ADMIN_PASSWORD}
  /etc/init.d/apacheds-2.0.0-M19-default stop
  /etc/init.d/apacheds-2.0.0-M19-default start
  sleep 10
  envsubst < "/templates/top_domain.ldif" > "/tmp/top_domain.ldif"
  ldapmodify -c -a -f /tmp/top_domain.ldif -h localhost -p 10389 -D "uid=admin,ou=system" -w ${ADMIN_PASSWORD}
else
  export DOMAIN_NAME="example"
  export DOMAIN_SUFFIX="com"
fi

enable_replication
setup_replication


nohup /root/replica_check.sh 0<&- &> /tmp/replica_check.log &


/etc/init.d/apacheds-2.0.0-M19-default stop
/etc/init.d/apacheds-2.0.0-M19-default console