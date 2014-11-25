#!/usr/bin/env bash

### bash best practices ###
# exit on error code
set -o errexit
# exit on unset variable
set -o nounset
# return error of last failed command in pipe
set -o pipefail
# expand aliases
shopt -s expand_aliases
# print trace
set -o xtrace

### logfile ###
timestamp="$(date +%Y-%m-%d_%H-%M-%S)"
logfile="logfile_${timestamp}.txt"
echo "${0} ${@}" > "${logfile}"
# save stdout to logfile
exec 1> >(tee -a "${logfile}")
# redirect errors to stdout
exec 2> >(tee -a "${logfile}" >&2)

### environment variables ###
source crosscompile.sh
export NAME="iozone"
export DEST="/mnt/DroboFS/Shares/DroboApps/${NAME}"
export DEPS="/mnt/DroboFS/Shares/DroboApps/${NAME}deps"
export CFLAGS="$CFLAGS -Os -fPIC"
export CXXFLAGS="$CXXFLAGS $CFLAGS"
export CPPFLAGS="-I${DEPS}/include"
export LDFLAGS="${LDFLAGS:-} -Wl,-rpath,${DEST}/lib -L${DEST}/lib"
alias make="make -j8 V=1 VERBOSE=1"

# $1: file
# $2: url
# $3: folder
_download_tgz() {
  [[ ! -f "download/${1}" ]] && wget -O "download/${1}" "${2}"
  [[ -d "target/${3}" ]] && rm -v -fr "target/${3}"
  [[ ! -d "target/${3}" ]] && tar -zxvf "download/${1}" -C target
  return 0
}

# $1: file
# $2: url
# $3: folder
_download_tar() {
  [[ ! -f "download/${1}" ]] && wget -O "download/${1}" "${2}"
  [[ -d "target/${3}" ]] && rm -v -fr "target/${3}"
  [[ ! -d "target/${3}" ]] && tar -xvf "download/${1}" -C target
  return 0
}

# $1: file
# $2: url
# $3: folder
_download_app() {
  [[ ! -f "download/${1}" ]] && wget -O "download/${1}" "${2}"
  [[ -d "target/${3}" ]] && rm -v -fr "target/${3}"
  mkdir -p "target/${3}"
  tar -zxvf "download/${1}" -C target/${3}
  return 0
}

# $1: branch
# $2: folder
# $3: url
_download_git() {
  [[ -d "target/${2}" ]] && rm -v -fr "target/${2}"
  [[ ! -d "target/${2}" ]] && git clone --branch "${1}" --single-branch --depth 1 "${3}" "target/${2}"
  return 0
}

# $1: file
# $2: url
_download_file() {
  [[ ! -f "download/${1}" ]] && wget -O "download/${1}" "${2}"
  return 0
}

### IOZONE ###
_build_iozone() {
local VERSION="3_429"
local FOLDER="iozone${VERSION}"
local FILE="${FOLDER}.tar"
local URL="http://www.iozone.org/src/current/${FILE}"

_download_tar "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}/src/current"
make linux-arm CC="${CC}" GCC="${CC}"
mkdir -p "${DEST}/bin"
cp -v iozone fileop pit_server "${DEST}/bin/"
popd
}

### BUILD ###
_build() {
  _build_iozone
  _package
}

_create_tgz() {
  local appname="$(basename ${PWD})"
  local appfile="${PWD}/${appname}.tgz"

  if [[ -f "${appfile}" ]]; then
    rm -v "${appfile}"
  fi

  pushd "${DEST}"
  tar --verbose --create --numeric-owner --owner=0 --group=0 --gzip --file "${appfile}" *
  popd
}

_package() {
  mkdir -p "${DEST}"
  cp -avfR src/dest/* "${DEST}"/
  find "${DEST}" -name "._*" -print -delete
  _create_tgz
}

_clean() {
  rm -v -fr "${DEPS}"
  rm -v -fr "${DEST}"
  rm -v -fr target/*
}

_dist_clean() {
  _clean
  rm -v -f logfile*
  rm -v -fr download/*
}

case "${1:-}" in
  clean)     _clean ;;
  distclean) _dist_clean ;;
  package)   _package ;;
  "")        _build ;;
  *)         _build_${1} ;;
esac
