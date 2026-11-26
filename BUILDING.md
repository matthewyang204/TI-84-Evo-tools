## Building TI-84 Calculator Toolbox
To build TI-84 Calculator Toolbox, you will need a working Rust toolchain, C++ compiler, the Qt 6 development libraries, and the source code.

### Building on Linux
The official Linux build of this program is built on a reasonably old version of Ubuntu. It is built on Ubuntu 20.04 Focal, with glibc 2.31 and Qt 6.5.3. The Qt libraries are installed from the official installer; the QML and Qt Quick components are the primary requirements. Additionally, if you are deploying a build of this program to run on a different system, your container/VM/computer must be capable of running AppImages. If the build system is a Docker container, it must not exit the moment the shell is closed (you will see this later!), so please use a `sleep infinity` or similarly idle PID 1 command when creating your container.

The following commands can be used to install all the required system packages onto a fresh container:
```bash
apt update

apt install -y \
    build-essential \
    sudo \
    git \
    openssh-client \
    curl \
    wget \
    pkg-config \
    libudev-dev \
    libxcb1-dev \
    libxcb-cursor-dev \
    libxcb-image0-dev \
    libxcb-keysyms1-dev \
    libxcb-randr0-dev \
    libxcb-render-util0-dev \
    libxcb-shape0-dev \
    libxcb-shm0-dev \
    libxcb-sync-dev \
    libxcb-xfixes0-dev \
    libxcb-xinerama0-dev \
    libxcb-xkb-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-dev \
    libx11-dev \
    libx11-xcb-dev \
    libgl1-mesa-dev \
    libxcb-icccm4 \
    fuse \
    libfuse2 \
    kmod \
    nano \
    tmux \
    patchelf
```
Please use `sudo` as necessary, if you are building on your daily system. If you are building in a container, run them as root.

Afterwards, install the Rust toolchain:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```
Run the installer with the default configuration. After installation, you may need to restart your shell or run `source $HOME/.cargo/env` to add the Rust toolchain to your PATH (I told you so about not using the shell as the PID 1 command in your container!).

Afterwards, you can just clone the source code (or get a tarball), enter the directory, and build it:
```bash
QMAKE=<path/to/qmake> ./build-linux.sh
```
