#!/bin/bash

export LIB_VER=${LIB_VER:-"OpenSSL_1_1_1m"}
export NAME="openssl"
export EXTRACT_DIR="/tmp/${NAME}"
export INSTALL_DIR="/tmp/build/${NAME}"
export GIT_URL="https://github.com/openssl/openssl.git"

function build_and_install()
{
  if [ $# -eq 0 ]; then
    ./config
  else
    ./config --prefix=$1 --openssldir=$1
  fi

  echo "Building OpenSSL with C++ flags: ${CPPFLAGS} ${CXXFLAGS}"
  make -j4

  if [ $# -eq 0 ]; then
    # No argument passed: installing in the system.
    echo "Installing OpenSSL in the system"
    sudo make install
  else
    # Argument passed: installing in a custom location.
    echo "Installing OpenSSL in $1"
    make install
  fi
}

git clone ${GIT_URL} ${EXTRACT_DIR} -b ${LIB_VER}
cd ${EXTRACT_DIR}
build_and_install ${INSTALL_DIR}
sudo echo '${LIB_VER}' | sudo tee -a ${INSTALL_DIR}/VERSION

if [ -x "$(command -v qibuild)" ]; then
  echo "------------ Building qitoolchain package ----------------"
  sudo qitoolchain make-package --auto --name ${NAME} --version ${LIB_VER} --target linux64 ${INSTALL_DIR} --output ${WORKSPACE_PATH}
else
  echo "Qibuild is not installed, skipping packaging"
fi

# install on the system for the next tasks
build_and_install
cd ..
sudo rm -rf ${EXTRACT_DIR}
