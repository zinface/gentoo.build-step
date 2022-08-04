# 本仓库旨在为你快速构建一个 gentoo 

- 本仓库的使用步骤
    1. 配置 `build.json`
        - arch: 当前支持amd64，未来支持(alpha|amd64|arm|arm64|hppa|ia64|m68k|mips|ppc|riscv|s390|sh|sparc)\
            默认是 `amd64`
        - daemon: init进程类型(openrc|systemd)\
            默认是 `systemd`
        - installdir: 配置安装路经\
            默认是 `/mnt/gentoo`
        
        ```json
        {
            "arch": "amd64",
            "daemon": "systemd",
            "installdir": "/mnt/gentoo"
        }
        ```
    2. 执行初始化构建脚本 `init.sh`
        ```bash
        $ ./init.sh
        # or
        make
        ```
    3. 初始化完成将获得构建步骤文件

