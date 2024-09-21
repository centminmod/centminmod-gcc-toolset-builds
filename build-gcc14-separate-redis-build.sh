#!/bin/bash

set -e

# Set variables
GCC_VERSION="14.2.1"
GDB_VERSION="15.1"
ANNOBIN_VERSION="12.70"
GCC_SRC_TAR="gcc-${GCC_VERSION}.tar.gz"
GDB_SRC_TAR="gdb-${GDB_VERSION}.tar.xz"
ANNOBIN_SRC_TAR="annobin-${ANNOBIN_VERSION}.tar.xz"
BUILD_DIR="$HOME/rpmbuild"
PREFIX="/opt/gcc-custom/gcc14"
USER_NAME="George Liu"
USER_EMAIL="centminmod.com"
RELEASE="1"
ARCH=$(uname -m)
DISTTAG=""
CRB_REPO=""
PYTHON_DEVEL=""

# Determine DISTTAG based on OS release
if grep -q "release 8" /etc/redhat-release; then
    DISTTAG='el8'
    CRB_REPO="powertools"
    PYTHON_DEVEL='python3-devel'
elif grep -q "release 9" /etc/redhat-release; then
    DISTTAG='el9'
    CRB_REPO="crb"
    PYTHON_DEVEL='python3-devel'
else
    echo "Unsupported OS version."
    exit 1
fi

# Enable necessary repositories: CRB or PowerTools, and EPEL
dnf clean all
dnf install -y epel-release
dnf config-manager --set-enabled ${CRB_REPO}

# Install build dependencies
dnf groupinstall -y "Development Tools"
dnf install --allowerasing -y \
  binutils \
  debugedit \
  rpm-build \
  gmp-devel \
  mpfr-devel \
  libmpc-devel \
  zlib-devel \
  isl-devel \
  texinfo \
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
  libtool \
  pkgconfig \
  ccache \
  gcc-toolset-13-annobin-annocheck \
  gcc-toolset-13-annobin-docs.noarch \
  gcc-toolset-13-annobin-plugin-gcc \
  gcc-toolset-13-binutils \
  gcc-toolset-13-binutils-devel \
  gcc-toolset-13-dwz \
  gcc-toolset-13-gcc \
  gcc-toolset-13-gcc-c++ \
  gcc-toolset-13-gcc-gfortran \
  gcc-toolset-13-gdb \
  gcc-toolset-13-libasan-devel \
  gcc-toolset-13-libatomic-devel \
  gcc-toolset-13-libgccjit \
  gcc-toolset-13-libgccjit-devel \
  gcc-toolset-13-libgccjit-docs \
  gcc-toolset-13-libitm-devel \
  gcc-toolset-13-liblsan-devel \
  gcc-toolset-13-libquadmath-devel \
  gcc-toolset-13-libstdc++-devel \
  gcc-toolset-13-libtsan-devel \
  gcc-toolset-13-libubsan-devel \
  gcc-toolset-13-runtime \
  expat-devel \
  ncurses-devel \
  elfutils-devel \
  elfutils-libelf-devel \
  libdwarf-devel \
  texlive-latex-bin-bin \
  texlive-makeindex-bin \
  rpm-devel \
  gettext-devel \
  ${PYTHON_DEVEL} --skip-broken

# Create RPM build directories
mkdir -p ${BUILD_DIR}/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
mkdir -p /home/gcc-toolset-build

# Download GCC source tarball if not already available
if [ ! -f ${BUILD_DIR}/SOURCES/${GCC_SRC_TAR} ]; then
  #wget "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/${GCC_SRC_TAR}" -O ${BUILD_DIR}/SOURCES/${GCC_SRC_TAR}
  wget "https://github.com/gcc-mirror/gcc/archive/refs/heads/releases/gcc-14.tar.gz" -O ${BUILD_DIR}/SOURCES/${GCC_SRC_TAR}
fi

# Download GDB source tarball if not already available
if [ ! -f ${BUILD_DIR}/SOURCES/${GDB_SRC_TAR} ]; then
  wget "https://ftp.gnu.org/gnu/gdb/${GDB_SRC_TAR}" -O ${BUILD_DIR}/SOURCES/${GDB_SRC_TAR}
fi

# Download annobin source tarball if not already available
if [ ! -f ${BUILD_DIR}/SOURCES/${ANNOBIN_SRC_TAR} ]; then
  wget "https://nickc.fedorapeople.org/${ANNOBIN_SRC_TAR}" -O ${BUILD_DIR}/SOURCES/${ANNOBIN_SRC_TAR}
fi

# Copy patches to SOURCES directory
ls -lah /workspace/patches
cp /workspace/patches/0001-Always-use-z-now-when-linking-with-pie.patch ${BUILD_DIR}/SOURCES/
cp /workspace/patches/optimize.patch ${BUILD_DIR}/SOURCES/
cp /workspace/patches/vectorize.patch ${BUILD_DIR}/SOURCES/
cp /workspace/patches/compilespeed.patch ${BUILD_DIR}/SOURCES/

# Create spec file for GCC 14 with custom prefix
cat << 'EOF' > ${BUILD_DIR}/SPECS/gcc-custom.spec
%global gcc_version 14.2.1
%global gdb_version 15.1
%global annobin_version 12.70
%global gcc_custom_prefix /opt/gcc-custom/gcc14

Name:           gcc-custom
Version:        %{gcc_version}
Release:        1%{?dist}
Summary:        GCC %{gcc_version} with custom installation path

License:        GPLv3+
URL:            https://gcc.gnu.org
Source0:        gcc-%{gcc_version}.tar.gz
Source1:        gdb-%{gdb_version}.tar.xz
Source2:        annobin-%{annobin_version}.tar.xz

Patch0:         optimize.patch
Patch1:         0001-Always-use-z-now-when-linking-with-pie.patch
Patch2:         vectorize.patch
Patch3:         compilespeed.patch

BuildRequires:  glibc-devel
BuildRequires:  gmp-devel
BuildRequires:  mpfr-devel
BuildRequires:  libmpc-devel
BuildRequires:  zlib-devel
BuildRequires:  isl-devel
BuildRequires:  texinfo
BuildRequires:  libtool
BuildRequires:  flex
BuildRequires:  bison
BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  debugedit
BuildRequires:  ccache
BuildRequires:  expat-devel
BuildRequires:  ncurses-devel
BuildRequires:  python3-devel

%description
GCC (GNU Compiler Collection) is a compiler system produced by the GNU Project supporting various programming languages. This package installs GCC %{gcc_version} in a custom directory.

%package core
Summary:        Core GCC files
Requires:       %{name}-libs = %{version}-%{release}

%description core
This package contains the core GCC files.

%package c++
Summary:        C++ support for GCC
Requires:       %{name}-core = %{version}-%{release}

%description c++
This package adds C++ support to the GNU Compiler Collection.

%package libs
Summary:        GCC runtime libraries

%description libs
This package contains GCC shared libraries for gcc %{version}.

%package devel
Summary:        GCC development files
Requires:       %{name}-core = %{version}-%{release}

%description devel
This package includes the GCC header files, static libraries, and other development files.

%package doc
Summary:        GCC documentation
BuildArch:      noarch

%description doc
This package contains documentation for GCC.

%package gdb
Summary:        GNU Debugger for GCC %{gcc_version}
Requires:       %{name}-core = %{version}-%{release}

%description gdb
GDB, the GNU Project debugger, allows you to see what is going on inside a program while it executes or what the program was doing at the moment it crashed.

%package annobin
Summary:        Annobin plugin for GCC %{gcc_version}
Requires:       %{name}-core = %{version}-%{release}

%description annobin
Annobin is a GCC plugin that records information about how binaries are built.

%prep
rm -rf %{_builddir}/*
%setup -q -n gcc-releases-gcc-14
%patch0 -p1
%patch1 -p1
%patch2 -p1
%patch3 -p1

# Extract GDB source
tar -xf %{SOURCE1}
# Extract annobin source
tar -xf %{SOURCE2}

%build
# Build GCC
mkdir -p build-gcc
cd build-gcc

# Set up ccache
mkdir -p /ccache
export CCACHE_DIR=/ccache
export CCACHE_COMPILERCHECK=content
export CCACHE_SLOPPINESS=time_macros
export CCACHE_MAXSIZE=10G

# Set common compiler flags
%if 0%{?rhel} == 8
CFLAGS_COMMON="-g -gdwarf-4 -O2 -Wno-maybe-uninitialized -Wno-free-nonheap-object -Wno-alloc-size-larger-than -Wno-pedantic -Wno-parentheses"
%else
CFLAGS_COMMON="-g -O2 -Wno-maybe-uninitialized -Wno-free-nonheap-object -Wno-alloc-size-larger-than -Wno-pedantic -Wno-parentheses"
%endif

# Set flags for different stages
export CC='ccache gcc'
export CXX='ccache g++'
CFLAGS="\$CFLAGS_COMMON"
CXXFLAGS="\$CFLAGS_COMMON"
BOOT_CFLAGS="\$CFLAGS_COMMON"
BOOT_CXXFLAGS="\$CFLAGS_COMMON"
CFLAGS_FOR_TARGET="\$CFLAGS_COMMON"
CXXFLAGS_FOR_TARGET="\$CFLAGS_COMMON"
STAGE1_CFLAGS="\$CFLAGS_COMMON"
STAGE1_CXXFLAGS="\$CFLAGS_COMMON"

# Export LD to use ld.gold
# export LD=/usr/bin/ld.gold
# Configure GCC
../configure \
    CFLAGS="\$CFLAGS" \
    CXXFLAGS="\$CXXFLAGS" \
    BOOT_CFLAGS="\$BOOT_CFLAGS" \
    BOOT_CXXFLAGS="\$BOOT_CXXFLAGS" \
    CFLAGS_FOR_TARGET="\$CFLAGS_FOR_TARGET" \
    CXXFLAGS_FOR_TARGET="\$CXXFLAGS_FOR_TARGET" \
    STAGE1_CFLAGS="\$STAGE1_CFLAGS" \
    STAGE1_CXXFLAGS="\$STAGE1_CXXFLAGS" \
  --prefix=%{gcc_custom_prefix} \
  --mandir=%{gcc_custom_prefix}/share/man \
  --infodir=%{gcc_custom_prefix}/share/info \
  --enable-bootstrap \
  --enable-languages=c,c++,lto \
  --enable-shared \
  --enable-threads=posix \
  --enable-checking=release \
  --disable-multilib \
  --with-system-zlib \
  --enable-__cxa_atexit \
  --disable-libunwind-exceptions \
  --enable-gnu-unique-object \
  --enable-linker-build-id \
  --with-gcc-major-version-only \
  --enable-libstdcxx-backtrace \
  --with-libstdcxx-zoneinfo=/usr/share/zoneinfo \
  --with-linker-hash-style=gnu \
  --enable-plugin \
  --enable-initfini-array \
  --without-isl \
  --enable-offload-targets=nvptx-none \
  --without-cuda-driver \
  --enable-offload-defaulted \
  --enable-gnu-indirect-function \
  --enable-cet \
  --with-tune=generic \
  --with-arch_64=x86-64-v2 \
  --with-arch_32=x86-64 \
  --build=x86_64-redhat-linux \
  --with-build-config=bootstrap-lto \
  --enable-link-serialization=1

# Output config.log
echo "=============== CONFIG.LOG ==============="
cat config.log
echo "=========== END OF CONFIG.LOG ============"

# Output Makefile
echo "=============== MAKEFILE ==============="
cat Makefile
echo "=========== END OF MAKEFILE ============"

# Output environment variables
echo "=============== BUILD ENVIRONMENT ==============="
env
echo "=========== END OF BUILD ENVIRONMENT ============"

make %{?_smp_mflags}
cd ..

# Build GDB
cd gdb-%{gdb_version}
mkdir -p build-gdb
cd build-gdb
../configure --prefix=%{gcc_custom_prefix}
make %{?_smp_mflags}
cd ../..

# Build annobin
cd annobin-%{annobin_version}
./configure --prefix=%{gcc_custom_prefix} --with-gcc-plugin-dir=%{gcc_custom_prefix}/lib/gcc/x86_64-redhat-linux/%{gcc_version}/plugin
make %{?_smp_mflags}
cd ..

%install
mkdir -p %{buildroot}${PREFIX}
cd build-gcc
make install DESTDIR=%{buildroot}
cd ..

# Install GDB
cd gdb-%{gdb_version}/build-gdb
make install DESTDIR=%{buildroot}
cd ../..

# Install annobin
cd annobin-%{annobin_version}
make install DESTDIR=%{buildroot}
cd ..

# Add enablement script
mkdir -p %{buildroot}%{gcc_custom_prefix}
cat << EOL > %{buildroot}%{gcc_custom_prefix}/enable
export PATH=%{gcc_custom_prefix}/bin:\$PATH
export LD_LIBRARY_PATH=%{gcc_custom_prefix}/lib64:\$LD_LIBRARY_PATH
export MANPATH=%{gcc_custom_prefix}/share/man:\$MANPATH
EOL

%clean
rm -rf %{buildroot}

%files core
%{gcc_custom_prefix}/enable
%{gcc_custom_prefix}/bin/gcc
%{gcc_custom_prefix}/bin/gcov
%{gcc_custom_prefix}/bin/gcc-ar
%{gcc_custom_prefix}/bin/gcc-nm
%{gcc_custom_prefix}/bin/gcc-ranlib
%{gcc_custom_prefix}/bin/lto-dump
%{gcc_custom_prefix}/libexec/gcc
%{gcc_custom_prefix}/lib/gcc
%{gcc_custom_prefix}/share/man/man1/gcc.1*
%{gcc_custom_prefix}/share/man/man1/gcov.1*

%files c++
%{gcc_custom_prefix}/bin/g++
%{gcc_custom_prefix}/bin/c++
%{gcc_custom_prefix}/include/c++
%{gcc_custom_prefix}/lib/gcc/*/*/cc1plus
%{gcc_custom_prefix}/share/man/man1/g++.1*

%files libs
%{gcc_custom_prefix}/lib64/libgcc_s.so.*
%{gcc_custom_prefix}/lib64/libstdc++.so.*
%{gcc_custom_prefix}/lib64/libgomp.so.*

%files devel
%{gcc_custom_prefix}/bin/cpp
%{gcc_custom_prefix}/include
%{gcc_custom_prefix}/lib/gcc/*/*/include
%{gcc_custom_prefix}/lib64/*.so
%{gcc_custom_prefix}/lib64/*.a

%files doc
%{gcc_custom_prefix}/share/info
%{gcc_custom_prefix}/share/man
%exclude %{gcc_custom_prefix}/share/man/man1/gcc.1*
%exclude %{gcc_custom_prefix}/share/man/man1/g++.1*
%exclude %{gcc_custom_prefix}/share/man/man1/gcov.1*

%files gdb
%{gcc_custom_prefix}/bin/gdb
%{gcc_custom_prefix}/share/man/man1/gdb.1*

%files annobin
%{gcc_custom_prefix}/bin/annocheck
%{gcc_custom_prefix}/lib/gcc/*/*/plugin/annobin.so

%changelog
EOF

# Add a custom changelog entry dynamically to the spec file
DATE=$(date +"%a %b %d %Y")
CHANGELOG_ENTRY="* ${DATE} ${USER_NAME} <${USER_EMAIL}> - ${GCC_VERSION}-1\n- Custom build for ${DISTTAG}\n"

if grep -q "^%changelog" ${BUILD_DIR}/SPECS/gcc-custom.spec; then
    sed -i "/^%changelog/a ${CHANGELOG_ENTRY}" ${BUILD_DIR}/SPECS/gcc-custom.spec
else
    echo -e "\n%changelog\n${CHANGELOG_ENTRY}" >> ${BUILD_DIR}/SPECS/gcc-custom.spec
fi

# Display the spec file to verify changelog was added
echo
cat ${BUILD_DIR}/SPECS/gcc-custom.spec
echo

# Build the RPM using rpmbuild
rm -rf ${BUILD_DIR}/{BUILD,BUILDROOT}/*
source /opt/rh/gcc-toolset-13/enable
export QA_RPATHS=$((0x0020))
mkdir -p /workspace
time rpmbuild -ba ${BUILD_DIR}/SPECS/gcc-custom.spec \
    --define "dist .${DISTTAG}" \
    --define "_buildhost host_${DISTTAG}" \
    2>&1 | tee "/workspace/build_gcc_toolset_$(date +"%d%m%y-%H%M%S").log"

# Move the built RPMs and SRPMs to the workspace for GitHub Actions
mkdir -p /workspace/rpms
cp ${BUILD_DIR}/RPMS/${ARCH}/*.rpm /workspace/rpms/ || echo "No RPM files found in ${BUILD_DIR}/RPMS/${ARCH}/"
cp ${BUILD_DIR}/SRPMS/*.rpm /workspace/rpms/ || echo "No SRPM files found in ${BUILD_DIR}/SRPMS/"

# Verify the copied files
ls -lah /workspace/rpms/
