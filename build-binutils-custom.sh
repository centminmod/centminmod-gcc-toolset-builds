#!/bin/bash

set -e

# Set variables
BINUTILS_VERSION="2.43"
BINUTILS_SRC_TAR="binutils-${BINUTILS_VERSION}.tar.gz"
BUILD_DIR="$HOME/rpmbuild"
PREFIX="/opt/binutils-custom"
USER_NAME="George Liu"
USER_EMAIL="centminmod.com"

# Determine DISTTAG based on input
DISTTAG=$1
if [ -z "$DISTTAG" ]; then
  echo "No DISTTAG provided. Exiting."
  exit 1
fi

# Enable necessary repositories: CRB or PowerTools, and EPEL
dnf clean all
dnf install -y epel-release
if [[ "$DISTTAG" == "el8" ]]; then
    dnf config-manager --set-enabled powertools
elif [[ "$DISTTAG" == "el9" ]]; then
    dnf config-manager --set-enabled crb
fi

# Install dependencies
dnf groupinstall -y "Development Tools"
dnf install --allowerasing -y \
  rpm-build \
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
  xz \
  xz-devel \
  libtool \
  pkgconfig \
  zlib-devel \
  libzstd-devel \
  elfutils-libelf \
  expat-devel \
  --skip-broken

# Create RPM build directories
mkdir -p ${BUILD_DIR}/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

# Download binutils source tarball if not already available
if [ ! -f ${BUILD_DIR}/SOURCES/${BINUTILS_SRC_TAR} ]; then
  wget "https://ftp.gnu.org/gnu/binutils/${BINUTILS_SRC_TAR}" -O ${BUILD_DIR}/SOURCES/${BINUTILS_SRC_TAR}
fi

# Create spec file for binutils with custom prefix
cat << EOF > ${BUILD_DIR}/SPECS/binutils-custom.spec
Name:           binutils-custom
Version:        ${BINUTILS_VERSION}
Release:        1%{?dist}
Summary:        Binutils ${BINUTILS_VERSION} at ${PREFIX} install path

License:        GPLv3+
URL:            https://www.gnu.org/software/binutils/
Source0:        ${BINUTILS_SRC_TAR}

BuildRequires:  gcc, make, texinfo, flex, bison, autoconf, automake, libtool, zlib-devel, libzstd-devel, elfutils-libelf, expat-devel

%description
The GNU Binutils are a collection of binary tools. This package installs binutils ${BINUTILS_VERSION} in a custom directory. With source /etc/profile.d/binutils-custom.sh activation support.

%prep
%setup -q -n binutils-%{version}

%build
./configure \
    --prefix=${PREFIX} \
    --mandir=${PREFIX}/share/man \
    --infodir=${PREFIX}/share/info \
    --enable-gold \
    --enable-plugins \
    --enable-ld=default \
    --enable-shared \
    --disable-multilib \
    --disable-werror \
    --with-system-zlib

make %{?_smp_mflags}

%install
make DESTDIR=%{buildroot} install

# Add enablement script
mkdir -p %{buildroot}/etc/profile.d
cat << EOL > %{buildroot}/etc/profile.d/binutils-custom.sh
export PATH=${PREFIX}/bin:\$PATH
export LD_LIBRARY_PATH=${PREFIX}/lib:\$LD_LIBRARY_PATH
export MANPATH=${PREFIX}/share/man:\$MANPATH
EOL

%clean
rm -rf %{buildroot}

%files
${PREFIX}
/etc/profile.d/binutils-custom.sh

%changelog
EOF

# Add a custom changelog entry dynamically to the spec file
DATE=$(date +"%a %b %d %Y")
CHANGELOG_ENTRY="* ${DATE} ${USER_NAME} <${USER_EMAIL}> - ${BINUTILS_VERSION}-1\n- Custom build for ${DISTTAG}\n- source /etc/profile.d/binutils-custom.sh activation support\n"

sed -i '/^%changelog/a '"${CHANGELOG_ENTRY}" ${BUILD_DIR}/SPECS/binutils-custom.spec

# Initialize the changelog section if not present
if ! grep -q "^%changelog" ${BUILD_DIR}/SPECS/binutils-custom.spec; then
    echo -e "\n%changelog\n${CHANGELOG_ENTRY}" >> ${BUILD_DIR}/SPECS/binutils-custom.spec
fi

# Display the spec file to verify changelog was added
echo
cat ${BUILD_DIR}/SPECS/binutils-custom.spec
echo

# Build the RPM using rpmbuild
rm -rf ${BUILD_DIR}/{BUILD,BUILDROOT}/*
mkdir -p /workspace
time rpmbuild -ba ${BUILD_DIR}/SPECS/binutils-custom.spec --define "dist .${DISTTAG}" --define "_buildhost host_${DISTTAG}" 2>&1 | tee "/workspace/build_binutils_$(date +"%d%m%y-%H%M%S").log"

# Move the built RPMs and SRPMs to the workspace for GitHub Actions
mkdir -p /workspace/rpms
cp ${BUILD_DIR}/RPMS/x86_64/*.rpm /workspace/rpms/ || echo "No RPM files found in ${BUILD_DIR}/RPMS/x86_64/"
cp ${BUILD_DIR}/SRPMS/*.rpm /workspace/rpms/ || echo "No SRPM files found in ${BUILD_DIR}/SRPMS/"

# Verify the copied files
ls -lah /workspace/rpms/
