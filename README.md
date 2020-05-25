# JC Packages

![jc](https://github.com/kellyjonbrazil/jc-packaging/raw/master/images/jc-dig.png)

`jc` is a command line tool that will JSONify the output of dozens of commands and file types. For more information, please see the project on [GitHub](https://github.com/kellyjonbrazil/jc).

## Installing JC
There are several ways to get `jc`. You can install via `pip`, `zypper`,  `brew`, DEB or RPM packages, or by downloading the correct binary for your architecture and running it anywhere on your filesystem.

### Pip (macOS, linux, unix, Windows)
For the most up-to-date version and the most cross-platform option, use `pip` or `pip3` to download and install `jc` directly from [PyPi](https://pypi.org/project/jc/)

![Pypi](https://img.shields.io/pypi/v/jc.svg)


```
$ pip3 install --upgrade jc
```

### Zypper (openSUSE linux)
Zypper packages are built from PyPi. These packages may not always be on the very latect `jc` version, but are regularly updated. You may run into a conflict if you try to install via `pip` and `zypper` on the same system simultaneously.
```
# zypper install jc
```

### Brew (macOS)
Homebrew packages are built from PyPi. These packages may not always be on the very latect `jc` version, but are regularly updated. You may run into a conflict if you try to install via `pip` and `brew` on the same system simultaneously.
```
$ brew install jc
```

### Packages
DEB and RPM packages are built from PyPi. These packages may not always be on the very latest `jc` version, but are regularly updated.

#### DEB (Debian, Ubuntu)

| Version   | File                                                                                             | SHA256 Hash                                                       |
|-----------|--------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.11.1    | [jc-1.11.1-1.x86_64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.11.1-1.x86_64.deb)  | 40a7e495ad38affdc27eb3e04970fdf3273a21b1ef9244978acaee2b77c508a7  |
| 1.10.5    | [jc-1.10.5-1.x86_64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.10.5-1.x86_64.deb)  | aa37a78cbe00e01a3f20aa68b99ef23101586968646cdc2d177b32aedc9d560d  |


#### RPM (Fedora, RHEL, CentOS)

| Version   | File                                                                                             | SHA256 Hash                                                       |
|-----------|--------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.11.1    | [jc-1.11.1-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.11.1-1.x86_64.rpm)  | c55d3d40cced6c64d8f906e26eac06ebd03a87c8adcb6d5f8b223b3844c97753  |
| 1.10.5    | [jc-1.10.5-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.10.5-1.x86_64.rpm)  | fd31f3be61e07aa277d1c0921ce46efd19a4ab2b211718bca377e6ff35b968c0  |


### Binaries
#### Linux (Fedora, RHEL, CentOS, Debian, Ubuntu)

| Version   | File                                                                                                 | SHA256 Hash (binary file)                                         |
|-----------|------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.11.1    | [jc-1.11.1-linux.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.11.1-linux.tar.gz)  | bf9e0f5865a415a1e2be11a2c36be29af0dfaa04c3630f98761eb9779b0b5c28  |
| 1.10.5    | [jc-1.10.5-linux.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.10.5-linux.tar.gz)  | 255eb9549ae90b2f96b316e29100208c466844cb13cbe9659770c6176fa4a502  |


#### macOS (Mojave and higher)

| Version   | File                                                                                                   | SHA256 Hash (binary file)                                         |
|-----------|--------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.11.1    | [jc-1.11.1-darwin.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.11.1-darwin.tar.gz)  | 6447306cb6900912073e01b047d05698e31332ddc560ba6a5ca2b20ea034a624  |
| 1.10.5    | [jc-1.10.5-darwin.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.10.5-darwin.tar.gz)  | e58c68cb7483049de686d9db623b19d24ff1c81bcfb00af64bd54652fcbb02f9  |
