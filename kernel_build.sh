#!/bin/bash
set -e

# =====================================================
# NOTE :
#  This script will be run in a temporary build dir
#  $1 is the original dir on the caller script (davos_build.sh)
# =====================================================

pushd $1

# Set kernel version if not set by command line arguments
if [ "$#" -le 1 ]; then
    kernel_version="4.19"
    kernel_base_url="https://cdn.kernel.org/pub/linux/kernel/v4.x"
else
    kernel_version="$2"
    kernel_base_url="$3"
fi

# =============================================================
# Don't edit anything below these lines
# =============================================================

file_name=linux-${kernel_version}.tar.xz
full_url=${kernel_base_url}/${file_name}
davos_src="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

if [[ -f /tmp/downloads/${file_name} ]]; then
    echo "Copying ${file_name} from /tmp/downloads"
    cp /tmp/downloads/${file_name} .
else
    echo "Downloading Kernel from ${full_url}"
    curl -O ${full_url}
fi

# Sometimes we get html instead of real file
if [[ ! -f "${file_name}" ||  $(stat -c%s "${file_name}") -lt 1048576 ]]; then
  echo "Failed to download the right file, check URLs"
  exit 1
fi

# Extract kernel sources
tar xJf ${file_name}
cd linux-${kernel_version}
cp ${davos_src}/kernel-config .config

# Install needed tools
apt -y install make gcc libc6-dev ncurses-dev bison flex libelf-dev libssl-dev

# Build the kernel
echo "Building kernel..."
make olddefconfig
make && make modules

# Copy built kernel and modules to kernel_build
mkdir ../kernel_build
cp arch/x86/boot/bzImage ../kernel_build/bzImage64
make INSTALL_MOD_PATH=../kernel_build/_modules modules_install


# Save config file as well as kernel source
cp .config ${davos_src}/kernel-config

if [[ ! -d "/tmp/downloads/" ]]; then
    mkdir -p /tmp/downloads/
fi

cp ../${file_name} /tmp/downloads/

popd
echo "Davos kernel built successfuly"
