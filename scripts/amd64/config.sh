#!/bin/bash
# wget https://mirrors.bfsu.edu.cn/gentoo/releases/amd64/autobuilds/current-stage3-amd64-systemd/stage3-amd64-systemd-20220703T170542Z.tar.xz


# 1.获取最新 stage3 下载地址(systemd|openrc) ------------------------------------------------
# 最新 stage3 文件信息
    # curl https://mirrors.bfsu.edu.cn/gentoo/releases/amd64/autobuilds/latest-stage3-amd64-systemd.txt
    # curl https://mirrors.bfsu.edu.cn/gentoo/releases/amd64/autobuilds/latest-stage3-amd64-openrc.txt
    # 后缀 tar.xz
        # grep tar.xz
    # 进行分割出文件名称
        # tr '/' ' '
    # 使用第一段内容
        # cut -d ' ' -f1
    
    # 内容过程
        # 20220731T170548Z/stage3-amd64-systemd-20220731T170548Z.tar.xz 233872772
        # 20220731T170548Z stage3-amd64-systemd-20220731T170548Z.tar.xz 233872772
        # 20220731T170548Z

INIT_TYPE="${BUILD_DAEMON}"


STAGE_INFO=`curl -s https://mirrors.bfsu.edu.cn/gentoo/releases/amd64/autobuilds/latest-stage3-amd64-${INIT_TYPE}.txt | grep tar.xz`
STAGE_NAME=`echo -n ${STAGE_INFO} | tr '/' ' ' | cut -d ' ' -f2`
STAGE_VERSION=`echo -n ${STAGE_INFO} | tr '/' ' ' | cut -d ' ' -f1`

echo "[config] stage3 文件: ${STAGE_NAME}"
echo "[config] stage3 版本: ${STAGE_VERSION}"
echo "#!/bin/bash" > 1.latest-stage3-amd64-${INIT_TYPE}.sh
echo "wget https://mirrors.bfsu.edu.cn/gentoo/releases/amd64/autobuilds/current-stage3-amd64-${INIT_TYPE}/${STAGE_NAME}" >> 1.latest-stage3-amd64-${INIT_TYPE}.sh
chmod +x 1.latest-stage3-amd64-${INIT_TYPE}.sh


# 2.获取最新 stage3 解压脚本 ------------------------------------------------
    # 将下载的 stage3 压缩包进行解压，并放入安装目录
echo "[config] stage3 install: ${BUILD_INSTALLDIR}"
echo "#!/bin/bash" > 2.stage3-amd64-${INIT_TYPE}-extract.sh
echo "mkdir -p ${BUILD_INSTALLDIR}"                          >> 2.stage3-amd64-${INIT_TYPE}-extract.sh
echo 'if [[ `id -un` != "root" ]]; then echo "请使用 sudo 执行此脚本" ; exit 1; fi' >> 2.stage3-amd64-${INIT_TYPE}-extract.sh
echo "tar -xf ${STAGE_NAME} -C ${BUILD_INSTALLDIR}" >> 2.stage3-amd64-${INIT_TYPE}-extract.sh
chmod +x 2.stage3-amd64-${INIT_TYPE}-extract.sh