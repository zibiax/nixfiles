# Helium browser (ungoogled-chromium based), repackaged from the official
# prebuilt Linux release tarball. Modelled on nixpkgs' google-chrome.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  addDriverRunpath,
  xdg-utils,
  commandLineArgs ? "",

  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  gtk4,
  libdrm,
  libglvnd,
  libkrb5,
  libpulseaudio,
  libva,
  libx11,
  libxcb,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxkbcommon,
  libxrandr,
  libxrender,
  libxscrnsaver,
  libxshmfence,
  libxtst,
  libgbm,
  nspr,
  nss,
  pango,
  pciutils,
  pipewire,
  systemdLibs,
  vulkan-loader,
  wayland,
  qt6,
  adwaita-icon-theme,
  gsettings-desktop-schemas,
}:

let
  version = "0.21.3.1";

  arch =
    {
      x86_64-linux = "x86_64";
      aarch64-linux = "arm64";
    }
    .${stdenv.hostPlatform.system} or (throw "helium: unsupported system ${stdenv.hostPlatform.system}");

  hashes = {
    x86_64 = "sha256-iPPFOiNxguhyrDBhzIwSnnWuy86Erq2DQiXYEDCWwlQ=";
    arm64 = "sha256-shm+E3Rbq0/H9wBqlSTPZ/mfw2zS5vlFIRejn+6G1Ak=";
  };

  # Libraries linked directly or dlopen'd at runtime.
  deps = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    gtk4
    libdrm
    libglvnd
    libkrb5
    libpulseaudio
    libva
    libx11
    libxcb
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxkbcommon
    libxrandr
    libxrender
    libxscrnsaver
    libxshmfence
    libxtst
    libgbm
    nspr
    nss
    pango
    pciutils
    pipewire
    systemdLibs
    vulkan-loader
    wayland
  ];
in
stdenv.mkDerivation {
  pname = "helium";
  inherit version;

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-${arch}_linux.tar.xz";
    hash = hashes.${arch};
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = deps ++ [
    stdenv.cc.cc.lib
    qt6.qtbase # libqt6_shim.so (Qt theme integration)
    adwaita-icon-theme
    gsettings-desktop-schemas
  ];

  # Qt5 theme shim is optional; we don't pull in Qt5 for it.
  autoPatchelfIgnoreMissingDeps = [
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
  ];
  dontWrapQtApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/helium $out/bin
    cp -a . $out/opt/helium/
    rm $out/opt/helium/libqt5_shim.so

    # Use the system Vulkan loader instead of the bundled one.
    ln -sf ${lib.getLib vulkan-loader}/lib/libvulkan.so.1 $out/opt/helium/libvulkan.so.1

    install -Dm444 product_logo_256.png $out/share/icons/hicolor/256x256/apps/helium.png
    install -Dm444 helium.desktop $out/share/applications/helium.desktop
    substituteInPlace $out/share/applications/helium.desktop \
      --replace-fail 'Exec=helium' "Exec=$out/bin/helium"

    makeWrapper $out/opt/helium/helium $out/bin/helium \
      --prefix LD_LIBRARY_PATH : "$out/opt/helium:${lib.makeLibraryPath deps}" \
      --suffix PATH : "${lib.makeBinPath [ xdg-utils ]}" \
      --prefix XDG_DATA_DIRS : "$XDG_ICON_DIRS:$GSETTINGS_SCHEMAS_PATH:${addDriverRunpath.driverLink}/share" \
      --set CHROME_WRAPPER helium \
      --set CHROME_VERSION_EXTRA nix \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
      --add-flags ${lib.escapeShellArg commandLineArgs}

    ln -s $out/opt/helium/chromedriver $out/bin/helium-chromedriver

    runHook postInstall
  '';

  meta = {
    description = "Private, fast and honest web browser based on ungoogled-chromium";
    homepage = "https://helium.computer";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "helium";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
