# JC Packages

![jc](https://github.com/kellyjonbrazil/jc-packaging/raw/master/images/jc-dig.png)

> Try the new `jc` [web demo](https://jc-web-demo.herokuapp.com/)!

> JC is [now available](https://galaxy.ansible.com/community/general) as an Ansible filter plugin in the `community.general` Collection!

`jc` JSONifies the output of dozens of commands and file-types. For more information, please see the project on [GitHub](https://github.com/kellyjonbrazil/jc).

Release notes can be found [here](https://blog.kellybrazil.com/category/jc-news/).

## Installing JC
There are several ways to get `jc`. You can install via `pip`, `apt-get`, `dnf`, `zypper`, `pacman`, `nix-env`, `guix`, `brew`, `portsnap`, DEB or RPM packages, or by downloading the correct binary for your architecture and running it anywhere on your filesystem.

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
| NixOS linux           | `nix-env -iA nixpkgs.jc`                                                      |
| Guix System linux     | `guix install jc`                                                             |
| MacOS                 | `brew install jc`                                                             |
| FreeBSD               | `portsnap fetch update && cd /usr/ports/textproc/py-jc && make install clean` |
| Ansible filter plugin | `ansible-galaxy collection install community.general`                         |

### Packages
DEB and RPM packages are built from PyPi. These packages may not always be on the very latest `jc` version, but are regularly updated.

#### DEB (Debian, Ubuntu)

| Version   | File                                                                                             | SHA256 Hash                                                       |
|-----------|--------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.14.1    | [jc-1.14.1-1.x86_64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.14.1-1.x86_64.deb)  | ccc7c627dba2349cfd3e1f2d0527792309d872a27a6d5f74e1cf97e681ba8357  |
| 1.14.0    | [jc-1.14.0-1.x86_64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.14.0-1.x86_64.deb)  | 138bd66a391390ce67e32c7a0bd7b9c67db187205102e2ac0d6f8c0963eb6e1f  |
| 1.13.4    | [jc-1.13.4-1.x86_64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.13.4-1.x86_64.deb)  | 43cd693a0d361557534c7955599303e76fd14919d61ba92026aac342909b2dc6  |
| 1.13.2    | [jc-1.13.2-1.x86_64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.13.2-1.x86_64.deb)  | 8a152bc3bb8555c3ff0231eb6e719d43cb8797fd458c3356dd10b42ab94473ea  |
| 1.13.1    | [jc-1.13.1-1.x86_64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.13.1-1.x86_64.deb)  | 85374a30efe9c93476686860cf73bee6d31714d163e54b4566d86151379424a5  |
| 1.11.8    | [jc-1.11.8-1.x86_64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.11.8-1.x86_64.deb)  | 913f2f78fa892b2f96390976168f8d007f0a01e2c4ad0410d3c0bf8524b93c78  |
| 1.11.2    | [jc-1.11.2-1.x86_64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.11.2-1.x86_64.deb)  | 284de328e5cdcf65e119c77300ba34ca6551d1830812abfe615f9f0057458e5c  |
| 1.11.1    | [jc-1.11.1-1.x86_64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.11.1-1.x86_64.deb)  | 40a7e495ad38affdc27eb3e04970fdf3273a21b1ef9244978acaee2b77c508a7  |
| 1.10.5    | [jc-1.10.5-1.x86_64.deb](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.10.5-1.x86_64.deb)  | aa37a78cbe00e01a3f20aa68b99ef23101586968646cdc2d177b32aedc9d560d  |


#### RPM (Fedora, RHEL, CentOS)

| Version   | File                                                                                             | SHA256 Hash                                                       |
|-----------|--------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.14.1    | [jc-1.14.1-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.14.1-1.x86_64.rpm)  | 4cb09fe8d35df14a45db0054bbdeb57f1be9eab5bcd2a2a1833273fed8c6a744  |
| 1.14.0    | [jc-1.14.0-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.14.0-1.x86_64.rpm)  | 738c7dcc3e9d42b3020e822ff5453d221323b0ecaf303c16fa75d25ea29bb126  |
| 1.13.4    | [jc-1.13.4-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.13.4-1.x86_64.rpm)  | 3c526ebb7e0955413a6d4e084461c3a16c29d14a7ba631abaa317c0aa30e2872  |
| 1.13.2    | [jc-1.13.2-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.13.2-1.x86_64.rpm)  | d91c1eb5aa5f74049f09374c75bebdce27d0ae911349232fb7e3e85b9e399fbc  |
| 1.13.1    | [jc-1.13.1-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.13.1-1.x86_64.rpm)  | f5b7ccc8a7c11d43dbb70ebb8079c0b63343b80c89d3319aa75873b75da13ae7  |
| 1.11.8    | [jc-1.11.8-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.11.8-1.x86_64.rpm)  | 0b571e8be375799193d7509b9da59595efb4626fd420f97fed5b66a1685d0322  |
| 1.11.2    | [jc-1.11.2-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.11.2-1.x86_64.rpm)  | 1b23d18f03d4f1086c0468d9064b5e45ae1dc7319df376ecec4e792da4cd8b93  |
| 1.11.1    | [jc-1.11.1-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.11.1-1.x86_64.rpm)  | c55d3d40cced6c64d8f906e26eac06ebd03a87c8adcb6d5f8b223b3844c97753  |
| 1.10.5    | [jc-1.10.5-1.x86_64.rpm](https://jc-packages.s3-us-west-1.amazonaws.com/jc-1.10.5-1.x86_64.rpm)  | fd31f3be61e07aa277d1c0921ce46efd19a4ab2b211718bca377e6ff35b968c0  |


### Binaries (x86_64)
Linux and macOS x86_64 binaries are built from PyPi and can be copied to any location in your path and run. These binaries may not always be on the very latest `jc` version, but are regularly updated.

#### Linux (Fedora, RHEL, CentOS, Debian, Ubuntu)

| Version   | File                                                                                                               | SHA256 Hash (binary file)                                         |
|-----------|--------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.14.1    | [jc-1.14.1-linux-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.14.1-linux-x86_64.tar.gz)  | 847cff4472daa570f1317475c311d373e8d0e210c0d591197e1e1be385efc94d  |
| 1.14.0    | [jc-1.14.0-linux-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.14.0-linux-x86_64.tar.gz)  | 6d3695cd2ace481854f2a882ea46cb4e859dc728b61298998c619ffccaf1e2bf  |
| 1.13.4    | [jc-1.13.4-linux-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.13.4-linux-x86_64.tar.gz)  | e622126593e69919fb3cd64fbb45185942f8535fdd80d96bec1fda28e096ce22  |
| 1.13.2    | [jc-1.13.2-linux.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.13.2-linux.tar.gz)                | 130be04bb91db84190bef927bf5b97a27738226e4c9f270800990714bac908ee  |
| 1.13.1    | [jc-1.13.1-linux.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.13.1-linux.tar.gz)                | 4224e06c470714cb02e3e30df56e710dd55dde6dded488548b13b316d8e7dc31  |
| 1.11.8    | [jc-1.11.8-linux.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.11.8-linux.tar.gz)                | d3a9133d10e260d99e4fff69d2b3add0ff691d2ec67bff710fd5296546f35966  |
| 1.11.2    | [jc-1.11.2-linux.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.11.2-linux.tar.gz)                | 2a2faee2eea4ce0a6d10069cd95932bbc5ae4b70c6dc913502edbfe39a3f759f  |
| 1.11.1    | [jc-1.11.1-linux.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.11.1-linux.tar.gz)                | bf9e0f5865a415a1e2be11a2c36be29af0dfaa04c3630f98761eb9779b0b5c28  |
| 1.10.5    | [jc-1.10.5-linux.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.10.5-linux.tar.gz)                | 255eb9549ae90b2f96b316e29100208c466844cb13cbe9659770c6176fa4a502  |


#### macOS (Mojave and higher)

| Version   | File                                                                                                                 | SHA256 Hash (binary file)                                         |
|-----------|----------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| 1.14.0    | [jc-1.14.0-darwin-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.14.0-darwin-x86_64.tar.gz)  | db66da2561b3a508defc55a19c956b878e9679b68fa10692ef1fe330718a2db8  |
| 1.13.4    | [jc-1.13.4-darwin-x86_64.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.13.4-darwin-x86_64.tar.gz)  | 419f9097a10f9f30e15975cfce6f428b67945ff705a93f1d1cb203f0c6850b3e  |
| 1.13.2    | [jc-1.13.2-darwin.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.13.2-darwin.tar.gz)                | a7cceb11e522b3a376ec0da1196d8373c6a19f21529553f6c8d0dbc7f8fab29f  |
| 1.13.1    | [jc-1.13.1-darwin.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.13.1-darwin.tar.gz)                | 111e1d589b6d2f4bd347ae81c0e67bb2b3ce820964b313ebb71b63bdf4f73979  |
| 1.11.8    | [jc-1.11.8-darwin.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.11.8-darwin.tar.gz)                | 0f834cb78c9969b9bb86d1617a9254151c2373976fef59c1ea1ee3bb9a7a3ab5  |
| 1.11.2    | [jc-1.11.2-darwin.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.11.2-darwin.tar.gz)                | d89ab43151dbfbf4befad61505fa64b93c4b2fe2b4cd3250c7f0a3507e2d41a4  |
| 1.11.1    | [jc-1.11.1-darwin.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.11.1-darwin.tar.gz)                | 6447306cb6900912073e01b047d05698e31332ddc560ba6a5ca2b20ea034a624  |
| 1.10.5    | [jc-1.10.5-darwin.tar.gz](https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-1.10.5-darwin.tar.gz)                | e58c68cb7483049de686d9db623b19d24ff1c81bcfb00af64bd54652fcbb02f9  |
