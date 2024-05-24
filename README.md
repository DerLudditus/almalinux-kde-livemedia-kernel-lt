# AlmaLinux KDE Custom Live Media

This git repository contains the scripts needed to produce a customized AlmaLinux KDE Live ISO. A fully-functioning `AlmaLinux` system is required, being it metal or virtual.

THIS UNOFFICIAL PROJECT IS **NOT** ENDORSED BY the AlmaLinux OS Foundation. IT IS A DERIVATIVE WORK USING MODIFIED SCRIPTS ORIGINALLY AND OFFICIALLY PUBLISHED ON [AlmaLinux/sig-livemedia](https://github.com/AlmaLinux/sig-livemedia).

## 1. Preliminary info

This project contains the `KickStart` file required to build KDE live media for AlmaLinux 9.4. In version 9.3, it was possible to patch `treebuilder.py` from `livemedia-creator` so that a different kernel is used to boot the Live ISO, but this is no longer possible for 9.4.

Both scripts that can used to build an ISO, `livemedia-creator` and `livecd-creator`, are pathetically improvised Python scripts that have multiple comments that support for more than one kernel should be added, but nobody did so. Sadly, `livemedia-creator` fails to work in 9.4, so I had to use `livecd-creator`, which is more difficult to modify. 

Therefore, despite being properly installed and configured in the installable Live ISO, `kernel-lt` from ELRepo can only be used **after you install the distro!** I needed a newer kernel, which in this case is 6.1, for its better support of more recent hardware than the official 5.14 one. **I specifically needed a newer kernel for an Acer laptop that uses MT7663 for Wi-Fi and BT.**

**IMPORTANT!** [As provided](http://elrepo.org/tiki/kernel-lt) and signed by ELRepo, `kernel-lt` cannot be used on UEFI systems with Secure Boot enabled! (Quote: `These packages are not signed for SecureBoot.`) **Make sure you disable Secure Boot** in the BIOS/UEFI.

Use this to install the prerequisites required to build this project:

```sh
sudo dnf -y install epel-release
sudo dnf -y --enablerepo="epel" install anaconda-tui \
                livecd-tools \
                lorax \
                subscription-manager \
                pykickstart \
                efibootmgr \
                efi-filesystem \
                efi-srpm-macros \
                efivar-libs \
                grub2-efi-*64 \
                grub2-efi-*64-cdboot \
                grub2-tools-efi \
                shim-*64
```

### 2. Building the ISO

```sh
sudo livecd-creator \
--config kickstarts/almalinux-9-live-kde-lt.ks \
--fslabel AlmaLinux-9_4-x86_64-Live-KDE-LT \
--title="AlmaLinux Live 9.4 KDE" \
--product="AlmaLinux Live 9.4 KDE" \
--cache=$PWD/pkg-cache-alma \
--releasever=9.4 
```

### 3. Changes towards the original scripts from [AlmaLinux/sig-livemedia](https://github.com/AlmaLinux/sig-livemedia)

* I'm using `timezone Europe/Berlin` and [ftp.gwdg.de](https://ftp.gwdg.de) for most repos in the `ks` file. You can change them to match your needs. Consult [mirrors.almalinux.org](https://mirrors.almalinux.org) if needed; also, [elrepo.org](http://elrepo.org/tiki/Download).
  
* Extra repositories have been added and enabled, with the packages shown below preselected:

  **elrepo** for `kernel-lt` (note that **elrepo-kernel** has to be enabled manually!)

  **almalinux-synergy** for `dnfdragora` (yay!)

  **rpmfusion-free-updates** and **rpmfusion-nonfree-updates** for the proper, unhindered versions of `ffmpeg`, `gstreamer1-plugins-ugly`, `libavcodec-freeworld`, `lame`, `vlc`.
  
* Additional software that will be preinstalled: `alsa-sof-firmware` (newer laptops need it, but most distros don't install it), `featherpad` (because it's a small gem), `fortune-mod` (because you should add it to `~/.bashrc`), `haruna` (I prefer it to VLC), `krename`, `mc`, `neofetch`, `warpinator`.

### 5. D/L the prebuilt ISO

I hosted an ISO file on SourceForge, under [almalinux-custom-kde-live](https://almalinux-custom-kde-live.sourceforge.io) - in [9.4](https://sourceforge.net/projects/almalinux-custom-kde-live/files/9.4/). Use it at your own risk! No warranties, explicit or implied. None whatsoever.
