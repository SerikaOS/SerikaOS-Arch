#!/usr/bin/env python3
"""
SerikaOS — Logo to Colored ASCII Art Converter
Converts the SerikaOS logo image into a colored ASCII art file
suitable for fastfetch/neofetch display.

Usage:
    python3 generate-ascii-logo.py [input_image] [output_file] [width]

Example:
    python3 generate-ascii-logo.py ../built-in-media/logo/f3423003-8e73-43b1-be27-14f423a50018-1760203168530.avif ../branding/ascii-logo.txt 40

Dependencies:
    pip install Pillow
    (or: sudo pacman -S python-pillow)
"""

import sys
import os

try:
    from PIL import Image
except ImportError:
    print("ERROR: Pillow is required. Install with:")
    print("  pip install Pillow")
    print("  -- or --")
    print("  sudo pacman -S python-pillow")
    sys.exit(1)


def image_to_colored_ascii(image_path, width=40, use_blocks=True):
    """Convert an image to colored ASCII art with ANSI true-color escape codes."""
    img = Image.open(image_path).convert("RGBA")

    # Terminal characters are ~2:1 height:width
    height = int(width * img.height / img.width / 2)
    img = img.resize((width, height), Image.LANCZOS)

    if use_blocks:
        chars = "█▓▒░ "
    else:
        chars = "@%#*+=-:. "

    lines = []
    for y in range(height):
        line = ""
        for x in range(width):
            r, g, b, a = img.getpixel((x, y))
            if a < 50:
                line += " "
            else:
                brightness = (r * 0.299 + g * 0.587 + b * 0.114)
                idx = int((1.0 - brightness / 255.0) * (len(chars) - 2))
                idx = max(0, min(idx, len(chars) - 2))
                char = chars[idx]
                line += f"\033[38;2;{r};{g};{b}m{char}\033[0m"
        lines.append(line)

    return lines


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    default_input = os.path.join(
        script_dir,
        "..", "built-in-media", "logo",
        "f3423003-8e73-43b1-be27-14f423a50018-1760203168530.avif"
    )
    default_output = os.path.join(script_dir, "..", "branding", "ascii-logo.txt")

    input_path = sys.argv[1] if len(sys.argv) > 1 else default_input
    output_path = sys.argv[2] if len(sys.argv) > 2 else default_output
    width = int(sys.argv[3]) if len(sys.argv) > 3 else 40

    if not os.path.exists(input_path):
        print(f"ERROR: Input image not found: {input_path}")
        sys.exit(1)

    print(f"Converting: {input_path}")
    print(f"Width: {width} chars")

    lines = image_to_colored_ascii(input_path, width, use_blocks=True)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w") as f:
        for line in lines:
            f.write(line + "\n")

    print(f"Output: {output_path}")
    print(f"Size: {width}x{len(lines)}")
    print()
    print("Preview:")
    for line in lines:
        print(f"  {line}")
    print()


if __name__ == "__main__":
    main()
