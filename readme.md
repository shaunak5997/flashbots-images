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

Create a qcow2 image to store persistent files:

```shell
qemu-img create -f qcow2 persistent.qcow2 200
```

Run with:

```shell
sudo qemu-system-x86_64 \                                                                                                         mkosi-poc on  main   nix-shell-env 
  -enable-kvm \
  -machine type=q35,smm=on \
  -m 16384M \
  -nographic \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd \
  -drive file=/usr/share/edk2/x64/OVMF_VARS.4m.fd,if=pflash,format=raw \
  -kernel build/tdx-debian \
  -drive file=persistent.qcow2,format=qcow2,if=virtio,cache=writeback
```

Directory Structure
-------------------

```
.
├── mkosi.conf                        # Main mkosi configuration file
├── flake.nix                         # Defines a shell environment with fixed deps for mkosi
├── kernel.nix                        # Nix derivation to reproducibly build the kernel
├── kernel-yocto.config               # Kernel configuration for kernel.nix, copied directly from Yocto
├── debloat.conf                      # Configuration to remove unnecessary files from the base image
├── env.json.example                  # Example environment variable configuration
├── buildernet                        # Contains all buildernet-specific configuration
│   ├── mkosi.skeleton/etc            # Files to be directly copied into buildernet images
│   │   ├── init.d                    # Contains sysvinit services for rbuilder services
│   │   ├── rbuilder/config.mustache  # Template for rbuilder configuration
│   │   ├── rclone.conf.mustache      # Template for reth-sync
│   │   └── boot.d/persistence        # Initializes runtime directories for persistence
│   ├── buildernet.conf               # Primary configuration file for rbuilder mkosi configuration
│   ├── mkosi.postinst                # Handles users/permissions and templates out mustache files
│   ├── build_rust_package.sh         # Helper script to reproducibly build rust binaries inside chroot
│   └── mkosi.build                   # Calls above helper script to build lighthouse, reth, and rbuilder
├── mkosi.skeleton                    # Files to be directly copied into all images
│   ├── etc                           # Base image sysvinit configuration
│   │   ├── inittab                   # Sysvinit configuration file
│   │   └── init.d/networking         # Minimal network interface and dhcp service
│   └── init                          # Initramfs entrypoint. This is called directly by the kernel
└── mkosi.prepare                     # Copies nix-generated kernel into the image
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
- [x] Run basic buildernet in image
- [ ] Verification Script
- [ ] Proper CI
