# Bible Bento UI/UX Design Guide

> **Design Philosophy**: Minimalist, reading-focused, gesture-driven, and content-first. Every UI element serves the purpose of enhancing the reading and study experience without getting in the way.

---

## Core Design Principles

### 1. **Reading-First Philosophy**
- The reading view is the entry point and primary interface
- Maximum screen real estate devoted to scripture text
- Minimal chrome/UI elements during reading
- Clean, distraction-free environment

### 2. **Gesture-Driven Navigation**
- Scroll up past verse 1 to reveal search bar
- Tap chapter reference to navigate chapters
- Natural, intuitive interactions
- Hidden features revealed contextually

### 3. **Persistent Context**
- App remembers last reading position (book, chapter, verse)
- Always returns to where user left off
- Translation preference persists
- Reading history automatically tracked

### 4. **Progressive Disclosure**
- Essential tools visible by default
- Advanced features accessible but not intrusive
- Context-appropriate feature exposure

---

## Color Palette & Typography

### Colors
- **Background**: Pure white (`#FFFFFF`)
- **Primary Text**: Black (`#000000`)
- **Accent Blue**: Used for interactive elements, verse numbers, abbreviations (`#007AFF` iOS blue)
- **Secondary Text**: Gray (`#8E8E93` for labels/metadata)
- **Highlights**: Orange/brown for translations (`#FF9500` style)
- **Error/Alert**: Red (`#FF3B30`)

### Typography
- **Reading Text**: 
  - Large, highly readable font (appears to be system font)
  - Generous line height (1.5-1.8)
  - Left-aligned
  - Comfortable font size (18-20pt)
- **Verse Numbers**: 
  - Blue, smaller than body text
  - Left margin alignment
  - Clear visual separation from text
- **Navigation/UI**: 
  - System font (San Francisco on iOS)
  - Standard iOS weight hierarchy

---

## Layout Structure

### 1. Main Reading View (Entry Point)

```
┌─────────────────────────────────────┐
│ < Jon 1 >    BibleBento    NET  📖 │ ← Header (navigation)
├─────────────────────────────────────┤
│ 1  The LORD said to Jonah son      │
│    of Amittai,                      │
│                                      │
│ 2  "Go immediately to Nineveh,     │
│    that large capital city, and     │
│    announce judgment...             │
│                                      │
│ 3  Instead, Jonah immediately      │
│    headed off to Tarshish to       │
│    escape from the commission...    │
│                                      │
│ [Continue reading...]               │
│                                      │
│                                      │
└─────────────────────────────────────┘
```

**Key Elements**:
- **Top Left**: `< Book Chapter >` (tappable chapter navigation)
- **Center**: App branding or current context
- **Top Right**: Translation selector + Bookmark icon
- **Left Margin**: Verse numbers in blue
- **Body**: Scripture text with generous padding

**Spacing**:
- Top/bottom padding: 16-24px
- Side margins: 16-20px
- Between verses: 12-16px
- Verse number to text: 8-12px

### 2. Search Reveal (Gesture-Based)

**Trigger**: Scroll up when at top of chapter (verse 1)

```
┌─────────────────────────────────────┐
│ ┌─────────────────────────────────┐│
│ │  🔍 Search NET                  ││ ← Search bar slides in
│ └─────────────────────────────────┘│
├─────────────────────────────────────┤
│ [Reading content slightly dimmed]   │
│                                      │
```

**Search Bar**:
- Rounded rectangle (8-12px radius)
- Light gray background (`#F2F2F7`)
- Placeholder text: "Search [TRANSLATION]"
- Animates in from top
- Search icon on left
- Focus automatically when revealed

**Behavior**:
- Word-based search (find occurrences throughout Bible)
- Results show verse references
- Searches saved to History tab
- Can search within current translation

### 3. Book Selection

```
┌─────────────────────────────────────┐
│ OT  NT         Jon         Font Done│ ← Tabs + Title + Actions
├─────────────────────────────────────┤
│ Genesis                       Gen ⓘ │
│ Exodus                        Exo ⓘ │
│ Leviticus                     Lev ⓘ │
│ Numbers                       Num ⓘ │
│ [Current: Jonah]  ← HIGHLIGHTED     │
│ Micah                         Mic ⓘ │
│ Nahum                         Nah ⓘ │
└─────────────────────────────────────┘
```

**Key Elements**:
- **OT/NT Tabs**: Testament switcher (top left)
- **Current Book**: Centered title
- **Font**: Typography settings
- **Done**: Dismiss action
- **List Items**: 
  - Full book name (left, black)
  - Abbreviation (right, gray)
  - Info icon (ⓘ) for book details
  - Current book highlighted with gray background

**Interaction**:
- Tap book name to select
- Swipe to scroll through books
- Info icon for book metadata/introduction

### 4. Bible Version Selection

```
┌─────────────────────────────────────┐
│ Credits         Version       Cancel│
├─────────────────────────────────────┤
│ ASV    American Standard Version    │
│ BGB    Berean Greek Bible           │
│ BHS    Biblia Hebraica Stuttgart... │
│ BLB    Berean Literal Bible         │
│ BSB    Berean Study Bible           │
│ KJV    King James Version           │
└─────────────────────────────────────┘
```

**Key Elements**:
- "Version" title centered
- "Credits" (left) and "Cancel" (right)
- Two-column list:
  - Abbreviation (blue, bold, left)
  - Full name (gray, right)
- Supports multiple languages
- Scrollable list

### 5. History/Favorites/Search Tabs

```
┌─────────────────────────────────────┐
│ [History] [Favourite] [Search]      │ ← Segmented Control
├─────────────────────────────────────┤
│ 7/2/26, 5:15:20 AM   NET  Jon 1:1  │
│ 7/2/26, 5:01:21 AM   NET  Jon 1:1  │
│ 7/2/26, 5:01:14 AM   NET  Jon 1:1  │
│ 6/14/26, 10:26:58 AM NET  Jon 1:2  │
│ 6/9/26, 11:46:57 AM  NET  Mal 1:2  │
├─────────────────────────────────────┤
│ Cancel    Add Jon 1:1    Clear All  │
└─────────────────────────────────────┘
```

**Key Elements**:
- **Segmented Control**: Three tabs (History, Favourite, Search)
- **List Format**: 
  - Timestamp (gray, left)
  - Translation (orange/brown, center)
  - Reference (red/maroon, right)
- **Bottom Actions**:
  - "Cancel" (left)
  - "Add [Reference]" (center, context-dependent)
  - "Clear All" (right)

**Purpose**:
- History: Track all readings with timestamps
- Favourite: Bookmarked verses
- Search: Past search history

### 6. Interlinear/Morphology View

```
┌─────────────────────────────────────┐
│ < Back          Jon 1:1       ☰ 📝 │
├─────────────────────────────────────┤
│ ASV  Now the word of Jehovah came  │
│      unto Jonah...                  │
│                                      │
│ BHS  וַיְהִי דְּבַר־יְהוָה אֶל־יוֹנָה│
│                                      │
│ ERV  Now the word of the LORD...   │
│                                      │
│ KJV  Now the word of the LORD...   │
├─────────────────────────────────────┤
│      וַ                    ו        │
│      w'a               and          │
│      H conjunction                  │
│                                      │
│      יְהִי                הָיָה      │
│      yᵉhî,i              be         │
│      H verb, qal, wayyiqtol...      │
└─────────────────────────────────────┘
```

**Key Elements**:
- Multiple translations shown in parallel
- Translation abbreviation (blue) precedes each
- Original language text (Hebrew/Greek)
- Word-by-word breakdown:
  - Original text (Hebrew/Greek, maroon)
  - Transliteration (gray)
  - English meaning (red)
  - Morphology (purple - part of speech, parsing)
  - "H" marker for Hebrew (could be "G" for Greek)

**Bottom Navigation**:
- Translation selector
- Word navigation ("AND" indicates current word)
- Search icon
- Share icon

### 7. Study Tools Menu

```
┌─────────────────────────────────────┐
│ 🔤  Comparison & Morphology      ✓ │
│ 🔗  Cross-Reference                 │
│ 📋  Share Multiple Verses           │
│ 📚  Parallel Bibles                 │
│ 💬  Bible Topics                    │
│ 📍  Bible Locations & Maps          │
│ 👥  Bible People                    │
│ 📊  Bible Timelines                 │
│ 🏛️  Bible Encyclopedia             │
│ 📺  Tutorial - Basics               │
│ 📺  Tutorials - Bible Maps          │
│ 📖  User Manual                     │
│ ✉️  Contact Eliran Wong            │
├─────────────────────────────────────┤
│ Credits                       Done  │
└─────────────────────────────────────┘
```

**Key Elements**:
- Icon-driven menu
- Clear, descriptive labels
- Checkmark indicates current active tool
- Rich study features:
  - Comparison tools
  - Cross-references
  - Parallel Bible viewing
  - Educational content (topics, maps, people, timelines)
  - Encyclopedia
  - Tutorials
  - Help/support

---

## Navigation Patterns

### Primary Navigation Hierarchy

1. **Main Reading View** (Entry point)
   ↓
2. **Chapter Navigation** (horizontal swipe or tap `< Book Ch >`)
   ↓
3. **Book Selection** (tap book name in header)
   ↓
4. **Bible Selection** (tap translation abbreviation)

### Secondary Navigation

- **Search**: Scroll up past verse 1 to reveal
- **Study Tools**: Accessible from reader (menu icon)
- **History**: Tab-based interface
- **Bookmarks**: Icon in header

### Gesture Conventions

- **Swipe Left/Right**: Navigate chapters
- **Scroll Up (at top)**: Reveal search
- **Tap Reference**: Chapter picker
- **Tap Translation**: Version picker
- **Tap Text**: Selection/highlighting (context menu)
- **Long Press**: Additional options

---

## Key UI Components

### 1. Segmented Control (iOS Standard)
- Used for: History/Favourite/Search tabs
- Selected state: Blue background, white text
- Unselected: Clear background, blue text
- Rounded corners, thin border

### 2. List Cells
- **Simple List**: Single line, chevron right for navigation
- **Detail List**: Left text (blue), right text (gray), info icon
- **History List**: Multi-column (timestamp, translation, reference)
- Separator lines between items
- Subtle gray background for alternating rows or selected state

### 3. Navigation Bar (Top Header)
- **Pattern**: [Left Action] [Title] [Right Action(s)]
- Height: Standard iOS (44pt)
- Transparent or white background
- Blue accent for interactive elements
- Multiple right actions possible (translation + bookmark)

### 4. Buttons
- **Primary**: iOS standard button style (blue text)
- **Destructive**: Red text ("Clear All")
- **Disabled**: Gray text
- No background fills, text-only
- Clear tap targets (44x44pt minimum)

### 5. Search Bar
- Rounded rectangle (full width minus margins)
- Light gray background
- Search icon left
- Placeholder text
- Clear button (x) when text entered

---

## Reading Experience Optimizations

### Text Rendering
- **High Contrast**: Black text on pure white
- **Generous Line Height**: 1.5-1.8x
- **Optimal Line Length**: ~60-70 characters
- **Paragraph Spacing**: Clear verse separation
- **Verse Numbers**: Non-intrusive, left-aligned

### Scrolling Behavior
- **Smooth Scrolling**: No pagination, continuous flow
- **Natural Momentum**: iOS-native scroll physics
- **Context Preservation**: Verse numbers always visible in margin
- **Intelligent Search Reveal**: Only at top of chapter

### Focus & Attention
- **Minimal Chrome**: UI fades away during reading
- **No Ads/Distractions**: Pure content focus
- **White Space**: Generous padding and margins
- **Single Column**: Optimized for mobile screens

---

## Feature Implementation Priority

### Phase 1: Core Reading Experience
1. ✅ Main reading view with clean layout
2. ✅ Verse-by-verse rendering
3. ✅ Chapter navigation (< Book Ch >)
4. ✅ Persistent reading position
5. ⚠️ Translation selector
6. ⚠️ Scroll-to-reveal search

### Phase 2: Navigation & Discovery
7. ⚠️ Book selection interface
8. ⚠️ Bible version selection
9. ⚠️ Search functionality
10. ⚠️ History tracking
11. ⚠️ Bookmark system

### Phase 3: Study Tools
12. 🔲 Interlinear/morphology view
13. 🔲 Parallel Bible comparison
14. 🔲 Cross-references
15. 🔲 Study resources menu

### Phase 4: Advanced Features
16. 🔲 Bible topics
17. 🔲 Maps & locations
18. 🔲 People & timelines
19. 🔲 Encyclopedia integration

**Legend**: ✅ Complete | ⚠️ In Progress | 🔲 Not Started

---

## Screen-by-Screen Specifications

### Reader Screen (Primary)

**Layout**:
- Status bar: System default
- Navigation bar: 44pt height
  - Left: Chapter nav (< Book Ch >)
  - Center: App name or context
  - Right: Translation + Bookmark icon
- Content area: Full remaining height
  - Top padding: 16px
  - Side margins: 16-20px
  - Bottom padding: 16px
- Verse numbers: Left column, 40px width
- Text: Remaining width after verse column

**Colors**:
- Background: `#FFFFFF`
- Text: `#000000`
- Verse numbers: `#007AFF`
- Navigation items: `#007AFF`

**Typography**:
- Body text: System font, 18-20pt, weight 400
- Verse numbers: System font, 14-16pt, weight 600
- Navigation: System font, 17pt, weight 400

**Interactions**:
- Tap reference: Open chapter picker
- Tap translation: Open version picker
- Tap bookmark: Toggle bookmark
- Scroll up at top: Reveal search
- Swipe left/right: Previous/next chapter (optional)
- Long press text: Selection/highlight menu

### Search Interface

**Trigger**: Scroll up when at verse 1

**Layout**:
- Search bar slides in from top
- Positioned below navigation bar
- Full width minus 16px margins
- Height: 44px
- Rounded corners: 10px

**Behavior**:
- Animate in: 0.3s ease-out
- Background dims slightly (overlay: rgba(0,0,0,0.1))
- Auto-focus keyboard
- Real-time search or search on submit
- Results overlay reading view

**Search Results**:
- Modal or slide-up panel
- List of matching verses
- Format: [Reference] [Preview text...]
- Tap to navigate to verse
- Save to search history

### Book Selection

**Layout**:
- Full screen modal
- OT/NT segmented control: Top left
- Current book title: Center
- Font button: Top right
- Done button: Top right (after Font)
- List: Scrollable, full height

**List Item**:
- Height: 44pt
- Left text (book name): Black, 17pt
- Right text (abbreviation): Gray, 17pt
- Info icon: 20x20pt, far right
- Selected state: Gray background (`#F2F2F7`)

**Interactions**:
- Tap OT/NT: Switch testament
- Tap book: Select and dismiss
- Tap info icon: Show book introduction
- Tap Font: Typography settings
- Tap Done: Dismiss without selection

### Version Selection

**Layout**:
- Full screen modal
- "Version" title: Centered
- "Credits" button: Top left
- "Cancel" button: Top right
- Scrollable list: Full height

**List Item**:
- Height: 44pt minimum (wrap if needed)
- Left text (abbreviation): Blue, 17pt, bold
- Right text (full name): Gray, 17pt, regular
- Support for non-Latin scripts

**Interactions**:
- Tap version: Select and dismiss
- Tap Credits: Show version credits/license
- Tap Cancel: Dismiss without selection

### History/Favorites

**Layout**:
- Segmented control: Top, full width
  - History | Favourite | Search
- List: Scrollable, full height
- Bottom toolbar:
  - Cancel (left)
  - Add [Reference] (center, context-aware)
  - Clear All (right)

**List Item**:
- Height: 44pt
- Left: Timestamp (gray, 14pt)
- Center: Translation (orange/brown, 16pt, bold)
- Right: Reference (red, 16pt, bold)

**Interactions**:
- Tap item: Navigate to verse
- Swipe left: Delete item
- Tap Clear All: Confirmation dialog
- Tap Add: Bookmark current reference

---

## Accessibility Considerations

### iOS Standards
- VoiceOver support for all interactive elements
- Dynamic Type support (user font size preferences)
- High contrast mode support
- Minimum touch target: 44x44pt
- Color not sole indicator (use icons + text)

### Reading-Specific
- Adjustable font size (Font button in Book Selection)
- Sufficient contrast ratios (AA or AAA)
- Clear visual hierarchy
- Logical tab order for keyboard navigation

---

## Animation & Transitions

### Principles
- Subtle, purposeful animations
- iOS-native feel (120Hz on ProMotion devices)
- Never gratuitous
- Respect "Reduce Motion" setting

### Key Animations
- **Search Reveal**: Slide down from top (0.3s ease-out)
- **Modal Presentation**: Standard iOS sheet (0.3s)
- **List Selection**: Immediate feedback (0.1s)
- **Chapter Navigation**: Optional page-turn or slide
- **Scroll**: Native iOS momentum physics

---

## Dark Mode Support

While screenshots show light mode, consider:

### Color Adaptations
- Background: `#000000` (true black for OLED)
- Text: `#FFFFFF`
- Verse numbers: `#0A84FF` (lighter blue)
- Secondary text: `#98989D`
- Backgrounds: `#1C1C1E`, `#2C2C2E`

### Semantic Colors
Use iOS semantic colors where possible:
- `label` / `secondaryLabel`
- `systemBackground` / `secondarySystemBackground`
- `systemBlue`

This ensures automatic dark mode support.

---

## Implementation Notes

### Current State Analysis
Based on the codebase:
- ✅ Basic reading view implemented
- ✅ Verse rendering working
- ⚠️ Navigation needs refinement
- ⚠️ Search not yet implemented
- 🔲 Study tools not yet started

### Immediate Priorities
1. Refine reader layout to match spacing/typography
2. Implement chapter navigation UI (`< Book Ch >`)
3. Add translation selector
4. Implement scroll-to-reveal search
5. Create book selection modal

### Technical Considerations
- **State Management**: Track current book/chapter/verse/translation
- **Persistence**: SharedPreferences for reading position
- **Performance**: Efficient list rendering for long chapters
- **Gestures**: Flutter GestureDetector for scroll reveal
- **Animations**: Flutter AnimatedContainer, SlideTransition

---

## Design Rationale

### Why This Works

1. **Minimal Cognitive Load**: 
   - Primary task (reading) has zero distractions
   - Secondary tasks hidden until needed

2. **Muscle Memory**: 
   - Standard iOS patterns (segmented control, lists, navigation bar)
   - Familiar gestures (scroll, tap, swipe)

3. **Progressive Disclosure**:
   - Basic users: Just read
   - Advanced users: Discover features naturally

4. **Respect for Content**:
   - Scripture is paramount
   - UI serves content, never competes

5. **Mobile-First**:
   - Optimized for one-handed use
   - Touch targets appropriately sized
   - Gestures reduce UI chrome

---

## Design System Components

### Reusable Patterns

1. **AppNavigationBar**
   - Three-slot layout (left, center, right)
   - Transparent or themed background
   - Standard height (44pt)

2. **VerseNumberedText**
   - Left margin verse numbers
   - Body text with proper spacing
   - Selectable/highlightable

3. **ReferenceSelector**
   - Format: "< Book Chapter >"
   - Tappable, opens picker
   - Shows current context

4. **TranslationBadge**
   - Abbreviation display
   - Tappable, opens version list
   - Consistent styling

5. **SearchBar**
   - Rounded, gray background
   - Search icon + placeholder
   - Animated reveal

6. **ListItemCell**
   - Flexible content slots
   - Separator lines
   - Selection states

---

## Resources & Assets Needed

### Icons
- Bookmark (outline + filled states)
- Search/magnifying glass
- Info icon (circled "i")
- Back chevron
- Forward chevron
- Menu/hamburger
- Share icon
- Note/pencil icon
- Study tool icons (maps, people, topics, etc.)

### Fonts
- System font (San Francisco on iOS)
- Optional: Custom reading font support

### Colors
- Define semantic color palette
- Light mode values
- Dark mode values
- Accent colors for different content types

---

## Testing Checklist

### Visual Parity
- [ ] Reader layout matches spacing/margins
- [ ] Typography sizes match
- [ ] Colors match palette
- [ ] Verse numbers aligned correctly
- [ ] Navigation bar elements positioned correctly

### Interaction Parity
- [ ] Scroll-to-reveal search works at verse 1
- [ ] Chapter navigation accessible and intuitive
- [ ] Book selection modal matches design
- [ ] Version selection matches design
- [ ] History list format matches

### Performance
- [ ] Smooth scrolling (60fps minimum)
- [ ] Fast chapter loading
- [ ] Responsive interactions
- [ ] No jank or stutter

### Accessibility
- [ ] VoiceOver reads content correctly
- [ ] Dynamic Type works
- [ ] Touch targets meet minimum size
- [ ] Color contrast meets standards

---

## Future Considerations

### Tablet/iPad Support
- Two-column layout for larger screens
- Persistent navigation sidebar
- Parallel Bible side-by-side

### Customization
- Font family selection
- Font size adjustment
- Line spacing options
- Theme variations beyond light/dark

### Enhanced Study
- Inline cross-references
- Hover/tap for word definitions
- Highlighting and notes
- Social/sharing features

---

## Conclusion

Bible Bento's UI/UX excellence stems from:
1. **Clarity of purpose**: Reading is paramount
2. **Restraint**: Only essential UI visible
3. **Discoverability**: Features revealed contextually
4. **Consistency**: iOS patterns throughout
5. **Performance**: Smooth, responsive interactions

Implement these principles systematically to achieve a comparable experience.
