#!/usr/bin/env bash
# run_me.sh - Basic bash structure with a "switch" (case) that does pre and post actions
# Usage: ./run_me.sh <command>
# Commands: start | stop | status | restart

set -euo pipefail
IFS=$'\n\t'

PRE_DONE=0

pre_action() {
    echo ">>> Pre-action: Installing rpmfusion and updating multimedia packages"
    # example preparation (create temp dir, check deps, etc.)
    # mkdir -p /tmp/myapp  || true
    if [[ "$(whoami)" != "root" ]]; then
        echo "Error: please run me as root(Tip: Type sudo before me)" >&2
        exit 1
    fi

    dnf upgrade -y
    dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
    dnf config-manager setopt fedora-cisco-openh264.enabled=1 
    dnf swap ffmpeg-free ffmpeg --allowerasing -y
    dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y


    PRE_DONE=1
}

post_action() {
    echo ">>> Post-action: Installing Skanlite, Printer Support, and more packages."
    dnf install skanlite sane-backends-drivers-scanners vlc -y
    dnf install cups system-config-printer -y
    echo ">>> Post-action: Installing curl and git."
    dnf install curl git -y
    echo ">>> Post-action: Installing curated support for printers."
    cd './PPD Files'
    cp -r ./* /usr/share/ppd/
    cd ..
    echo ">>> Installation complete. Please reboot to make sure all changes take effect."
}

cmd_intel() {
    echo "Installing Driver for Intel..."
    # intel logic here
    dnf install intel-media-driver -y
    
}

cmd_old_intel() {
    echo "Installing Older Driver for Intel..."
    # old intel logic here
    dnf install libva-intel-driver -y
}

cmd_amd() {
    echo "Installing Driver for AMD..."
    # amd logic here
    dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y
    dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld -y
}

cmd_vbox() {
    echo "Installing GuestAdditions for VirtualBox..."
    # virtualbox logic here
    dnf install virtualbox-guest-additions -y
}

cmd_nvidia() {
    echo "Sorry, NVIDIA driver installation is not yet implemented."
    # nvidia logic here

}

usage() {
    cat <<EOF
Usage: $0 {intel|amd|vbox|nvidia}
Commands:
  intel      Install Intel media driver
  old-intel  Install older Intel media driver
  amd        Install AMD media driver
  vbox       Install VirtualBox Guest Additions
  nvidia     Install NVIDIA driver (not yet implemented)
EOF
    exit 2
}

main() {
    [[ $# -ge 1 ]] || usage

    pre_action

    case "${1:-}" in
        intel)
            cmd_intel
            ;;
        amd)
            cmd_amd
            ;;
        vbox)
            cmd_vbox
            ;;
        nvidia)
            # example of reusing existing case branches while continuing flow
            cmd_nvidia
            ;;

        old-intel)
            # example of reusing existing case branches while continuing flow
            cmd_old_intel
            ;;
        *)
            echo "Unknown command: ${1:-}"
            usage
            ;;
    esac

    # continue with post actions regardless of which branch ran
    post_action
}

main "$@"