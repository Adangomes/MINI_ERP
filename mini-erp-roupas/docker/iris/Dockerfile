FROM intersystemsdc/iris-community:2026.1

USER root
WORKDIR /opt/app
RUN chown -R ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/app

# The base image's first-start SQL bootstrap fails on ARM64 at dbapi.connect.
RUN printf 'initialized\n' > /usr/irissys/iris.init \
    && chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /usr/irissys/iris.init

USER ${ISC_PACKAGE_MGRUSER}

COPY bootstrap.sh /opt/app/bootstrap.sh
