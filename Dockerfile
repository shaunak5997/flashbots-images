FROM ubuntu:25.04

RUN apt-get update && apt-get install -y \
    curl git sudo qemu-system-x86 qemu-utils \
    debian-archive-keyring systemd-boot reprepro xz-utils

RUN adduser --disabled-password --gecos '' nix && \
    echo "nix ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/nix && \
    chmod 0440 /etc/sudoers.d/nix

COPY --chown=nix:nix . /home/nix/mkosi
RUN mkdir -p /home/nix/mkosi/mkosi.packages /home/nix/mkosi/mkosi.cache \
        /home/nix/mkosi/mkosi.builddir /home/nix/mkosi/build /nix && \
    chown -R nix:nix /home/nix/mkosi /nix

USER nix
RUN curl -L https://nixos.org/nix/install | sh -s -- --no-daemon && \
    mkdir -p ~/.config/nix ~/.cache/mkosi/ && \
    echo 'experimental-features = nix-command flakes' > ~/.config/nix/nix.conf
RUN /home/nix/.nix-profile/bin/nix develop -c /bin/true

WORKDIR /home/nix/mkosi
ENTRYPOINT ["/home/nix/.nix-profile/bin/nix", "develop", "-c", "/bin/bash"]