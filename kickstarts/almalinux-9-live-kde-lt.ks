# UNOFFICIAL!
# X Window System configuration information
xconfig  --startxonboot
# Keyboard layouts
keyboard 'us'
# Root password
rootpw --plaintext rootme
# System language
lang en_US.UTF-8
# Shutdown after installation
shutdown
# System timezone
timezone Europe/Berlin
# Network information
network  --bootproto=dhcp --device=link --activate

# Repos for European users
url --url=https://ftp.gwdg.de/pub/linux/almalinux/9/BaseOS/$basearch/os/
repo --name="baseos" --baseurl=https://ftp.gwdg.de/pub/linux/almalinux/9/BaseOS/$basearch/os/
repo --name="appstream" --baseurl=https://ftp.gwdg.de/pub/linux/almalinux/9/AppStream/$basearch/os/
repo --name="extras" --baseurl=https://ftp.gwdg.de/pub/linux/almalinux/9/extras/$basearch/os/
repo --name="crb" --baseurl=https://ftp.gwdg.de/pub/linux/almalinux/9/CRB/$basearch/os/
repo --name="epel" --baseurl=https://dl.fedoraproject.org/pub/epel/9/Everything/$basearch/
repo --name="almalinux-synergy" --baseurl=https://ftp.gwdg.de/pub/linux/almalinux/9/synergy/$basearch/os/
repo --name="elrepo" --install --baseurl=https://ftp.gwdg.de/pub/linux/elrepo/elrepo/el9/$basearch/
repo --name="elrepo-kernel" --install --baseurl=https://ftp.gwdg.de/pub/linux/elrepo/kernel/el9/$basearch/
repo --name="rpmfusion-free-updates" --baseurl=http://download1.rpmfusion.org/free/el/updates/9/$basearch/
repo --name="rpmfusion-nonfree-updates" --baseurl=http://download1.rpmfusion.org/nonfree/el/updates/9/$basearch/

# Firewall configuration
firewall --enabled --service=mdns
# SELinux configuration
selinux --enforcing

# System services
services --disabled="sshd" --enabled="NetworkManager,ModemManager"
# System bootloader configuration
bootloader --location=none
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel
# Disk partitioning information
part / --size=10238

%post

# Enable livesys services
systemctl enable livesys.service
systemctl enable livesys-late.service

# Enable sddm since EPEL packages it disabled by default
systemctl enable sddm.service

# enable tmpfs for /tmp
systemctl enable tmp.mount

# make it so that we don't do writing to the overlay for things which
# are just tmpdirs/caches
# note https://bugzilla.redhat.com/show_bug.cgi?id=1135475
cat >> /etc/fstab << EOF
vartmp   /var/tmp    tmpfs   defaults   0  0
EOF

# work around for poor key import UI in PackageKit
rm -f /var/lib/rpm/__db*

# import AlmaLinux PGP key
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

# import EPEL PGP key
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-9

# import ELRepo PGP key
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org

echo "Packages within this LiveCD"
rpm --rebuilddb
rpm -qa

# Note that running rpm recreates the rpm db files which aren't needed or wanted
rm -f /var/lib/rpm/__db*

# go ahead and pre-make the man -k cache (#455968)
/usr/bin/mandb

# make sure there aren't core files lying around
rm -f /core*

# remove random seed, the newly installed instance should make it's own
rm -f /var/lib/systemd/random-seed

# convince readahead not to collect
# FIXME: for systemd

echo 'File created by kickstart. See systemd-update-done.service(8).' \
    | tee /etc/.updated >/var/.updated

# Drop the rescue kernel and initramfs, we don't need them on the live media itself.
# See bug 1317709
rm -f /boot/*-rescue*

# Very ODD fix to get Alma background, find alternative
rm -rf /usr/share/wallpapers/Fedora
ln -s Alma-mountains-white /usr/share/wallpapers/Fedora
# background end

# Update default theme - this has to stay KS
# Hack KDE Fedora package starts. TODO: need almalinux-kde-fix package
sed -i 's/defaultWallpaperTheme=Fedora/defaultWallpaperTheme=Alma-mountains-white/' /usr/share/plasma/desktoptheme/default/metadata.desktop
sed -i 's/defaultFileSuffix=.png/defaultFileSuffix=.jpg/' /usr/share/plasma/desktoptheme/default/metadata.desktop
sed -i 's/defaultWidth=1920/defaultWidth=2048/' /usr/share/plasma/desktoptheme/default/metadata.desktop
sed -i 's/defaultHeight=1080/defaultHeight=1536/' /usr/share/plasma/desktoptheme/default/metadata.desktop
# Update KInfocenter
sed -i 's/pixmaps\/system-logo-white.png/icons\/hicolor\/256x256\/apps\/fedora-logo-icon.png/' /etc/xdg/kcm-about-distrorc
sed -i 's/http:\/\/fedoraproject.org/https:\/\/almalinux.org/' /etc/xdg/kcm-about-distrorc
# Hack KDE Fedora package ends

# Disable network service here, as doing it in the services line
# fails due to RHBZ #1369794
systemctl disable network

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

# set livesys session type
sed -i 's/^livesys_session=.*/livesys_session="kde"/' /etc/sysconfig/livesys

# set default GTK+ theme for root (see #683855, #689070, #808062)
cat > /root/.gtkrc-2.0 << EOF
include "/usr/share/themes/Adwaita/gtk-2.0/gtkrc"
include "/etc/gtk-2.0/gtkrc"
gtk-theme-name="Adwaita"
EOF
mkdir -p /root/.config/gtk-3.0
cat > /root/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-theme-name = Adwaita
EOF

# enable CRB repo
dnf config-manager --enable crb

%end

%post --nochroot
# cp $INSTALL_ROOT/usr/share/licenses/*-release/* $LIVE_ROOT/

# only works on x86, x86_64
if [ "$(uname -i)" = "i386" -o "$(uname -i)" = "x86_64" ]; then
  if [ ! -d $LIVE_ROOT/LiveOS ]; then mkdir -p $LIVE_ROOT/LiveOS ; fi
  cp /usr/bin/livecd-iso-to-disk $LIVE_ROOT/LiveOS
fi

%end

%packages
Box2D
LibRaw
ModemManager
ModemManager-glib
NetworkManager
NetworkManager-l2tp
NetworkManager-libnm
NetworkManager-libreswan
NetworkManager-openconnect
NetworkManager-openvpn
NetworkManager-pptp
NetworkManager-team
NetworkManager-tui
NetworkManager-wifi
PackageKit
PackageKit-Qt5
PackageKit-command-not-found
PackageKit-glib
aajohan-comfortaa-fonts
abattis-cantarell-fonts
accounts-qml-module
accountsservice
acl
adobe-mappings-cmap
adobe-mappings-cmap-deprecated
adobe-mappings-pdf
adobe-source-code-pro-fonts
adwaita-cursor-theme
adwaita-gtk2-theme
adwaita-icon-theme
akonadi-import-wizard
akregator
akregator-libs
almalinux-backgrounds
almalinux-backgrounds-extras
almalinux-gpg-keys
almalinux-indexhtml
almalinux-logos
almalinux-release
almalinux-release-synergy
almalinux-repos
alsa-lib
alsa-sof-firmware
alternatives
anaconda
anaconda-install-env-deps
anaconda-live
@anaconda-tools
anthy-unicode
appstream
appstream-data
appstream-qt
ark
ark-libs
at-spi2-atk
at-spi2-core
atk
audit
audit-libs
augeas-libs
authselect
authselect-libs
autocorr-en
avahi
avahi-glib
avahi-libs
baloo-widgets
basesystem
bash
bc
blivet-data
bluedevil
bluez
bluez-libs
bolt
boost-chrono
boost-date-time
boost-filesystem
boost-iostreams
boost-locale
boost-system
boost-thread
breeze-cursor-theme
breeze-gtk-common
breeze-gtk-gtk2
breeze-gtk-gtk3
breeze-icon-theme
bubblewrap
bzip2
bzip2-libs
c-ares
ca-certificates
cairo
cairo-gobject
checkpolicy
chkconfig
chrony
clucene-contribs-lib
clucene-core
cmake-filesystem
codec2
color-filesystem
colord
colord-kde
colord-libs
copy-jdk-configs
coreutils
coreutils-common
cpio
cpp
cracklib
cracklib-dicts
cronie
cronie-anacron
crontabs
crypto-policies
crypto-policies-scripts
cryptsetup-libs
cups
cups-client
cups-filesystem
cups-filters
cups-filters-libs
cups-ipptool
cups-libs
cups-pk-helper
curl
cyrus-sasl-lib
cyrus-sasl-md5
cyrus-sasl-plain
daxctl-libs
dbus
dbus-broker
dbus-common
dbus-daemon
dbus-glib
dbus-libs
dbus-tools
dbus-x11
dbusmenu-qt5
dconf
dejavu-sans-fonts
dejavu-sans-mono-fonts
dejavu-serif-fonts
desktop-file-utils
device-mapper
device-mapper-event
device-mapper-event-libs
device-mapper-libs
device-mapper-multipath
device-mapper-multipath-libs
device-mapper-persistent-data
@dial-up
diffutils
dmidecode
dnf
dnf-data
dnf-plugins-core
dnfdragora
docbook-dtds
docbook-style-xsl
dolphin
dolphin-libs
dolphin-plugins
dosfstools
dotconf
dracut
dracut-config-generic
dracut-config-rescue
dracut-live
dracut-network
dracut-squash
e2fsprogs
e2fsprogs-libs
efi-filesystem
efibootmgr
efivar-libs
egl-utils
elfutils-default-yama-scope
elfutils-libelf
elfutils-libs
emacs-filesystem
enchant2
elrepo-release
epel-release
espeak-ng
ethtool
exempi
exfatprogs
exiv2
exiv2-libs
expat
f35-backgrounds-base
f35-backgrounds-kde
fatresize
fdk-aac-free
featherpad
ffmpeg
ffmpeg-libs
ffmpegthumbs
fftw-libs-double
file
file-libs
filesystem
findutils
firewall-config
firewalld
firewalld-filesystem
flac-libs
flashrom
flatpak
flatpak-libs
flatpak-selinux
flatpak-session-helper
flute
fontconfig
fonts-filesystem
fortune-mod
freerdp
freerdp-libs
freetype
fribidi
fuse
fuse-common
fuse-libs
fuse-sshfs
fwupd
fwupd-plugin-flashrom
gawk
gawk-all-langpacks
gcr
gcr-base
gd
gdbm-libs
gdisk
gdk-pixbuf2
gdk-pixbuf2-modules
geoclue2
gettext
gettext-libs
ghostscript
ghostscript-tools-fonts
ghostscript-tools-printing
giflib
gjs
glib-networking
glib2
glibc
glibc-all-langpacks
glibc-common
glibc-gconv-extra
glibc-langpack-en
glx-utils
gmp
gnome-keyring
gnome-keyring-pam
gnome-menus
gnome-software
gnupg2
gnutls
gobject-introspection
google-carlito-fonts
google-droid-sans-fonts
google-noto-cjk-fonts-common
google-noto-fonts-common
google-noto-sans-cjk-ttc-fonts
google-noto-sans-fonts
google-noto-sans-khmer-fonts
google-noto-sans-khmer-ui-fonts
google-noto-sans-malayalam-fonts
google-noto-sans-malayalam-ui-fonts
google-noto-sans-mono-fonts
google-noto-sans-sinhala-fonts
google-noto-serif-fonts
gpgme
gpgmepp
gpsd-libs
grantlee-editor
grantlee-editor-libs
grantlee-qt5
graphene
graphite2
grep
groff-base
grub2-common
grub2-efi-x64
grub2-efi-x64-cdboot
grub2-pc-modules
grub2-tools
grub2-tools-minimal
grubby
gsettings-desktop-schemas
gsm
gspell
gstreamer1
gstreamer1-plugins-bad-free
gstreamer1-plugins-base
gstreamer1-plugins-good
gstreamer1-plugins-good-gtk
gstreamer1-plugins-ugly-free
gstreamer1-plugins-ugly
gtk-update-icon-cache
gtk2
gtk2-engines
gtk3
@guest-desktop-agents
gwenview
gwenview-libs
gzip
harfbuzz
harfbuzz-icu
haruna
hfsplus-tools
hicolor-icon-theme
highcontrast-icon-theme
highway
hostname
ht-caladea-fonts
hunspell
hunspell-en
hunspell-en-GB
hunspell-en-US
hunspell-filesystem
hwdata
hyphen
hyphen-en
ibus
ibus-gtk2
ibus-gtk3
ibus-libs
ibus-setup
iceauth
iio-sensor-proxy
ilbc
ima-evm-utils
imath
inih
initial-setup
initial-setup-gui
initscripts
initscripts-rename-device
initscripts-service
intel-mediasdk
@internet-browser
iproute
iproute-tc
ipset
ipset-libs
iptables-libs
iptables-nft
iputils
irqbalance
iso-codes
isomd5sum
iw
iwl100-firmware
iwl1000-firmware
iwl105-firmware
iwl135-firmware
iwl2000-firmware
iwl2030-firmware
iwl3160-firmware
iwl5000-firmware
iwl5150-firmware
iwl6000g2a-firmware
iwl6050-firmware
iwl7260-firmware
jansson
jasper-libs
java-11-openjdk-headless
javapackages-filesystem
javapackages-tools
jbig2dec-libs
jbigkit-libs
json-c
json-glib
jxl-pixbuf-loader
kaccounts-integration
kaccounts-providers
kactivitymanagerd
kaddressbook
kaddressbook-libs
kamera
kamoso
kate
kate-plugins
kbd
kbd-misc
kcalc
kcharselect
kcolorchooser
kcolorpicker
kde-cli-tools
kde-filesystem
kde-gtk-config
kde-partitionmanager
kde-print-manager
kde-print-manager-libs
kde-settings
kde-settings-plasma
kde-settings-pulseaudio
@kde-apps
@kde-media
kde-connect
kde-connect-libs
kdecoration
kdegraphics-mobipocket
kdegraphics-thumbnailers
#kdepim-addons
kdepim-runtime
kdepim-runtime-libs
kdeplasma-addons
kdesu
kdiagram
kdialog
kdnssd
kdsoap
keditbookmarks
keditbookmarks-libs
kernel
kernel-core
kernel-lt
kernel-lt-core
kernel-lt-modules
kernel-lt-modules-extra
kernel-modules
kernel-modules-extra
kernel-tools
kernel-tools-libs
kexec-tools
keybinder3
keyutils-libs
kf5-akonadi-calendar
kf5-akonadi-contacts
kf5-akonadi-mime
kf5-akonadi-notes
kf5-akonadi-search
kf5-akonadi-server
kf5-akonadi-server-mysql
kf5-attica
kf5-baloo
kf5-baloo-file
kf5-baloo-libs
kf5-bluez-qt
kf5-calendarsupport
kf5-eventviews
kf5-filesystem
kf5-frameworkintegration
kf5-frameworkintegration-libs
kf5-grantleetheme
kf5-incidenceeditor
kf5-kactivities
kf5-kactivities-stats
kf5-karchive
kf5-kauth
kf5-kbookmarks
kf5-kcalendarcore
kf5-kcalendarutils
kf5-kcmutils
kf5-kcodecs
kf5-kcompletion
kf5-kconfig-core
kf5-kconfig-gui
kf5-kconfigwidgets
kf5-kcontacts
kf5-kcoreaddons
kf5-kcrash
kf5-kdav
kf5-kdbusaddons
kf5-kdeclarative
kf5-kded
kf5-kdelibs4support
kf5-kdelibs4support-libs
kf5-kdesu
kf5-kdnssd
kf5-kdoctools
kf5-kfilemetadata
kf5-kglobalaccel
kf5-kglobalaccel-libs
kf5-kguiaddons
kf5-kholidays
kf5-khtml
kf5-ki18n
kf5-kiconthemes
kf5-kidentitymanagement
kf5-kidletime
kf5-kimageformats
kf5-kimap
kf5-kinit
kf5-kio-core
kf5-kio-core-libs
kf5-kio-doc
kf5-kio-file-widgets
kf5-kio-gui
kf5-kio-ntlm
kf5-kio-widgets
kf5-kio-widgets-libs
kf5-kipi-plugins
kf5-kipi-plugins-libs
kf5-kirigami2
kf5-kirigami2-addons
kf5-kirigami2-addons-treeview
kf5-kitemmodels
kf5-kitemviews
kf5-kitinerary
kf5-kjobwidgets
kf5-kjs
kf5-kldap
kf5-kmailtransport
kf5-kmbox
kf5-kmime
kf5-knewstuff
kf5-knotifications
kf5-knotifyconfig
kf5-kontactinterface
kf5-kpackage
kf5-kparts
kf5-kpeople
kf5-kpimtextedit
kf5-kpkpass
kf5-kpty
kf5-kquickcharts
kf5-kross-core
kf5-krunner
kf5-kservice
kf5-ksmtp
kf5-ktexteditor
kf5-ktextwidgets
kf5-ktnef
kf5-kunitconversion
kf5-kwallet
kf5-kwallet-libs
kf5-kwayland
kf5-kwidgetsaddons
kf5-kwindowsystem
kf5-kxmlgui
kf5-kxmlrpcclient
kf5-libgravatar
kf5-libkdcraw
kf5-libkdepim
kf5-libkexiv2
kf5-libkipi
kf5-libkleo
kf5-libksane
kf5-libksieve
kf5-mailcommon
kf5-mailimporter
kf5-mailimporter-akonadi
kf5-messagelib
kf5-modemmanager-qt
kf5-networkmanager-qt
kf5-pimcommon
kf5-pimcommon-akonadi
kf5-plasma
kf5-prison
kf5-purpose
kf5-solid
kf5-sonnet-core
kf5-sonnet-ui
kf5-syndication
kf5-syntax-highlighting
kf5-threadweaver
kfind
kgpg
khelpcenter
khmer-os-content-fonts
khotkeys
kimageannotator
kinfocenter
kio-extras
kmag
kmahjongg
kmail
kmail-account-wizard
kmail-libs
kmenuedit
kmines
kmod
kmod-libs
kmousetool
kmouth
kolourpaint
kolourpaint-libs
konsole5
konsole5-part
kontact
kontact-libs
konversation
korganizer
korganizer-libs
kpartx
kpmcore
krb5-libs
krdc
krdc-libs
krename
krfb
krfb-libs
kruler
kscreen
kscreenlocker
ksshaskpass
ksystemstats
kuserfeedback
kwalletmanager5
kwayland-integration
kwayland-server
kwin
kwin-common
kwin-libs
kwin-wayland
kwin-x11
kwrite
kwrited
ladspa
lame
lame-libs
langpacks-core-en
langpacks-core-font-en
langpacks-core-font-ko
langpacks-en
langtable
layer-shell-qt
lcms2
ldns
leptonica
less
libICE
libSM
libX11
libX11-common
libX11-xcb
libXScrnSaver
libXau
libXaw
libXcomposite
libXcursor
libXdamage
libXdmcp
libXext
libXfixes
libXfont2
libXft
libXi
libXinerama
libXmu
libXpm
libXrandr
libXrender
libXres
libXt
libXtst
libXv
libXxf86dga
libXxf86vm
libabw
libaccounts-glib
libaccounts-qt5
libacl
libaio
libao
libaom
libappstream-glib
libarchive
libass
libassuan
libasyncns
libatasmart
libattr
libavcodec-freeworld
libavif
libbase
libbasicobjects
libblkid
libblockdev
libblockdev-crypto
libblockdev-dm
libblockdev-fs
libblockdev-kbd
libblockdev-loop
libblockdev-lvm
libblockdev-mdraid
libblockdev-mpath
libblockdev-nvdimm
libblockdev-part
libblockdev-swap
libblockdev-utils
libbluray
libbpf
libbrotli
libbs2b
libbytesize
libcanberra
libcanberra-gtk2
libcanberra-gtk3
libcap
libcap-ng
libcap-ng-python3
libcbor
libcdr
libchewing
libchromaprint
libcmis
libcollection
libcom_err
libcomps
libcurl
libdaemon
libdatrie
libdav1d
libdb
libdhash
libdmtx
libdmx
libdnf
libdrm
libdvdnav
libdvdread
libeconf
libedit
libepoxy
libepubgen
liberation-fonts
liberation-fonts-common
liberation-mono-fonts
liberation-sans-fonts
liberation-serif-fonts
libestr
libetonyek
libevdev
libevent
libexif
libexttextcat
libfastjson
libfdisk
libffi
libfido2
libfontenc
libfonts
libformula
libfreehand
libgcab1
libgcc
libgcrypt
libgexiv2
libglvnd
libglvnd-egl
libglvnd-gles
libglvnd-glx
libglvnd-opengl
libgnomekbd
libgomp
libgpg-error
libgphoto2
libgs
libgsf
libgudev
libgusb
libgxps
libhandy
libibverbs
libical
libicu
libidn2
libieee1284
libijs
libimobiledevice
libini_config
libinput
libiptcdata
libjcat
libjpeg-turbo
libjxl
libkcapi
libkcapi-hmaccalc
libkdegames
libkgapi
libkmahjongg
libkmahjongg-data
libkolabxml
libksba
libkscreen-qt5
libksysguard
libksysguard-common
libkworkspace5
liblangtag
liblangtag-data
liblayout
libldac
libldb
libloader
libmarkdown
libmng
libmnl
libmodplug
libmodulemd
libmount
libmpc
libmspub
libmtp
libmwaw
libmysofa
libndp
libnetfilter_conntrack
libnfnetlink
libnftnl
libnghttp2
libnl3
libnl3-cli
libnma
libnotify
libnumbertext
libodfgen
libogg
libopenmpt
liborcus
libosinfo
libpagemaker
libpaper
libpath_utils
libpcap
libpciaccess
libpinyin
libpinyin-data
libpipeline
libpkgconf
libplist
libpng
libproxy
libproxy-webkitgtk4
libpskc
libpsl
libpwquality
libqalculate
libqxp
libref_array
librepo
libreport
libreport-anaconda
libreport-cli
libreport-filesystem
libreport-gtk
libreport-plugin-reportuploader
libreport-web
librepository
libreswan
librevenge
librsvg2
libsamplerate
libsane-airscan
libsbc
libseccomp
libsecret
libselinux
libselinux-utils
libsemanage
libsepol
libserializer
libshaderc
libshout
libsigsegv
libsmartcols
libsmbclient
libsmbios
libsndfile
libsodium
libsolv
libsoup
libspectre
libsrtp
libss
libssh
libssh-config
libsss_certmap
libsss_idmap
libsss_nss_idmap
libsss_sudo
libstaroffice
libstdc++
libstemmer
libsysfs
libtalloc
libtasn1
libtdb
libteam
libtevent
libthai
libtheora
libtiff
libtimezonemap
libtirpc
libtool-ltdl
libtracker-sparql
libudfread
libudisks2
libunistring
libunwind
libusbmuxd
libusbx
libuser
libutempter
libuuid
libv4l
libva
libvdpau
libverto
libvisio
libvisual
libvmaf
libvncserver
libvorbis
libvpx
libwacom
libwacom-data
libwayland-client
libwayland-cursor
libwayland-egl
libwayland-server
libwbclient
libwebp
libwinpr
libwpd
libwpe
libwpg
libwps
libxcb
libxcrypt
libxcrypt-compat
libxkbcommon
libxkbcommon-x11
libxkbfile
libxklavier
libxml2
libxmlb
libxshmfence
libxslt
libyaml
libzip
libzmf
libzstd
linux-firmware
linux-firmware-whence
livesys-scripts
lklug-fonts
lksctp-tools
llvm-libs
lm_sensors-libs
lmdb-libs
lockdev
logrotate
lohit-assamese-fonts
lohit-bengali-fonts
lohit-devanagari-fonts
lohit-gujarati-fonts
lohit-gurmukhi-fonts
lohit-kannada-fonts
lohit-marathi-fonts
lohit-odia-fonts
lohit-tamil-fonts
lohit-telugu-fonts
low-memory-monitor
lpcnetfreedv
lpsolve
lshw
lsof
lsscsi
lua
lua-libs
lua-posix
lv2
lvm2
lvm2-libs
lz4-libs
lzo
maliit-framework
maliit-framework-qt5
maliit-keyboard
man-db
mariadb
mariadb-backup
mariadb-common
mariadb-connector-c
mariadb-connector-c-config
mariadb-errmsg
mariadb-gssapi-server
mariadb-server
mariadb-server-utils
mc
mdadm
media-player-info
memtest86+
mesa-dri-drivers
mesa-filesystem
mesa-libEGL
mesa-libGL
mesa-libgbm
mesa-libglapi
mesa-libxatracker
mesa-vulkan-drivers
microcode_ctl
mobile-broadband-provider-info
mokutil
mozilla-filesystem
mpfr
mpg123-libs
mtdev
mtools
mysql-selinux
mythes
mythes-en
nano
ncurses
ncurses-base
ncurses-libs
ndctl
ndctl-libs
neofetch
neon
nettle
newt
nftables
nm-connection-editor
npth
nspr
nss
nss-mdns
nss-softokn
nss-softokn-freebl
nss-sysinit
nss-tools
nss-util
numactl-libs
ocl-icd
@office-suite
okular
okular-libs
okular-part
ongres-scram
ongres-scram-client
openal-soft
openconnect
openexr-libs
openjpeg2
openldap
openldap-compat
openpgm
openssh
openssh-clients
openssh-server
openssl
openssl-libs
openssl-pkcs11
openvpn
opus
orc
os-prober
osinfo-db
osinfo-db-tools
ostree
ostree-libs
oxygen-sound-theme
p11-kit
p11-kit-server
p11-kit-trust
pam
pam-kwallet
pango
parted
passwd
pcaudiolib
pciutils-libs
pcre
pcre2
pcre2-syntax
pcre2-utf16
pcsc-lite-libs
pentaho-libxml
pentaho-reporting-flow-engine
perl-AutoLoader
perl-B
perl-Carp
perl-Class-Struct
perl-DBD-MariaDB
perl-DBI
perl-Data-Dumper
perl-Digest
perl-Digest-MD5
perl-DynaLoader
perl-Encode
perl-Errno
perl-Exporter
perl-Fcntl
perl-File-Basename
perl-File-Copy
perl-File-Path
perl-File-Temp
perl-File-stat
perl-FileHandle
perl-Getopt-Long
perl-Getopt-Std
perl-HTTP-Tiny
perl-IO
perl-IO-Socket-IP
perl-IO-Socket-SSL
perl-IPC-Open3
perl-MIME-Base64
perl-Math-BigInt
perl-Math-Complex
perl-Mozilla-CA
perl-NDBM_File
perl-Net-SSLeay
perl-POSIX
perl-PathTools
perl-Pod-Escapes
perl-Pod-Perldoc
perl-Pod-Simple
perl-Pod-Usage
perl-Scalar-List-Utils
perl-SelectSaver
perl-Socket
perl-Storable
perl-Symbol
perl-Sys-Hostname
perl-Term-ANSIColor
perl-Term-Cap
perl-Text-ParseWords
perl-Text-Tabs+Wrap
perl-Time-Local
perl-URI
perl-base
perl-constant
perl-if
perl-interpreter
perl-libnet
perl-libs
perl-mro
perl-overload
perl-overloading
perl-parent
perl-podlators
perl-subs
perl-vars
phonon-qt5
phonon-qt5-backend-gstreamer
pigz
pim-data-exporter
pim-data-exporter-libs
pim-sieve-editor
pinentry
pinentry-gnome3
pipewire
pipewire-alsa
pipewire-jack-audio-connection-kit
pipewire-libs
pipewire-pulseaudio
pixman
pkcs11-helper
pkgconf
pkgconf-m4
pkgconf-pkg-config
plasma-breeze
plasma-breeze-common
plasma-browser-integration
plasma-desktop
plasma-desktop-doc
plasma-discover
plasma-discover-flatpak
plasma-discover-libs
plasma-discover-notifier
plasma-discover-packagekit
plasma-drkonqi
plasma-integration
plasma-lookandfeel-fedora
plasma-milou
plasma-nm
plasma-nm-l2tp
plasma-nm-openconnect
plasma-nm-openswan
plasma-nm-openvpn
plasma-nm-pptp
plasma-pa
plasma-systemmonitor
plasma-systemsettings
plasma-thunderbolt
plasma-workspace
plasma-workspace-common
plasma-workspace-geolocation
plasma-workspace-geolocation-libs
plasma-workspace-libs
plasma-workspace-wallpapers
plasma-workspace-wayland
plasma-workspace-x11
plymouth
plymouth-core-libs
plymouth-graphics-libs
plymouth-plugin-label
plymouth-plugin-two-step
plymouth-scripts
plymouth-system-theme
plymouth-theme-spinner
policycoreutils
policycoreutils-python-utils
polkit
polkit-kde
polkit-libs
polkit-pkla-compat
polkit-qt5-1
poppler
poppler-cpp
poppler-data
poppler-glib
poppler-qt5
poppler-utils
popt
postgresql-jdbc
powerdevil
ppp
pptp
prefixdevname
procps-ng
protobuf-c
psmisc
publicsuffix-list-dafsa
pulseaudio-libs
pulseaudio-libs-glib2
pulseaudio-utils
python-unversioned-command
python3
python3-audit
python3-blivet
python3-blockdev
python3-bytesize
python3-cairo
python3-chardet
python3-cups
python3-dasbus
python3-dateutil
python3-dbus
python3-dnf
python3-dnf-plugins-core
python3-firewall
python3-gobject
python3-gobject-base
python3-gobject-base-noarch
python3-gpg
python3-hawkey
python3-idna
python3-kickstart
python3-langtable
python3-libcomps
python3-libdnf
python3-libreport
python3-libs
python3-libselinux
python3-libsemanage
python3-meh
python3-meh-gui
python3-nftables
python3-pid
python3-pip-wheel
python3-policycoreutils
python3-productmd
python3-pwquality
python3-pycurl
python3-pyparted
python3-pysocks
python3-pytz
python3-pyudev
python3-requests
python3-requests-file
python3-requests-ftp
python3-rpm
python3-setools
python3-setuptools
python3-setuptools-wheel
python3-simpleline
python3-six
python3-systemd
python3-urllib3
qca-qt5
qca-qt5-ossl
qgpgme
qpdf-libs
qqc2-desktop-style
qrencode-libs
qt5-qtbase
qt5-qtbase-common
qt5-qtbase-gui
qt5-qtbase-mysql
qt5-qtdeclarative
qt5-qtfeedback
qt5-qtgraphicaleffects
qt5-qtimageformats
qt5-qtlocation
qt5-qtmultimedia
qt5-qtnetworkauth
qt5-qtquickcontrols
qt5-qtquickcontrols2
qt5-qtscript
qt5-qtsensors
qt5-qtspeech
qt5-qtspeech-speechd
qt5-qtsvg
qt5-qttools
qt5-qttools-common
qt5-qttools-libs-designer
qt5-qtvirtualkeyboard
qt5-qtwayland
qt5-qtwebchannel
qt5-qtwebengine
qt5-qtwebkit
qt5-qtx11extras
qt5-qtxmlpatterns
qtkeychain-qt5
raptor2
rasqal
rav1e-libs
readline
redland
rootfiles
rpm
rpm-build-libs
rpmfusion-free-release
rpmfusion-nonfree-release
rpm-libs
rpm-plugin-audit
rpm-plugin-selinux
rpm-plugin-systemd-inhibit
rpm-sign-libs
rsync
rsyslog
rsyslog-logrotate
rtkit
rubberband
sac
samba-client
samba-client-libs
samba-common
samba-common-libs
sane-airscan
sane-backends
sane-backends-drivers-cameras
sane-backends-drivers-scanners
sane-backends-libs
satyr
sddm
sddm-breeze
sddm-kcm
sddm-wayland-plasma
sed
selinux-policy
selinux-policy-targeted
setup
setxkbmap
sg3_utils
sg3_utils-libs
sgml-common
shadow-utils
shared-mime-info
shim-x64
signon
signon-plugin-oauth2
signon-ui
sil-padauk-fonts
slang
smc-meera-fonts
smc-rachana-fonts
snappy
socat
sound-theme-freedesktop
soundtouch
soxr
spectacle
speech-dispatcher
speech-dispatcher-espeak-ng
speex
spirv-tools-libs
sqlite
sqlite-libs
squashfs-tools
srt-libs
sssd-client
sssd-common
sssd-kcm
@standard
stoken-libs
sudo
svt-av1-libs
syslinux
syslinux-nonlinux
system-config-printer-libs
systemd
systemd-libs
systemd-pam
systemd-rpm-macros
systemd-udev
taglib
tar
teamd
tesseract
tesseract-langpack-eng
tesseract-tessdata-doc
tigervnc-license
tigervnc-server-minimal
totem-pl-parser
tpm2-tss
tracker
tracker-miners
trousers-lib
twolame-libs
tzdata
tzdata-java
udftools
udisks2
unbound-libs
unzip
upower
urw-base35-bookman-fonts
urw-base35-c059-fonts
urw-base35-d050000l-fonts
urw-base35-fonts
urw-base35-fonts-common
urw-base35-gothic-fonts
urw-base35-nimbus-mono-ps-fonts
urw-base35-nimbus-roman-fonts
urw-base35-nimbus-sans-fonts
urw-base35-p052-fonts
urw-base35-standard-symbols-ps-fonts
urw-base35-z003-fonts
usermode
userspace-rcu
util-linux
util-linux-core
vamp-plugin-sdk
vapoursynth-libs
vid.stab
vim-minimal
vlc
volume_key-libs
vpnc-script
vulkan-loader
warpinator
wavpack
wayland-utils
webkit2gtk3
webkit2gtk3-jsc
webrtc-audio-processing
which
wireless-regdb
wireplumber
wireplumber-libs
woff2
wpa_supplicant
wpebackend-fdo
xapian-core-libs
xcb-util
xcb-util-cursor
xcb-util-image
xcb-util-keysyms
xcb-util-renderutil
xcb-util-wm
xdg-dbus-proxy
xdg-desktop-portal
xdg-desktop-portal-gtk
xdg-desktop-portal-kde
xdg-user-dirs
xerces-c
xfsprogs
xkbcomp
xkeyboard-config
xl2tpd
xmessage
xml-common
xmlrpc-c
xmlrpc-c-client
xmlsec1
xmlsec1-nss
xorg-x11-drv-evdev
xorg-x11-drv-fbdev
xorg-x11-drv-libinput
xorg-x11-drv-vmware
xorg-x11-drv-wacom
xorg-x11-drv-wacom-serial-support
xorg-x11-server-Xorg
xorg-x11-server-Xwayland
xorg-x11-server-common
xorg-x11-server-utils
xorg-x11-utils
xorg-x11-xauth
xorg-x11-xinit
xorg-x11-xinit-session
xsettingsd
xz
xz-libs
yelp
yelp-libs
yelp-xsl
yum
zenity
zeromq
zimg
zlib
zstd
zxing-cpp
-desktop-backgrounds-compat
-@dial-up
-@input-methods
-fcoe-utils
-gfs2-utils
-kde-connect
-kdeconnectd
-kde-connect-libs
-sdubby
-tracker-miners
-tracker

%end
