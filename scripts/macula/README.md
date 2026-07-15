# Macula Conversion

This directory contains helpers for converting Macula datasets into the compact
LightSword syntax JSON format used by `SyntaxRepository`.

## Lowfat Conversion

The lowfat converter currently used by the build scripts accepts both Macula
Greek and Macula Hebrew lowfat XML and emits the compact syntax JSON consumed by
`SyntaxRepository`.

Example conversion:

```bash
python3 scripts/macula/convert_macula_lowfat.py \
  /path/to/10-ephesians.xml \
  bible_core/assets/data/syntax/EPH_syntax.json
```

Current scope:
- verse-local word indexing
- word annotations with `role`
- `referent` links
- `subjref` links mapped to `subject` arcs

## Batch NT Build

To build the supported Macula Greek NT books directly from the upstream
repository into app assets:

```bash
python3 scripts/macula/build_macula_greek_syntax.py
```

Optional subset build:

```bash
python3 scripts/macula/build_macula_greek_syntax.py --books ephesians romans john
```

## Batch OT Build

To build the supported Macula Hebrew OT books directly from the upstream
repository into app assets:

```bash
python3 scripts/macula/build_macula_hebrew_syntax.py
```

Optional subset build:

```bash
python3 scripts/macula/build_macula_hebrew_syntax.py --books Gen Exod Ps
```

This is intentionally a first-pass transform for UI integration. It does not yet
attempt to preserve the full Macula tree structure.