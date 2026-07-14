# Data Licenses

This document tracks all open-source Bible texts, lexicons, and morphological data used in LightSword, along with their licenses and attribution requirements.

## Currently Integrated Data Sources

### STEPBible.org Lexicon Data ✅

**Status**: Integrated and Active

**Content**: 
- Strong's Hebrew Lexicon (9,345 entries)
- Strong's Greek Lexicon (10,847 entries)
- Hebrew/Greek lemmas (original language text)
- Transliterations
- Glosses (short definitions)
- Full definitions
- Basic morphology codes

**License**: Creative Commons Attribution 4.0 International (CC BY 4.0)

**Source**: https://github.com/STEPBible/STEPBible-Data
- TBESH - Translators Brief lexicon of Extended Strongs for Hebrew
- TBESG - Translators Brief lexicon of Extended Strongs for Greek

**Files in Repository**:
- `bible_core/assets/data/lexicon/strongs_hebrew.json` (3.0 MB)
- `bible_core/assets/data/lexicon/strongs_greek.json` (4.1 MB)
- `bible_core/assets/data/lexicon/LICENSE.txt`

**Attribution Requirement**: 
"Contains lexicon data from STEPBible.org, used under CC BY 4.0 license. Based on work at Tyndale House Cambridge."

**Compliance**: 
- ✅ Free redistribution permitted
- ✅ Commercial use allowed
- ✅ Modification allowed
- ✅ Attribution provided in LICENSE.txt and app UI (to be implemented)

---

### Open Scriptures Hebrew Bible (OSHB) ✅

**Status**: Integrated and Active

**Content**:
- Complete Hebrew Old Testament (39 books)
- Full Hebrew text with vowel points and cantillation marks
- Verse-by-verse alignment
- Based on Westminster Leningrad Codex (WLC)

**License**: Creative Commons Attribution 4.0 International (CC BY 4.0)

**Source**: https://github.com/openscriptures/morphhb
- Open Scriptures Hebrew Bible project
- Westminster Leningrad Codex

**Files in Repository**:
- `bible_core/assets/data/hebrew/*_hebrew.json` (5.8 MB total, 39 files)
- `bible_core/assets/data/hebrew/LICENSE.txt`

**Attribution Requirement**:
"Contains Hebrew text from the Open Scriptures Hebrew Bible (OSHB), used under CC BY 4.0 license. Based on the Westminster Leningrad Codex, maintained by the J. Alan Groves Center for Advanced Biblical Research."

**Compliance**:
- ✅ Free redistribution permitted
- ✅ Commercial use allowed
- ✅ Modification allowed
- ✅ Attribution provided in LICENSE.txt and app UI (to be implemented)

---

### TAHOT - Translators Amalgamated Hebrew Old Testament ✅

**Status**: Integrated and Active

**Content**:
- Complete Hebrew Old Testament (39 books)
- Vocalized Hebrew text with cantillation marks
- Word-by-word transliteration
- English glosses for every word
- Disambiguated Strong's numbers (extended format)
- Full morphological analysis (ETCBC-based)
- Prefix/suffix breakdown
- Based on Leningrad Codex via Westminster/OpenScriptures

**License**: Creative Commons Attribution 4.0 International (CC BY 4.0)

**Source**: https://github.com/STEPBible/STEPBible-Data
- Translators Amalgamated Hebrew OT (TAHOT)
- Created by Tyndale House Cambridge, curated by STEPBible.org

**Files in Repository**:
- `bible_core/assets/data/tahot/*_tahot.json` (31.7 MB total, 39 files)
- `bible_core/assets/data/tahot/LICENSE.txt`

**Data Structure**: Each word includes:
- Hebrew text with vocalization (בְּ/רֵאשִׁ֖ית)
- Transliteration (be./re.Shit)
- English gloss (in/ beginning)
- Strong's number (H7225G - disambiguated)
- Morphology code (HR/Ncfsa)

**Attribution Requirement**:
"Contains TAHOT (Translators Amalgamated Hebrew OT) data from STEPBible.org, used under CC BY 4.0 license. Data created by www.STEPBible.org based on work at Tyndale House Cambridge."

**Compliance**:
- ✅ Free redistribution permitted
- ✅ Commercial use allowed
- ✅ Modification allowed
- ✅ Attribution provided in LICENSE.txt
- ✅ More comprehensive than basic BHS (includes transliteration & glosses)

---

### TAGNT - Translators Amalgamated Greek New Testament ✅

**Status**: Integrated and Active

**Content**:
- Complete Greek New Testament (27 books)
- Greek text with accents and breathing marks from multiple editions (NA27/28, TR, SBL, TH, Byz, WH, Treg)
- Word-by-word transliteration
- English glosses for every word
- Disambiguated Strong's numbers (extended format)
- Full morphological analysis for all words
- Based on scholarly comparison of all major Greek editions

**License**: Creative Commons Attribution 4.0 International (CC BY 4.0)

**Source**: https://github.com/STEPBible/STEPBible-Data
- Translators Amalgamated Greek NT (TAGNT)
- Created by Tyndale House Cambridge, curated by STEPBible.org

**Files in Repository**:
- `bible_core/assets/data/greek/*_tagnt.json` (23 MB total, 27 files)
- `bible_core/assets/data/greek/LICENSE.txt`

**Data Structure**: Each word includes:
- Greek text with accents (Βίβλος)
- Transliteration (Biblos)
- English gloss ([The] book)
- Strong's number (G0976 - disambiguated)
- Morphology code (N-NSF)

**Attribution Requirement**:
"Contains TAGNT (Translators Amalgamated Greek NT) data from STEPBible.org, used under CC BY 4.0 license. Data created by www.STEPBible.org based on work at Tyndale House Cambridge."

**Compliance**:
- ✅ Free redistribution permitted
- ✅ Commercial use allowed
- ✅ Modification allowed
- ✅ Attribution provided in LICENSE.txt
- ✅ Comprehensive coverage of all major Greek text editions
- ✅ Parallel structure to TAHOT for consistency

---

## Candidates Under Evaluation

### Hebrew Old Testament
- **Open Scriptures Hebrew Bible (OSHB)**
  - License: Creative Commons Attribution 4.0 International
  - URL: https://github.com/openscriptures/morphhb
  - Includes: Morphological tagging, Strong's numbers
  - Attribution: Required

### Greek New Testament
- **Berean Interlinear Bible / Berean Study Bible**
  - License: Public Domain (CC0 or similar - verify exact terms)
  - URL: https://berean.bible/
  - Includes: Interlinear Greek, Strong's tagging
  - Attribution: Requested but not required (verify)

- **STEPBible Data (Tyndale House)**
  - License: Creative Commons Attribution 4.0 International (verify exact version)
  - URL: https://github.com/STEPBible/STEPBible-Data
  - Includes: Tagged Greek/Hebrew with morphology
  - Attribution: Required

### SWORD Project Modules
- **Format**: OSIS/ThML-based modules
- **License**: Varies by module; many are public domain
- **URL**: https://crosswire.org/sword/modules/
- **Note**: Each module has its own license; must check individually

### Strong's Concordance
- **Content**: Public domain (original work is very old)
- **Digitization License**: Depends on specific dataset used
- **Candidates**:
  - OpenBible.info Strong's data (verify license)
  - Other open JSON/XML packages (TBD)

## Required Before Public Deployment

- [ ] Finalize data source selections
- [ ] Document exact license for each source
- [ ] Add in-app attribution screen
- [ ] Verify App Store / Play Store compliance
- [ ] Include license files in repository

## Notes

All data must:
- Be freely redistributable
- Allow commercial use (even though LightSword is free, app stores may classify it commercially)
- Be compatible with static hosting (GitHub Pages)
- Not require proprietary APIs or paywalled access
