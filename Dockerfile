FROM dockerfile/java:oracle-java7

RUN apt-get update && apt-get install -y xinetd ldap-utils curl jq

ADD http://apache.tradebit.com/pub//directory/apacheds/dist/2.0.0-M19/apacheds-2.0.0-M19-amd64.deb /tmp/installer.deb
RUN dpkg -i /tmp/installer.deb 

COPY files/health_check.sh /root/health_check.sh
COPY files/healthchk /etc/xinetd.d/healthchk

RUN  mkdir /templates
COPY templates/replication_enabled.ldif /templates/replication_enabled.ldif
COPY templates/setup_replication.ldif /templates/setup_replication.ldif
COPY templates/admin_password.ldif /templates/admin_password.ldif

COPY scripts/start.sh /root/start.sh
COPY scripts/functions.sh /root/functions.sh
COPY scripts/replica_check.sh /root/replica_check.sh

RUN echo 'healthchk      11001/tcp' >> /etc/services

EXPOSE 10389 10636 11001

ENTRYPOINT ["/root/start.sh"]