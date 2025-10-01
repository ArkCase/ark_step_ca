#
# Basic Parameters
#
ARG PUBLIC_REGISTRY="public.ecr.aws"
ARG PRIVATE_REGISTRY
ARG ARCH="x86_64"
ARG OS="linux"
ARG VER="0.28.4"
ARG PKG="step-ca"
ARG APP_USER="step"
ARG APP_UID="1000"
ARG APP_GROUP="${APP_USER}"
ARG APP_GID="${APP_UID}"

ARG STEP_REBUILD_REGISTRY="${PRIVATE_REGISTRY}"
ARG STEP_REBUILD_REPO="arkcase/rebuild-step-ca"
ARG STEP_REBUILD_TAG="latest"
ARG STEP_REBUILD_IMG="${STEP_REBUILD_REGISTRY}/${STEP_REBUILD_REPO}:${STEP_REBUILD_TAG}"

ARG BASE_REGISTRY="${PUBLIC_REGISTRY}"
ARG BASE_REPO="arkcase/base"
ARG BASE_VER="8"
ARG BASE_VER_PFX=""
ARG BASE_IMG="${BASE_REGISTRY}/${BASE_REPO}:${BASE_VER_PFX}${BASE_VER}"

FROM "${STEP_REBUILD_IMG}" AS step

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

RUN yum -y install epel-release yum-utils && \
    yum -y clean all

# Install the rebuilt step & step-ca executables
COPY --chown=root:root --chmod=0755 --from=step /step /step-ca /usr/local/bin/

ENV HOME="/app/${APP_USER}"
ENV STEP="${HOME}"
ENV STEPPATH="${STEP}"
ENV CONFIGPATH="${STEPPATH}/config/ca.json"
ENV PWDPATH="${STEPPATH}/secrets/password"

RUN groupadd --system --gid "${APP_GID}" "${APP_GROUP}" && \
    useradd  --system --uid "${APP_UID}" --gid "${APP_GROUP}" --groups "${APP_GROUP}" --create-home --home-dir "${HOME}" "${APP_USER}"

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
