#!/bin/bash

export LIB_VER=${LIB_VER:-"3.4.0"}
export NAME="eigen"
export EXTRACT_DIR="/tmp/${NAME}"
export INSTALL_DIR="/tmp/build/${NAME}"
export GIT_URL="https://gitlab.com/libeigen/eigen.git"

function build_and_install()
{
  mkdir build
  cd build

  if [ $# -eq 0 ]; then
    cmake ..
  else
    cmake -DCMAKE_INSTALL_PREFIX=$1 ..
  fi
  make -j4

  if [ $# -eq 0 ]; then
    # No argument passed: installing in the system.
    echo "Installing Eigen3 in the system"
    sudo make install
  else
    # Argument passed: installing in a custom location.
    echo "Installing Eigen3 in $1"
    make install
  fi

  cd ..
  sudo rm -rf build
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
