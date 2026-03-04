import sys
from PIL import Image

try:
    img = Image.open('assets/sprites/caminar_dan.png')
    print(f"Size: {img.width}x{img.height}")
    sys.exit(0)
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
