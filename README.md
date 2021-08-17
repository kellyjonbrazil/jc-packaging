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
| 1.16.1    | [jc_1.16.1-1_amd64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc_1.16.1-1_amd64.deb)    | c8159a569c32f503055b608ee72811246aab550a635551aa1d2f05859cd99862  |
| 1.16.0    | [jc_1.16.0-1_amd64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc_1.16.0-1_amd64.deb)    | 1dbf7b44c11ee97793128738ad714b693fa1f9ca6fc909fd53dc70f226fea835  |
| 1.15.4    | [jc_1.15.4-1_amd64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc_1.15.4-1_amd64.deb)    | 50081172a695a850905214368ee28e1a1c7e3333c812fce730e286ea328709ff  |
| 1.15.3    | [jc_1.15.3-1_amd64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc_1.15.3-1_amd64.deb)    | 33ddd1095daf490e0286610930cd76dc73ef608a86d0f67918096754a681aed3  |
| 1.15.2    | [jc-1.15.2-1.x86_64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.15.2-1.x86_64.deb)  | 1c486b9734bfe63ea90700a89a483f0d0c36cb9acd715a50a18d70a596336185  |
| 1.15.1    | [jc-1.15.1-1.x86_64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.15.1-1.x86_64.deb)  | edfeb6bb89627db7120faf2074d4372c465a9baca0c7dc78869a311a30003ef8  |
| 1.15.0    | [jc-1.15.0-2.x86_64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.15.0-2.x86_64.deb)  | 63705ef57074c6de48c12f16dcaf7199f678f6081f1b3226cc9f26985d0fed85  |

> Click [here](https://kellyjonbrazil.github.io/jc-packaging/package-archive) for older packages

#### RPM (Fedora, RHEL, CentOS)

| Version   | File                                                                                             | SHA256 Hash                                                       |
|-----------|--------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.16.1    | [jc-1.16.1-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.16.1-1.x86_64.rpm)  | a5a84651b7f16f5f64eaca75785f4c24569b2ec318ed6e1aae21a657c38f9380  |
| 1.16.0    | [jc-1.16.0-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.16.0-1.x86_64.rpm)  | e427405aebecc1011c0ed4a8bd477104c35fbdb9453bd671fbc870c428dd0248  |
| 1.15.4    | [jc-1.15.4-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.15.4-1.x86_64.rpm)  | 72cc20462db33f9025f008cc3c3ae409cc8f385e151c7d0cd9736b5098f58726  |
| 1.15.3    | [jc-1.15.3-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.15.3-1.x86_64.rpm)  | fad42d570dc73fe33a66c19f4a44dc86a092ed95e4b0c9fa7b42f0ed4ae08413  |
| 1.15.2    | [jc-1.15.2-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.15.2-1.x86_64.rpm)  | 5f2a4fffd2ac33eadf01581c1e1461cb5a0200ddab48b7d5850acac2eddcae6e  |
| 1.15.1    | [jc-1.15.1-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.15.1-1.x86_64.rpm)  | d133de69b8907b27147991e6fe6679cfb43da55c2e1ea3652d849c9a7ba422fd  |
| 1.15.0    | [jc-1.15.0-2.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.15.0-2.x86_64.rpm)  | c4011c673baf947f2e6658dafc6f21d266bc8105b7dcf5e2e6587746f8d29eac  |

> Click [here](https://kellyjonbrazil.github.io/jc-packaging/package-archive) for older packages

#### MSI (Windows 2016+)

| Version   | File                                                                             | SHA256 Hash                                                       |
|-----------|----------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.16.1    | [jc-1.16.1.msi](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.16.1.msi)    | 2f084c451ec05bb1e8e474a65f09db4417939e673f31f55c73522d3e3af30e28  |
| 1.16.0    | [jc-1.16.0.msi](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.16.0.msi)    | f1973e5aed3af3234a6b7070729c1487258af35867caf83112664053301d1324  |
| 1.15.4    | [jc-1.15.4.msi](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.15.4.msi)    | f3b3afeda0ee702f17d8706d684a41a56536ace1ec79da24880545338523c425  |

> Click [here](https://kellyjonbrazil.github.io/jc-packaging/package-archive) for older packages

### Binaries (x86_64)
Linux and macOS x86_64 binaries are built from PyPi and can be copied to any location in your path and run. These binaries may not always be on the very latest `jc` version, but are regularly updated.

#### Linux (Fedora, RHEL, CentOS, Debian, Ubuntu)

| Version   | File                                                                                                               | SHA256 Hash (binary file)                                         |
|-----------|--------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.16.1    | [jc-1.16.1-linux-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.16.1-linux-x86_64.tar.gz)  | 9e04245ad7f70b56a117a3e837776c2479cbfaa56f3ffc971174d8f171051654  |
| 1.16.0    | [jc-1.16.0-linux-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.16.0-linux-x86_64.tar.gz)  | 675c8592424b0c9c2470879e8ccff0e9714d35c129dc40894b59d298391f9d14  |
| 1.15.4    | [jc-1.15.4-linux-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.15.4-linux-x86_64.tar.gz)  | fb9e910d3f4d984340e65df240dbb1795ab8203778420d905b2d090f8e7c8ab6  |
| 1.15.3    | [jc-1.15.3-linux-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.15.3-linux-x86_64.tar.gz)  | 1977f94e30f402c2899df18b80880d1745e015eb87f793be104fa0430654b226  |
| 1.15.2    | [jc-1.15.2-linux-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.15.2-linux-x86_64.tar.gz)  | b7fa0e85a36a9805569d8d613e3b44a4ff4171d4417435eba4164393c5030e3b  |
| 1.15.1    | [jc-1.15.1-linux-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.15.1-linux-x86_64.tar.gz)  | f7636a6836a141d0ee85641b3fc3f7a9f94a3c8dee8739d13e67c39e34863785  |
| 1.15.0    | [jc-1.15.0-linux-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.15.0-linux-x86_64.tar.gz)  | 68ec9df75a740761067ac68c3b664bcb9f80e980e4f2fd8258184d7fd88e03b7  |

> Click [here](https://kellyjonbrazil.github.io/jc-packaging/package-archive) for older binaries

#### macOS (Mojave and higher)

| Version   | File                                                                                                                 | SHA256 Hash (binary file)                                         |
|-----------|----------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.16.1    | [jc-1.16.1-darwin-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.16.1-darwin-x86_64.tar.gz)  | abe288aa0fc44ccb42d33c4291e8d7f38676cf2d27486b5c34dd460aa6b89598  |
| 1.16.0    | [jc-1.16.0-darwin-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.16.0-darwin-x86_64.tar.gz)  | 0d296ded946734e96b0f3b2b8572fdfa3e3f823210ad2f8b6760a98efa647aea  |
| 1.15.4    | [jc-1.15.4-darwin-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.15.4-darwin-x86_64.tar.gz)  | 2afcbfe32ba217b4c2ae7e478e451939e58fa6eb9961878a4e060b48671f9cdf  |
| 1.15.3    | [jc-1.15.3-darwin-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.15.3-darwin-x86_64.tar.gz)  | 8154cffa8e3f274f800b87cf368105db48c655741f838bfe43579c336d52b63f  |
| 1.15.2    | [jc-1.15.2-darwin-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.15.2-darwin-x86_64.tar.gz)  | dc53641621f742f5a1dc65a9e0ddfb7f2006d87025bac83e1be0461066fceca0  |
| 1.15.1    | [jc-1.15.1-darwin-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.15.1-darwin-x86_64.tar.gz)  | 1f88f11dad5a77f5dbfe2a8e8baef61c6ebdfe3dd0f1ae86d9b58ea5647c1cd6  |
| 1.15.0    | [jc-1.15.0-darwin-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.15.0-darwin-x86_64.tar.gz)  | ea13a38fe73bdc15b971c7afdcd62c1cca1ef1429c189a6e284bf3a609933a5b  |

> Click [here](https://kellyjonbrazil.github.io/jc-packaging/package-archive) for older binaries
