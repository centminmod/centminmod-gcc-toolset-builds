![GitHub last commit (master)](https://img.shields.io/github/last-commit/centminmod/centminmod-gcc-toolset-builds/master) [![GitHub stars](https://img.shields.io/github/stars/centminmod/centminmod-gcc-toolset-builds.svg?style=flat-square)](https://github.com/centminmod/centminmod-gcc-toolset-builds/stargazers) [![GCC 15 RPM Build + Redis Benchmark Tests](https://github.com/centminmod/centminmod-gcc-toolset-builds/actions/workflows/build-gcc15-toolset-rpm-quick-redis-build-scheduled.yml/badge.svg)](https://github.com/centminmod/centminmod-gcc-toolset-builds/actions/workflows/build-gcc15-toolset-rpm-quick-redis-build-scheduled.yml)

EL9

```
rpm -qp -info gcc-custom-15.0.0-1.el9.x86_64.rpm
Name        : gcc-custom
Version     : 15.0.0
Release     : 1.el9
Architecture: x86_64
Install Date: (not installed)
Group       : Unspecified
Size        : 332572579
License     : GPLv3+
Signature   : (none)
Source RPM  : gcc-custom-15.0.0-1.el9.src.rpm
Build Date  : Wed Sep 18 07:48:20 2024
Build Host  : host_el9
URL         : https://gcc.gnu.org
Summary     : GCC 15 with custom installation path
Description :
GCC (GNU Compiler Collection) is a compiler system produced by the GNU Project supporting various programming languages. This package installs GCC 15 in a custom directory
```
```
rpm -qp -changelog gcc-custom-15.0.0-1.el9.x86_64.rpm
* Wed Sep 18 2024 George Liu <centminmod.com> - 15.0.0-1
- Custom build for AlmaLinux el9
```

EL8

```
rpm -qp -info gcc-custom-15.0.0-1.el8.x86_64.rpm
Name        : gcc-custom
Version     : 15.0.0
Release     : 1.el8
Architecture: x86_64
Install Date: (not installed)
Group       : Unspecified
Size        : 332914327
License     : GPLv3+
Signature   : (none)
Source RPM  : gcc-custom-15.0.0-1.el8.src.rpm
Build Date  : Thu 19 Sep 2024 12:00:19 AM UTC
Build Host  : host_el8
Relocations : (not relocatable)
URL         : https://gcc.gnu.org
Summary     : GCC 15 with custom installation path
Description :
GCC (GNU Compiler Collection) is a compiler system produced by the GNU Project supporting various programming languages. This package installs GCC 15 in a custom directory.
```
```
rpm -qp -changelog gcc-custom-15.0.0-1.el8.x86_64.rpm
* Wed Sep 18 2024 George Liu <centminmod.com> - 15.0.0-1
- Custom build for AlmaLinux el8
```