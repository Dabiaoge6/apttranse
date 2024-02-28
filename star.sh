#!/bin/bash
# 导出离线安装包

# 在脚本开头设置
set -e

downloadPackage(){
    local package=$1
    echo "down_load lackage"
    apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances $package| grep "^\w" | sort -u)
    sudo chmod 777 -R ./
}
env_ready(){
if ! dpkg -l dpkg-dev >/dev/null 2>&1; then
    echo "dpkg-dev 未安装，请输入 Y 开始自动安装，或者按任意键退出。"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # 安装 dpkg-dev
        sudo apt-get update
        sudo apt-get install dpkg-dev
        echo "dpkg-dev 安装完成。"
    else
        echo "退出脚本。"
        exit 1
    fi
fi
}

genInstallScript(){
cat << 'EOF' > install.sh
#!/bin/bash
# 导出离线安装包

# 在脚本开头设置
set -e

#tar cvzf ../aptPackage.tar.gz -C ../aptPackage

gzip -d aptPackage/archives/Packages.gz

mv /etc/apt/sources.list /etc/apt/sources.list.bak
current_dir=$(pwd)
echo "deb [trusted=yes] file://$current_dir/aptPackage archives/" >> /etc/apt/sources.list
apt-get update
EOF
}


env_ready
# Function to parse arguments
echo "开始导出离线源,导出个数为$#.....";
echo "导出个数为$#";
apt-get install -y dpkg-dev
count=1

if [ ! -d "aptPackage" ]; then
    # 文件不存在，创建文件
    mkdir aptPackage
fi
cd aptPackage

if [ ! -f "archives" ]; then
    # 文件不存在，创建文件
    mkdir -p archives
fi

for arg in "$@"; do
    echo "正在导出第$count 个离线源: $arg"
    downloadPackage $arg
    count=$((count + 1))
done
pwd
cd ..
echo "制作.gz文件"
dpkg-scanpackages ./ /dev/null | gzip > aptPackage/archives/Packages.gz -r

genInstallScript
for arg in "$@"; do
    echo "apt install -y  $arg" >> install.sh
done

tar cvzf aptPackage.tar.gz aptPackage install.sh

rm -rf test.sh aptPackage 

