{
  lib,
  buildGoModule,
  fetchFromGitHub,
  fetchYarnDeps,
  yarnConfigHook,
  yarnBuildHook,
  nodejs,
  stdenv,
}:
let

  version = "1.10.3";

  src = fetchFromGitHub {
    owner = "screego";
    repo = "server";
    rev = "v${version}";
    hash = "sha256-X8KZAUh1cO8qNYH6nc9zZ+mnfItgef8N948ErJLlZII=";
  };

  ui = stdenv.mkDerivation {
    pname = "screego-ui";
    inherit version;

    src = src + "/ui";

    offlineCache = fetchYarnDeps {
      yarnLock = "${src}/ui/yarn.lock";
      hash = "sha256-ye8UDkal10k/5uCd0VrZsG2FJGB727q+luExFTUmB/M=";
    };

    nativeBuildInputs = [
      yarnConfigHook
      yarnBuildHook
      nodejs
    ];

    installPhase = ''
      cp -r build $out
    '';

  };

in

buildGoModule rec {
  inherit src version;

  pname = "screego-server";

  vendorHash = "sha256-ry8LO+KmNU9MKL8/buk9qriDe/zq+2uIsws6wVZmoo4=";

  ldflags = [
    "-s"
    "-w"
    "-X=main.version=${version}"
    "-X=main.commitHash=${src.rev}"
    "-X=main.mode=prod"
  ];

  postPatch = ''
    mkdir -p ./ui/build
    cp -r "${ui}" ./ui/build
  '';

  postInstall = ''
    mv $out/bin/server $out/bin/screego
  '';

  meta = with lib; {
    description = "Screen sharing for developers";
    homepage = "https://screego.net";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ pinpox ];
    mainProgram = "screego";
  };
}
