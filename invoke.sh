#!/bin/sh

alr run
magick framebuffer.png -interpolate nearest -filter point -resize 512x512\! out.png
