#!/usr/bin/env bash
# Regenerate the web (HTML/revealjs) logo files in _extensions/ncar/ncar-assets/web/.
# (Their own directory: next to the PDFs, LaTeX's extension search could pick them up.)
#
# The vendored PDF logos are CMYK: rasterized or converted to SVG, NCAR Blue drifts
# from #0057C2 to ~#3555AE, and the NSF seal becomes a 4 MB SVG of embedded rasters.
# So:
#   * NSF NCAR lockups -- the brand's official RGB PNGs, downscaled.  Pass the
#     brand kit (the directory holding elements/ and extracted_logos/) as $1.
#   * UCAR and UCP     -- pdftocairo SVGs (pure vector), with the CMYK-converted
#     aqua snapped to the exact UCAR Aqua #00A2B4.
#   * NSF NCAR-UCAR    -- none: no RGB source exists and the conversion is
#     off-color, so HTML output falls back to the NSF NCAR lockup.
#
# Needs ImageMagick (magick) and poppler (pdftocairo).
set -euo pipefail
kit=${1:?usage: tools/web-logos.sh <brand-kit-dir>}
src=$(cd "$(dirname "$0")/../_extensions/ncar/ncar-assets/logos" && pwd)
logos=$(cd "$src/../web" && pwd)

# NSF NCAR full color (on white / Light Gray) and NSF color + white-reversed
# (on NCAR Blue, Dark Blue, Space).  1200 px wide is ~4x the on-slide size.
magick "$kit/elements/NSF-NCAR_Logo_FullColor_RGB.png" -resize 1200x \
  -strip -define png:compression-level=9 "$logos/NSF-NCAR_Logo_FullColor_RGB.png"
magick "$kit/extracted_logos/slide3_Google_Shape_16_p3.png" -resize 1200x \
  -strip -define png:compression-level=9 "$logos/NSF-NCAR_Logo_Color-White_RGB.png"

for f in UCAR-Logo_Color_RGB UCAR-Logo_White_RGB UCP-Logo_Color_RGB UCP-Logo_White_RGB; do
  pdftocairo -svg "$src/$f.pdf" - |
    sed -E 's/rgb\(23\.[0-9]+%, 64\.[0-9]+%, 71\.[0-9]+%\)/#00A2B4/g' > "$logos/$f.svg"
done
ls -l "$logos"/*.png "$logos"/*.svg
