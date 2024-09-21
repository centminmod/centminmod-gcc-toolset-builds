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
  gcc-toolset-13-runtime --skip-broken

# Create RPM build directories
mkdir -p ${BUILD_DIR}/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
mkdir -p /home/gcc-toolset-build

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

BuildRequires:  glibc-devel gmp-devel mpfr-devel libmpc-devel zlib-devel isl-devel texinfo libtool flex bison autoconf automake debugedit

%description
GCC (GNU Compiler Collection) is a compiler system produced by the GNU Project supporting various programming languages. This package installs GCC 15 in a custom directory.

%prep
rm -rf %{_builddir}/*
%setup -q -n gcc-master

%build
mkdir -p build
cd build

# Conditional setting of flags based on RHEL version
%if 0%{?rhel} == 8
CFLAGS_COMMON="-g -gdwarf-4 -O2 -fopt-info-vec-all=%{_builddir}/gcc-master/vec_report.txt -Wno-maybe-uninitialized -Wno-free-nonheap-object -Wno-alloc-size-larger-than -Wno-pedantic -Wno-parentheses"
%else
CFLAGS_COMMON="-g -O2 -fopt-info-vec-all=%{_builddir}/gcc-master/vec_report.txt -Wno-maybe-uninitialized -Wno-free-nonheap-object -Wno-alloc-size-larger-than -Wno-pedantic -Wno-parentheses"
%endif

# Set flags for different stages
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

../configure \
    CFLAGS="\$CFLAGS" \
    CXXFLAGS="\$CXXFLAGS" \
    BOOT_CFLAGS="\$BOOT_CFLAGS" \
    BOOT_CXXFLAGS="\$BOOT_CXXFLAGS" \
    CFLAGS_FOR_TARGET="\$CFLAGS_FOR_TARGET" \
    CXXFLAGS_FOR_TARGET="\$CXXFLAGS_FOR_TARGET" \
    STAGE1_CFLAGS="\$STAGE1_CFLAGS" \
    STAGE1_CXXFLAGS="\$STAGE1_CXXFLAGS" \
  --prefix=${PREFIX} \
  --mandir=${PREFIX}/share/man \
  --infodir=${PREFIX}/share/info \
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

%install
mkdir -p %{buildroot}${PREFIX}
cd build
make install DESTDIR=%{buildroot}

# Add enablement script
mkdir -p %{buildroot}${PREFIX}
cat << EOL > %{buildroot}${PREFIX}/enable
export PATH=${PREFIX}/bin:\$PATH
export LD_LIBRARY_PATH=${PREFIX}/lib64:\$LD_LIBRARY_PATH
export MANPATH=${PREFIX}/share/man:\$MANPATH
EOL

%post
python3 - <<EOF
import re
import os
import platform
import subprocess
from collections import defaultdict

def get_cpu_info():
    cpu_info = {}
    try:
        with open('/proc/cpuinfo', 'r') as f:
            for line in f:
                if ':' in line:
                    key, value = line.split(':', 1)
                    cpu_info[key.strip()] = value.strip()
    except:
        cpu_info['model name'] = platform.processor()
    return cpu_info

def get_cpu_flags():
    try:
        with open('/proc/cpuinfo', 'r') as f:
            for line in f:
                if line.startswith('flags'):
                    return line.split(':')[1].strip()
    except:
        return "Unable to retrieve CPU flags"

def get_gcc_version():
    try:
        return subprocess.check_output(['gcc', '--version']).decode().split('\n')[0]
    except:
        return "GCC version unknown"

def analyze_vec_info(input_file, output_file):
    vectorized = defaultdict(list)
    missed = defaultdict(list)
    notes = []
    
    with open(input_file, 'r') as file:
        for line in file:
            if 'vectorized' in line.lower():
                match = re.search(r'(?P<type>loop|function|statement) (?:at|in): (?P<location>.+)', line, re.IGNORECASE)
                if match:
                    vec_type = match.group('type').lower()
                    vectorized[vec_type].append(match.group('location').strip())
            elif 'not vectorized' in line.lower() or 'missed vectorization opportunity' in line.lower():
                match = re.search(r'(?P<type>loop|function|statement) (?:at|in): (?P<location>.+)', line, re.IGNORECASE)
                if match:
                    vec_type = match.group('type').lower()
                    missed[vec_type].append(match.group('location').strip())
            elif 'note:' in line.lower():
                notes.append(line.strip())
    
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    with open(output_file, 'w') as report:
        report.write("Vectorization Summary\n")
        report.write("=====================\n\n")
        
        # Add build environment information
        cpu_info = get_cpu_info()
        cpu_flags = get_cpu_flags()
        gcc_version = get_gcc_version()
        
        report.write("Build Environment:\n")
        report.write(f"CPU Model: {cpu_info.get('model name', 'Unknown')}\n")
        report.write(f"CPU Flags: {cpu_flags}\n")
        report.write(f"GCC Version: {gcc_version}\n")
        report.write(f"Compiler Flags: {os.environ.get('CFLAGS', 'Unknown')}\n\n")
        
        for vec_type in ['function', 'loop', 'statement']:
            report.write(f"Vectorized {vec_type}s:\n")
            for item in sorted(set(vectorized[vec_type])):
                report.write(f"- {item}\n")
            report.write(f"Total: {len(set(vectorized[vec_type]))}\n\n")
            
            report.write(f"Missed {vec_type} vectorization opportunities:\n")
            for item in sorted(set(missed[vec_type])):
                report.write(f"- {item}\n")
            report.write(f"Total: {len(set(missed[vec_type]))}\n\n")
        
        total_vectorized = sum(len(set(items)) for items in vectorized.values())
        total_missed = sum(len(set(items)) for items in missed.values())
        report.write(f"Overall Summary:\n")
        report.write(f"Total vectorized: {total_vectorized}\n")
        report.write(f"Total missed opportunities: {total_missed}\n\n")
        
        report.write("Vectorization Notes:\n")
        for note in notes[:20]:  # Limiting to first 20 notes to keep the report manageable
            report.write(f"- {note}\n")
        if len(notes) > 20:
            report.write(f"... and {len(notes) - 20} more notes\n")

input_file = '%{_builddir}/gcc-master/vec_report.txt'
output_file = '%{buildroot}%{_prefix}/vectorization_summary.txt'
analyze_vec_info(input_file, output_file)
EOF

%clean
rm -rf $RPM_BUILD_ROOT

%files
${PREFIX}
${PREFIX}/enable
EOF

# Add a custom changelog entry dynamically to the spec file
DATE=$(date +"%a %b %d %Y")
CHANGELOG_ENTRY="* ${DATE} ${USER_NAME} <${USER_EMAIL}> - ${GCC_VERSION}-1\n- Custom build for ${DISTTAG}\n"

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
rm -rf ${BUILD_DIR}/{BUILD,BUILDROOT}/*
source /opt/rh/gcc-toolset-13/enable
export QA_RPATHS=$((0x0020))
mkdir -p /workspace
time rpmbuild -ba ${BUILD_DIR}/SPECS/gcc-custom.spec --define "dist .${DISTTAG}" --define "_buildhost host_${DISTTAG}" 2>&1 | tee "/workspace/build_gcc_toolset_$(date +"%d%m%y-%H%M%S").log"

# Move the built RPMs and SRPMs to the workspace for GitHub Actions
mkdir -p /workspace/rpms
cp ${BUILD_DIR}/RPMS/x86_64/*.rpm /workspace/rpms/ || echo "No RPM files found in ${BUILD_DIR}/RPMS/x86_64/"
cp ${BUILD_DIR}/SRPMS/*.rpm /workspace/rpms/ || echo "No SRPM files found in ${BUILD_DIR}/SRPMS/"

# Verify the copied files
ls -lah /workspace/rpms/
