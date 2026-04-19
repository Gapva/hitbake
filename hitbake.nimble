# package
version       = "0.1.0"
author        = "Laith Hijazi"
description   = "lightning-fast utility for baking rhythm game hit-sounds"
license       = "AGPL-3.0-or-later"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["hitbake"]

# dependencies
requires "nim >= 2.2.4"
requires "cligen >= 1.0.0"
requires "prettyterm >= 0.1.0"
