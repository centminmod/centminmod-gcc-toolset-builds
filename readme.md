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