#!/usr/bin/env python3

from __future__ import annotations

import argparse
import pathlib
import sys
import urllib.request


RAW_SOURCES = {
    "TAHOT Gen-Deu - Translators Amalgamated Hebrew OT - STEPBible.org CC BY.txt": (
        "https://raw.githubusercontent.com/STEPBible/STEPBible-Data/master/"
        "Translators%20Amalgamated%20OT%2BNT/"
        "TAHOT%20Gen-Deu%20-%20Translators%20Amalgamated%20Hebrew%20OT%20-%20"
        "STEPBible.org%20CC%20BY.txt"
    ),
    "TAHOT Jos-Est - Translators Amalgamated Hebrew OT - STEPBible.org CC BY.txt": (
        "https://raw.githubusercontent.com/STEPBible/STEPBible-Data/master/"
        "Translators%20Amalgamated%20OT%2BNT/"
        "TAHOT%20Jos-Est%20-%20Translators%20Amalgamated%20Hebrew%20OT%20-%20"
        "STEPBible.org%20CC%20BY.txt"
    ),
    "TAHOT Job-Sng - Translators Amalgamated Hebrew OT - STEPBible.org CC BY.txt": (
        "https://raw.githubusercontent.com/STEPBible/STEPBible-Data/master/"
        "Translators%20Amalgamated%20OT%2BNT/"
        "TAHOT%20Job-Sng%20-%20Translators%20Amalgamated%20Hebrew%20OT%20-%20"
        "STEPBible.org%20CC%20BY.txt"
    ),
    "TAHOT Isa-Mal - Translators Amalgamated Hebrew OT - STEPBible.org CC BY.txt": (
        "https://raw.githubusercontent.com/STEPBible/STEPBible-Data/master/"
        "Translators%20Amalgamated%20OT%2BNT/"
        "TAHOT%20Isa-Mal%20-%20Translators%20Amalgamated%20Hebrew%20OT%20-%20"
        "STEPBible.org%20CC%20BY.txt"
    ),
    "TVTMS - Translators Versification Traditions with Methodology for Standardisation for Eng+Heb+Lat+Grk+Others - STEPBible.org CC BY.txt": (
        "https://raw.githubusercontent.com/STEPBible/STEPBible-Data/master/"
        "Versification/"
        "TVTMS%20-%20Translators%20Versification%20Traditions%20with%20Methodology%20for%20Standardisation%20for%20Eng%2BHeb%2BLat%2BGrk%2BOthers%20-%20STEPBible.org%20CC%20BY.txt"
    ),
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Download raw TAHOT and versification source files from STEPBible.",
    )
    parser.add_argument(
        "--output-dir",
        default="scripts/tahot/raw",
        help="Directory to store downloaded source files.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Re-download files even if they already exist locally.",
    )
    return parser.parse_args()


def download_file(url: str, destination: pathlib.Path) -> None:
    with urllib.request.urlopen(url) as response:
        destination.write_bytes(response.read())


def main() -> int:
    args = parse_args()
    output_dir = pathlib.Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    for filename, url in RAW_SOURCES.items():
        destination = output_dir / filename
        if destination.exists() and not args.force:
          print(f"skip {destination}")
          continue

        print(f"download {filename}")
        download_file(url, destination)

    print(f"downloaded {len(RAW_SOURCES)} files to {output_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())