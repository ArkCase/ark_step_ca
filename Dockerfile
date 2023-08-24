#
# Basic Parameters
#
ARG PUBLIC_REGISTRY="public.ecr.aws"
ARG BASE_REPO="arkcase/base"
ARG BASE_TAG="8.8-02"
ARG ARCH="x86_64"
ARG OS="linux"
ARG VER="0.24.2"
ARG BLD="01"
ARG PKG="step-ca"
ARG SRC_IMAGE="smallstep/step-ca"
ARG APP_USER="step"
ARG APP_UID="1000"
ARG APP_GROUP="${APP_USER}"
ARG APP_GID="${APP_UID}"
ARG STEP_SRC="https://github.com/smallstep/certificates/releases/download/v${VER}/step-ca_${VER}_amd64.rpm"
ARG STEP_KMS_VER="0.9.1"
ARG STEP_KMS_SRC="https://github.com/smallstep/step-kms-plugin/releases/download/v${STEP_KMS_VER}/step-kms-plugin_${STEP_KMS_VER}_amd64.rpm"

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
ARG STEP_SRC
ARG STEP_KMS_SRC

#
# Some important labels
#
LABEL ORG="ArkCase LLC"
LABEL MAINTAINER="ArkCase Support <support@arkcase.com>"
LABEL APP="Step-CA"
LABEL VERSION="${VER}"

RUN yum -y install epel-release yum-utils && \
    yum -y install \
        "${STEP_SRC}" \
        "${STEP_KMS_SRC}" \
    && \
    yum -y clean all

ENV HOME="/app/${APP_USER}"
ENV STEP="${HOME}"
ENV STEPPATH="${STEP}"
ENV CONFIGPATH="${STEPPATH}/config/ca.json"
ENV PWDPATH="${STEPPATH}/secrets/password"

RUN groupadd --system --gid "${APP_GID}" "${APP_GROUP}" && \
    useradd  --system --uid "${APP_UID}" --gid "${APP_GROUP}" --groups "${APP_GROUP}" --create-home --home-dir "${HOME}" "${APP_USER}"

WORKDIR "${HOME}"

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
HEALTHCHECK CMD /usr/bin/step ca health 2>/dev/null | /usr/bin/grep -i "^ok" >/dev/null
ENTRYPOINT /entrypoint
