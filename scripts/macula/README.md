# Macula Conversion

This directory contains helpers for converting Macula datasets into the compact
LightSword syntax JSON format used by `SyntaxRepository`.

## Greek Lowfat Conversion

The first converter targets Macula Greek lowfat XML:

```bash
python3 scripts/macula/convert_macula_greek.py \
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

This is intentionally a first-pass transform for UI integration. It does not yet
attempt to preserve the full Macula tree structure.