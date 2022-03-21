#!/bin/env bash

# This script's directory: https://stackoverflow.com/questions/59895/how-can-i-get-the-source-directory-of-a-bash-script-from-within-the-script-itsel
export THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

export LIB_VER=${LIB_VER:-"77"}
export NAME="boost"
export EXTRACT_DIR="/tmp/"
export INSTALL_DIR="/tmp/build/${NAME}"
export PKG_URL="http://sourceforge.net/projects/boost/files/boost/1.${LIB_VER}.0/boost_1_${LIB_VER}_0.tar.gz"
export ICU_ROOT="/usr/local/lib/icu/70.1/"

function build_and_install()
{
  if [ $# -eq 0 ]; then
    ./bootstrap.sh --with-python-version=3.5 --with-python=$(which python3) --with-icu=${ICU_ROOT}
  else
    ./bootstrap.sh --with-python-version=3.5 --with-python=$(which python3) --with-icu=${ICU_ROOT} --prefix="$1"
  fi

  local GATHERED_FLAGS=()
  if [ -n "${CXXFLAGS}" ]; then
    GATHERED_FLAGS+=($CXXFLAGS)
  fi
  if [ -n "${CPPFLAGS}" ]; then
    GATHERED_FLAGS+=($CPPFLAGS)
  fi

  # We want a release build of shared libraries only
  local BOOST_COMPILE_ARGS=()
  BOOST_COMPILE_ARGS+=("variant=release")
  BOOST_COMPILE_ARGS+=("link=shared")
  if [ -n "${GATHERED_FLAGS}" ]; then
    echo "Building Boost with C++ flags: ${GATHERED_FLAGS}"
    BOOST_COMPILE_ARGS+=("cxxflags=${GATHERED_FLAGS}")
  else
    echo "Building Boost with no C++ flag"
  fi
  echo "./b2 ${BOOST_COMPILE_ARGS}"
  ./b2 ${BOOST_COMPILE_ARGS}

  if [ $# -eq 0 ]; then
    # No argument passed: installing in the system.
    echo "Installing Boost in the system"
    sudo ./b2 install ${BOOST_COMPILE_ARGS}
  else
    # Argument passed: installing in a custom location.
    echo "Installing Boost in $1"
    ./b2 install ${BOOST_COMPILE_ARGS}
  fi
}

# install boost from source (specific version is needed)
# with https://stackoverflow.com/questions/5539557/boost-and-python-3-x
curl -L -v "${PKG_URL}" | tar -C ${EXTRACT_DIR}/ -xz
cd ${EXTRACT_DIR}/boost_1_${LIB_VER}_0/
build_and_install ${INSTALL_DIR}
echo '${LIB_VER}' | sudo tee -a ${INSTALL_DIR}/VERSION

if [ -x "$(command -v qibuild)" ]; then
  echo "------------ Building qitoolchain package ----------------"
  export CMAKE_RELATIVE_DIR="share/cmake/"
  export CMAKE_LOCAL_DIR="${THIS_DIR}/${CMAKE_RELATIVE_DIR}"
  export CMAKE_INSTALL_DIR="${INSTALL_DIR}/${CMAKE_RELATIVE_DIR}"
  mkdir -p "${CMAKE_INSTALL_DIR}"
  cp -rv "${CMAKE_LOCAL_DIR}/"* "${CMAKE_INSTALL_DIR}"
  sudo qitoolchain make-package --auto --name ${NAME} --version "1.${LIB_VER}.0" --target linux64 ${INSTALL_DIR} --output ${WORKSPACE_PATH}
else
  echo "Qibuild is not installed, skipping packaging"
fi

# install on the system for the next tasks
build_and_install
