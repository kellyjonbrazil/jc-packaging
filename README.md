# JC Packages

![jc](https://github.com/kellyjonbrazil/jc-packaging/raw/master/images/jc-dig.png)

`jc` JSONifies the output of dozens of commands and file-types. For more information, please see the project on [GitHub](https://github.com/kellyjonbrazil/jc).

## Installing JC
There are several ways to get `jc`. You can install via `pip`, `zypper`, `nix-env`, `brew`, `portsnap`, DEB or RPM packages, or by downloading the correct binary for your architecture and running it anywhere on your filesystem.

### Pip (macOS, linux, unix, Windows)
For the most up-to-date version and the most cross-platform option, use `pip` or `pip3` to download and install `jc` directly from [PyPi](https://pypi.org/project/jc/)

![Pypi](https://img.shields.io/pypi/v/jc.svg)


```
$ pip3 install --upgrade jc
```

### OS Package Repositories

#### Zypper (openSUSE linux)
Zypper packages are built from github. These packages may not always be on the very latect `jc` version, but are regularly updated.
```
# zypper install jc
```

#### nix-env (NixOS linux)
NixOS packages are built from github. These packages may not always be on the very latect `jc` version, but are regularly updated.
```
$ nix-env -iA nixpkgs.jc
```

#### Brew (macOS)
Homebrew packages are built from PyPi. These packages may not always be on the very latect `jc` version, but are regularly updated.
```
$ brew install jc
```

#### Ports (FreeBSD)
Ports packages are built from PyPi. These packages may not always be on the very latect `jc` version, but are regularly updated.
```
# portsnap fetch update && cd /usr/ports/textproc/py-jc && make install clean
```

### Packages
DEB and RPM packages are built from PyPi. These packages may not always be on the very latest `jc` version, but are regularly updated.

#### DEB (Debian, Ubuntu)

| Version   | File                                                                                             | SHA256 Hash                                                       |
|-----------|--------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.11.2    | [jc-1.11.2-1.x86_64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.11.2-1.x86_64.deb)  | 284de328e5cdcf65e119c77300ba34ca6551d1830812abfe615f9f0057458e5c  |
| 1.11.1    | [jc-1.11.1-1.x86_64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.11.1-1.x86_64.deb)  | 40a7e495ad38affdc27eb3e04970fdf3273a21b1ef9244978acaee2b77c508a7  |
| 1.10.5    | [jc-1.10.5-1.x86_64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.10.5-1.x86_64.deb)  | aa37a78cbe00e01a3f20aa68b99ef23101586968646cdc2d177b32aedc9d560d  |


#### RPM (Fedora, RHEL, CentOS)

| Version   | File                                                                                             | SHA256 Hash                                                       |
|-----------|--------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.11.2    | [jc-1.11.2-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.11.2-1.x86_64.rpm)  | 1b23d18f03d4f1086c0468d9064b5e45ae1dc7319df376ecec4e792da4cd8b93  |
| 1.11.1    | [jc-1.11.1-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.11.1-1.x86_64.rpm)  | c55d3d40cced6c64d8f906e26eac06ebd03a87c8adcb6d5f8b223b3844c97753  |
| 1.10.5    | [jc-1.10.5-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.10.5-1.x86_64.rpm)  | fd31f3be61e07aa277d1c0921ce46efd19a4ab2b211718bca377e6ff35b968c0  |


### Binaries
Linux and macOS binaries are built from PyPi and can be copied to any location in your path and run. These binaries may not always be on the very latest `jc` version, but are regularly updated.

#### Linux (Fedora, RHEL, CentOS, Debian, Ubuntu)

| Version   | File                                                                                                 | SHA256 Hash (binary file)                                         |
|-----------|------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.11.2    | [jc-1.11.2-linux.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.11.2-linux.tar.gz)  | 2a2faee2eea4ce0a6d10069cd95932bbc5ae4b70c6dc913502edbfe39a3f759f  |
| 1.11.1    | [jc-1.11.1-linux.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.11.1-linux.tar.gz)  | bf9e0f5865a415a1e2be11a2c36be29af0dfaa04c3630f98761eb9779b0b5c28  |
| 1.10.5    | [jc-1.10.5-linux.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.10.5-linux.tar.gz)  | 255eb9549ae90b2f96b316e29100208c466844cb13cbe9659770c6176fa4a502  |


#### macOS (Mojave and higher)

| Version   | File                                                                                                   | SHA256 Hash (binary file)                                         |
|-----------|--------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.11.2    | [jc-1.11.2-darwin.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.11.2-darwin.tar.gz)  | d89ab43151dbfbf4befad61505fa64b93c4b2fe2b4cd3250c7f0a3507e2d41a4  |
| 1.11.1    | [jc-1.11.1-darwin.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.11.1-darwin.tar.gz)  | 6447306cb6900912073e01b047d05698e31332ddc560ba6a5ca2b20ea034a624  |
| 1.10.5    | [jc-1.10.5-darwin.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.10.5-darwin.tar.gz)  | e58c68cb7483049de686d9db623b19d24ff1c81bcfb00af64bd54652fcbb02f9  |
