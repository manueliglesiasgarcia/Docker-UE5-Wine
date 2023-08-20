FROM archlinux:base-devel-20230319.0.135218

ENV TZ=Europe/London
ENV WINEESYNC=1
# Disable Fsync causes hangs during compilation
ENV WINEFSYNC=0
ENV WINEARCH=win64
ENV WINEDEBUG=-all
ENV WINEPREFIX=/root/.wine

RUN mkdir -p "$WINEPREFIX"
RUN echo -e "[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
RUN pacman-key --init

WORKDIR /msvc-temp

RUN pacman -Syu --noconfirm && pacman -S --noconfirm \
    wine-staging=8.12-1 \
    wget \
    zip \
    unzip \
    msitools \
    xorg-xwayland \
    weston \
    xorg-xinit \
    mesa \
    git \
    samba \
    gnutls \
    lib32-gnutls \
    ca-certificates \
    xorg-server-xvfb

RUN wget -P /usr/bin https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && chmod +x /usr/bin/winetricks

RUN wine64 wineboot --init && \
    while pgrep wineserver > /dev/null; do sleep 1; done

RUN winetricks -f -q dotnet48

RUN mkdir -p /tmp/.X11-unix
RUN wget https://download.visualstudio.microsoft.com/download/pr/91cf5cbb-c34a-4766-bff6-aea28265d815/97e3a74aad85ccb86346ebb76baa537e166cbab550d7239487c92a835e10d4f1/vs_BuildTools.exe

RUN XDG_RUNTIME_DIR="$HOME" weston --use-pixman --backend=headless-backend.so --xwayland & \
    DISPLAY=:0 wine64 vs_buildtools.exe \
    --add Microsoft.VisualStudio.Workload.VCTools \
    --add Microsoft.VisualStudio.Workload.MSBuildTools \
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 \
    --add Microsoft.VisualStudio.Component.NuGet \
    --add Microsoft.VisualStudio.Component.Windows10SDK.20348 \
    --add Microsoft.Net.Component.4.6.2.TargetingPack \
    --add Microsoft.Net.ComponentGroup.DevelopmentPrerequisites \
    --add Microsoft.NetCore.Component.SDK \
    --add Microsoft.NetCore.Component.Runtime.3.1 \
    --quiet --wait --norestart --nocache

RUN wine64 winecfg -v win10
