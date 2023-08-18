#
# Basic Parameters
#
ARG PUBLIC_REGISTRY="public.ecr.aws"
ARG BASE_REPO="arkcase/base"
ARG BASE_TAG="8.7.0"
ARG ARCH="x86_64"
ARG OS="linux"
ARG VER="0.24.2"
ARG PKG="step-ca"
ARG SRC_IMAGE="smallstep/step-ca"
ARG APP_USER="step"
ARG APP_UID="1000"
ARG APP_GROUP="${APP_USER}"
ARG APP_GID="${APP_UID}"

#
# For artifact copying
#
FROM "${SRC_IMAGE}:${VER}" as src

ARG PUBLIC_REGISTRY
ARG BASE_REPO
ARG BASE_TAG

#
# For actual execution
#
FROM "${PUBLIC_REGISTRY}/${BASE_REPO}:${BASE_TAG}"

#
# Basic Parameters
#
ARG ARCH
ARG OS
ARG VER
ARG PKG
ARG APP_USER
ARG APP_UID
ARG APP_GROUP
ARG APP_GID

#
# Some important labels
#
LABEL ORG="ArkCase LLC"
LABEL MAINTAINER="ArkCase Support <support@arkcase.com>"
LABEL APP="Step-CA"
LABEL VERSION="${VER}"

RUN yum -y install epel-release yum-utils && \
    yum -y update && \
    yum -y clean all

ENV HOME="/home/${APP_USER}"
ENV STEP="${HOME}"
ENV STEPPATH="${STEP}"
ENV CONFIGPATH="${STEPPATH}/config/ca.json"
ENV PWDPATH="${STEPPATH}/secrets/password"

RUN groupadd --system --gid "${APP_GID}" "${APP_GROUP}" && \
    useradd  --system --uid "${APP_UID}" --gid "${APP_GROUP}" --groups "${APP_GROUP}" --create-home --home-dir "${HOME}" "${APP_USER}"

WORKDIR "${HOME}"

#
# Copy the required executables
#
COPY --from=src /usr/local/bin/step-ca \
                /usr/local/bin/step-kms-plugin \
                /usr/local/bin/step \
                /usr/local/bin/

#
# Declare some important volumes
#
VOLUME [ "${HOME}" ]

EXPOSE 9000
STOPSIGNAL SIGTERM

#
# Set up script and run
#
COPY entrypoint reconfigure /
RUN chmod 755 /entrypoint /reconfigure

USER "${APP_USER}"
HEALTHCHECK CMD /usr/local/bin/step ca health 2>/dev/null | /usr/bin/grep "^ok" >/dev/null
ENTRYPOINT /entrypoint
