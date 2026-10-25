"""Generate logo assets from the untouched Figma export.

Run inside the project's Podman environment with Python 3 and CairoSVG:
    python3 tool/branding/generate_logos.py
Then regenerate native resources with flutter_launcher_icons (see docs/branding.md).
"""

from copy import deepcopy
from pathlib import Path
import xml.etree.ElementTree as ET

import cairosvg

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / 'assets/icons'
NS = 'http://www.w3.org/2000/svg'
ET.register_namespace('', NS)


def svg_document(paths, view_box):
    """Crop the export without changing the designer's path data or fills."""
    svg = ET.Element(f'{{{NS}}}svg', {'viewBox': view_box, 'fill': 'none'})
    for path in paths:
        svg.append(deepcopy(path))
    return ET.tostring(svg, encoding='unicode') + '\n'


def main():
    paths = list(ET.parse(Path(__file__).with_name('designer_logos.svg')).getroot())
    if len(paths) != 15:
        raise ValueError('Expected three Figma tiles with five paths each')

    variants = [
        ('app_icon_color.svg', paths[:5], '0 0 154.037 154.087'),
        ('app_icon_light.svg', paths[5:10], '0 168.354 154.037 154.087'),
        ('app_icon_pick_me.svg', paths[10:15], '2.85254 336.709 154.03746 154.087'),
    ]
    for name, group, view_box in variants:
        (ASSETS / name).write_text(svg_document(group, view_box))

    # Transparent glyph for callers that explicitly request a monochrome mark.
    glyph = svg_document(paths[1:5], variants[0][2])
    (ASSETS / 'app_icon.svg').write_text(glyph)
    # Opaque, square launcher master. The OS applies its own icon mask; never
    # bake rounded transparent corners into the adaptive icon background.
    blue_tile = (ASSETS / 'app_icon_color.svg').read_text()
    cairosvg.svg2png(
        bytestring=blue_tile.encode(),
        write_to=str(ASSETS / 'app_icon_color.png'),
        output_width=1024,
        output_height=1024,
        background_color=paths[0].attrib['fill'],
    )
    cairosvg.svg2png(
        bytestring=glyph.encode(),
        write_to=str(ASSETS / 'app_icon_foreground.png'),
        output_width=1024,
        output_height=1024,
    )
    print('Generated three Figma tiles, monochrome glyph and two launcher PNGs')


if __name__ == '__main__':
    main()
