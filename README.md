# 本仓库旨在为你快速构建一个 gentoo 

- 本仓库的使用步骤
    1. 配置 `build.json`
        - arch: 当前支持amd64，未来支持(alpha|amd64|arm|arm64|hppa|ia64|m68k|mips|ppc|riscv|s390|sh|sparc)\
            默认是 `amd64`
        - daemon: init进程类型(openrc|systemd)\
            默认是 `systemd`
        - installdir: 配置安装路经\
            默认是 `/mnt/gentoo`
        - editor: 配置编辑工具\
            默认是 `vim`
        - sync_uri: 配置 portage 默认同步源
        ```json
        {
            "arch": "amd64",
            "daemon": "systemd",
            "installdir": "/mnt/gentoo",
            "editor": "vim",
            "sync_uri": "rsync://mirrors.bfsu.edu.cn/gentoo-portage"
        }
        ```
    2. 执行初始化构建脚本 `init.sh`
        ```bash
        $ ./init.sh
        # or
        make
        ```
    3. 初始化完成将获得构建步骤文件
        - 1. 下载最新 stage3 文件脚本
        - 2. 解压最新 stage3 文件到安装目录
        - 3. 利用配置的编辑器编辑 make.conf
            - 3.1 初始化 `etc/portage/repos.conf/gentoo.conf` 文件\
                并将 `sync-uri` 源配置为 `rsync://mirrors.bfsu.edu.cn/gentoo-portage`
        - 4. 对 stage3 进行环境迁移设置
        - 5. 进入 stage3 的 rootfs
        - 6. 对 stage3 进行环境迁移卸载
        - `clean.sh` 对生成的步骤文件进行清理


