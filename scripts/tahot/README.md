# TAHOT Regeneration

These scripts rebuild the app's TAHOT JSON assets from raw STEPBible TSV sources.

The important normalization rule is:

- Use the English-side reference as the runtime key.
- Preserve the Hebrew-side reference in the generated versification sidecar.

This matters for chapters like Genesis 32 and Exodus 8 where raw TAHOT contains
dual references such as `Gen.32.1(32.2)#01` and `Exo.8.1(7.26)#01`.

## Usage

Download upstream sources:

```bash
python3 scripts/tahot/download_tahot_sources.py
```

Convert raw TAHOT into app-shaped JSON:

```bash
python3 scripts/tahot/convert_tahot.py
```

Compare regenerated output with the currently shipped assets:

```bash
python3 scripts/tahot/validate_tahot.py
```

## Outputs

- `scripts/tahot/raw/` - downloaded upstream TSV files and versification data
- `scripts/tahot/output/*_tahot.json` - regenerated per-book JSON assets
- `scripts/tahot/output/_versification_map.json` - English-to-Hebrew verse mapping
- `scripts/tahot/output/validation_report.json` - comparison against current assets

The scripts do not overwrite `bible_core/assets/data/tahot/` automatically.
Review the validation report first.