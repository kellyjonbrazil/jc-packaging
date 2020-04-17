# JC Packages
`jc` is a command line tool to JSONify the output of dozens of commands and file types. For more information, please see the project on GitHub at https://github.com/kellyjonbrazil/jc

## Installing JC
There are several ways to get `jc`. You can install via pip, deb or rpm packages, or by downloading the correct binary for your architecture and running it anywhere on your filesystem.

### Pip (macOS, linux, unix, Windows)
For the most up-to-date version and the most cross-platform option, use `pip` or `pip3` to download and install `jc` directly from [PyPi](https://pypi.org/project/jc/)
```
$ pip3 install --upgrade jc
```

### Packages
DEB, RPM, and macOS PKG files are built from PyPi. These packages may not always be on the very latest `jc` version, but are regularly updated.

### DEB (Debian, Ubuntu)
```
$ curl -O https://jc-packages.s3-us-west-1.amazonaws.com/latest/jc.deb
$ sudo dpkg -i jc.deb
```

### RPM (Fedora, RHEL, CentOS)
```
$ curl -O https://jc-packages.s3-us-west-1.amazonaws.com/latest/jc.rpm
$ sudo rpm -i jc.rpm
```

### PKG (macOS)
Coming Soon!

### Binaries
#### Linux (Fedora, RHEL, CentOS, Debian, Ubuntu)
```
$ curl -O https://jc-packages.s3-us-west-1.amazonaws.com/bin/linux/latest/jc
```
#### macOS
Coming soon!
