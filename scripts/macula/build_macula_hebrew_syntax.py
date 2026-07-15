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
    'https://api.github.com/repos/Clear-Bible/macula-hebrew/git/trees/main?recursive=1'
)
RAW_BASE_URL = (
    'https://raw.githubusercontent.com/Clear-Bible/macula-hebrew/main/'
)

MACULA_BOOK_TO_OUTPUT_PREFIX = {
    'Gen': 'GEN',
    'Exo': 'EXO',
    'Lev': 'LEV',
    'Num': 'NUM',
    'Deu': 'DEU',
    'Jos': 'JOS',
    'Jdg': 'JDG',
    'Rut': 'RUT',
    '1Sa': '1SA',
    '2Sa': '2SA',
    '1Ki': '1KI',
    '2Ki': '2KI',
    '1Ch': '1CH',
    '2Ch': '2CH',
    'Ezra': 'EZR',
    'Neh': 'NEH',
    'Esth': 'EST',
    'Job': 'JOB',
    'Psa': 'PSA',
    'Pro': 'PRO',
    'Eccl': 'ECC',
    'Sng': 'SNG',
    'Isa': 'ISA',
    'Jer': 'JER',
    'Lam': 'LAM',
    'Ezk': 'EZE',
    'Dan': 'DAN',
    'HOS': 'HOS',
    'Jol': 'JOE',
    'Amos': 'AMO',
    'Obad': 'OBA',
    'Jonah': 'JON',
    'Mic': 'MIC',
    'Nam': 'NAH',
    'Hab': 'HAB',
    'Zep': 'ZEP',
    'Hag': 'HAG',
    'Zec': 'ZEC',
    'Mal': 'MAL',
}


def fetch_tree() -> list[str]:
    with urllib.request.urlopen(TREE_URL) as response:
        payload = json.load(response)
    tree = payload.get('tree', [])
    return [entry['path'] for entry in tree if entry.get('type') == 'blob']


def lowfat_paths(tree_paths: list[str]) -> dict[str, list[str]]:
    paths: dict[str, list[str]] = {}
    for path in tree_paths:
        if not path.startswith('WLC/lowfat/') or not path.endswith('-lowfat.xml'):
            continue
        stem = Path(path).stem
        parts = stem.split('-')
        if len(parts) != 4:
            continue
        _, book_slug, _, suffix = parts
        if suffix != 'lowfat':
            continue
        if book_slug in MACULA_BOOK_TO_OUTPUT_PREFIX:
            paths.setdefault(book_slug, []).append(path)

    for book_slug in paths:
        paths[book_slug].sort()
    return paths


def download_file(url: str, destination: Path) -> None:
    with urllib.request.urlopen(url) as response:
        destination.write_bytes(response.read())


def build_chapter(
    converter: Path,
    xml_path: Path,
    output_path: Path,
) -> None:
    subprocess.run(
        [sys.executable, str(converter), str(xml_path), str(output_path)],
        check=True,
    )


def merge_book_chapters(chapter_json_paths: list[Path]) -> dict[str, dict[str, object]]:
    merged: dict[str, dict[str, object]] = {}

    for chapter_json_path in chapter_json_paths:
        chapter_data = json.loads(chapter_json_path.read_text(encoding='utf-8'))
        if not isinstance(chapter_data, dict):
            continue
        for chapter, verses in chapter_data.items():
            if chapter in merged:
                raise ValueError(f'Duplicate chapter {chapter} while merging {chapter_json_path.name}')
            if not isinstance(verses, dict):
                raise ValueError(f'Unexpected chapter payload in {chapter_json_path.name}: {chapter!r}')
            merged[chapter] = verses

    return dict(sorted(merged.items(), key=lambda item: int(item[0])))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description='Download and build Macula Hebrew lowfat syntax assets for OT books.',
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
        help='Optional Macula book slugs to build (e.g. Gen Exod Ps). Defaults to all supported OT books.',
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
    converter = repo_root / 'scripts/macula/convert_macula_lowfat.py'
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

    temp_dir_obj = tempfile.TemporaryDirectory(prefix='macula-hebrew-')
    temp_dir = Path(temp_dir_obj.name)

    try:
        for book_slug in requested_books:
            output_prefix = MACULA_BOOK_TO_OUTPUT_PREFIX[book_slug]
            output_path = output_dir / f'{output_prefix}_syntax.json'
            chapter_json_paths: list[Path] = []

            for chapter_index, upstream_path in enumerate(available_paths[book_slug], start=1):
                xml_destination = temp_dir / f'{book_slug}-{chapter_index:03d}.xml'
                chapter_output_path = temp_dir / f'{book_slug}-{chapter_index:03d}.json'

                print(f'Downloading {Path(upstream_path).name}...')
                download_file(f'{RAW_BASE_URL}{upstream_path}', xml_destination)

                print(f'Converting {Path(upstream_path).name}...')
                build_chapter(converter, xml_destination, chapter_output_path)
                chapter_json_paths.append(chapter_output_path)

            print(f'Merging {len(chapter_json_paths)} chapters into {output_path.name}...')
            merged_book = merge_book_chapters(chapter_json_paths)
            output_path.write_text(
                json.dumps(merged_book, ensure_ascii=False, indent=2) + '\n',
                encoding='utf-8',
            )

        print(f'Built {len(requested_books)} syntax assets in {output_dir}')
        if args.keep_xml:
            print(f'Kept downloaded XML in {temp_dir}')
            temp_dir_obj = None
    finally:
        if temp_dir_obj is not None:
            temp_dir_obj.cleanup()


if __name__ == '__main__':
    main()