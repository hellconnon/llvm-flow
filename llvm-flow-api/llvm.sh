#!/bin/bash
################################################################################
# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
################################################################################
#
# This script will install the llvm toolchain on the different
# Debian and Ubuntu versions

set -eux

usage() {
    set +x
    echo "Usage: $0 [llvm_major_version] [OPTIONS]" 1>&2
    echo -e "-n=code_name\t\tSpecifies the distro codename, for example bionic" 1>&2
    echo -e "-h\t\t\tPrints this help." 1>&2
    echo -e "-m=repo_base_url\tSpecifies the base URL from which to download." 1>&2
    exit 1;
}

CURRENT_LLVM_STABLE=19
BASE_URL="http://apt.llvm.org"

NEW_DEBIAN_DISTROS=("trixie" "unstable")
# Set default values for commandline arguments
# We default to the current stable branch of LLVM
LLVM_VERSION=$CURRENT_LLVM_STABLE
ALL=0
DISTRO=$(lsb_release -is)
VERSION_CODENAME=$(lsb_release -cs)
VERSION=$(lsb_release -sr)
UBUNTU_CODENAME=""
CODENAME_FROM_ARGUMENTS=""
# Obtain VERSION_CODENAME and UBUNTU_CODENAME (for Ubuntu and its derivatives)
source /etc/os-release
DISTRO=${DISTRO,,}

# Check for required tools

# Check if this is a new Debian distro
is_new_debian=0
if [[ "${DISTRO}" == "debian" ]]; then
    for new_distro in "${NEW_DEBIAN_DISTROS[@]}"; do
        if [[ "${VERSION_CODENAME}" == "${new_distro}" ]]; then
            is_new_debian=1
            break
        fi
    done
fi

# Check for required tools
needed_binaries=(lsb_release wget gpg)
# add-apt-repository is not needed for newer Debian distros
if [[ $is_new_debian -eq 0 ]]; then
    needed_binaries+=(add-apt-repository)
fi

missing_binaries=()
using_curl=
for binary in "${needed_binaries[@]}"; do
    if ! command -v $binary &>/dev/null ; then
        if [[ "$binary" == "wget" ]] && command -v curl &>/dev/null; then
            using_curl=1
            continue
        fi
        missing_binaries+=($binary)
    fi
done

if [[ ${#missing_binaries[@]} -gt 0 ]] ; then
    echo "You are missing some tools this script requires: ${missing_binaries[@]}"
    echo "(hint: apt install lsb-release wget software-properties-common gnupg)"
    echo "curl is also supported"
    exit 4
fi

case ${DISTRO} in
    debian)
        # Debian Trixie has a workaround because of
        # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1038383
        if [[ "${VERSION}" == "unstable" ]] || [[ "${VERSION}" == "testing" ]] || [[ "${VERSION_CODENAME}" == "trixie" ]]; then
            CODENAME=unstable
            LINKNAME=
        else
            # "stable" Debian release
            CODENAME=${VERSION_CODENAME}
            LINKNAME=-${CODENAME}
        fi
        ;;
    *)
        # ubuntu and its derivatives
        if [[ -n "${UBUNTU_CODENAME}" ]]; then
            CODENAME=${UBUNTU_CODENAME}
            if [[ -n "${CODENAME}" ]]; then
                LINKNAME=-${CODENAME}
            fi
        fi
        ;;
esac

# read optional command line arguments
LLVM_VERSION=$1

while getopts ":hm:n:" arg; do
    case $arg in
    h)
        usage
        ;;
    m)
        BASE_URL=${OPTARG}
        ;;
    n)
        CODENAME=${OPTARG}
        if [[ "${CODENAME}" == "unstable" ]]; then
            # link name does not apply to unstable repository
            LINKNAME=
        else
            LINKNAME=-${CODENAME}
        fi
        CODENAME_FROM_ARGUMENTS="true"
        ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root!"
   exit 1
fi

declare -A LLVM_VERSION_PATTERNS
LLVM_VERSION_PATTERNS[9]="-9"
LLVM_VERSION_PATTERNS[10]="-10"
LLVM_VERSION_PATTERNS[11]="-11"
LLVM_VERSION_PATTERNS[12]="-12"
LLVM_VERSION_PATTERNS[13]="-13"
LLVM_VERSION_PATTERNS[14]="-14"
LLVM_VERSION_PATTERNS[15]="-15"
LLVM_VERSION_PATTERNS[16]="-16"
LLVM_VERSION_PATTERNS[17]="-17"
LLVM_VERSION_PATTERNS[18]="-18"
LLVM_VERSION_PATTERNS[19]="-19"
LLVM_VERSION_PATTERNS[20]="-20"
LLVM_VERSION_PATTERNS[21]=""

if [ ! ${LLVM_VERSION_PATTERNS[$LLVM_VERSION]+_} ]; then
    echo "This script does not support LLVM version $LLVM_VERSION"
    exit 3
fi

LLVM_VERSION_STRING=${LLVM_VERSION_PATTERNS[$LLVM_VERSION]}

# join the repository name
if [[ -n "${CODENAME}" ]]; then
    REPO_NAME="deb ${BASE_URL}/${CODENAME}/  llvm-toolchain${LINKNAME}${LLVM_VERSION_STRING} main"
    # check if the repository exists for the distro and version
    if ! wget -q --method=HEAD ${BASE_URL}/${CODENAME} &> /dev/null && \
      ! curl -sSLI -XHEAD ${BASE_URL}/${CODENAME} &> /dev/null; then
        if [[ -n "${CODENAME_FROM_ARGUMENTS}" ]]; then
            echo "Specified codename '${CODENAME}' is not supported by this script."
        else
            echo "Distribution '${DISTRO}' in version '${VERSION}' is not supported by this script."
        fi
        exit 2
    fi
fi


# install everything

if [[ ! -f /etc/apt/trusted.gpg.d/apt.llvm.org.asc ]]; then
    # download GPG key once
    if [[ -z "$using_curl" ]]; then
        wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc
    else
        curl -sSL https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc
    fi
fi

if [[ -z "`apt-key list 2> /dev/null | grep -i llvm`" ]]; then
    # Delete the key in the old format
    apt-key del AF4F7421 || true
fi


# Add repository based on distribution
if [[ "${VERSION_CODENAME}" == "bookworm" ]]; then
    # add it twice to workaround:
    # https://github.com/llvm/llvm-project/issues/62475
    add-apt-repository -y "${REPO_NAME}"
    add-apt-repository -y "${REPO_NAME}"
elif [[ $is_new_debian -eq 1 ]]; then
    # workaround missing add-apt-repository in newer Debian and use new source.list format
    SOURCES_FILE="/etc/apt/sources.list.d/http_apt_llvm_org_${CODENAME}_-${VERSION_CODENAME}.sources"
    TEXT_TO_ADD="Types: deb
Architectures: amd64 arm64
Signed-By: /etc/apt/trusted.gpg.d/apt.llvm.org.asc
URIs: ${BASE_URL}/${CODENAME}/
Suites: llvm-toolchain${LINKNAME}${LLVM_VERSION_STRING}
Components: main"
    echo "$TEXT_TO_ADD" | tee -a "$SOURCES_FILE" > /dev/null
else
    add-apt-repository -y "${REPO_NAME}"
fi

apt-get update
PKG="clang-$LLVM_VERSION lld-$LLVM_VERSION"
apt-get install -y $PKG
