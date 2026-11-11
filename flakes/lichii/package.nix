# Lichii: Eden fork with Switch 2 support. Based on nixpkgs' eden derivation.
{
  lib,
  stdenv,
  src,
  version,
  # Force the Qt (and SDL) frontends onto X11/XWayland. Can still be
  # overridden at runtime by setting QT_QPA_PLATFORM / SDL_VIDEO_DRIVER.
  forceX11 ? true,

  cmake,
  ninja,
  boost,
  cpp-jwt,
  cubeb,
  enet,
  fetchFromGitHub,
  applyPatches,
  ffmpeg-headless,
  fmt,
  frozen-containers,
  gamemode,
  glslang,
  httplib,
  kdePackages,
  libopus,
  libusb1,
  lz4,
  nlohmann_json,
  openssl,
  pipewire,
  pkg-config,
  python3,
  qt6,
  sdl3,
  simpleini,
  sirit,
  spirv-headers,
  spirv-tools,
  unordered_dense,
  vulkan-headers,
  vulkan-loader,
  vulkan-memory-allocator,
  vulkan-utility-libraries,
  xbyak,
  zlib,
  zstd,
  eden,
  wrapGAppsHook3,
}:

let
  # Download-only deps from cpmfile.json that nixpkgs doesn't ship as-is.
  zbic = fetchFromGitHub {
    owner = "kinnay";
    repo = "zbic";
    rev = "11b08f2712264bbed731545085cbd9702096ceb7";
    hash = "sha256-pHvxa1gkUvQo6mUgmLWtj1kcu01BLdGmttZyb8ZAj/o=";
  };
  xxhash = fetchFromGitHub {
    owner = "Cyan4973";
    repo = "xxHash";
    rev = "v0.8.3";
    hash = "sha256-h6kohM+NxvQ89R9NEXZcYBG2wPOuB4mcyPfofKrx9wQ=";
  };
  # Upstream always bundles this exact zstd so archives are byte-identical.
  zstd-src = fetchFromGitHub {
    owner = "facebook";
    repo = "zstd";
    rev = "33618c89e511637f8a6ef955b3501766d71feb53";
    hash = "sha256-UP99PUq8N+fmU972Jxim4f9u//T+4hRW+wuTZzWg3uI=";
  };
  reshade = applyPatches {
    name = "reshade-src";
    src = fetchFromGitHub {
      owner = "crosire";
      repo = "reshade";
      rev = "v6.8.0";
      hash = "sha256-K6QC7CLqy8M318n9WbuqGvcRF9g9abvDD/xbr7T+nXo=";
    };
    patches = [ "${src}/.patch/reshade/0001-from-chars-fallback.patch" ];
  };

  bundled = name: dir: [
    (lib.cmakeBool "${name}_FORCE_BUNDLED" true)
    (lib.cmakeFeature "${name}_CUSTOM_DIR" "${dir}")
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "lichii";
  inherit version src;

  strictDeps = true;
  __structuredAttrs = true;

  nativeBuildInputs = [
    cmake
    ninja
    glslang
    pkg-config
    python3
    qt6.qttools
    qt6.wrapQtAppsHook
    wrapGAppsHook3
  ];

  buildInputs = [
    boost
    cpp-jwt
    cubeb
    enet
    ffmpeg-headless
    fmt
    frozen-containers
    gamemode
    httplib
    kdePackages.quazip
    libopus
    libusb1
    lz4
    nlohmann_json
    openssl
    qt6.qtbase
    qt6.qtmultimedia
    qt6.qtwayland
    qt6.qtwebengine
    qt6.qtcharts
    sdl3
    simpleini
    spirv-headers
    spirv-tools
    vulkan-headers
    vulkan-memory-allocator
    vulkan-utility-libraries
    sirit
    unordered_dense
    zlib
    zstd
  ]
  ++ lib.optionals stdenv.hostPlatform.isx86_64 [ xbyak ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_TESTING" false)
    (lib.cmakeBool "YUZU_TESTS" false)
    (lib.cmakeBool "ENABLE_WERROR" false)

    (lib.cmakeBool "CPMUTIL_FORCE_SYSTEM" true)
    (lib.cmakeFeature "YUZU_TZDB_PATH" "${eden.nx_tzdb}")

    (lib.cmakeBool "YUZU_USE_QT_WEB_ENGINE" true)
    (lib.cmakeBool "YUZU_USE_QT_MULTIMEDIA" true)
    (lib.cmakeBool "YUZU_INSTALL_UDEV_RULES" true)
  ]
  ++ bundled "zstd" zstd-src
  ++ bundled "zbic" zbic
  ++ bundled "xxhash" xxhash
  ++ bundled "reshade" reshade;

  preFixup = ''
    qtWrapperArgs+=(--prefix LD_LIBRARY_PATH : ${
      lib.makeLibraryPath [
        vulkan-loader
        pipewire
      ]
    })
  ''
  + lib.optionalString forceX11 ''
    qtWrapperArgs+=(
      --set-default QT_QPA_PLATFORM xcb
      --set-default SDL_VIDEO_DRIVER x11
    )
  '';

  meta = {
    description = "Experimental Nintendo Switch / Switch 2 emulator (Eden fork)";
    homepage = "https://github.com/zortos293/Lichii";
    mainProgram = "lichii";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
})
