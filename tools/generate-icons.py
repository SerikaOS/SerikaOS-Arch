#!/usr/bin/env python3
import os
import sys
from PIL import Image, ImageDraw, ImageFilter

def create_icon(draw_func, filename, color, glow_color=None):
    # Dimensions for rendering (high res for downscaling to get anti-aliasing)
    size = 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    
    # 1. Glow layer
    glow_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_img)
    draw_func(glow_draw, size, color if not glow_color else glow_color, is_glow=True)
    # Apply heavy blur for neon glow
    glow_img = glow_img.filter(ImageFilter.GaussianBlur(16))
    
    # 2. Sharp layer
    sharp_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sharp_draw = ImageDraw.Draw(sharp_img)
    draw_func(sharp_draw, size, color, is_glow=False)
    
    # Combine layers
    combined = Image.alpha_composite(glow_img, sharp_img)
    
    # Downscale
    try:
        resample_filter = Image.Resampling.LANCZOS
    except AttributeError:
        # Compatibility with older Pillow versions
        resample_filter = Image.ANTIALIAS
        
    final_img = combined.resize((32, 32), resample_filter)
    final_img.save(filename, "PNG")
    print(f"Generated {filename}")

# --- Drawing functions ---

def draw_serikaos(draw, size, color, is_glow=False):
    # Minimalist cat ears + floating halo
    w = 24 if is_glow else 12
    # Cat ears outline
    # Left Ear: from (150, 360) -> (100, 200) -> (220, 270)
    draw.line([(150, 380), (100, 220), (220, 290)], fill=color, width=w, joint="round")
    # Right Ear: from (362, 380) -> (412, 220) -> (292, 290)
    draw.line([(362, 380), (412, 220), (292, 290)], fill=color, width=w, joint="round")
    # Head connection: (220, 290) -> (292, 290)
    draw.line([(220, 290), (292, 290)], fill=color, width=w, joint="round")
    
    # Halo: ellipse at top (130, 90) to (382, 150)
    draw.ellipse([130, 80, 382, 150], outline=color, width=w)
    
    # Halo cross/wing accents
    draw.line([(110, 115), (140, 115)], fill=color, width=w)
    draw.line([(370, 115), (400, 115)], fill=color, width=w)

def draw_arch(draw, size, color, is_glow=False):
    # Sleek Arch Linux logo outline
    w = 24 if is_glow else 12
    
    # Path of the Arch 'A'
    points = [
        (256, 70),   # Peak
        (100, 410),  # Left base
        (160, 410),  # Left inner base
        (256, 220),  # Inner peak
        (352, 410),  # Right inner base
        (412, 410),  # Right base
        (256, 70)    # Back to peak
    ]
    
    # Draw outline path
    draw.line([points[0], points[1]], fill=color, width=w, joint="round")
    draw.line([points[1], points[2]], fill=color, width=w, joint="round")
    draw.line([points[2], points[3]], fill=color, width=w, joint="round")
    draw.line([points[3], points[4]], fill=color, width=w, joint="round")
    draw.line([points[4], points[5]], fill=color, width=w, joint="round")
    draw.line([points[5], points[0]], fill=color, width=w, joint="round")
    
    # Swoosh
    draw.line([(190, 340), (256, 320), (322, 340)], fill=color, width=w, joint="round")

def draw_linux(draw, size, color, is_glow=False):
    # Sleek minimalist Tux outline
    w = 24 if is_glow else 12
    # Head
    draw.ellipse([196, 100, 316, 220], outline=color, width=w)
    # Body
    draw.ellipse([156, 220, 356, 420], outline=color, width=w)
    # Wings
    draw.line([(156, 260), (120, 320), (156, 360)], fill=color, width=w, joint="round")
    draw.line([(356, 260), (392, 320), (356, 360)], fill=color, width=w, joint="round")
    # Feet
    draw.line([(170, 415), (140, 430), (220, 430)], fill=color, width=w, joint="round")
    draw.line([(342, 415), (372, 430), (292, 430)], fill=color, width=w, joint="round")

def draw_windows(draw, size, color, is_glow=False):
    # Sleek Windows 11 style flat logo
    w = 24 if is_glow else 12
    
    # 4 squares
    gap = 20
    mid = 256
    
    # Top Left
    draw.rectangle([100, 100, mid - gap, mid - gap], outline=color, width=w)
    # Top Right
    draw.rectangle([mid + gap, 100, 412, mid - gap], outline=color, width=w)
    # Bottom Left
    draw.rectangle([100, mid + gap, mid - gap, 412], outline=color, width=w)
    # Bottom Right
    draw.rectangle([mid + gap, mid + gap, 412, 412], outline=color, width=w)

def draw_efi(draw, size, color, is_glow=False):
    # Motherboard chip
    w = 24 if is_glow else 12
    
    # Central chip body
    draw.rectangle([160, 160, 352, 352], outline=color, width=w)
    draw.rectangle([200, 200, 312, 312], outline=color, width=w)
    
    # Pins radiating out
    for offset in [200, 256, 312]:
        # Top
        draw.line([(offset, 160), (offset, 110)], fill=color, width=w)
        # Bottom
        draw.line([(offset, 352), (offset, 402)], fill=color, width=w)
        # Left
        draw.line([(160, offset), (110, offset)], fill=color, width=w)
        # Right
        draw.line([(352, offset), (402, offset)], fill=color, width=w)

def draw_restart(draw, size, color, is_glow=False):
    # Circular reload arrow
    w = 24 if is_glow else 12
    
    # Outer circle arc (open at top right)
    draw.arc([112, 112, 400, 400], start=45, end=315, fill=color, width=w)
    
    # Arrow head at 45 degrees (around x=359, y=153)
    # Drawing pointing down-left
    draw.line([(356, 156), (356, 80)], fill=color, width=w, joint="round")
    draw.line([(356, 156), (280, 156)], fill=color, width=w, joint="round")

def draw_shutdown(draw, size, color, is_glow=False):
    # Classic Power Symbol
    w = 24 if is_glow else 12
    
    # Arc open at top
    draw.arc([112, 112, 400, 400], start=-220, end=40, fill=color, width=w)
    
    # Vertical line in center
    draw.line([(256, 80), (256, 240)], fill=color, width=w, joint="round")

def draw_memtest(draw, size, color, is_glow=False):
    # RAM stick outline
    w = 24 if is_glow else 12
    
    # Main board
    draw.rectangle([80, 200, 432, 290], outline=color, width=w)
    
    # Memory modules (chips)
    for x in range(120, 380, 60):
        draw.rectangle([x, 215, x + 40, 275], outline=color, width=w//2 if is_glow else w)
        
    # Connector pins at bottom
    draw.line([(96, 310), (416, 310)], fill=color, width=w)
    for x in range(110, 410, 20):
        draw.line([(x, 310), (x, 325)], fill=color, width=w//2 if is_glow else w)

def draw_unknown(draw, size, color, is_glow=False):
    # Sleek question mark
    w = 24 if is_glow else 12
    
    # Question mark curve
    draw.arc([140, 100, 372, 280], start=-180, end=45, fill=color, width=w)
    draw.line([(338, 227), (256, 300), (256, 350)], fill=color, width=w, joint="round")
    
    # Dot
    draw.ellipse([240, 390, 272, 420], fill=color)

def draw_submenu(draw, size, color, is_glow=False):
    # Chevron pointing right
    w = 24 if is_glow else 12
    draw.line([(180, 130), (330, 256), (180, 382)], fill=color, width=w, joint="round")

def draw_hd(draw, size, color, is_glow=False):
    # Hard drive chassis
    w = 24 if is_glow else 12
    
    # Chassis
    draw.rectangle([120, 90, 392, 422], outline=color, width=w)
    # Disk platter circle
    draw.ellipse([156, 126, 356, 326], outline=color, width=w)
    draw.ellipse([236, 206, 276, 246], outline=color, width=w)
    # Head armature arm
    draw.line([(256, 226), (320, 350), (280, 380)], fill=color, width=w, joint="round")

def main():
    dest_dir = "grub-theme/icons"
    os.makedirs(dest_dir, exist_ok=True)
    
    pink = "#e8a0bf"
    teal = "#5cc6d0"
    dim_gray = "#6a6a8a"
    
    # Mapping of filenames to their drawing function, primary color, and glow color
    icons = {
        "serikaos.png": (draw_serikaos, pink, pink),
        "arch.png": (draw_arch, teal, teal),
        "linux.png": (draw_linux, teal, teal),
        "windows.png": (draw_windows, teal, teal),
        "uefi.png": (draw_efi, teal, teal),
        "efi.png": (draw_efi, teal, teal),
        "restart.png": (draw_restart, teal, teal),
        "shutdown.png": (draw_shutdown, pink, pink),
        "memtest.png": (draw_memtest, dim_gray, dim_gray),
        "unknown.png": (draw_unknown, dim_gray, dim_gray),
        "submenu.png": (draw_submenu, pink, pink),
        "hd.png": (draw_hd, teal, teal)
    }
    
    for filename, (draw_func, color, glow_color) in icons.items():
        filepath = os.path.join(dest_dir, filename)
        create_icon(draw_func, filepath, color, glow_color)
        
if __name__ == "__main__":
    main()
