Mkosi Debian Proof of Concept
=============================


Prerequisites
-------------

- Nix should be installed and the `nix-command` and `flakes` features should be enabled.

- For now, the Debian archive keyring needs to be installed on your computer. This will be fixed in a future update

Usage
-----

```shell
nix develop -c $SHELL
mkosi --force
```

> Make sure the above command is not run with sudo, as this will clear necessary environment variables set by the nix shell

Create a qcow2 image to store persistent files:

```shell
qemu-img create -f qcow2 persistent.qcow2 2048G
```

Run with:

```shell
sudo qemu-system-x86_64 \
  -enable-kvm \
  -machine type=q35,smm=on \
  -m 16384M \
  -nographic \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd \
  -drive file=/usr/share/edk2/x64/OVMF_VARS.4m.fd,if=pflash,format=raw \
  -kernel build/tdx-debian \
  -drive file=persistent.qcow2,format=qcow2,if=virtio,cache=writeback
```

Developing
----------

<h3>Building the Kernel</h3>

Just running `mkosi` itself will not trigger a kernel build. To rebuild the kernel, run:

```shell
exit # if you're currently in the nix develop shell
nix build --rebuild flake.nix # not needed if you only modified kernel.nix
nix develop -c $SHELL
```

<h3>Mkosi Debugging</h3>

To debug the mkosi environment, insert the following line in the mkosi script where you want to break:
```shell
socat UNIX-LISTEN:$SRCDIR/debug.sock,fork EXEC:/bin/bash,pty,stderr
```

Then, once the breakpoint is hit, you can get a shell on your computer with:
```shell
script -qfc "socat STDIO UNIX-CONNECT:debug.sock" /dev/null
```

From here, you can run `mkosi-chroot /bin/bash` to get inside Debian

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
├── scripts                           # Build scripts for compiling software inside the Debian chroot
│   └── build_rust_package.sh         # Helper script to reproducibly build rust binaries inside chroot
├── buildernet                        # Contains all buildernet-specific configuration
│   ├── mkosi.skeleton/etc            # Files to be directly copied into buildernet images
│   │   ├── init.d                    # Contains sysvinit services for rbuilder services
│   │   ├── rbuilder/config.mustache  # Template for rbuilder configuration
│   │   ├── rclone.conf.mustache      # Template for reth-sync
│   │   └── boot.d/persistence        # Initializes runtime directories for persistence
│   ├── buildernet.conf               # Primary configuration file for rbuilder mkosi configuration
│   ├── mkosi.postinst                # Handles users/permissions and templates out mustache files
│   └── mkosi.build                   # Calls rust build script to build lighthouse, reth, and rbuilder
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
- [ ] Run CVM Reverse Image Proxy
- [ ] Devtools
- [ ] Verification Script
- [ ] Proper CI
