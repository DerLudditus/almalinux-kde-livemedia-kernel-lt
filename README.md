# AlmaLinux KDE Custom Live Media

This git repository contains the scripts needed to produce a customized AlmaLinux KDE Live ISO. A fully-functioning `AlmaLinux` system is required, being it metal or virtual.

THIS UNOFFICIAL PROJECT IS **NOT** ENDORSED BY the AlmaLinux OS Foundation. IT IS A DERIVATIVE WORK USING MODIFIED SCRIPTS ORIGINALLY AND OFFICIALLY PUBLISHED ON [AlmaLinux/sig-livemedia](https://github.com/AlmaLinux/sig-livemedia).

## 1. How to build it

This project contains the `KickStart` file required to build KDE live media for AlmaLinux 9.3, and modified templates that are required in order to use `kernel-lt` from ELRepo, which is 6.1, better supporting more recent hardware than the official 5.14 one. **I specifically needed a newer kernel for an Acer laptop that uses MT7663 for Wi-Fi and BT.**

**IMPORTANT!** [As provided](http://elrepo.org/tiki/kernel-lt) and signed by ELRepo, `kernel-lt` cannot be used on UEFI systems with Secure Boot enabled! (Quote: `These packages are not signed for SecureBoot.`) **Make sure you disable Secure Boot** in the BIOS/UEFI.

Because I couldn't find out how to tell `livecd-tools` to use a different kernel than the standard one, I had to use `livemedia-creator`, hence `lorax`, despite this one being unable to use package caching (blame `anaconda` for that).&#x20;

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

### 2. Building using `lorax`

To use `kernel-lt` and (its modules) instead of `kernel` (and its modules), `lorax` needs to use modified templates. The orthodox way is to use a separate set of templates, and tell it to use that folder hierarchy. I found this annoyingly stupid, as `/usr/share/lorax/templates.d/` contains 132 files, of which one or two require changes. So I just edited them in place.

Not knowing which of them is used, I changed them both:

`/usr/share/lorax/templates.d/80-rhel/runtime-install.tmpl`

`/usr/share/lorax/templates.d/99-generic/runtime-install.tmpl`

It's counterintuitive, but these are the scripts that needed to be edited in order to change the kernel used by the LiveISO **to boot**; once in the live session, you can have as many kernels as there are added as packages, they show up in GRUB, and they will all (i.e. both) installed (if you'll want to install the OS), but the kernel used to boot this ISO is just one. See more in section 4.

So, **before doing anything else, make sure you override** those files in your building system with the ones provided here!

Then, and only then, run this to build the KDE ISO:

```sh
sudo livemedia-creator \
    --ks=kickstarts/almalinux-9-live-kde-lt.ks \
    --no-virt --resultdir  ./iso-kde \
    --project "AlmaLinux Live" \
    --make-iso \
    --iso-only \
    --iso-name AlmaLinux-9.3-x86_64-Live-KDE-Ludditus.iso \
    --releasever 9.3 \
    --volid "AlmaLinux-9_3-x86_64-Live-KDE-LT" \
    --nomacboot 
```

### 3. Changes towards the original scripts from [AlmaLinux/sig-livemedia](https://github.com/AlmaLinux/sig-livemedia)

* The Live media will boot using `kernel-lt` [from ELRepo](http://elrepo.org/tiki/kernel-lt). The installed system will have both `kernel-lt` (6.1) and `kernel` (5.14), so pay attention to those situations when updating the system only brings a new `kernel`, which would go first in GRUB, before `kernel-lt`. But you should know that if you ever used several kernel branches simultaneously (Arch, EndeavourOS, Manjaro, anyone?).
* I'm using `timezone Europe/Berlin` and [ftp.gwdg.de](https://ftp.gwdg.de) for most repos in the `ks` file. You can change them to match your needs. Consult [mirrors.almalinux.org](https://mirrors.almalinux.org) if needed; also, [elrepo.org](http://elrepo.org/tiki/Download).
* I have used this script to build a KDE Live ISO of AlmaLinux 9.3 before the team could build an official ISO, because I needed it for a new install, and without the requirement of a USB Ethernet adapter + a patch cord for the said laptop, so I couldn't be stopped by the situation that prevented them from offering an official KDE ISO: when EPEL9 has updated KDE to Plasma 5.27.6, KF5 5.108, Apps 23.04.3, `kdepim-addons` couldn't be updated because `kf5itinerary` needed a newer `poplar` than the one available in EL9 ([read about it here](https://lists.fedoraproject.org/archives/list/epel-devel@lists.fedoraproject.org/thread/VAAKEKAEKGSBBPXO4HJK3J7EDVPUUKJM/)). **I'm not using KDE PIM at all, so I just excluded `kdepim-addons`.**
* Extra repositories have been added and enabled, with the packages shown below preselected:\
  **epel-testing**: for `krename` (I installed it while it was still in testing; now it got properly released, but I found _epel-testing_ to be solid enough, yet slow to release, hence I keep it enabled!)\
  **almalinux-synergy:** for `dnfdragora` (yay!)\
  **rpmfusion-free-updates** and **rpmfusion-nonfree-updates**: for the proper, unhindered versions of `ffmpeg`, `gstreamer1-plugins-ugly`, `libavcodec-freeworld`, `lame`, `mplayer`, `smplayer`, `vlc`.
* Additional software that will be preinstalled: `alsa-sof-firmware` (newer laptops need it, but most distros don't install it), `featherpad` (because it's a small gem), `fortune-mod` (because you should add it to `~/.bashrc`), `mc.`

### 4. What I don't like in these building systems  

IMVHO, both `livecd-tools` and `livemedia-creator` (`lorax`) suck big time. Their creators never thought that some people might want to customize the boot kernel, to include more than one kernel, etc. They "knew better" (à la Microsoft), and this area is the least configurable in these open-source projects!

The resulting ISO files suffer from the following inconsistency:

* The booting kernel is in **isolinux/vmlinuz** and it cannot be customized. The booting system lacks any GRUB configuration file, and the only options are (1) to boot this kernel, or (2) to perform a checksum verification, then to boot. It's impossible to use a second kernel. `livecd-tools` will use the `kernel` package, no matter what; `livemedia-creator` can be customized, but far too many templates are used in the process (well, it comes from RH, right?).
* Once you have booted into **LiveOS/squashfs.img**, the live system will include whatever has been installed there, in this case both `kernel` and `kernel-lt`, properly listed in `grub2.cfg`, and installable by Anaconda.

Nobody, and by this I mean the designers of such pieces of software, ever thought of any of these options:

* Let the user specify the kernel they want to use for **isolinux/vmlinuz**.
* F-ing use a proper GRUB configuration and make it able to boot all the kernels that are included in the installed live system **LiveOS/squashfs.img**.
* Alternatively, and regardless of what's in the squash, include all the kernels that have "Provide: kernel", even if that would mean to include all the kernels available in all the enabled repos; in this case, `kernel-ml` would be a 3rd kernel, which would be an interesting way to test a live system without installing anything.

Hardcoding shit is shitty.

### 5. Download a prebuilt ISO

I hosted an ISO file on SourceForge, under [almalinux-custom-kde-live](https://sourceforge.net/projects/almalinux-custom-kde-live/) - in [9.3](https://sourceforge.net/projects/almalinux-custom-kde-live/files/9.3/). Use it at your own risk! No warranties, explicit or implied. None whatsoever.
