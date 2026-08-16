#!/usr/bin/env bash
# 注入内置内容（TD-14 内容全内置）到 assets/：词库 DB + 发音 mp3。
#
# 用法：
#   tools/scripts/inject_assets.sh [版本]     # 默认 1.1（与 WordbookInstaller.defaultLatestVersion 一致）
#
# 来源优先级：
#   1) 本地内容管线产物 tools/content_pipeline/output/wordbook-gaokao-3500-v<版本>/
#      （免网络，CI 无此目录时自动走第 2 项）
#   2) GitHub Release（本机需经代理，DEV_ENV §3：默认 127.0.0.1:7888，
#      可用 HBDC_HTTP_PROXY 覆盖；CI 环境自动直连）
# 校验：按 manifest.json 的 SHA-256 逐产物校验（与 App 端导入校验口径一致，
# TECH_DOC §8.2/§9.2）。产物不入 git（AGENTS §5.3，.gitignore 兜底）。
set -euo pipefail

VERSION="${1:-1.1}"
REPO="Lmx2891632957/HappyBeiDanCi"
PACK_BASE="wordbook-gaokao-3500"
DB_FILE="${PACK_BASE}-v${VERSION}.db"
ZIP_FILE="audio-${PACK_BASE}-v${VERSION}.zip"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOCAL_OUT="${ROOT}/tools/content_pipeline/output/${PACK_BASE}-v${VERSION}"

# SHA-256 摘要：Linux（CI）用 sha256sum，macOS 用 shasum 兜底。
if command -v sha256sum >/dev/null 2>&1; then
  sha256_of() { sha256sum "$1" | awk '{print $1}'; }
else
  sha256_of() { shasum -a 256 "$1" | awk '{print $1}'; }
fi

# manifest 内字段抽取（JSON 用 python3；内容管线依赖 Python，CI 预装）。
manifest_field() {
  python3 -c "import json,sys; print(json.load(open(sys.argv[1]))$1)" "$2"
}

mkdir -p "${ROOT}/assets/wordbooks" "${ROOT}/assets/audio"
WORK="$(mktemp -d)"
# 仅清理本脚本自建的临时目录（系统临时区，非仓库内容，见 AGENTS §5.5 注释）。
trap 'rm -rf -- "$WORK"' EXIT

# 来源选择：本地产物齐全优先，缺失则从 GitHub Release 下载。
if [[ -d "${LOCAL_OUT}" && -f "${LOCAL_OUT}/${DB_FILE}" && -f "${LOCAL_OUT}/${ZIP_FILE}" && -f "${LOCAL_OUT}/manifest.json" ]]; then
  echo "使用本地内容管线产物：${LOCAL_OUT}"
  SRC="${LOCAL_OUT}"
else
  echo "本地内容管线产物缺失，从 GitHub Release 下载（TD-14 注入源）..."
  SRC="${WORK}"
  BASE_URL="https://github.com/${REPO}/releases/download/${PACK_BASE}-v${VERSION}"
  # 代理：CI 直连；本机默认 Clash 127.0.0.1:7888（DEV_ENV §3），可覆盖。
  if [[ -n "${CI:-}" ]]; then
    PROXY=""
  else
    PROXY="${HBDC_HTTP_PROXY:-http://127.0.0.1:7888}"
  fi
  CURL_ARGS=(-fL --retry 6 --retry-all-errors -C -)
  [[ -n "${PROXY}" ]] && CURL_ARGS+=(-x "${PROXY}")
  curl "${CURL_ARGS[@]}" -o "${WORK}/manifest.json" "${BASE_URL}/manifest.json"
  curl "${CURL_ARGS[@]}" -o "${WORK}/${DB_FILE}" "${BASE_URL}/${DB_FILE}"
  curl "${CURL_ARGS[@]}" -o "${WORK}/${ZIP_FILE}" "${BASE_URL}/${ZIP_FILE}"
fi

# SHA-256 校验：DB 与音频 zip 逐项比对 manifest（缺失/不匹配即失败）。
expected_db="$(manifest_field "['artifacts']['wordbook_db']['sha256']" "${SRC}/manifest.json")"
actual_db="$(sha256_of "${SRC}/${DB_FILE}")"
[[ "${expected_db}" == "${actual_db}" ]] || { echo "词库 DB SHA-256 不匹配：${DB_FILE}" >&2; exit 1; }
expected_zip="$(manifest_field "['artifacts']['audio_zip']['sha256']" "${SRC}/manifest.json")"
actual_zip="$(sha256_of "${SRC}/${ZIP_FILE}")"
[[ "${expected_zip}" == "${actual_zip}" ]] || { echo "音频 zip SHA-256 不匹配：${ZIP_FILE}" >&2; exit 1; }

# 注入词库 DB；清掉旧版本残留（assets 内容为构建期产物，不入 git）。
rm -f "${ROOT}"/assets/wordbooks/*.db "${ROOT}"/assets/audio/*.mp3
cp "${SRC}/${DB_FILE}" "${ROOT}/assets/wordbooks/${DB_FILE}"

# 解压音频 zip（内含 audio/<key>.mp3，TD-08 布局）为 assets/audio/ 扁平文件，
# 供 just_audio AssetSource 按 assets/audio/<key>.mp3 直读（TECH_DOC §9.1）。
unzip -q -o "${SRC}/${ZIP_FILE}" -d "${WORK}/unzip"
find "${WORK}/unzip/audio" -maxdepth 1 -name '*.mp3' -exec cp {} "${ROOT}/assets/audio/" \;

count="$(find "${ROOT}/assets/audio" -maxdepth 1 -name '*.mp3' | wc -l | tr -d ' ')"
db_size="$(du -h "${ROOT}/assets/wordbooks/${DB_FILE}" | cut -f1)"
echo "注入完成：assets/wordbooks/${DB_FILE}（${db_size}）+ assets/audio/ 共 ${count} 个 mp3"
