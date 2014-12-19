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

enable_replication
setup_replication


nohup /root/replica_check.sh 0<&- &> /tmp/some_log.log &


/etc/init.d/apacheds-2.0.0-M19-default stop
/etc/init.d/apacheds-2.0.0-M19-default console