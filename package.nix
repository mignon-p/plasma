{
  lib,
  stdenv,
  cmake,
  ninja,
  perl,
  pkg-config,
  makeWrapper,
  libyaml,
  openssl,
  boost,
  icu,
  avahi,
  which,
  psmisc,
  procps,
  hostname,
  ruby,
  getconf,
  doCheck ? true,
}:

let
  fs = lib.fileset;
  isBackup = file: lib.hasSuffix "~" file.name;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "plasma";
  version = "5.6.1";

  src = fs.toSource {
    root = ./.;
    fileset = fs.difference ./. (
      fs.unions [
        (fs.maybeMissing ./build)
        (fs.maybeMissing ./result)
        ./docker
        ./flake.nix
        (fs.maybeMissing ./flake.lock)
        ./package.nix
        (fs.fileFilter isBackup ./.)
      ]
    );
  };

  nativeBuildInputs = [
    cmake
    ninja
    perl
    pkg-config
    makeWrapper
  ];

  # The generated .pc files refer to these as bare -l flags, so
  # consumers need them in their own build environment too.
  propagatedBuildInputs = [
    libyaml
    openssl
    boost
    icu
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [ avahi ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_CXX_LIBS" true)
    (lib.cmakeBool "BUILD_TESTS" finalAttrs.doCheck)
    # Newer compilers and Nix's hardening flags add warnings that
    # the upstream code base has not been cleaned up for.
    (lib.cmakeBool "PLASMA_WERROR" false)
  ];

  postPatch = ''
    patchShebangs .
    substituteInPlace \
      libLoam/c/tests/test-version.sh \
      libLoam/c/tests/test-obversion.rb \
      --replace-fail /usr/bin/getconf getconf
  '';

  inherit doCheck;
  # Commands used by the yotest harness and the shell-script tests.
  nativeCheckInputs = [
    which
    procps
    hostname
    openssl
    ruby
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [
    psmisc
    getconf
  ];
  # Tests in the same directory share a "scratch" subdirectory, so
  # they can't run in parallel.
  enableParallelChecking = false;
  # The test fixtures run pool_tcp_server on localhost.
  __darwinAllowLocalNetworking = true;

  preCheck = ''
    export HOME=$TMPDIR
    export CTEST_PARALLEL_LEVEL=1
    # These expect EPERM when creating a pool owned by root, but the
    # build sandbox doesn't map uid 0, so chown fails with EINVAL.
    export GTEST_FILTER='-RecentServerOnly.FailedPermissionize*'
    export OB_POOLS_DIR=$TMPDIR/pools
    mkdir -p $OB_POOLS_DIR
  '';

  # CTestCustom.cmake starts and stops the pool server fixtures around
  # the run.  pool-permissions.rb needs to chgrp a pool to "nogroup",
  # which the sandbox doesn't allow.
  checkPhase = ''
    runHook preCheck
    ctest --output-on-failure -E '^pool-permissions\.rb$'
    runHook postCheck
  '';

  postInstall = ''
    if [ -e $out/bin/ob-plasma-cert.sh ]; then
      wrapProgram $out/bin/ob-plasma-cert.sh \
        --prefix PATH : ${lib.makeBinPath [ openssl ]}
    fi
  '';

  meta = {
    description = "g-speak libLoam and libPlasma (slawx and pools)";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
