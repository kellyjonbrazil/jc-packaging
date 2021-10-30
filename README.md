# JC Packages

![jc](https://github.com/kellyjonbrazil/jc-packaging/raw/master/images/jc-dig.png)

> Try the `jc` [web demo](https://jc-web-demo.herokuapp.com/)

> JC is [now available](https://galaxy.ansible.com/community/general) as an Ansible filter plugin in the `community.general` Collection

`jc` JSONifies the output of dozens of commands and file-types. For more information, please see the project on [GitHub](https://github.com/kellyjonbrazil/jc).

Release notes can be found [here](https://blog.kellybrazil.com/category/jc-news/).

## Installing JC
There are several ways to get `jc`. You can install via `pip`, OS package repositories, DEB/RPM/MSI packaged binaries; or by downloading the correct binary for your architecture and running it anywhere on your filesystem.

### Pip (macOS, linux, unix, Windows)
For the most up-to-date version and the most cross-platform option, use `pip` or `pip3` to download and install `jc` directly from [PyPi](https://pypi.org/project/jc/):

![Pypi](https://img.shields.io/pypi/v/jc.svg)


```bash
pip3 install jc
```

### OS Package Repositories

| OS                    | Command                                                                       | 
|-----------------------|-------------------------------------------------------------------------------|
| Debian/Ubuntu linux   | `apt-get install jc`                                                          |
| Fedora linux          | `dnf install jc`                                                              |
| openSUSE linux        | `zypper install jc`                                                           |
| Arch linux            | `pacman -S jc`                                                                |
| NixOS linux           | `nix-env -iA nixpkgs.jc` or `nix-env -iA nixos.jc`                            |
| Guix System linux     | `guix install jc`                                                             |
| macOS                 | `brew install jc`                                                             |
| FreeBSD               | `portsnap fetch update && cd /usr/ports/textproc/py-jc && make install clean` |
| Ansible filter plugin | `ansible-galaxy collection install community.general`                         |

[![Packaging status](https://repology.org/badge/vertical-allrepos/jc.svg)](https://repology.org/project/jc/versions)

### Packaged Binaries
DEB, RPM, and MSI packages include the linux and Windows binaries built from PyPi. These packages may not always be on the very latest `jc` version, but are regularly updated.

Version 1.15.0 and above DEB and RPM packages include the `jc` binary and man page. Older versions do not include the man page.

#### DEB (Debian, Ubuntu)

| Version   | File                                                                                             | SHA256 Hash                                                       |
|-----------|--------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.17.1    | [jc_1.17.1-1_amd64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc_1.17.1-1_amd64.deb)    | 3d02e668aa460b3cf430e2d975f9e2f0c94a2456a4d525eedf033df2acddfeed  |
| 1.17.0    | [jc_1.17.0-1_amd64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc_1.17.0-1_amd64.deb)    | 2578d61ed6bdeb3cb6f2ed0ffc6df65478e906f49f32f89ef3804a965450d72b  |
| 1.16.1    | [jc_1.16.1-1_amd64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc_1.16.1-1_amd64.deb)    | c8159a569c32f503055b608ee72811246aab550a635551aa1d2f05859cd99862  |
| 1.16.0    | [jc_1.16.0-1_amd64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc_1.16.0-1_amd64.deb)    | 1dbf7b44c11ee97793128738ad714b693fa1f9ca6fc909fd53dc70f226fea835  |

> Click [here](https://kellyjonbrazil.github.io/jc-packaging/package-archive) for older packages

#### RPM (Fedora, RHEL, CentOS)

| Version   | File                                                                                             | SHA256 Hash                                                       |
|-----------|--------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.17.1    | [jc-1.17.1-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.17.1-1.x86_64.rpm)  | 88ffcbcab22706533120e48a5cea09a93e6ac7dcd255bebd9edb247a611ee8fa  |
| 1.17.0    | [jc-1.17.0-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.17.0-1.x86_64.rpm)  | 3d5df318f42083d9fb090a28de16d87ded9234c9f230efe48a403be36e9ae51c  |
| 1.16.1    | [jc-1.16.1-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.16.1-1.x86_64.rpm)  | a5a84651b7f16f5f64eaca75785f4c24569b2ec318ed6e1aae21a657c38f9380  |
| 1.16.0    | [jc-1.16.0-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.16.0-1.x86_64.rpm)  | e427405aebecc1011c0ed4a8bd477104c35fbdb9453bd671fbc870c428dd0248  |

> Click [here](https://kellyjonbrazil.github.io/jc-packaging/package-archive) for older packages

#### MSI (Windows 2016+)

| Version   | File                                                                             | SHA256 Hash                                                       |
|-----------|----------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.17.1    | [jc-1.17.1.msi](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.17.1.msi)    | 36a69cd8c603cb75beaabefa936d3fa9da4d22f6df92cbf365666cdc5ccd4f4b  |
| 1.17.0    | [jc-1.17.0.msi](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.17.0.msi)    | 2c3021f4d3e4d03ca1a74bccb3dd297ef70fce3899be07b446c0d10f5b6f654b  |
| 1.16.1    | [jc-1.16.1.msi](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.16.1.msi)    | 2f084c451ec05bb1e8e474a65f09db4417939e673f31f55c73522d3e3af30e28  |
| 1.16.0    | [jc-1.16.0.msi](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.16.0.msi)    | f1973e5aed3af3234a6b7070729c1487258af35867caf83112664053301d1324  |

> Click [here](https://kellyjonbrazil.github.io/jc-packaging/package-archive) for older packages

### Binaries (x86_64)
Linux and macOS x86_64 binaries are built from PyPi and can be copied to any location in your path and run. These binaries may not always be on the very latest `jc` version, but are regularly updated.

#### Linux (Fedora, RHEL, CentOS, Debian, Ubuntu)

| Version   | File                                                                                                               | SHA256 Hash (binary file)                                         |
|-----------|--------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.17.1    | [jc-1.17.1-linux-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.17.1-linux-x86_64.tar.gz)  | c467998e36f6026787276c0d7a3cd47f388f52f1b4c4fdecb2775a45e29ff446  |
| 1.17.0    | [jc-1.17.0-linux-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.17.0-linux-x86_64.tar.gz)  | 479e0a03e7e6656059016e54fa268499b3389dd5306c86535a3a92a864b71625  |
| 1.16.1    | [jc-1.16.1-linux-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.16.1-linux-x86_64.tar.gz)  | 9e04245ad7f70b56a117a3e837776c2479cbfaa56f3ffc971174d8f171051654  |
| 1.16.0    | [jc-1.16.0-linux-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.16.0-linux-x86_64.tar.gz)  | 675c8592424b0c9c2470879e8ccff0e9714d35c129dc40894b59d298391f9d14  |

> Click [here](https://kellyjonbrazil.github.io/jc-packaging/package-archive) for older binaries

#### macOS (Mojave and higher)

| Version   | File                                                                                                                 | SHA256 Hash (binary file)                                         |
|-----------|----------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.17.1    | [jc-1.17.1-darwin-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.17.1-darwin-x86_64.tar.gz)  | c467998e36f6026787276c0d7a3cd47f388f52f1b4c4fdecb2775a45e29ff446  |
| 1.17.0    | [jc-1.17.0-darwin-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.17.0-darwin-x86_64.tar.gz)  | 501f359ca483d4ac5cde3d69a69f5c3b061c44bc36428288d47843b3c6caa4a5  |
| 1.16.1    | [jc-1.16.1-darwin-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.16.1-darwin-x86_64.tar.gz)  | abe288aa0fc44ccb42d33c4291e8d7f38676cf2d27486b5c34dd460aa6b89598  |
| 1.16.0    | [jc-1.16.0-darwin-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.16.0-darwin-x86_64.tar.gz)  | 0d296ded946734e96b0f3b2b8572fdfa3e3f823210ad2f8b6760a98efa647aea  |

> Click [here](https://kellyjonbrazil.github.io/jc-packaging/package-archive) for older binaries
