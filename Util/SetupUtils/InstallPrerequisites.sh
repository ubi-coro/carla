#!/bin/bash

set -e

python_path_default='python3'
python_path=$python_path_default

options=$(\
    getopt \
    -o "pypath:" \
    --long "python-path:" \
    -n 'CarlaSetup.sh' -- "$@")

eval set -- "$options"
while true; do
    case "$1" in
        -pypath|--python-path)
            python_path=$2
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            ;;
    esac
done

# -- INSTALL PYTHON PACKAGES --
echo "Installing Python Packages..."
$python_path -m pip install --upgrade pip
$python_path -m pip install -r requirements.txt

# -- INSTALL CMAKE --
check_cmake_version() {
    CMAKE_VERSION="$($2 --version | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')"
    CMAKE_MINIMUM_VERSION=$1
    MAJOR="${CMAKE_VERSION%%.*}"
    REMAINDER="${CMAKE_VERSION#*.}"
    MINOR="${REMAINDER%.*}"
    REVISION="${REMAINDER#*.}"
    MINIMUM_MAJOR="${CMAKE_MINIMUM_VERSION%%.*}"
    MINIMUM_REMAINDER="${CMAKE_MINIMUM_VERSION#*.}"
    MINIMUM_MINOR="${MINIMUM_REMAINDER%.*}"

    if [ -z "$CMAKE_VERSION" ]; then
        false
    else
        if [ $MAJOR -gt $MINIMUM_MAJOR ] || ([ $MAJOR -eq $MINIMUM_MAJOR ] && ([ $MINOR -gt $MINIMUM_MINOR ] || [ $MINOR -eq $MINIMUM_MINOR ])); then
            true
        else
            false
        fi
    fi
}

CMAKE_MINIMUM_VERSION=3.28.0
CMAKE_PATH=/media/internal/nvme/jlurvig/opt
if (check_cmake_version $CMAKE_MINIMUM_VERSION cmake) || (check_cmake_version $CMAKE_MINIMUM_VERSION $CMAKE_PATH/cmake-3.28.3-linux-x86_64/bin/cmake); then
    echo "Found CMake $CMAKE_MINIMUM_VERSION"
else
    echo "Could not find CMake >=$CMAKE_MINIMUM_VERSION."
    echo "Installing CMake 3.28.3..."
    curl -L -O https://github.com/Kitware/CMake/releases/download/v3.28.3/cmake-3.28.3-linux-x86_64.tar.gz
    tar -xzf cmake-3.28.3-linux-x86_64.tar.gz -C $CMAKE_PATH
    if [[ ":$PATH:" != *":$CMAKE_PATH/cmake-3.28.3-linux-x86_64/bin:"* ]]; then
        echo -e '\n#CARLA CMake 3.28.3\nPATH=$CMAKE_PATH/cmake-3.28.3-linux-x86_64/bin:$PATH' >> ~/.bashrc
        export PATH=$CMAKE_PATH/cmake-3.28.3-linux-x86_64/bin:$PATH
    fi
    rm -rf cmake-3.28.3-linux-x86_64.tar.gz
    echo "Installed CMake 3.28.3."
fi
