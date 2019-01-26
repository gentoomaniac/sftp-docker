#! /usr/bin/env bash

set -o pipefail
set -u

# load default values and export them
set -a
# shellcheck disable=SC1091
. /etc/preseed
set +a

DEBUG=0
CMD_PARAMS=()

while [[ ${#} -gt 0 ]]; do
    key=${1//=*}
    [[ "${1}" == *"="* ]] && value=${1##*=} || value=
    shift

    case "${key}" in

        -d|--debug)
        DEBUG=1
        ;;

        -s|--seed)
        SEED_FILE="${value}"
        ;;

        --)
        break
        ;;

        *)
        if [ -z "${value}" ]; then
            CMD_PARAMS+=( "${key}" )
        else
            CMD_PARAMS+=( "${key}=${value}" )
        fi
        ;;

    esac
done

if [ "${DEBUG}" -gt 0 ]; then
    set -x
fi

if [ -v SEED_FILE ]; then
    set -a
    # shellcheck disable=SC1090
    . "${SEED_FILE}"
    set +a
fi

SFTP_USERS_GROUP='sftp-users'
groupadd --gid "${SFTP_USERS_GID}" "${SFTP_USERS_GROUP}"

# create all sftp users based on the keys found in /sftp/authorized_keys
USER_BASE_DIR="/sftp/users"
USER_CREATE_ARGS='--no-create-home --shell /usr/sbin/nologin --comment sftp-user'
for dir in "${USER_BASE_DIR}"/*; do
    NAME="${dir##*/}"
    USER_HOME="$(head -n 1 ${USER_BASE_DIR}/home_dir 2>/dev/null)"
    USER_UID="$(head -n 1 ${USER_BASE_DIR}/uid 2>/dev/null)"
    USER_GIDS="$(head -n 1 ${USER_BASE_DIR}/gids 2>/dev/null)"

    ARGS="${USER_CREATE_ARGS}"
    if [ ! -z "${USER_HOME}" ]; then
        ARGS+=" --home-dir ${USER_HOME}"
    else
        ARGS+=" --home-dir /sftp/root"
    fi
    if [ ! -z "${USER_UID}" ]; then
        ARGS+=" --gid ${USER_UID}"
    else
        ARGS+=" --gid ${SFTP_USERS_GROUP}"
    fi
    if [ ! -z "${USER_GIDS}" ]; then
        ARGS+=" --groups ${USER_GIDS}"
    fi
    # shellcheck disable=SC2086
    useradd ${ARGS} "${NAME}"
done

# Set the received config values
for key in "${!SSHD_CONFIG[@]}"; do
    sed -i "s/{{${key}}}/${SSHD_CONFIG[${key}]}/g" /sftp/sshd_config
done

# shellcheck disable=SC2086,SC2068
#exec /sbin/tini -- /usr/local/bin/jenkins.sh ${CMD_PARAMS[*]} ${@}
exec /usr/sbin/sshd -f /sftp/sshd_config -D -e ${CMD_PARAMS[*]} ${@}