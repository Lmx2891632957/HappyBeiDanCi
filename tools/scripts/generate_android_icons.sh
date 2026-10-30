#!/usr/bin/env bash

# 从品牌源图生成 Android 传统图标与自适应图标，避免手工维护多套尺寸。
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source_image="${1:-${repo_root}/assets/branding/app_icon_source.jpeg}"
android_res="${repo_root}/android/app/src/main/res"
temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/happy-beidanci-icons.XXXXXX")"

cleanup() {
  rm -f "${temp_dir}/legacy.png" \
    "${temp_dir}/adaptive.png"
  rmdir "${temp_dir}"
}
trap cleanup EXIT

if [[ ! -f "${source_image}" ]]; then
  echo "找不到应用图标源图：${source_image}" >&2
  exit 1
fi

# 源图是带桌面背景的横图；只取中央品牌图案，避免启动器缩略图混入无关背景。
# 480 用于传统方形图标，520 用于自适应层以保留完整蓝色圆角边框。
sips -s format png -c 480 480 "${source_image}" \
  --out "${temp_dir}/legacy.png" >/dev/null
sips -s format png -c 520 520 "${source_image}" \
  --out "${temp_dir}/adaptive.png" >/dev/null

legacy_densities=(mdpi hdpi xhdpi xxhdpi xxxhdpi)
legacy_sizes=(48 72 96 144 192)
adaptive_sizes=(108 162 216 324 432)

for index in "${!legacy_densities[@]}"; do
  density="${legacy_densities[index]}"
  size="${legacy_sizes[index]}"
  sips -s format png -z "${size}" "${size}" "${temp_dir}/legacy.png" \
    --out "${android_res}/mipmap-${density}/ic_launcher.png" >/dev/null
  sips -s format png -z "${adaptive_sizes[index]}" "${adaptive_sizes[index]}" \
    "${temp_dir}/adaptive.png" \
    --out "${android_res}/mipmap-${density}/ic_launcher_foreground.png" >/dev/null
done

echo "Android 应用图标已生成到 ${android_res}"
