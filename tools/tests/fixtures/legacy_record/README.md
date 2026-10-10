# Legacy Record compatibility fixture

These files are byte-for-byte copies of the pre-local-production Record source
and header from project revision `2cad23c32d43bcc295b31326212aadbe7a188cae`:
`src/NewPirate/common/UtilTools/Record.cpp` and `Record.h`.

The source is checked in so a fresh or shallow clone, including a publication
with squashed history, can run the compatibility test without that historical
Git object or any network access. The hashes below identify the original bytes;
the historical revision is provenance only, never a runtime prerequisite.

- `Record.cpp`: Git blob `d14723dca87a3f4c7d4390b440cf6e3c8283fba8`; SHA-256 `b8d0c2e49ab9cf52af76c46e727df3d562123e8f3e3497ecd52062c85876e75f`
- `Record.h`: Git blob `f08d694a7584edea55d7e137251bd1c057bd5883`; SHA-256 `ab94b7d6b8c74ff8ad7712d6bb442baba8c696b9a0d5f2aa28853bd3ad8bea29`

`run_record_atomic_native.py` compiles this fixture as `LegacyRecord`, solely
inside its temporary test executable. The production Record implementation is
compiled separately. The harness checks legacy-write/current-read,
current-write/legacy-read, and identical encoded bytes for identical input.
The legacy header is pinned as well, so current declaration changes cannot
silently change the reference class definition.

This is historical code, including its known small-input compression-buffer
limitation. Tests use compressible legacy fixtures and exercise the small-input
regression only through the fixed current implementation. Both implementations
use the current unchanged compression algorithm and its corrected array
destruction. This fixture is never part of the game build or used with a player
profile. Do not modernize it along with production code.
