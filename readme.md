Mkosi Debian Proof of Concept
=============================


Prerequisites
-------------

- Nix should be installed and the `nix-command` and `flakes` features should be enabled.

- Right now, I'm using the latest commit of mkosi directly with no patches, so the official nixpkgs patches to fix the hardcoded paths in mkosi aren't being applied. For this reason, you should install qemu and debian-archive-keyring since they will be used from the host for the time being. After I submit the updated patches to nixpkgs, this will no longer be necessary.

Usage
-----

```shell
nix develop -c $SHELL
mkosi --force
```

> Make sure the above command is not run with sudo, as this will clear necessary environment variables set by the nix shell

Run with:

```shell
sudo qemu-system-x86_64 \                                                                   mkosi-poc on  main  nix-shell-env took 15s 
  -machine type=q35,smm=on \
  -m 2048M \
  -nographic \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd \
  -drive file=/usr/share/edk2/x64/OVMF_VARS.4m.fd,if=pflash,format=raw \
  -kernel build/tdx-debian
```


Current Functionality
---------------------

- [x] Bit-for-bit reproducible/deterministic images
- [x] Uses sysvinit instead of systemd
- [x] Customizable kernel config
- [x] Doesn't use libraries or binaries from host
- [x] Build process doesn't require containerization
- [x] Small image size (<50Mb root partition base size)
- [x] Ultra minimal initramfs
- [x] Packaged cleanly as a tiny UKI image
- [ ] Linked with a proof of concept flashbots reproducible Debian pkg repo
- [ ] Verification Script
- [ ] Proper CI
- [ ] Contains full functionality of meta-confidential-compute
