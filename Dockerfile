FROM dockerfile/java:oracle-java7

ADD http://apache.tradebit.com/pub//directory/apacheds/dist/2.0.0-M17/apacheds-2.0.0-M17-amd64.deb /tmp/installer.deb

RUN dpkg -i /tmp/installer.deb 

EXPOSE 10389 10636

CMD /opt/apacheds-2.0.0-M17/bin/apacheds console default