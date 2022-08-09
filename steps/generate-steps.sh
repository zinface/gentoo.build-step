#!/bin/bash

FULL_DIR_PATH=`cd $(dirname $0) && pwd`
cd "$FULL_DIR_PATH"

if [ -d "scripts" ]; then
    rm -rf scripts/*.sh || true
fi

cat_step() {
    cat "${STEP_JSON}"
}

step_value() {
    local key="$1"
    cat_step | jq ".${key}" -r
}

step_length() {
    step_value ' | length'
}

step_read_index() {
    local index=$1
    local key=$2
    step_value "[${index}]${key}" 
}

step_read_file() {
    local index=$1
    step_read_index "${index}" ".file"
}

step_read_title() {
    local index=$1
    step_read_index "${index}" ".title"
}

step_read_content() {
    local index=$1
    step_read_index "${index}" ".content[]"
}

# 基于模板 - 生成通用结构配置
mk_template() {
    template="$1"
    local description="$2"

    echo "    [steps-scripts] 生成配置 ${template}"
    cp ./scripts/step-template ./scripts/${template}

    template="./scripts/${template}"
    sed -i -e "s/模板文件/${description}/g" ${template}
}


# STEP_JSON='xxx.json'
mk_step() {
    local index=$1
    local template=
    mk_template "$(step_read_file ${index})" "$(step_read_title ${index})"
    cat >> ${template} << EOF
$(step_read_content ${index})
EOF
}

# emerge_install_ufed() {
#     local template=
#     mk_template "4.emerge-install-ufed.sh" "安装 USE 命令行管理工具"
    
#     cat >> ${template} << EOF
# # 安装 USE 命令行管理工具
# emerge --ask app-portage/ufed
# EOF
# }

# echo "STEP_JSON=${STEP_JSON}"
if [[ -f "${STEP_JSON}" ]]; then 
    echo "    [step 数量]: $(step_length)"
    for i in `seq $(step_length)`; do
        index=$(echo ${i}-1|bc)
        mk_step "${index}"
    done
fi