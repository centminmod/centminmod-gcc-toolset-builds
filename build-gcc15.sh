#!/bin/bash

set -e

# Set variables
GCC_VERSION="15.0.0"
GCC_SRC_TAR="gcc-${GCC_VERSION}.tar.gz"
BUILD_DIR="$HOME/rpmbuild"
PREFIX="/opt/gcc-custom/gcc15"
USER_NAME="George Liu"
USER_EMAIL="centminmod.com"

# Determine DISTTAG based on OS release
if grep -q "release 8" /etc/redhat-release; then
    DISTTAG='el8'
    CRB_REPO="powertools"
elif grep -q "release 9" /etc/redhat-release; then
    DISTTAG='el9'
    CRB_REPO="crb"
fi

# Enable necessary repositories: CRB or PowerTools, and EPEL
dnf clean all
dnf install -y epel-release
dnf config-manager --set-enabled ${CRB_REPO}

# Install dependencies
dnf groupinstall -y "Development Tools"
dnf install --allowerasing -y \
  gmp-devel \
  mpfr-devel \
  libmpc-devel \
  zlib-devel \
  isl-devel \
  texinfo \
  libtool \
  flex \
  bison \
  autoconf \
  automake \
  gcc \
  make \
  cmake \
  wget \
  nano \
  jq \
  bc \
  tar \
  curl \
  openssl-devel \
  xz \
  xz-devel \
  binutils \
  libtool \
  pkgconfig

# Create RPM build directories
mkdir -p ${BUILD_DIR}/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

# Download GCC source tarball if not already available
if [ ! -f ${BUILD_DIR}/SOURCES/${GCC_SRC_TAR} ]; then
  #wget ftp://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/${GCC_SRC_TAR} -O ${BUILD_DIR}/SOURCES/${GCC_SRC_TAR}
  wget "https://github.com/gcc-mirror/gcc/archive/refs/heads/master.tar.gz" -O ${BUILD_DIR}/SOURCES/${GCC_SRC_TAR}
fi

# Create spec file for GCC 15 with custom prefix
cat << EOF > ${BUILD_DIR}/SPECS/gcc-custom.spec
Name:           gcc-custom
Version:        ${GCC_VERSION}
Release:        1%{?dist}
Summary:        GCC 15 with custom installation path

License:        GPLv3+
URL:            https://gcc.gnu.org
Source0:        ${GCC_SRC_TAR}

BuildRequires:  gmp-devel mpfr-devel libmpc-devel zlib-devel isl-devel texinfo libtool flex bison autoconf automake

%description
GCC (GNU Compiler Collection) is a compiler system produced by the GNU Project supporting various programming languages. This package installs GCC 15 in a custom directory.

%prep
%setup -q gcc-master

%build
mkdir -p build
cd build
../configure --prefix=${PREFIX} --enable-bootstrap --enable-languages=c,c++,fortran,lto --enable-shared --enable-threads=posix --enable-checking=release --enable-multilib --with-system-zlib --enable-__cxa_atexit --disable-libunwind-exceptions --enable-gnu-unique-object --enable-linker-build-id --with-gcc-major-version-only --enable-libstdcxx-backtrace --with-libstdcxx-zoneinfo=/usr/share/zoneinfo --with-linker-hash-style=gnu --enable-plugin --enable-initfini-array --without-isl --enable-offload-targets=nvptx-none --without-cuda-driver --enable-offload-defaulted --enable-gnu-indirect-function --enable-cet --with-tune=generic --with-arch_64=x86-64-v2 --with-arch_32=x86-64 --build=x86_64-redhat-linux --with-build-config=bootstrap-lto --enable-link-serialization=1
make -j$(nproc)

%install
mkdir -p %{buildroot}${PREFIX}
cd build
make install DESTDIR=%{buildroot}${PREFIX}

# Add enablement script
mkdir -p %{buildroot}/etc/profile.d
cat << EOL > %{buildroot}/etc/profile.d/gcc15-custom.sh
export PATH=${PREFIX}/bin:\$PATH
export LD_LIBRARY_PATH=${PREFIX}/lib64:\$LD_LIBRARY_PATH
export MANPATH=${PREFIX}/share/man:\$MANPATH
EOL

%files
${PREFIX}
/etc/profile.d/gcc15-custom.sh
EOF

# Add a custom changelog entry dynamically to the spec file
DATE=$(date +"%a %b %d %Y")
CHANGELOG_ENTRY="* ${DATE} ${USER_NAME} <${USER_EMAIL}> - ${GCC_VERSION}-1\n- Custom build for AlmaLinux ${DISTTAG}\n"

sed -i '/^%changelog/a '"${CHANGELOG_ENTRY}" ${BUILD_DIR}/SPECS/gcc-custom.spec

# Initialize the changelog section if not present
if ! grep -q "^%changelog" ${BUILD_DIR}/SPECS/gcc-custom.spec; then
    echo -e "\n%changelog\n${CHANGELOG_ENTRY}" >> ${BUILD_DIR}/SPECS/gcc-custom.spec
fi

# Display the spec file to verify changelog was added
echo
cat ${BUILD_DIR}/SPECS/gcc-custom.spec
echo

# Build the RPM using rpmbuild
rpmbuild -ba ${BUILD_DIR}/SPECS/gcc-custom.spec --define "dist .${DISTTAG}"

# Move the built RPMs and SRPMs to the workspace for GitHub Actions
mkdir -p /workspace/rpms
cp ${BUILD_DIR}/RPMS/x86_64/*.rpm /workspace/rpms/ || echo "No RPM files found in ${BUILD_DIR}/RPMS/x86_64/"
cp ${BUILD_DIR}/SRPMS/*.rpm /workspace/rpms/ || echo "No SRPM files found in ${BUILD_DIR}/SRPMS/"

# Verify the copied files
ls -lah /workspace/rpms/
