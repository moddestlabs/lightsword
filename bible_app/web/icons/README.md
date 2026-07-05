# App Icons Needed

## Required Icons for PWA

The following icon files are referenced in `manifest.json` but need to be created:

### Icon-192.png
- **Size:** 192×192 pixels
- **Format:** PNG with transparency
- **Purpose:** Standard app icon, shown in install prompts
- **Design:** Center the LIGHTSWORD logo with padding (~20-30px from edges)

### Icon-512.png
- **Size:** 512×512 pixels  
- **Format:** PNG with transparency
- **Purpose:** High-resolution icon for splash screens
- **Design:** Same as 192px version, just higher resolution

## Design Guidelines

### Logo Concept
The name "LIGHTSWORD" represents the Word of God as both light and sword. Icon should reflect:
- Biblical/scholarly theme
- Clean, modern aesthetic
- Readable at small sizes
- Works on light and dark backgrounds

### Suggested Designs
1. **Sword and Light:** Stylized sword with illuminated blade
2. **Book Icon:** Open book with stylized pages
3. **Scroll:** Ancient scroll with text
4. **Combined:** Book with Hebrew letter overlay

### Color Scheme
Use app's theme colors from manifest.json:
- **Primary:** #8B4513 (saddle brown) - warm, scholarly
- **Background:** #FFFEF8 (cream) - paper-like
- Consider gradient or solid depending on design

### Technical Requirements
- **Format:** PNG
- **Transparency:** Yes (alpha channel)
- **Color depth:** 24-bit or 32-bit
- **Purpose:** "any maskable" (works on all platforms)

## Tools for Creating Icons

### Online Generators
- **Favicon.io:** https://favicon.io/ (generate from text/image)
- **RealFaviconGenerator:** https://realfavicongenerator.net/
- **PWA Asset Generator:** https://www.pwabuilder.com/

### Design Software
- **Figma** (free, web-based)
- **Canva** (easy templates)
- **Inkscape** (free, vector graphics)
- **GIMP** (free, raster graphics)
- **Adobe Illustrator/Photoshop** (professional)

## Quick Start (Placeholder Icons)

For testing, you can use solid color placeholders:

### Using ImageMagick
```bash
# Install imagemagick if not available
# sudo apt-get install imagemagick

# Create 192x192 placeholder
convert -size 192x192 xc:"#8B4513" \
  -gravity center \
  -fill white \
  -pointsize 72 \
  -font DejaVu-Sans-Bold \
  -annotate +0+0 "ד" \
  Icon-192.png

# Create 512x512 placeholder  
convert -size 512x512 xc:"#8B4513" \
  -gravity center \
  -fill white \
  -pointsize 200 \
  -font DejaVu-Sans-Bold \
  -annotate +0+0 "ד" \
  Icon-512.png
```

### Using Online Tool
1. Go to https://favicon.io/favicon-generator/
2. Enter text: "ד" or "דבר"
3. Choose background: #8B4513
4. Choose text color: white
5. Download generated icons
6. Rename to Icon-192.png and Icon-512.png

## Apple Touch Icon

For iOS, also create:
- **apple-touch-icon.png** - 180×180 pixels
- Same design as regular icons
- No transparency (iOS adds rounded corners automatically)

## Validation

After creating icons:

1. **Test locally:**
   ```bash
   cd bible_app
   flutter run -d chrome
   ```
   - Check install prompt shows icon
   - Check DevTools > Application > Manifest

2. **Validate manifest:**
   - DevTools > Application > Manifest
   - Should show all icons without errors

3. **Test installed:**
   - Install app to home screen
   - Check icon appears correctly
   - Try on light and dark backgrounds

## Current Status

⚠️ **Icons not yet created** - Placeholder references in manifest.json

When icons are ready:
1. Place in `bible_app/web/icons/`
2. Ensure filenames match manifest.json
3. Test in browser DevTools
4. Rebuild and deploy

## Resources

- [PWA Icon Guidelines](https://web.dev/maskable-icon/)
- [Android Adaptive Icons](https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive)
- [iOS Icon Guidelines](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [Maskable Icon Editor](https://maskable.app/)
