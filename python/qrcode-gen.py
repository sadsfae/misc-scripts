#!/usr/bin/env python3
# takes a base image and embeds a QR code into it.
# requires python3-qrcode
# example:
# python3 qrcode_gen.py /path/to/an/image  "Some text you want encoded as QR Code" some_image_output.jpg
# original credit: https://www.reddit.com/user/tritis

import qrcode
from PIL import Image
import sys

if len(sys.argv[1:]) != 3:
    print ("## Requires 3 arguments ##")
    print ("qrcode_gen.py /path/to/an/image string_or_url your_new_image.jpg")
    exit(1)

def main():
    img = Image.open(sys.argv[1])
    qr = qrcode.make(sys.argv[2])
    img.paste(qr)
    img.save(sys.argv[3])

if __name__ == '__main__':
    main()
