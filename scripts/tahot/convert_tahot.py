#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
from collections import defaultdict
from typing import Any


REF_PATTERN = re.compile(
    r"^(?P<book>[1-3]?[A-Za-z]{2,3})\."
    r"(?P<eng_chapter>\d+)\."
    r"(?P<eng_verse>\d+)"
    r"(?:\((?P<heb_chapter>\d+)\.(?P<heb_verse>\d+)\))?"
    r"#(?P<word_index>\d+)=(?P<text_type>[^\t]+)$"
)
STRONGS_PATTERN = re.compile(r"[HG]\d+[A-Z]?")

BOOK_CODE_MAP = {
    "Gen": "GEN",
    "Exo": "EXO",
    "Lev": "LEV",
    "Num": "NUM",
    "Deu": "DEU",
    "Jos": "JOS",
    "Jdg": "JDG",
    "Rut": "RUT",
    "1Sa": "1SA",
    "2Sa": "2SA",
    "1Ki": "1KI",
    "2Ki": "2KI",
    "1Ch": "1CH",
    "2Ch": "2CH",
    "Ezr": "EZR",
    "Neh": "NEH",
    "Est": "EST",
    "Job": "JOB",
    "Psa": "PSA",
    "Pro": "PRO",
    "Ecc": "ECC",
    "Sng": "SNG",
    "Isa": "ISA",
    "Jer": "JER",
    "Lam": "LAM",
    "Ezk": "EZE",
    "Dan": "DAN",
    "Hos": "HOS",
    "Jol": "JOE",
    "Amo": "AMO",
    "Oba": "OBA",
    "Jon": "JON",
    "Mic": "MIC",
    "Nam": "NAH",
    "Hab": "HAB",
    "Zep": "ZEP",
    "Hag": "HAG",
    "Zec": "ZEC",
    "Mal": "MAL",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert raw STEPBible TAHOT TSV files into app JSON assets.",
    )
    parser.add_argument(
        "--input-dir",
        default="scripts/tahot/raw",
        help="Directory containing downloaded raw TAHOT source files.",
    )
    parser.add_argument(
        "--output-dir",
        default="scripts/tahot/output",
        help="Directory to write regenerated TAHOT JSON files.",
    )
    return parser.parse_args()


def is_data_row(line: str) -> bool:
    return bool(line and "\t" in line and REF_PATTERN.match(line.split("\t", 1)[0]))


def extract_strongs(raw: str) -> str | None:
    match = STRONGS_PATTERN.search(raw)
    return match.group(0) if match else None


def sorted_nested_dict(data: dict[str, Any]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for chapter in sorted(data, key=lambda value: int(value)):
        chapter_data = data[chapter]
        if isinstance(chapter_data, dict):
            result[chapter] = {}
            for verse in sorted(chapter_data, key=lambda value: int(value)):
                result[chapter][verse] = chapter_data[verse]
        else:
            result[chapter] = chapter_data
    return result


def main() -> int:
    args = parse_args()
    input_dir = pathlib.Path(args.input_dir)
    output_dir = pathlib.Path(args.output_dir)

    if not input_dir.exists():
        print(f"input directory not found: {input_dir}", file=sys.stderr)
        return 1

    output_dir.mkdir(parents=True, exist_ok=True)

    books: dict[str, dict[str, dict[str, list[dict[str, Any]]]]] = defaultdict(
        lambda: defaultdict(lambda: defaultdict(list))
    )
    versification_map: dict[str, dict[str, dict[str, int]]] = defaultdict(dict)
    row_count = 0

    for path in sorted(input_dir.glob("TAHOT *.txt")):
        with path.open("r", encoding="utf-8") as handle:
            for line in handle:
                line = line.rstrip("\n")
                if not is_data_row(line):
                    continue

                parts = line.split("\t")
                ref_match = REF_PATTERN.match(parts[0])
                if ref_match is None:
                    continue

                upstream_book = ref_match.group("book")
                output_book = BOOK_CODE_MAP.get(upstream_book)
                if output_book is None:
                    continue

                english_chapter = ref_match.group("eng_chapter")
                english_verse = ref_match.group("eng_verse")
                hebrew_chapter = ref_match.group("heb_chapter")
                hebrew_verse = ref_match.group("heb_verse")

                books[output_book][english_chapter][english_verse].append(
                    {
                        "hebrew": parts[1],
                        "translit": parts[2],
                        "gloss": parts[3],
                        "strongs": extract_strongs(parts[4]),
                        "morphology": parts[5],
                    }
                )

                if hebrew_chapter is not None and hebrew_verse is not None:
                    english_key = f"{english_chapter}:{english_verse}"
                    versification_map[output_book][english_key] = {
                        "hebrewChapter": int(hebrew_chapter),
                        "hebrewVerse": int(hebrew_verse),
                    }

                row_count += 1

    for output_book, chapters in books.items():
        ordered = sorted_nested_dict(chapters)
        output_path = output_dir / f"{output_book}_tahot.json"
        output_path.write_text(
            json.dumps(ordered, ensure_ascii=False, separators=(",", ":")),
            encoding="utf-8",
        )

    versification_path = output_dir / "_versification_map.json"
    ordered_versification = {
        book: {
            key: versification_map[book][key]
            for key in sorted(
                versification_map[book],
                key=lambda value: tuple(int(part) for part in value.split(":")),
            )
        }
        for book in sorted(versification_map)
    }
    versification_path.write_text(
        json.dumps(ordered_versification, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(f"converted {row_count} TAHOT rows into {len(books)} book files at {output_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())