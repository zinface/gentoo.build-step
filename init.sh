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

echo_info "1.读取 build.json 配置文件..."

export BUILD_ARCH=`read_arch`
export BUILD_DAEMON=`read_daemon`
export BUILD_INSTALLDIR=`read_installdir`

# 主要环境配置

echo "构建架构: ${BUILD_ARCH}"
echo "构建类型: ${BUILD_DAEMON}"
echo "构建目录: ${BUILD_INSTALLDIR}"

echo_info "========== 正在初始化环境 =========="

echo_info "2.执行 ./scripts/${BUILD_ARCH}/config.sh 脚本..."

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

echo_info "========== 环境初始化完成 =========="


# 次要环境配置
