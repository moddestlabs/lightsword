#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import pathlib
import sys


EXPECTED_CHAPTER_COUNTS = {
    "GEN": 50,
    "EXO": 40,
    "LEV": 27,
    "NUM": 36,
    "DEU": 34,
    "JOS": 24,
    "JDG": 21,
    "RUT": 4,
    "1SA": 31,
    "2SA": 24,
    "1KI": 22,
    "2KI": 25,
    "1CH": 29,
    "2CH": 36,
    "EZR": 10,
    "NEH": 13,
    "EST": 10,
    "JOB": 42,
    "PSA": 150,
    "PRO": 31,
    "ECC": 12,
    "SNG": 8,
    "ISA": 66,
    "JER": 52,
    "LAM": 5,
    "EZE": 48,
    "DAN": 12,
    "HOS": 14,
    "JOE": 3,
    "AMO": 9,
    "OBA": 1,
    "JON": 4,
    "MIC": 7,
    "NAH": 3,
    "HAB": 3,
    "ZEP": 3,
    "HAG": 2,
    "ZEC": 14,
    "MAL": 4,
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compare regenerated TAHOT JSON with the currently shipped assets.",
    )
    parser.add_argument(
        "--current-dir",
        default="bible_core/assets/data/tahot",
        help="Directory containing the currently shipped TAHOT JSON assets.",
    )
    parser.add_argument(
        "--regenerated-dir",
        default="scripts/tahot/output",
        help="Directory containing regenerated TAHOT JSON assets.",
    )
    parser.add_argument(
        "--report-file",
        default="scripts/tahot/output/validation_report.json",
        help="Path to write the validation report JSON.",
    )
    return parser.parse_args()


def load_json(path: pathlib.Path) -> dict[str, object]:
    return json.loads(path.read_text(encoding="utf-8"))


def missing_chapters(book_data: dict[str, object], expected_count: int) -> list[int]:
    return [chapter for chapter in range(1, expected_count + 1) if str(chapter) not in book_data]


def main() -> int:
    args = parse_args()
    current_dir = pathlib.Path(args.current_dir)
    regenerated_dir = pathlib.Path(args.regenerated_dir)
    report_file = pathlib.Path(args.report_file)

    if not regenerated_dir.exists():
        print(f"regenerated directory not found: {regenerated_dir}", file=sys.stderr)
        return 1

    report: dict[str, object] = {"books": {}, "summary": {}}
    books_with_improvements = 0
    regenerated_failures: list[str] = []

    for book_code, expected_count in EXPECTED_CHAPTER_COUNTS.items():
        current_path = current_dir / f"{book_code}_tahot.json"
        regenerated_path = regenerated_dir / f"{book_code}_tahot.json"

        current_data = load_json(current_path) if current_path.exists() else {}
        regenerated_data = load_json(regenerated_path) if regenerated_path.exists() else {}

        current_missing = missing_chapters(current_data, expected_count)
        regenerated_missing = missing_chapters(regenerated_data, expected_count)
        fixed = [chapter for chapter in current_missing if chapter not in regenerated_missing]

        if fixed:
            books_with_improvements += 1
        if regenerated_missing:
            regenerated_failures.append(book_code)

        report["books"][book_code] = {
            "currentMissingChapters": current_missing,
            "regeneratedMissingChapters": regenerated_missing,
            "fixedChapters": fixed,
            "currentChapterCount": len(current_data),
            "regeneratedChapterCount": len(regenerated_data),
        }

    report["summary"] = {
        "booksWithImprovements": books_with_improvements,
        "booksStillMissingChapters": regenerated_failures,
    }

    report_file.parent.mkdir(parents=True, exist_ok=True)
    report_file.write_text(json.dumps(report, indent=2), encoding="utf-8")

    print(f"wrote validation report to {report_file}")
    for book_code, book_report in report["books"].items():
        fixed = book_report["fixedChapters"]
        remaining = book_report["regeneratedMissingChapters"]
        if fixed or remaining:
            print(
                f"{book_code}: fixed={fixed if fixed else '[]'} remaining={remaining if remaining else '[]'}"
            )

    return 1 if regenerated_failures else 0


if __name__ == "__main__":
    sys.exit(main())