#!/bin/bash

FULL_DIR_PATH=`cd $(dirname $0) && pwd`
cd "$FULL_DIR_PATH"

# 1.生成 steps 脚本文件(已由 init.sh 初始化生成)
# echo "[steps] 生成 steps 脚本文件"
# ./scripts/generate-steps-steps.sh

# 2.复制 steps 脚本文件到 <安装目录>/root
echo "[steps] 复制 steps 脚本文件到 ${BUILD_INSTALLDIR}/root"
cp ${FULL_DIR_PATH}/scripts/*.sh ${BUILD_INSTALLDIR}/root || exit 1
chmod +x ${BUILD_INSTALLDIR}/root/*.sh

# 3. 清理 steps 脚本文件
# if [ -d "./scripts/steps" ]; then
#     rm ./scripts/steps/*.sh
# fi