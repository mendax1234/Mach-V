#!/usr/bin/env python3
"""
Pad a binary file to a specified size and convert to hex format.
Usage: python3 pad_hex.py <input.bin> <output.hex> <size_in_bytes>
"""

import sys
import os

def pad_and_convert_to_hex(input_bin, output_hex, target_size):
    """
    Read binary file, pad with zeros to target size, and output as hex.
    Hex format: 4 bytes per line in little-endian format.
    """
    # Read the input binary file
    with open(input_bin, 'rb') as f:
        data = bytearray(f.read())
    
    current_size = len(data)
    print(f"Input file size: {current_size} bytes ({current_size/1024:.2f} KB)")
    
    # Pad with zeros if needed
    if current_size < target_size:
        padding_needed = target_size - current_size
        data.extend(b'\x00' * padding_needed)
        print(f"Padded with {padding_needed} bytes of zeros")
    elif current_size > target_size:
        print(f"Warning: Input file ({current_size} bytes) is larger than target size ({target_size} bytes)")
        print(f"Truncating to {target_size} bytes")
        data = data[:target_size]
    
    # Write hex file (4 bytes per line)
    with open(output_hex, 'w') as f:
        for i in range(0, len(data), 4):
            # Get 4 bytes (pad last word with zeros if needed)
            word = data[i:i+4]
            while len(word) < 4:
                word.append(0)
            
            # Convert to 32-bit hex (little-endian)
            value = word[0] | (word[1] << 8) | (word[2] << 16) | (word[3] << 24)
            f.write(f" {value:08x}\n")
    
    lines = len(data) // 4
    print(f"Output file: {output_hex}")
    print(f"Final size: {len(data)} bytes ({len(data)/1024:.2f} KB)")
    print(f"Hex lines: {lines}")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python3 pad_hex.py <input.bin> <output.hex> <size_in_bytes>")
        print("Example: python3 pad_hex.py data.bin data.hex 7168")
        sys.exit(1)
    
    input_bin = sys.argv[1]
    output_hex = sys.argv[2]
    target_size = int(sys.argv[3])
    
    if not os.path.exists(input_bin):
        print(f"Error: Input file '{input_bin}' not found")
        sys.exit(1)
    
    pad_and_convert_to_hex(input_bin, output_hex, target_size)
    print("Done!")