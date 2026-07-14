#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path


TREE_URL = (
    'https://api.github.com/repos/Clear-Bible/macula-greek/git/trees/main?recursive=1'
)
RAW_BASE_URL = (
    'https://raw.githubusercontent.com/Clear-Bible/macula-greek/main/'
)

MACULA_BOOK_TO_OUTPUT_PREFIX = {
    'matthew': 'MATT',
    'mark': 'MARK',
    'luke': 'LUKE',
    'john': 'JOHN',
    'acts': 'ACTS',
    'romans': 'ROM',
    '1corinthians': '1CO',
    '2corinthians': '2CO',
    'galatians': 'GAL',
    'ephesians': 'EPH',
    'philippians': 'PHIL',
    'colossians': 'COL',
    '1thessalonians': '1TH',
    '2thessalonians': '2TH',
    '1timothy': '1TI',
    '2timothy': '2TI',
    'titus': 'TITUS',
    'philemon': 'PHLM',
    'hebrews': 'HEB',
    'james': 'JAS',
    '1peter': '1PE',
    '2peter': '2PE',
    '1john': '1JN',
    '2john': '2JN',
    '3john': '3JN',
    'jude': 'JUDE',
    'revelation': 'REV',
}


def fetch_tree() -> list[str]:
    with urllib.request.urlopen(TREE_URL) as response:
        payload = json.load(response)
    tree = payload.get('tree', [])
    return [entry['path'] for entry in tree if entry.get('type') == 'blob']


def lowfat_paths(tree_paths: list[str]) -> dict[str, str]:
    paths = {}
    for path in tree_paths:
        if not path.startswith('Nestle1904/lowfat/') or not path.endswith('.xml'):
            continue
        stem = Path(path).stem
        _, _, book_slug = stem.partition('-')
        if book_slug in MACULA_BOOK_TO_OUTPUT_PREFIX:
            paths[book_slug] = path
    return paths


def download_file(url: str, destination: Path) -> None:
    with urllib.request.urlopen(url) as response:
        destination.write_bytes(response.read())


def build_book(
    converter: Path,
    xml_path: Path,
    output_path: Path,
) -> None:
    subprocess.run(
        [sys.executable, str(converter), str(xml_path), str(output_path)],
        check=True,
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description='Download and build Macula Greek lowfat syntax assets for NT books.',
    )
    parser.add_argument(
        '--output-dir',
        type=Path,
        default=Path('bible_core/assets/data/syntax'),
        help='Directory where *_syntax.json assets should be written.',
    )
    parser.add_argument(
        '--books',
        nargs='*',
        help='Optional Macula book slugs to build (e.g. ephesians romans 1john). Defaults to all supported NT books.',
    )
    parser.add_argument(
        '--keep-xml',
        action='store_true',
        help='Preserve downloaded XML files in a temporary folder printed at the end.',
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    repo_root = Path(__file__).resolve().parents[2]
    converter = repo_root / 'scripts/macula/convert_macula_greek.py'
    output_dir = (repo_root / args.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    tree_paths = fetch_tree()
    available_paths = lowfat_paths(tree_paths)

    requested_books = args.books or sorted(available_paths)
    missing_books = [book for book in requested_books if book not in available_paths]
    if missing_books:
        raise SystemExit(
            f'Unsupported or unavailable Macula books: {", ".join(sorted(missing_books))}'
        )

    temp_dir_obj = tempfile.TemporaryDirectory(prefix='macula-greek-')
    temp_dir = Path(temp_dir_obj.name)

    try:
        for book_slug in requested_books:
            upstream_path = available_paths[book_slug]
            xml_destination = temp_dir / f'{book_slug}.xml'
            output_prefix = MACULA_BOOK_TO_OUTPUT_PREFIX[book_slug]
            output_path = output_dir / f'{output_prefix}_syntax.json'

            print(f'Downloading {book_slug}...')
            download_file(f'{RAW_BASE_URL}{upstream_path}', xml_destination)

            print(f'Building {output_path.name}...')
            build_book(converter, xml_destination, output_path)

        print(f'Built {len(requested_books)} syntax assets in {output_dir}')
        if args.keep_xml:
            print(f'Kept downloaded XML in {temp_dir}')
            temp_dir_obj = None
    finally:
        if temp_dir_obj is not None:
            temp_dir_obj.cleanup()


if __name__ == '__main__':
    main()