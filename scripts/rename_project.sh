#!/usr/bin/env bash
#
# rename_project.sh - 快速重命名 your_project_name 模板包
#
# 用法:
#   ./scripts/rename_project.sh <new_project_name> [new_node_name]
#
# 功能:
#   1. 重命名 your_project_name/ 目录
#   2. 重命名其中的 include/your_project_name/ 子目录
#   3. 替换 CMakeLists.txt、package.xml、src/、include/ 中出现的
#      project_name (your_project_name) 与 node_name (your_node_name)
#
# 说明:
#   在 git 仓库内使用 git mv 以保留文件历史；文件名 your_cpp_name.cpp、
#   your_hpp_name.hpp 与类名 Your_Hpp_Name 不在处理范围内，可按需手动修改。
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WS_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

OLD_PROJECT="your_project_name"
OLD_NODE="your_node_name"

usage() {
  echo "用法: $0 <new_project_name> [new_node_name]"
  echo "  new_project_name: 新包名，小写字母开头，仅含小写字母/数字/下划线"
  echo "  new_node_name:    新节点名，缺省为 <new_project_name>_node"
  exit 1
}

[ $# -ge 1 ] || usage

NEW_PROJECT="$1"
NEW_NODE="${2:-${NEW_PROJECT}_node}"

# 校验 ROS 包名合法性
if ! [[ "${NEW_PROJECT}" =~ ^[a-z][a-z0-9_]*$ ]]; then
  echo "[错误] 包名 '${NEW_PROJECT}' 不合法: 必须以小写字母开头，仅含小写字母、数字、下划线"
  exit 1
fi

if [ "${NEW_PROJECT}" = "${OLD_PROJECT}" ] && [ "${NEW_NODE}" = "${OLD_NODE}" ]; then
  echo "[错误] 新旧名称相同，无需重命名"
  exit 1
fi

SRC_DIR="${WS_ROOT}/${OLD_PROJECT}"
DST_DIR="${WS_ROOT}/${NEW_PROJECT}"

if [ ! -d "${SRC_DIR}" ]; then
  echo "[错误] 未找到模板包目录: ${SRC_DIR}"
  echo "       请将本脚本放在与 ${OLD_PROJECT} 同级的工作空间目录下运行"
  exit 1
fi

if [ -e "${DST_DIR}" ]; then
  echo "[错误] 目标目录已存在: ${DST_DIR}"
  exit 1
fi

# git 仓库内优先使用 git mv，保留历史
IN_GIT_REPO=false
if git -C "${WS_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  IN_GIT_REPO=true
fi

echo "[1/2] 重命名目录..."
if [ "${IN_GIT_REPO}" = true ]; then
  git -C "${WS_ROOT}" mv "${OLD_PROJECT}" "${NEW_PROJECT}"
else
  mv "${SRC_DIR}" "${DST_DIR}"
fi
echo "  ${OLD_PROJECT}/ -> ${NEW_PROJECT}/"

if [ -d "${DST_DIR}/include/${OLD_PROJECT}" ]; then
  if [ "${IN_GIT_REPO}" = true ]; then
    git -C "${WS_ROOT}" mv "${NEW_PROJECT}/include/${OLD_PROJECT}" "${NEW_PROJECT}/include/${NEW_PROJECT}"
  else
    mv "${DST_DIR}/include/${OLD_PROJECT}" "${DST_DIR}/include/${NEW_PROJECT}"
  fi
  echo "  ${NEW_PROJECT}/include/${OLD_PROJECT}/ -> ${NEW_PROJECT}/include/${NEW_PROJECT}/"
fi

echo "[2/2] 替换文件内容 (project_name 与 node_name)..."
cd "${DST_DIR}"

TARGET_FILES=(CMakeLists.txt package.xml)
while IFS= read -r f; do
  TARGET_FILES+=("${f}")
done < <(find src include -type f \( -name '*.cpp' -o -name '*.hpp' -o -name '*.msg' \) 2>/dev/null || true)

for f in "${TARGET_FILES[@]}"; do
  if [ -f "${f}" ] && grep -q -e "${OLD_PROJECT}" -e "${OLD_NODE}" "${f}"; then
    sed -i "s/${OLD_PROJECT}/${NEW_PROJECT}/g; s/${OLD_NODE}/${NEW_NODE}/g" "${f}"
    echo "  已修改: ${f}"
  fi
done

echo ""
echo "[完成] 包重命名: ${OLD_PROJECT} -> ${NEW_PROJECT}"
echo "        节点重命名: ${OLD_NODE} -> ${NEW_NODE}"
echo ""
echo "后续步骤:"
echo "  1. 重新编译: colcon build --packages-select ${NEW_PROJECT}"
echo "  2. 运行节点: ros2 run ${NEW_PROJECT} ${NEW_NODE}"
