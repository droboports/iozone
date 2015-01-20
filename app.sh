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
