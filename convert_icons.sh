#!/bin/bash

# 确保 ImageMagick 已安装
if ! command -v convert &> /dev/null; then
    echo "需要安装 ImageMagick。请运行: brew install imagemagick"
    exit 1
fi

# 图标尺寸数组
SIZES=(16 32 64 128 256 512 1024)

# 源SVG文件
SVG_FILE="FloatingClock/Assets.xcassets/AppIcon.appiconset/icon.svg"

# 为每个尺寸创建PNG
for size in "${SIZES[@]}"; do
    convert -background none -size ${size}x${size} "$SVG_FILE" "FloatingClock/Assets.xcassets/AppIcon.appiconset/icon_${size}.png"
done

echo "图标转换完成！" 