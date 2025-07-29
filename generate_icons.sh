#!/bin/bash

# 从 clock.png 生成所有尺寸的图标
cd FloatingClock/Assets.xcassets/AppIcon.appiconset

# 删除旧的图标文件
rm -f icon_*.png

# 生成各种尺寸的图标
echo "正在生成图标..."

# 16x16 (1x)
magick convert ../../../clock.png -resize 16x16 icon_16.png

# 32x32 (2x for 16x16, 1x for 32x32)
magick convert ../../../clock.png -resize 32x32 icon_32.png

# 64x64 (2x for 32x32)
magick convert ../../../clock.png -resize 64x64 icon_64.png

# 128x128 (1x for 128x128)
magick convert ../../../clock.png -resize 128x128 icon_128.png

# 256x256 (2x for 128x128, 1x for 256x256)
magick convert ../../../clock.png -resize 256x256 icon_256.png

# 512x512 (2x for 256x256, 1x for 512x512)
magick convert ../../../clock.png -resize 512x512 icon_512.png

# 1024x1024 (2x for 512x512)
magick convert ../../../clock.png -resize 1024x1024 icon_1024.png

echo "图标生成完成！"

# 显示生成的文件
ls -la icon_*.png 