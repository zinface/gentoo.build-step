#!/bin/bash
# 设置环境

CONFIG="build.json"

cat_config() {
    cat "${CONFIG}"
}

read_value() {
    local key="$1"
    cat_config | jq ".${key}" -r
}

read_arch() {
    read_value "arch"
}

read_daemon() {
    read_value "daemon"
}

read_installdir() {
    read_value "installdir"
}

read_editor() {
    read_value "editor"
}

read_sync_uri() {
    read_value "sync_uri"
}

check_jq() {
    local JQ=$(which jq)
    if [[ -z "$JQ" ]]; then
        echo_error "!!! 错误：您未安装 jq 命令，无法解析 build.json"
        return 1
    fi
    echo "[check] 已安装 jq 命令，可以解析 build.json"
}

check_config() {
    cat_config | jq '.arch' -r 1>/dev/null
    local status=$?
    if [[ "$status" != 0 ]]; then
        echo_error "!!! 错误：无法解析 build.json，请检查 build.json 是否完整"
        return ${status}
    fi
    echo "[check] 检查 build.json 通过，可以读取"
    return 0
}

# 
FC_DEFAULT="\033[0m"
FC_RED="\033[0;31m"
FC_GREEN="\033[0;32m"
# 

echo_error() {
    echo -e "${FC_RED}${@}${FC_DEFAULT}"
}

echo_info() {
    echo -e "${FC_GREEN}${@}${FC_DEFAULT}"
}

echo_info "========== 初始化 gentoo build 仓库 =========="

echo_info "1.检查是否已安装 jq 命令..."
check_jq || exit 1

echo_info "2.检查 build.json 是否完整..."
check_config || exit 1

echo_info "3.读取 build.json 配置文件..."

export BUILD_ARCH=`read_arch`
export BUILD_DAEMON=`read_daemon`
export BUILD_INSTALLDIR=`read_installdir`
export BUILD_EDITOR=`read_editor`
export BUILD_SYNC_URI=`read_sync_uri`

# 主要环境配置

echo "[build] 构建架构: ${BUILD_ARCH}"
echo "[build] 构建类型: ${BUILD_DAEMON}"
echo "[build] 构建目录: ${BUILD_INSTALLDIR}"
echo "[build] 编辑工具: ${BUILD_EDITOR}"
echo "[build] 同步设置: ${BUILD_SYNC_URI}"

echo_info "========== 正在初始化环境 =========="

echo_info "4.执行 ./scripts/${BUILD_ARCH}/config.sh 脚本..."

case "${BUILD_DAEMON}" in 
    systemd|openrc)
        if [[ -f "./scripts/${BUILD_ARCH}/config.sh" ]];then
            ./scripts/${BUILD_ARCH}/config.sh
        else
            echo_error "!!! 无法初始化，请检查 build.json"
            exit 1    
        fi
        ;;
    *)
        echo_error "!!! 无法初始化，请检查 daemon 进程类型"
        exit 1
        ;; 
esac


echo_info "========== 正在初始化 step-jsons =========="
echo_info "5.读取 build.json 内容的 step-jsons 配置"

step_jsons_length() {
    read_value 'step_jsons | length'
}

step_jsons_read_index() {
    local index=$1
    local key=$2
    read_value "step_jsons[${index}]${key}" 
}

step_jsons_read_line() {
    local index=$1
    step_jsons_read_index "${index}" ""
}

step_jsons_loader() {
    local STEP_JSON=$1
    export STEP_JSON
    ./steps/generate-steps.sh
}

echo "[step-jsons] 数量: $(step_jsons_length)"

# 此处的 i 从 1 开始，但 index 应从 0 开始
for i in `seq $(step_jsons_length)`; do
    index=$(echo ${i}-1|bc)

    # 如果 step_json 里的文件存在
    if [[ -f "$(step_jsons_read_line ${index})" ]]; then
        echo "  [读取]: $(step_jsons_read_line ${index})"
        step_jsons_loader $(realpath "$(step_jsons_read_line ${index})")
    fi
done

echo_info "========== 初始化 step-jsons 完成 =========="

# 次要环境配置
