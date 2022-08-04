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
echo "[config] stage3 安装: ${BUILD_INSTALLDIR}"
echo "#!/bin/bash" > 2.stage3-amd64-${INIT_TYPE}-extract.sh
echo "mkdir -p ${BUILD_INSTALLDIR}"                          >> 2.stage3-amd64-${INIT_TYPE}-extract.sh
echo 'if [[ `id -un` != "root" ]]; then echo "请使用 sudo 执行此脚本" ; exit 1; fi' >> 2.stage3-amd64-${INIT_TYPE}-extract.sh
echo "tar -xf ${STAGE_NAME} -C ${BUILD_INSTALLDIR}" >> 2.stage3-amd64-${INIT_TYPE}-extract.sh
chmod +x 2.stage3-amd64-${INIT_TYPE}-extract.sh


# 3.获取 stage3 make.conf 编辑脚本 ------------------------------------------------
    # 用于修改 make.conf 文件
echo "[config] stage3 编辑: ${BUILD_EDITOR}"
echo "#!/bin/bash" > 3.${BUILD_EDITOR}-portage-make-conf.sh
# echo 'if [[ `id -un` != "root" ]]; then echo "请使用 sudo 执行此脚本" ; exit 1; fi' >> 3.${BUILD_EDITOR}-portage-make-conf.sh
echo "${BUILD_EDITOR} ${BUILD_INSTALLDIR}/etc/portage/make.conf" >> 3.${BUILD_EDITOR}-portage-make-conf.sh
chmod +x 3.${BUILD_EDITOR}-portage-make-conf.sh

# 3.1.初始化 portage-repos-gentoo.conf 位置
echo "[config] stage3 仓库: ${BUILD_SYNC_URI}"
echo "#!/bin/bash"                                  > 3.1.init-portage-repos-gentoo-conf.sh
echo 'if [[ `id -un` != "root" ]]; then echo "请使用 sudo 执行此脚本" ; exit 1; fi' >> 3.1.init-portage-repos-gentoo-conf.sh
echo "mkdir -p ${BUILD_INSTALLDIR}/etc/portage/repos.conf"   >> 3.1.init-portage-repos-gentoo-conf.sh
echo "cp ${BUILD_INSTALLDIR}/usr/share/portage/config/repos.conf ${BUILD_INSTALLDIR}/etc/portage/repos.conf/gentoo.conf" >> 3.1.init-portage-repos-gentoo-conf.sh
echo "sed -i 's_rsync://rsync.gentoo.org/gentoo-portage_${BUILD_SYNC_URI}_' ${BUILD_INSTALLDIR}/etc/portage/repos.conf/gentoo.conf"           >> 3.1.init-portage-repos-gentoo-conf.sh
echo ""                                                                 >> 3.1.init-portage-repos-gentoo-conf.sh
echo "# before:"                                                        >> 3.1.init-portage-repos-gentoo-conf.sh
echo "    # sync-uri = rsync://rsync.gentoo.org/gentoo-portage"         >> 3.1.init-portage-repos-gentoo-conf.sh
echo "# after:"                                                         >> 3.1.init-portage-repos-gentoo-conf.sh
echo "    # sync-uri = rsync://mirrors.bfsu.edu.cn/gentoo-portage"      >> 3.1.init-portage-repos-gentoo-conf.sh
chmod +x 3.1.init-portage-repos-gentoo-conf.sh


# 4.获取 stage3 环境迁移脚本
echo "[config] stage3 环境: chroot-environment-mount"
echo "#!/bin/bash" >  4.chroot-environment-mount.sh
echo 'if [[ `id -un` != "root" ]]; then echo "请使用 sudo 执行此脚本" ; exit 1; fi' >> 4.chroot-environment-mount.sh
echo "cp --dereference /etc/resolv.conf ${BUILD_INSTALLDIR}/etc/"      >> 4.chroot-environment-mount.sh
echo "mount -t proc /proc ${BUILD_INSTALLDIR}/proc"                    >> 4.chroot-environment-mount.sh
echo "mount --rbind /sys ${BUILD_INSTALLDIR}/sys"                      >> 4.chroot-environment-mount.sh
echo "mount --make-rslave ${BUILD_INSTALLDIR}/sys"                     >> 4.chroot-environment-mount.sh
echo "mount --rbind /dev ${BUILD_INSTALLDIR}/dev"                      >> 4.chroot-environment-mount.sh
echo "mount --make-rslave ${BUILD_INSTALLDIR}/dev"                     >> 4.chroot-environment-mount.sh
chmod +x 4.chroot-environment-mount.sh


# 5.获取 stage3 环境切换脚本
echo "[config] stage3 环境: chroot"
echo "#!/bin/bash" >  5.chroot-rootfs.sh
echo 'if [[ `id -un` != "root" ]]; then echo "请使用 sudo 执行此脚本" ; exit 1; fi' >> 5.chroot-rootfs.sh
echo "chroot ${BUILD_INSTALLDIR} /bin/bash" >> 5.chroot-rootfs.sh
chmod +x 5.chroot-rootfs.sh


# 5 获取 stage3 环境卸载脚本
echo "[config] stage3 环境: chroot-environment-umount"
echo '#!/bin/bash' >  6.chroot-environment-umount.sh
echo ''                                                                                          >> 6.chroot-environment-umount.sh
echo 'if [[ `id -un` != "root" ]]; then echo "请使用 sudo 执行此脚本" ; exit 1; fi'                 >> 6.chroot-environment-umount.sh
echo ''                                                                                          >> 6.chroot-environment-umount.sh
echo '# grep /${BUILD_INSTALLDIR}/ /proc/mounts | cut -f2 -d" " | sort -r | xargs -r umount -n'  >> 6.chroot-environment-umount.sh
echo '# 为了解决可能会遇到空的结果将不使用以上命令'                                                     >> 6.chroot-environment-umount.sh
echo ''                                                                                          >> 6.chroot-environment-umount.sh
echo "MOUNTP='${BUILD_INSTALLDIR}/'"                                                             >> 6.chroot-environment-umount.sh
echo 'for dir in $(grep "$MOUNTP" /proc/mounts | cut -f2 -d" " | sort -r)'                       >> 6.chroot-environment-umount.sh
echo 'do'                                                                                        >> 6.chroot-environment-umount.sh
echo '    umount $dir 2> /dev/null'                                                              >> 6.chroot-environment-umount.sh
echo '    (( $? )) && umount -n $dir'                                                            >> 6.chroot-environment-umount.sh
echo 'done'                                                                                      >> 6.chroot-environment-umount.sh
chmod +x 6.chroot-environment-umount.sh



# 对生成的文件进行垃圾清理操作
echo "[config] clean  清理: clean.sh"
echo '#!/bin/bash' > clean.sh
echo "rm 1.latest-stage3-amd64-${INIT_TYPE}.sh"     >> clean.sh
echo "rm 2.stage3-amd64-${INIT_TYPE}-extract.sh"    >> clean.sh
echo "rm 3.${BUILD_EDITOR}-portage-make-conf.sh"    >> clean.sh
echo "rm 3.1.init-portage-repos-gentoo-conf.sh"     >> clean.sh
echo "rm 4.chroot-environment-mount.sh"             >> clean.sh
echo "rm 5.chroot-rootfs.sh"                        >> clean.sh
echo "rm 6.chroot-environment-umount.sh"            >> clean.sh
echo "rm clean.sh"                                  >> clean.sh
chmod +x clean.sh