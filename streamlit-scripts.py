import streamlit as st
import json
import os
import zipfile
import gzip
import io
import requests
import re
import xml

def _max_width_(prcnt_width:int = 75):
    max_width_str = f"max-width: {prcnt_width}rem;"
    st.markdown(f""" 
                <style> 
                .block-container{{{max_width_str}}}
                </style>    
                """, 
                unsafe_allow_html=True,
    )
_max_width_(80)

def intro():
    st.title('欢迎使用可视化工具')

    # workdir = 'scripts'
    # archs = ['amd64', 'arm64', 'ppc64le', 's390x', 'x86_64']
    
def portage_viewer():
    st.title('portage 可视化工具')
    
    prefix_mirrors = [
        'https://mirrors.bfsu.edu.cn/gentoo-portage'
    ]
    
    prefix_mirror = st.sidebar.selectbox('选择源', options=prefix_mirrors)
    Manifestfiles = os.path.join(prefix_mirror, 'Manifest.files.gz')
    # requests.get(Manifestfiles).content
    manifest_pattern = re.compile(r'MANIFEST ((\S+)/(\S+))')
    ebuid_pattern = re.compile(r'EBUILD ((\S+))')
    # Manifests = []
    prefix_packages = []
    gzip_file = io.BytesIO(requests.get(Manifestfiles).content)
    with gzip.GzipFile(fileobj=gzip_file, mode='r') as gzip_ref:
        # zip_ref.extractall(os.path.join(prefix, 'portage'))
        for line in gzip_ref.readlines():
            line = line.decode(errors='ignore')
            if line.startswith('MANIFEST'):
                if m := manifest_pattern.match(line):
                    prefix_packages.append(m.group(2))
    
    prefix_package = st.selectbox('选择前缀', options=prefix_packages)
    prefix_package_manifest = os.path.join(prefix_mirror, prefix_package, 'Manifest.gz')
    gzip_file = io.BytesIO(requests.get(prefix_package_manifest).content)
    suffix_packages = []
    with gzip.GzipFile(fileobj=gzip_file, mode='r') as gzip_ref:
        for line in gzip_ref.readlines():
            line = line.decode(errors='ignore')
            if line.startswith('MANIFEST'):
                if m := manifest_pattern.match(line):
                    suffix_packages.append(m.group(2))
                
    suffix_package = st.selectbox('选择后缀', options=suffix_packages)
    package_prefix = os.path.join(prefix_mirror, prefix_package, suffix_package)
    
    package_manifest = os.path.join(package_prefix, 'Manifest')
    manifest = requests.get(package_manifest).content.decode(errors='ignore')
    package_ebuilds = []
    for line in manifest.splitlines():
        if line.startswith('EBUILD'):
            if m := ebuid_pattern.match(line):
                package_ebuilds.append(m.group(1))
    
    # package_metadata =os.path.join(package_prefix, 'metadata.xml')
    # metadata = requests.get(package_metadata).content.decode(errors='ignore')
    # xml.parsers.expat.parse(metadata)
    # p = xml.parsers.expat.ParserCreate()
    # def start_element(name, attrs):
        # if name
    # p.StartElementHandler
    
    ebuildfile = st.selectbox('选择 ebuild 文件', options=package_ebuilds)
    package_ebuild = os.path.join(package_prefix, ebuildfile)
    ebuild = requests.get(package_ebuild).content.decode(errors='ignore')
    with st.expander('内容', expanded=True):
        st.code(ebuild, language='shell')
   
@st.cache_data(show_spinner=False)
def cache_get(url):
    return requests.get(url)
    
def portage_viewer_full():
    st.title('portage 可视化工具 - 全量版')
    
    prefix_mirrors = [
        'https://mirrors.bfsu.edu.cn/gentoo-portage'
    ]
    
    prefix_mirror = st.sidebar.selectbox('选择源', options=prefix_mirrors)
    Manifestfiles = os.path.join(prefix_mirror, 'Manifest.files.gz')
    # requests.get(Manifestfiles).content
    manifest_pattern = re.compile(r'MANIFEST ((\S+)/(\S+))')
    ebuid_pattern = re.compile(r'EBUILD ((\S+))')
    # Manifests = []
    package_prefix_suffixs = []
    prefix_packages = []
    gzip_file = io.BytesIO(cache_get(Manifestfiles).content)
    with gzip.GzipFile(fileobj=gzip_file, mode='r') as gzip_ref:
        # zip_ref.extractall(os.path.join(prefix, 'portage'))
        # with st.spinner('正在获取包信息...'):
        with st.progress(0, '正在获取包信息...') as progress_bar:
            lines = gzip_ref.readlines()
            for i, line in enumerate(lines):
                line = line.decode(errors='ignore')
                if line.startswith('MANIFEST'):
                    if m := manifest_pattern.match(line):
                        prefix_packages.append(m.group(2))
                        prefix_package = m.group(2)
                        pr = int(i / len(lines) * 100)
                        if pr > 100: pr = 100
                        st.progress(pr, f'正在获取 {prefix_package} 的内容...')

                        # prefix_package = st.selectbox('选择前缀', options=prefix_packages)
                        prefix_package_manifest = os.path.join(prefix_mirror, prefix_package, 'Manifest.gz')
                        gzip_file = io.BytesIO(cache_get(prefix_package_manifest).content)
                        suffix_packages = []
                        with gzip.GzipFile(fileobj=gzip_file, mode='r') as gzip_ref:
                            for line in gzip_ref.readlines():
                                line = line.decode(errors='ignore')
                                if line.startswith('MANIFEST'):
                                    if m := manifest_pattern.match(line):
                                        suffix_packages.append(m.group(2))
                                        suffix_package = m.group(2)

                                        package_prefix_suffix = os.path.join(prefix_package, suffix_package)
                                        package_prefix_suffixs.append(package_prefix_suffix)
    
    package_prefix_suffix = st.selectbox('选择包', options=package_prefix_suffixs)
    package_prefix = os.path.join(prefix_mirror, package_prefix_suffix)
    
    package_manifest = os.path.join(package_prefix, 'Manifest')
    manifest = requests.get(package_manifest).content.decode(errors='ignore')
    package_ebuilds = []
    for line in manifest.splitlines():
        if line.startswith('EBUILD'):
            if m := ebuid_pattern.match(line):
                package_ebuilds.append(m.group(1))
    
    # package_metadata =os.path.join(package_prefix, 'metadata.xml')
    # metadata = requests.get(package_metadata).content.decode(errors='ignore')
    # xml.parsers.expat.parse(metadata)
    # p = xml.parsers.expat.ParserCreate()
    # def start_element(name, attrs):
        # if name
    # p.StartElementHandler
    
    ebuildfile = st.selectbox('选择 ebuild 文件', options=package_ebuilds)
    package_ebuild = os.path.join(package_prefix, ebuildfile)
    ebuild = requests.get(package_ebuild).content.decode(errors='ignore')
    with st.expander('内容', expanded=True):
        st.code(ebuild, language='shell')

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
    'portage 可视化': portage_viewer,
    'portage 可视化工具 - 全量版': portage_viewer_full
}

page = st.sidebar.selectbox('页面导航', options=pages.keys())
pages[page]()
