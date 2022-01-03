#!/bin/bash
set -o errexit

export GNUPGHOME=/data/mirrors/.keyring
MIRRORS_ROOT=/data/mirrors
REPO_NAME=nginx
REPO_ROOT="${MIRRORS_ROOT}/${REPO_NAME}"
RETAIN_SNAPSHOTS=2

DS=$(date +%Y%m%d%H%M%S)
APTLY_CONFIG=${MIRRORS_ROOT}/${REPO_NAME}/.aptly.conf
REMOTE_URL_BASE=http://nginx.org/packages/mainline
REPOKEY_URL=https://nginx.org/keys/nginx_signing.key

DISTROS=( debian ubuntu )
DEBIAN_RELEASES=( buster bullseye )
UBUNTU_RELEASES=( bionic focal )


if [[ ! -d "${REPO_ROOT}" ]] || [[ ! -d "${REPO_ROOT}/db" ]]; then
    echo "*** No existing mirror found"

    mkdir -p ${MIRRORS_ROOT}/${REPO_NAME}
    curl -s "${REPOKEY_URL}" \
        | gpg --no-default-keyring --keyring=${GNUPGHOME}/trustedkeys.gpg --import
fi


for distro in ${DISTROS[@]}; do
    releases=()
    [ "$distro" = "debian" ] && releases="${DEBIAN_RELEASES[@]}"
    [ "$distro" = "ubuntu" ] && releases="${UBUNTU_RELEASES[@]}"

    for release in ${releases[@]}; do
        echo -e "\n****************************** ${distro} ${release} ******************************"
        repo="${REPO_NAME}-${distro}-${release}"
        snap="${repo}-${DS}"
        is_new=1
        
        if aptly -config=${APTLY_CONFIG} mirror list -raw | grep -q "${repo}"; then
            is_new=0
        fi

        if [ $is_new = 1 ]; then
            aptly -config=${APTLY_CONFIG} mirror create -architectures=amd64 "${repo}" "${REMOTE_URL_BASE}/${distro}" "${release}" nginx
        fi

        aptly -config=${APTLY_CONFIG} mirror update "${repo}"
        aptly -config=${APTLY_CONFIG} snapshot create "${snap}" from mirror "${repo}"

        old_snapshots="$(aptly -config=${APTLY_CONFIG} snapshot list -raw -sort=time | grep "${repo}" | grep -E '\-[0-9]{14}' | head -n -${RETAIN_SNAPSHOTS})"

        if [ $is_new = 1 ]; then
            aptly -config=${APTLY_CONFIG} publish snapshot "${snap}" ${distro}
        else
            aptly -config=${APTLY_CONFIG} publish switch ${release} ${distro} "${snap}"
        fi

        echo "Removing old snapshots..."
        for old_snapshot in $old_snapshots; do
            echo " - ${old_snapshot}"
            aptly -config=${APTLY_CONFIG} snapshot drop ${old_snapshot}
        done
    done
done
