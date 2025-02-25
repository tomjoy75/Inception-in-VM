FROM debian:bullseye
RUN apt-get update && apt-get upgrade -y 
RUN apt-get install -y mariadb-server netcat
COPY ./conf/mdb-conf.sh /mdb-conf.sh
RUN chmod +x /mdb-conf.sh
# Add correct permissions for mysql user
RUN mkdir -p /var/lib/mysql /var/run/mysqld \
    && chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
    && chmod 777 /var/run/mysqld
ENTRYPOINT ["./mdb-conf.sh"]

