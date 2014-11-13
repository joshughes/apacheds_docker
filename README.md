apacheds_docker
===============

[ApacheDS Homepage](http://directory.apache.org/apacheds/)

This project run ApacheDS in a docker container with an Oracle Java 7 environment. 


##How to use this image
Currently this image does not take any environment variables but you need to expose ports to your local machine to connect using [Apache Directory Studio](http://directory.apache.org/studio/)

* `-p 10389:10389`  (unencrypted or StartTLS)
* `-p 10636:10636`  (SSL)


##Example with boot2docker

1. `docker run --name apacheds -d -p 10389:10389 jjhughes57/apacheds-docker`
2. Start Apache Directory Studio 
3. In the bottom left corner there is a section called "Connections" Click on the "LDAP" icon to add a connection to your container. 
4. Hostname: `192.168.59.103` and Port: `10389`
5. Click "Next"
6. Bind DN or user: `uid=admin,ou=system` Bind password: `secret` (Default ApacheDS password)
7. Click "Finish"




