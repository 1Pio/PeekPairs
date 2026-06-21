#!/usr/bin/env python3

import argparse
from pathlib import Path

from PIL import Image


def parse_hex_color(value):
    value = value.strip().lstrip("#")
    if len(value) != 6:
        raise ValueError("Expected a 6-digit hex color.")
    return tuple(int(value[index:index + 2], 16) for index in (0, 2, 4))


def smoothstep(edge0, edge1, value):
    if edge0 == edge1:
        return 1.0 if value >= edge1 else 0.0
    t = max(0.0, min(1.0, (value - edge0) / (edge1 - edge0)))
    return t * t * (3.0 - 2.0 * t)


def chroma_distance(pixel, key):
    return sum((pixel[channel] - key[channel]) ** 2 for channel in range(3)) ** 0.5


def key_dominance_transparency(pixel, key_channel):
    channels = [pixel[0], pixel[1], pixel[2]]
    other_channels = [channels[index] for index in range(3) if index != key_channel]
    excess = channels[key_channel] - max(other_channels)
    bright_key = smoothstep(90, 190, channels[key_channel])
    dominant_key = smoothstep(70, 145, excess)
    return bright_key * dominant_key


def sampled_border_key(image):
    width, height = image.size
    pixels = image.load()
    samples = []

    for x in range(width):
        samples.append(pixels[x, 0][:3])
        samples.append(pixels[x, height - 1][:3])
    for y in range(height):
        samples.append(pixels[0, y][:3])
        samples.append(pixels[width - 1, y][:3])

    return tuple(int(round(sum(pixel[channel] for pixel in samples) / len(samples))) for channel in range(3))


def remove_chroma_key(input_path, output_path, key, transparent_threshold, opaque_threshold, max_size):
    image = Image.open(input_path).convert("RGBA")
    if key is None:
        key = sampled_border_key(image)

    pixels = image.load()
    width, height = image.size

    output = Image.new("RGBA", image.size)
    output_pixels = output.load()

    key_channel = max(range(3), key=lambda channel: key[channel])

    for y in range(height):
        for x in range(width):
            red, green, blue, alpha = pixels[x, y]
            distance = chroma_distance((red, green, blue), key)
            distance_matte = smoothstep(transparent_threshold, opaque_threshold, distance)
            dominance_matte = 1.0 - key_dominance_transparency((red, green, blue), key_channel)
            matte = min(distance_matte, dominance_matte)
            new_alpha = int(round(alpha * matte))

            if 0 < new_alpha < 255:
                channels = [red, green, blue]
                spill = max(0, channels[key_channel] - max(channels[(key_channel + 1) % 3], channels[(key_channel + 2) % 3]))
                channels[key_channel] = max(0, channels[key_channel] - int(spill * (1.0 - matte) * 0.82))
                red, green, blue = channels

            output_pixels[x, y] = (red, green, blue, new_alpha)

    if max_size and max(output.size) > max_size:
        output.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output.save(output_path)


def validate_alpha(path):
    image = Image.open(path).convert("RGBA")
    width, height = image.size
    corners = [
        image.getpixel((0, 0))[3],
        image.getpixel((width - 1, 0))[3],
        image.getpixel((0, height - 1))[3],
        image.getpixel((width - 1, height - 1))[3],
    ]
    data = image.get_flattened_data() if hasattr(image, "get_flattened_data") else image.getdata()
    alpha_values = [pixel[3] for pixel in data]
    opaque_pixels = sum(1 for alpha in alpha_values if alpha > 220)
    visible_pixels = sum(1 for alpha in alpha_values if alpha > 12)
    coverage = visible_pixels / max(1, width * height)

    return {
        "width": width,
        "height": height,
        "corners_transparent": all(alpha == 0 for alpha in corners),
        "visible_coverage": coverage,
        "opaque_pixels": opaque_pixels,
    }


def main():
    parser = argparse.ArgumentParser(description="Remove a flat chroma-key background from a PNG.")
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--key", default="auto-border")
    parser.add_argument("--transparent-threshold", type=float, default=18)
    parser.add_argument("--opaque-threshold", type=float, default=160)
    parser.add_argument("--max-size", type=int, default=None)
    args = parser.parse_args()

    remove_chroma_key(
        input_path=args.input,
        output_path=args.out,
        key=None if args.key == "auto-border" else parse_hex_color(args.key),
        transparent_threshold=args.transparent_threshold,
        opaque_threshold=args.opaque_threshold,
        max_size=args.max_size,
    )

    validation = validate_alpha(args.out)
    print(
        "w={width} h={height} corners_transparent={corners_transparent} "
        "visible_coverage={visible_coverage:.3f} opaque_pixels={opaque_pixels}".format(**validation)
    )


if __name__ == "__main__":
    main()
