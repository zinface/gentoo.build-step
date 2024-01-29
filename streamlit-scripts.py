import streamlit as st
import json
import os
import zipfile
import io

def intro():
    st.title('欢迎使用可视化工具')


def gentoo_editor():
    st.title('gentoo 步骤可视化编辑器')

    workdir = 'steps'
    suffix = '.json'

    configfiles = [f for f in os.listdir(workdir) if f.endswith(suffix)]

    config = st.sidebar.selectbox('选择配置文件', options=configfiles)
    config_file = os.path.join(workdir, config)

    with open(config_file, 'r') as f:
        data = json.loads(f.read())


    title = st.selectbox('选择操作', options=[i['file'] for i in data])
    for item in data:
        if item['file'] == title:
            st.subheader(item['title'])
            oldcontent = '\n'.join(item['content'])
            newcontent = st.text_area('配置编辑', oldcontent, height=400)
            if newcontent != oldcontent:
                st.warning('内容发生变化')

    if st.button('保存修改'):
        for item in data:
            if item['file'] == title:
                item['content'] = newcontent.splitlines()

        with open(config_file, 'w') as f:
            f.write(json.dumps(data, indent=4, ensure_ascii=False))

def gentoo_build_editor():
    st.title('gentoo 可视化构建')
    
    buildfile = 'build.json'
    
    with open(buildfile) as f:
        buildobj = json.loads(f.read())
        

    gentoo_arch = st.radio('架构选择', ['amd64'])
    gentoo_daemon = st.radio('守护进程:', ['systemd', 'openrc'])
    gentoo_install = st.text_input('安装路径:', value='/mnt/gentoo')
    gentoo_rsync = st.text_input('rsync 源:', 'rsync://mirrors.bfsu.edu.cn/gentoo-portage')


    buildobj['arch'] = gentoo_arch
    buildobj['daemon'] = gentoo_daemon
    buildobj['installdir'] = gentoo_install
    buildobj['sync_uri'] = gentoo_rsync

    if st.button('修改'):
        with open(buildfile, 'w') as f:
            f.write(json.dumps(buildobj, indent=4, ensure_ascii=False))
        st.rerun()


def gentoo_build_download():
    st.title('gentoo 可视化构建')
    
    buildfile = 'build.json'
    
    with open(buildfile) as f:
        buildobj = json.loads(f.read())
        

    gentoo_arch = st.radio('架构选择', ['amd64'])
    gentoo_daemon = st.radio('守护进程:', ['systemd', 'openrc'])
    gentoo_install = st.text_input('安装路径:', value='/mnt/gentoo')
    rsyncs = [
        'rsync://mirrors.bfsu.edu.cn/gentoo-portage',
        'rsync://mirror.iscas.ac.cn/gentoo-portage',
        'rsync://mirrors.tuna.tsinghua.edu.cn/gentoo-portage',
        'rsync://mirrors.sjtug.sjtu.edu.cn/gentoo'
    ]
    gentoo_rsync = st.selectbox('选择 rsync 源', options=rsyncs)
    gentoo_rsync = st.text_input('rsync 源:', gentoo_rsync)


    buildobj['arch'] = gentoo_arch
    buildobj['daemon'] = gentoo_daemon
    buildobj['installdir'] = gentoo_install
    buildobj['sync_uri'] = gentoo_rsync

    if st.button('构建'):
        with open(buildfile, 'w') as f:
            f.write(json.dumps(buildobj, indent=4, ensure_ascii=False))

        with os.popen('make') as f:
            st.code(f.read())

        files = [
            # 'Makefile',
            'scripts',
            'steps',
            '1.latest-stage3-amd64-systemd.sh',
            '2.stage3-amd64-systemd-extract.sh',
            '3.0.vim-portage-make-conf.sh',
            '3.1.init-portage-repos-gentoo-conf.sh',
            '3.steps-copy-to-root.sh',
            '4.chroot-environment-mount.sh',
            '5.chroot-rootfs.sh',
            '6.chroot-environment-umount.sh',
        ]
        zipdata = io.BytesIO()
        zip = zipfile.ZipFile(zipdata, 'w')
        for file in files:
            zip.write(file, f'gentoo-build-steps/{file}')
        zip.close()

        filename = f'gentoo-build-{gentoo_daemon}-{gentoo_arch}.zip'

        st.download_button(f'下载 {filename}', data=zipdata, file_name=filename)



pages = {
    'intro': intro,
    '可视化步骤': gentoo_editor,
    'gentoo构建编辑': gentoo_build_editor,
    'gentoo构建下载': gentoo_build_download,
}

page = st.sidebar.selectbox('页面导航', options=pages.keys())
pages[page]()
