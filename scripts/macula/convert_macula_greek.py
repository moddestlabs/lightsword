#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import re
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path


XML_NS = '{http://www.w3.org/XML/1998/namespace}'
VERSE_ID_RE = re.compile(r'^[A-Z0-9]+\s+(\d+):(\d+)$')


def local_name(tag: str) -> str:
    if '}' in tag:
        return tag.split('}', 1)[1]
    return tag


def split_refs(value: str | None) -> list[str]:
    if not value:
        return []
    return [item for item in value.split() if item]


def parse_verse_id(value: str | None) -> tuple[int, int] | None:
    if not value:
        return None
    match = VERSE_ID_RE.match(value.strip())
    if not match:
        return None
    return int(match.group(1)), int(match.group(2))


def convert_lowfat(root: ET.Element) -> dict[str, dict[str, dict[str, object]]]:
    verses: dict[tuple[int, int], list[dict[str, object]]] = defaultdict(list)
    clause_word_ids: dict[tuple[int, int], dict[int, list[str]]] = defaultdict(dict)
    next_clause_id: dict[tuple[int, int], int] = defaultdict(int)

    def walk(
        element: ET.Element,
        current_verse: tuple[int, int] | None,
        clause_stack: tuple[int, ...],
    ) -> tuple[int, int] | None:
        name = local_name(element.tag)
        if name == 'milestone' and element.attrib.get('unit') == 'verse':
            current_verse = parse_verse_id(element.attrib.get('id'))

        local_clause_stack = clause_stack
        if (
            name == 'wg'
            and current_verse is not None
            and element.attrib.get('class') == 'cl'
        ):
            clause_id = next_clause_id[current_verse]
            next_clause_id[current_verse] += 1
            clause_word_ids[current_verse][clause_id] = []
            local_clause_stack = clause_stack + (clause_id,)

        if name == 'w' and current_verse is not None:
            xml_id = element.attrib.get(f'{XML_NS}id') or element.attrib.get('xml:id')
            if xml_id:
                clause_id = local_clause_stack[-1] if local_clause_stack else None
                verses[current_verse].append(
                    {
                        'xmlId': xml_id,
                        'tokenText': (element.text or '').strip(),
                        'role': element.attrib.get('role'),
                        'type': element.attrib.get('type'),
                        'gender': element.attrib.get('gender'),
                        'referentIds': split_refs(element.attrib.get('referent')),
                        'subjectIds': split_refs(element.attrib.get('subjref')),
                        'clauseId': clause_id,
                    }
                )
                if clause_id is not None:
                    clause_word_ids[current_verse][clause_id].append(xml_id)

        for child in element:
            current_verse = walk(child, current_verse, local_clause_stack)

        return current_verse

    current_verse: tuple[int, int] | None = None
    for child in root:
        current_verse = walk(child, current_verse, ())

    book_data: dict[str, dict[str, dict[str, object]]] = {}
    for (chapter, verse), words in sorted(verses.items()):
        id_to_index = {
            word['xmlId']: index for index, word in enumerate(words)
        }
        annotations = []
        arcs = []
        spans = []
        seen_arcs: set[tuple[int, int, str]] = set()
        seen_spans: set[tuple[int, int, int, str]] = set()
        clause_ranges = {}

        for clause_id, xml_ids in clause_word_ids[(chapter, verse)].items():
            indices = [id_to_index[xml_id] for xml_id in xml_ids if xml_id in id_to_index]
            if indices:
                clause_ranges[clause_id] = (min(indices), max(indices))

        for index, word in enumerate(words):
            referent_index = None
            referent_span = None
            for referent_id in word['referentIds']:
                if referent_id in id_to_index:
                    referent_index = id_to_index[referent_id]
                    arc_key = (index, referent_index, 'referent')
                    if arc_key not in seen_arcs:
                        arcs.append(
                            {
                                'fromWordIndex': index,
                                'toWordIndex': referent_index,
                                'kind': 'referent',
                                'label': 'referent',
                            }
                        )
                        seen_arcs.add(arc_key)

                    referent_word = words[referent_index]
                    referent_clause_id = referent_word.get('clauseId')
                    source_clause_id = word.get('clauseId')
                    if (
                        referent_clause_id is not None
                        and referent_clause_id != source_clause_id
                        and referent_clause_id in clause_ranges
                    ):
                        referent_span = clause_ranges[referent_clause_id]
                        span_key = (
                            index,
                            referent_span[0],
                            referent_span[1],
                            'referent',
                        )
                        if span_key not in seen_spans:
                            spans.append(
                                {
                                    'fromWordIndex': index,
                                    'startWordIndex': referent_span[0],
                                    'endWordIndex': referent_span[1],
                                    'kind': 'referent',
                                    'label': 'referent clause',
                                }
                            )
                            seen_spans.add(span_key)
                    break

            annotation = {
                'wordIndex': index,
                'tokenId': word['xmlId'],
                'tokenText': word['tokenText'],
            }
            if word['role']:
                annotation['role'] = word['role']
            if referent_index is not None:
                annotation['referentWordIndex'] = referent_index
            if referent_span is not None:
                annotation['referentSpanStartWordIndex'] = referent_span[0]
                annotation['referentSpanEndWordIndex'] = referent_span[1]

            head_index = None
            for subject_id in word['subjectIds']:
                if subject_id in id_to_index:
                    head_index = id_to_index[subject_id]
                    arc_key = (head_index, index, 'subject')
                    if arc_key not in seen_arcs:
                        arcs.append(
                            {
                                'fromWordIndex': head_index,
                                'toWordIndex': index,
                                'kind': 'subject',
                                'label': 'subject',
                            }
                        )
                        seen_arcs.add(arc_key)
                    break
            if head_index is not None:
                annotation['headWordIndex'] = head_index

            annotations.append(annotation)

        chapter_key = str(chapter)
        verse_key = str(verse)
        book_data.setdefault(chapter_key, {})[verse_key] = {
            'words': annotations,
            'arcs': arcs,
            'spans': spans,
        }

    return book_data


def main() -> None:
    parser = argparse.ArgumentParser(
        description='Convert Macula Greek lowfat XML into compact LightSword syntax JSON.',
    )
    parser.add_argument('input', type=Path, help='Path to Macula lowfat XML file')
    parser.add_argument('output', type=Path, help='Path to output JSON file')
    args = parser.parse_args()

    tree = ET.parse(args.input)
    converted = convert_lowfat(tree.getroot())

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(converted, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )


if __name__ == '__main__':
    main()