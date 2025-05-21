#
# Basic Parameters
#
ARG PUBLIC_REGISTRY="public.ecr.aws"
ARG ARCH="x86_64"
ARG OS="linux"
ARG VER="0.28.6"
ARG PKG="step-ca"
ARG APP_USER="step"
ARG APP_UID="1000"
ARG APP_GROUP="${APP_USER}"
ARG APP_GID="${APP_UID}"

ARG STEP_SRC="https://github.com/smallstep/certificates/releases/download/v${VER}/step-ca_amd64.rpm"
ARG STEP_KMS_VER="0.12.2"
ARG STEP_KMS_SRC="https://github.com/smallstep/step-kms-plugin/releases/download/v${STEP_KMS_VER}/step-kms-plugin_${STEP_KMS_VER}_amd64.rpm"

ARG BASE_REGISTRY="${PUBLIC_REGISTRY}"
ARG BASE_REPO="arkcase/base"
ARG BASE_VER="8"
ARG BASE_VER_PFX=""
ARG BASE_IMG="${BASE_REGISTRY}/${BASE_REPO}:${BASE_VER_PFX}${BASE_VER}"

#
# For actual execution
#
FROM "${BASE_IMG}"

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
COPY entrypoint reconfigure check-ready /
RUN chmod 755 /entrypoint /reconfigure /check-ready

USER "${APP_USER}"
HEALTHCHECK CMD /usr/bin/step ca health 2>/dev/null | /usr/bin/grep -i "^ok" >/dev/null
ENTRYPOINT [ "/entrypoint" ]
