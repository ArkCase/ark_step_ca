#
# Basic Parameters
#
ARG FIPS=""
ARG PUBLIC_REGISTRY="public.ecr.aws"
ARG PRIVATE_REGISTRY
ARG ARCH="x86_64"
ARG OS="linux"
ARG VER="0.30.2"
ARG PKG="step-ca"
ARG APP_USER="step"
ARG APP_UID="1000"
ARG APP_GROUP="${APP_USER}"
ARG APP_GID="${APP_UID}"

ARG BASE_REGISTRY="${PUBLIC_REGISTRY}"
ARG BASE_REPO="arkcase/base"
ARG BASE_VER="24.04"
ARG BASE_VER_PFX=""
ARG BASE_IMG="${BASE_REGISTRY}/${BASE_REPO}${FIPS}:${BASE_VER_PFX}${BASE_VER}"

ARG STEP_REGISTRY="${PRIVATE_REGISTRY}"
ARG STEP_REPO="arkcase/rebuild-step-ca"
ARG STEP_VER="${VER}"
ARG STEP_VER_PFX="${BASE_VER_PFX}"
ARG STEP_IMG="${STEP_REGISTRY}/${STEP_REPO}${FIPS}:${STEP_VER_PFX}${STEP_VER}"

FROM "${STEP_IMG}" AS step

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

#
# Some important labels
#
LABEL ORG="ArkCase LLC"
LABEL MAINTAINER="ArkCase Support <support@arkcase.com>"
LABEL APP="Step-CA"
LABEL VERSION="${VER}"

ENV HOME="/app/${APP_USER}"
ENV STEP="${HOME}"
ENV STEPPATH="${STEP}"
ENV CONFIGPATH="${STEPPATH}/config/ca.json"
ENV PWDPATH="${STEPPATH}/secrets/password"

ENV STEP_CERTIFICATE_TEMPLATE="/usr/local/etc/default-certificate-template.tpl"

ENV SSL_INIT_DEFERRED="true"
RUN --mount=type=bind,target=/src \
    --mount=type=bind,from=step,target=/step \
    install -o root -g root -m 0755 -t /usr/local/bin /step/step-ca && \
    install -o root -g root -m 0555 -t /usr/local/bin /src/reconfigure /src/entrypoint && \
    groupadd --system --gid "${APP_GID}" "${APP_GROUP}" && \
    useradd  --system --uid "${APP_UID}" --gid "${APP_GROUP}" --groups "${APP_GROUP}" --create-home --home-dir "${HOME}" "${APP_USER}" && \
    chmod -R g-w,o-rwx "${HOME}" && \
    install -o root -g root -m 0444 /src/default-certificate-template.tpl "${STEP_CERTIFICATE_TEMPLATE}" && \
    chown -R "${APP_USER}:${APP_GROUP}" "${TEMP_DIR}" && \
    chmod -R u=rwX,g=rX,o= "${TEMP_DIR}"

WORKDIR "${HOME}"

EXPOSE 9000
STOPSIGNAL SIGTERM

USER "${APP_USER}"
HEALTHCHECK CMD /usr/bin/step ca health 2>/dev/null | /usr/bin/grep -i "^ok" >/dev/null
