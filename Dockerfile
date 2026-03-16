#
# Basic Parameters
#
ARG FIPS=""
ARG PUBLIC_REGISTRY="public.ecr.aws"
ARG PRIVATE_REGISTRY
ARG ARCH="x86_64"
ARG OS="linux"
ARG VER="0.29.0"
ARG PKG="step-ca"
ARG APP_USER="step"
ARG APP_UID="1000"
ARG APP_GROUP="${APP_USER}"
ARG APP_GID="${APP_UID}"

ARG STEP_REGISTRY="${PRIVATE_REGISTRY}"
ARG STEP_REPO="arkcase/rebuild-step-ca"
ARG STEP_VER="${VER}"
ARG STEP_VER_PFX="${BASE_VER_PFX}"
ARG STEP_IMG="${STEP_REGISTRY}/${STEP_REPO}:${STEP_VER_PFX}${STEP_VER}"

ARG BASE_REGISTRY="${PUBLIC_REGISTRY}"
ARG BASE_REPO="arkcase/base"
ARG BASE_VER="24.04"
ARG BASE_VER_PFX=""
ARG BASE_IMG="${BASE_REGISTRY}/${BASE_REPO}${FIPS}:${BASE_VER_PFX}${BASE_VER}"

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

# Install the rebuilt step & step-ca executables
COPY --chown=root:root --chmod=0755 --from=step /step /step-ca /usr/local/bin/

ENV HOME="/app/${APP_USER}"
ENV STEP="${HOME}"
ENV STEPPATH="${STEP}"
ENV CONFIGPATH="${STEPPATH}/config/ca.json"
ENV PWDPATH="${STEPPATH}/secrets/password"

RUN groupadd --system --gid "${APP_GID}" "${APP_GROUP}" && \
    useradd  --system --uid "${APP_UID}" --gid "${APP_GROUP}" --groups "${APP_GROUP}" --create-home --home-dir "${HOME}" "${APP_USER}" && \
    chmod -R g-w,o-rwx "${HOME}"

WORKDIR "${HOME}"

EXPOSE 9000
STOPSIGNAL SIGTERM

#
# Set up script and run
#
COPY --chown=root:root --chmod=0755 entrypoint /
COPY --chown=root:root --chmod=0755 reconfigure /usr/local/bin/

USER "${APP_USER}"
HEALTHCHECK CMD /usr/bin/step ca health 2>/dev/null | /usr/bin/grep -i "^ok" >/dev/null
ENTRYPOINT [ "/entrypoint" ]
