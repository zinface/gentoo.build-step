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
cat > 1.latest-stage3-amd64-${INIT_TYPE}.sh << EOF
#!/bin/bash

wget https://mirrors.bfsu.edu.cn/gentoo/releases/amd64/autobuilds/current-stage3-amd64-${INIT_TYPE}/${STAGE_NAME}
EOF
chmod +x 1.latest-stage3-amd64-${INIT_TYPE}.sh


# 2.获取最新 stage3 解压脚本 ------------------------------------------------
    # 将下载的 stage3 压缩包进行解压，并放入安装目录
echo "[config] stage3 安装: ${BUILD_INSTALLDIR}"
cat > 2.stage3-amd64-${INIT_TYPE}-extract.sh << EOF
#!/bin/bash
mkdir -p ${BUILD_INSTALLDIR}

if [[ \`id -un\` != "root" ]]; then 
    echo "请使用 sudo 执行此脚本"
    exit 1
fi

tar -xf ${STAGE_NAME} -C ${BUILD_INSTALLDIR}
EOF
chmod +x 2.stage3-amd64-${INIT_TYPE}-extract.sh


# 3. 将已生成的通用脚本复制到 <rootfs>/root ------------------------------------------
echo "[config] stage3 steps: ${BUILD_INSTALLDIR}/root/*.sh"
cat > 3.steps-copy-to-root.sh << EOF
#!/bin/bash

if [[ \`id -un\` != "root" ]]; then 
    echo "请使用 sudo 执行此脚本"
    exit 1
fi

export BUILD_INSTALLDIR='${BUILD_INSTALLDIR}'
./steps/config-steps.sh
EOF
chmod +x 3.steps-copy-to-root.sh


# 3.0.获取 stage3 make.conf 编辑脚本 ------------------------------------------------
    # 用于修改 make.conf 文件
echo "[config] stage3 编辑: ${BUILD_EDITOR}"
cat > 3.0.${BUILD_EDITOR}-portage-make-conf.sh << EOF
#!/bin/bash

if [[ \`id -un\` != "root" ]]; then 
    echo "请使用 sudo 执行此脚本"
    exit 1
fi

${BUILD_EDITOR} ${BUILD_INSTALLDIR}/etc/portage/make.conf
EOF
chmod +x 3.0.${BUILD_EDITOR}-portage-make-conf.sh


# 3.1.初始化 portage-repos-gentoo.conf 位置 ------------------------------------------------
echo "[config] stage3 仓库: ${BUILD_SYNC_URI}"
cat > 3.1.init-portage-repos-gentoo-conf.sh << EOF
#!/bin/bash

if [[ \`id -un\` != "root" ]]; then 
    echo "请使用 sudo 执行此脚本"
    exit 1
fi

mkdir -p ${BUILD_INSTALLDIR}/etc/portage/repos.conf
cp ${BUILD_INSTALLDIR}/usr/share/portage/config/repos.conf ${BUILD_INSTALLDIR}/etc/portage/repos.conf/gentoo.conf
sed -i 's_rsync://rsync.gentoo.org/gentoo-portage_${BUILD_SYNC_URI}_' ${BUILD_INSTALLDIR}/etc/portage/repos.conf/gentoo.conf

# before:
    # sync-uri = rsync://rsync.gentoo.org/gentoo-portage
# after:
    # sync-uri = rsync://mirrors.bfsu.edu.cn/gentoo-portage
EOF
chmod +x 3.1.init-portage-repos-gentoo-conf.sh


# 4.获取 stage3 环境迁移脚本 ------------------------------------------------
echo "[config] stage3 环境: chroot-environment-mount"
cat > 4.chroot-environment-mount.sh << EOF
#!/bin/bash

if [[ \`id -un\` != "root" ]]; then 
    echo "请使用 sudo 执行此脚本"
    exit 1
fi

cp --dereference /etc/resolv.conf ${BUILD_INSTALLDIR}/etc/
mount -t proc /proc ${BUILD_INSTALLDIR}/proc
mount --rbind /sys ${BUILD_INSTALLDIR}/sys
mount --make-rslave ${BUILD_INSTALLDIR}/sys
mount --rbind /dev ${BUILD_INSTALLDIR}/dev
mount --make-rslave ${BUILD_INSTALLDIR}/dev
mount --bind /run ${BUILD_INSTALLDIR}/run
mount --make-slave ${BUILD_INSTALLDIR}/run
EOF
chmod +x 4.chroot-environment-mount.sh


# 5.获取 stage3 环境切换脚本 ------------------------------------------------
echo "[config] stage3 环境: chroot"
cat > 5.chroot-rootfs.sh << EOF
#!/bin/bash

if [[ \`id -un\` != "root" ]]; then 
    echo "请使用 sudo 执行此脚本"
    exit 1
fi

chroot ${BUILD_INSTALLDIR} /bin/bash
EOF
chmod +x 5.chroot-rootfs.sh


# 5 获取 stage3 环境卸载脚本 ------------------------------------------------
echo "[config] stage3 环境: chroot-environment-umount"
cat > 6.chroot-environment-umount.sh << EOF
#!/bin/bash

if [[ \`id -un\` != "root" ]]; then 
    echo "请使用 sudo 执行此脚本"
    exit 1
fi

# grep /${BUILD_INSTALLDIR}/ /proc/mounts | cut -f2 -d" " | sort -r | xargs -r umount -n
# 为了解决可能会遇到空的结果将不使用以上命令

MOUNTP='${BUILD_INSTALLDIR}/'
for dir in \$(grep "\$MOUNTP" /proc/mounts | cut -f2 -d" " | sort -r)
do
    umount \$dir 2> /dev/null
    (( \$? )) && umount -n \$dir
done
EOF
chmod +x 6.chroot-environment-umount.sh



# 对生成的文件进行垃圾清理操作 ------------------------------------------------
echo "[config] clean  清理: clean.sh"
cat > clean.sh << EOF
#!/bin/bash

rm 1.latest-stage3-amd64-${INIT_TYPE}.sh
rm 2.stage3-amd64-${INIT_TYPE}-extract.sh
rm 3.steps-copy-to-root.sh
rm 3.0.${BUILD_EDITOR}-portage-make-conf.sh
rm 3.1.init-portage-repos-gentoo-conf.sh
rm 4.chroot-environment-mount.sh
rm 5.chroot-rootfs.sh
rm 6.chroot-environment-umount.sh
rm clean.sh
EOF
chmod +x clean.sh