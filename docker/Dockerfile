FROM container-registry.oracle.com/database/free:23.7.0.0-lite-amd64

USER oracle
RUN mkdir /opt/oracle/sash
COPY sash_dev/* /opt/oracle/sash/
COPY docker/01_install.sh /opt/oracle/scripts/startup
COPY docker/setPassword.sh /opt/oracle

USER root
RUN chown oracle:oinstall /opt/oracle/setPassword.sh
RUN chmod +x /opt/oracle/setPassword.sh
USER oracle
ENV SQLPATH=/opt/oracle/sash

