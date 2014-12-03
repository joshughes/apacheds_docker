#!/bin/bash
#
# This script checks if the apacheds server is healthy running on localhost. It will
# return:
#
# "HTTP/1.x 200 OK"
#
# - OR -
#
# "HTTP/1.x 500 Internal Server Error" (else)
#
# Author: Joseph Hughes
#

TMP_FILE="/tmp/healthcheck.out"
ERR_FILE="/tmp/healthcheck.err"


#
# Check the output. If it is not empty then everything is fine and we return
# something. Else, we just do not return anything.
#

ldapsearch -h localhost -p 10389 -D "uid=admin,ou=system" -w ${ADMIN_PASSWORD:=secret} -b "ou=system" -s one "(uid=admin)" dn > /dev/null 2>&1

rc=$?

if [ $rc == 0 ]
then
    # ApacheDS is fine, return http 200
    /bin/echo -en "HTTP/1.1 200 OK\r\n"
    /bin/echo -en "Content-Type: text/plain\r\n"
    /bin/echo -en "Content-Length: 23\r\n"
    /bin/echo -en "\r\n"
    /bin/echo -en "ApacheDS is running.\r\n"
    /bin/echo -en "\r\n"
else
    # ApacheDS is fine, return http 503
    /bin/echo -en "HTTP/1.1 503 Service Unavailable\r\n"
    /bin/echo -en "Content-Length: 22"
    /bin/echo -en "Content-Type: Content-Type: text/plain\r\n"
    /bin/echo -en "\r\n"
    /bin/echo -en "ApacheDS is *down*.\r\n"
    /bin/echo -en "\r\n"
fi