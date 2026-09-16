#!/usr/bin/env bash
#
# rename_project.sh - 快速重命名 your_project_name 模板包
#
# 用法:
#   ./scripts/rename_project.sh <new_project_name> [new_node_name]
#
# 功能:
#   1. 重命名 your_project_name/ 目录及 include/your_project_name/ 子目录
#   2. 重命名占位文件，统一为 <new_project_name>.hpp / <new_project_name>.cpp:
#      include/your_project_name/your_hpp_name.hpp
#      src/your_cpp_name.cpp
#   3. 替换 CMakeLists.txt、package.xml、src/、include/ 中出现的:
#      - 包名:        your_project_name
#      - 节点名:      your_node_name
#      - 头/源文件名: your_hpp_name / your_cpp_name（含 #include 与 CMake 源文件路径）
#      - 守卫宏:      YOUR_HPP_NAME__YOUR_HPP_NAME_HPP_
#      - 类名:        Your_Hpp_Name（自动转为新包名的 PascalCase）
#
# 说明:
#   在 git 仓库内使用 git mv 以保留文件历史；只针对未重命名的原始模板执行。
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WS_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

OLD_PROJECT="your_project_name"
OLD_NODE="your_node_name"
OLD_HPP="your_hpp_name"
OLD_CPP="your_cpp_name"
OLD_CLASS="Your_Hpp_Name"
OLD_GUARD="YOUR_HPP_NAME"

# snake_case -> PascalCase，如 my_pkg -> MyPkg
to_pascal() {
  echo "$1" | awk -F'_' '{
    out = "";
    for (i = 1; i <= NF; i++)
      out = out toupper(substr($i, 1, 1)) substr($i, 2);
    print out
  }'
}

usage() {
  echo "用法: $0 <new_project_name> [new_node_name]"
  echo "  new_project_name: 新包名，小写字母开头，仅含小写字母/数字/下划线"
  echo "  new_node_name:    新节点名，缺省为 <new_project_name>_node"
  exit 1
}

[ $# -ge 1 ] || usage

NEW_PROJECT="$1"
NEW_NODE="${2:-${NEW_PROJECT}_node}"

# 校验名称合法性
if ! [[ "${NEW_PROJECT}" =~ ^[a-z][a-z0-9_]*$ ]]; then
  echo "[错误] 包名 '${NEW_PROJECT}' 不合法: 必须以小写字母开头，仅含小写字母、数字、下划线"
  exit 1
fi
if ! [[ "${NEW_NODE}" =~ ^[a-z][a-z0-9_]*$ ]]; then
  echo "[错误] 节点名 '${NEW_NODE}' 不合法: 必须以小写字母开头，仅含小写字母、数字、下划线"
  exit 1
fi

# 派生名称: 头/源文件基名与包名一致，守卫宏取大写，类名取 PascalCase
NEW_HPP="${NEW_PROJECT}"
NEW_CPP="${NEW_PROJECT}"
NEW_GUARD="$(echo "${NEW_HPP}" | tr '[:lower:]' '[:upper:]')"
NEW_CLASS="$(to_pascal "${NEW_PROJECT}")"

if [ "${NEW_PROJECT}" = "${OLD_PROJECT}" ] && [ "${NEW_NODE}" = "${OLD_NODE}" ]; then
  echo "[错误] 新旧名称相同，无需重命名"
  exit 1
fi

SRC_DIR="${WS_ROOT}/${OLD_PROJECT}"
DST_DIR="${WS_ROOT}/${NEW_PROJECT}"

if [ ! -d "${SRC_DIR}" ]; then
  echo "[错误] 未找到模板包目录: ${SRC_DIR}"
  echo "       请将本脚本放在与 ${OLD_PROJECT} 同级的工作空间目录下，对未重命名的模板执行"
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

echo "[1/3] 重命名目录..."
if [ "${IN_GIT_REPO}" = true ]; then
  git -C "${WS_ROOT}" mv "${OLD_PROJECT}" "${NEW_PROJECT}"
  git -C "${WS_ROOT}" mv "${NEW_PROJECT}/include/${OLD_PROJECT}" "${NEW_PROJECT}/include/${NEW_PROJECT}"
else
  mv "${SRC_DIR}" "${DST_DIR}"
  mv "${DST_DIR}/include/${OLD_PROJECT}" "${DST_DIR}/include/${NEW_PROJECT}"
fi
echo "  ${OLD_PROJECT}/ -> ${NEW_PROJECT}/"
echo "  ${NEW_PROJECT}/include/${OLD_PROJECT}/ -> ${NEW_PROJECT}/include/${NEW_PROJECT}/"

echo "[2/3] 重命名占位文件..."
if [ -f "${DST_DIR}/include/${NEW_PROJECT}/${OLD_HPP}.hpp" ]; then
  if [ "${IN_GIT_REPO}" = true ]; then
    git -C "${WS_ROOT}" mv "${NEW_PROJECT}/include/${NEW_PROJECT}/${OLD_HPP}.hpp" "${NEW_PROJECT}/include/${NEW_PROJECT}/${NEW_HPP}.hpp"
  else
    mv "${DST_DIR}/include/${NEW_PROJECT}/${OLD_HPP}.hpp" "${DST_DIR}/include/${NEW_PROJECT}/${NEW_HPP}.hpp"
  fi
  echo "  ${OLD_HPP}.hpp -> ${NEW_HPP}.hpp"
fi
if [ -f "${DST_DIR}/src/${OLD_CPP}.cpp" ]; then
  if [ "${IN_GIT_REPO}" = true ]; then
    git -C "${WS_ROOT}" mv "${NEW_PROJECT}/src/${OLD_CPP}.cpp" "${NEW_PROJECT}/src/${NEW_CPP}.cpp"
  else
    mv "${DST_DIR}/src/${OLD_CPP}.cpp" "${DST_DIR}/src/${NEW_CPP}.cpp"
  fi
  echo "  ${OLD_CPP}.cpp -> ${NEW_CPP}.cpp"
fi

echo "[3/3] 替换文件内容..."
cd "${DST_DIR}"

TARGET_FILES=(CMakeLists.txt package.xml)
while IFS= read -r f; do
  TARGET_FILES+=("${f}")
done < <(find src include -type f \( -name '*.cpp' -o -name '*.hpp' -o -name '*.msg' \) 2>/dev/null || true)

for f in "${TARGET_FILES[@]}"; do
  if [ -f "${f}" ] && grep -q -e "${OLD_PROJECT}" -e "${OLD_NODE}" -e "${OLD_HPP}" -e "${OLD_CPP}" -e "${OLD_CLASS}" -e "${OLD_GUARD}" "${f}"; then
    sed -i "s/${OLD_PROJECT}/${NEW_PROJECT}/g; s/${OLD_NODE}/${NEW_NODE}/g; s/${OLD_HPP}/${NEW_HPP}/g; s/${OLD_CPP}/${NEW_CPP}/g; s/${OLD_CLASS}/${NEW_CLASS}/g; s/${OLD_GUARD}/${NEW_GUARD}/g" "${f}"
    echo "  已修改: ${f}"
  fi
done

echo ""
echo "[完成] 包重命名: ${OLD_PROJECT} -> ${NEW_PROJECT}"
echo "        节点重命名: ${OLD_NODE} -> ${NEW_NODE}"
echo "        文件重命名: ${OLD_HPP}.hpp / ${OLD_CPP}.cpp -> ${NEW_HPP}.hpp / ${NEW_CPP}.cpp"
echo "        类名: ${OLD_CLASS} -> ${NEW_CLASS}    守卫宏: ${OLD_GUARD}__* -> ${NEW_GUARD}__*"
echo ""
echo "后续步骤:"
echo "  1. 重新编译: colcon build --packages-select ${NEW_PROJECT}"
echo "  2. 运行节点: ros2 run ${NEW_PROJECT} ${NEW_NODE}"
