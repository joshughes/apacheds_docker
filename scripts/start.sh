#/bin/bash
/etc/init.d/apacheds-2.0.0-M19-default start
/etc/init.d/xinetd start

sleep 10

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

if [ -n "${ADMIN_PASSWORD}" ]; then
  envsubst < "/templates/admin_password.ldif" > "/tmp/admin_password.ldif"
  ldapmodify -c -a -f /tmp/admin_password.ldif -h localhost -p 10389 -D "uid=admin,ou=system" -w secret
else
  export ADMIN_PASSWORD='secret'
fi

if [ -n "${SLAVE}" ]; then
  ROLE='slave'
  REPLCATION_SEARCH="ads-replProvHostName=${MASTER_HOST}"
else
  ROLE='master'
  REPLCATION_SEARCH='ads-replReqHandler=org.apache.directory.server.ldap.replication.provider.SyncReplRequestHandler'
fi

test_replication

if [ ! -n "${REPLICATION}" ]; then
  envsubst < "/templates/${ROLE}.ldif" > "/tmp/${ROLE}.ldif"
  ldapmodify -c -a -f /tmp/${ROLE}.ldif -h localhost -p 10389 -D "uid=admin,ou=system" -w ${ADMIN_PASSWORD}
fi

/etc/init.d/apacheds-2.0.0-M19-default stop