#!/bin/bash

# Deer 服务器管理工具 v1.0.0
# 支持: Ubuntu/Debian/CentOS/Alpine/Kali/Arch/RedHat/Fedora/Alma/Rocky

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# 检查root权限
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}请使用 root 权限运行此脚本${NC}" 
   exit 1
fi

# 检测系统类型
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo "无法检测系统类型"
    exit 1
fi

# 获取包管理器
get_pkg_manager() {
    case $OS in
        "ubuntu"|"debian"|"kali")
            PKG_MANAGER="apt"
            ;;
        "centos"|"rhel"|"fedora"|"alma"|"rocky")
            PKG_MANAGER="yum"
            ;;
        "alpine")
            PKG_MANAGER="apk"
            ;;
        "arch")
            PKG_MANAGER="pacman"
            ;;
        *)
            echo "不支持的系统类型"
            exit 1
            ;;
    esac
}
get_pkg_manager

# 系统信息
system_info() {
    echo -e "\n${GREEN}系统信息:${NC}"
    echo "操作系统: $OS $VERSION"
    echo "内核版本: $(uname -r)"
    echo "CPU信息: $(grep 'model name' /proc/cpuinfo | head -n1 | cut -d':' -f2)"
    echo "CPU核心数: $(grep -c ^processor /proc/cpuinfo)"
    echo "内存使用: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo "磁盘使用: $(df -h / | awk 'NR==2 {print $3 "/" $2}')"
    echo "已安装软件包数量: $(dpkg -l | grep '^ii' | wc -l 2>/dev/null || rpm -qa | wc -l 2>/dev/null || pacman -Q | wc -l 2>/dev/null || apk info | wc -l 2>/dev/null)"
}

# 系统更新
system_update() {
    echo -e "\n${YELLOW}正在更新系统...${NC}"
    case $PKG_MANAGER in
        "apt")
            apt update && apt upgrade -y || echo -e "${RED}更新失败${NC}"
            ;;
        "yum")
            yum update -y || echo -e "${RED}更新失败${NC}"
            ;;
        "apk")
            apk update && apk upgrade || echo -e "${RED}更新失败${NC}"
            ;;
        "pacman")
            pacman -Syu --noconfirm || echo -e "${RED}更新失败${NC}"
            ;;
    esac
}

# 清理系统
system_clean() {
    echo -e "\n${YELLOW}正在清理系统...${NC}"
    case $PKG_MANAGER in
        "apt")
            apt autoremove -y && apt clean || echo -e "${RED}清理失败${NC}"
            ;;
        "yum")
            yum clean all || echo -e "${RED}清理失败${NC}"
            ;;
        "apk")
            apk cache clean || echo -e "${RED}清理失败${NC}"
            ;;
        "pacman")
            pacman -Sc --noconfirm || echo -e "${RED}清理失败${NC}"
            ;;
    esac
}

# 安装常用工具
install_tools() {
    echo -e "\n${YELLOW}正在安装常用工具...${NC}"
    TOOLS="curl wget git htop"
    
    case $PKG_MANAGER in
        "apt")
            apt install -y $TOOLS || echo -e "${RED}安装失败${NC}"
            ;;
        "yum")
            yum install -y $TOOLS || echo -e "${RED}安装失败${NC}"
            ;;
        "apk")
            apk add $TOOLS || echo -e "${RED}安装失败${NC}"
            ;;
        "pacman")
            pacman -S --noconfirm $TOOLS || echo -e "${RED}安装失败${NC}"
            ;;
    esac
}

# 更换软件源
change_mirrors() {
    echo -e "\n${GREEN}选择镜像源:${NC}"
    echo "1. 阿里云"
    echo "2. 清华源"
    echo "3. 中科大"
    echo "0. 返回"
    
    read -p "请选择 [0-3]: " mirror_choice
    
    change_mirror() {
        local mirror_url=$1
        local backup_file=$2
        local source_file=$3
        
        cp $source_file $backup_file
        sed -i "s|$4|$mirror_url|g" $source_file
    }
    
    case $OS in
        "ubuntu"|"debian")
            backup_file="/etc/apt/sources.list.bak"
            source_file="/etc/apt/sources.list"
            
            case $mirror_choice in
                1) change_mirror "mirrors.aliyun.com" $backup_file $source_file "archive.ubuntu.com\|security.ubuntu.com\|deb.debian.org" ;;
                2) change_mirror "mirrors.tuna.tsinghua.edu.cn" $backup_file $source_file "archive.ubuntu.com\|security.ubuntu.com\|deb.debian.org" ;;
                3) change_mirror "mirrors.ustc.edu.cn" $backup_file $source_file "archive.ubuntu.com\|security.ubuntu.com\|deb.debian.org" ;;
                0) return ;;
                *) echo "无效选项"; return ;;
            esac
            apt update || echo -e "${RED}更新失败${NC}"
            ;;
            
        "centos"|"rhel"|"fedora"|"alma"|"rocky")
            backup_dir="/etc/yum.repos.d/backup"
            mkdir -p $backup_dir
            cp /etc/yum.repos.d/*.repo $backup_dir/
            
            case $mirror_choice in
                1) curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-$(rpm -E %{rhel}).repo ;;
                2) curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.tuna.tsinghua.edu.cn/repo/centos/$(rpm -E %{rhel})/os/x86_64/ ;;
                3) curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.ustc.edu.cn/centos/$(rpm -E %{rhel})/os/x86_64/ ;;
                0) return ;;
                *) echo "无效选项"; return ;;
            esac
            yum clean all && yum makecache || echo -e "${RED}更新失败${NC}"
            ;;
            
        "alpine")
            cp /etc/apk/repositories /etc/apk/repositories.bak
            
            case $mirror_choice in
                1) change_mirror "mirrors.aliyun.com" "/etc/apk/repositories.bak" "/etc/apk/repositories" "dl-cdn.alpinelinux.org" ;;
                2) change_mirror "mirrors.tuna.tsinghua.edu.cn" "/etc/apk/repositories.bak" "/etc/apk/repositories" "dl-cdn.alpinelinux.org" ;;
                3) change_mirror "mirrors.ustc.edu.cn" "/etc/apk/repositories.bak" "/etc/apk/repositories" "dl-cdn.alpinelinux.org" ;;
                0) return ;;
                *) echo "无效选项"; return ;;
            esac
            apk update || echo -e "${RED}更新失败${NC}"
            ;;
    esac
    echo -e "${GREEN}软件源更换完成!${NC}"
}

# Docker 管理功能
docker_manage() {
    clear
    echo -e "${GREEN}==== Docker 管理 ====${NC}"
    echo "1. 安装 Docker 和 Docker Compose"
    echo "2. 卸载 Docker"
    echo "3. 启动 Docker"
    echo "4. 停止 Docker"
    echo "5. 重启 Docker"
    echo "6. 查看 Docker 容器状态"
    echo "0. 返回主菜单"
    echo
    
    read -p "请选择操作 [0-6]: " docker_choice
    
    case $docker_choice in
        1)
            echo -e "\n${YELLOW}正在安装 Docker...${NC}"
            
            # 判断是否为国内网络
            read -p "是否使用国内 Docker 源? [y/n]: " use_china_source
            if [ "$use_china_source" == "y" ]; then
                echo -e "\n${YELLOW}使用国内 Docker 源...${NC}"
                curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
            else
                echo -e "\n${YELLOW}使用默认 Docker 源...${NC}"
                curl -fsSL https://get.docker.com | bash
            fi
            
            systemctl start docker
            systemctl enable docker
            echo -e "${GREEN}Docker 安装完成！${NC}"
            
            read -p "是否安装 Docker Compose? [y/n]: " install_compose
            if [ "$install_compose" == "y" ]; then
                echo -e "\n${YELLOW}正在安装 Docker Compose...${NC}"
                curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                chmod +x /usr/local/bin/docker-compose
                echo -e "${GREEN}Docker Compose 安装完成！${NC}"
            fi
            ;;
        2)
            echo -e "\n${YELLOW}正在卸载 Docker...${NC}"
            systemctl stop docker
            case $PKG_MANAGER in
                "apt")
                    apt purge -y docker-ce docker-ce-cli containerd.io
                    apt autoremove -y
                    ;;
                "yum")
                    yum remove -y docker-ce docker-ce-cli containerd.io
                    ;;
            esac
            rm -rf /var/lib/docker
            rm -rf /var/lib/containerd
            echo -e "${GREEN}Docker 卸载完成！${NC}"
            ;;
        3)
            systemctl start docker
            echo -e "${GREEN}Docker 已启动！${NC}"
            ;;
        4)
            systemctl stop docker
            echo -e "${GREEN}Docker 已停止！${NC}"
            ;;
        5)
            systemctl restart docker
            echo -e "${GREEN}Docker 已重启！${NC}"
            ;;
        6)
            echo -e "\n${YELLOW}Docker 容器状态:${NC}"
            docker ps -a
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}无效选项${NC}"
            ;;
    esac
}

# 主菜单
show_menu() {
    clear
    echo -e "${GREEN}==== Deer 服务器管理工具 ====${NC}"
    echo "当前系统: $OS $VERSION"
    echo
    echo "1. 系统信息"
    echo "2. 系统更新"
    echo "3. 清理系统"
    echo "4. 安装常用工具"
    echo "5. 更换软件源"
    echo "6. Docker 管理"
    echo "0. 退出"
    echo
}

# 主程序
while true; do
    show_menu
    read -p "请输入选项 [0-6]: " choice
    case $choice in
        1) system_info ;;
        2) system_update ;;
        3) system_clean ;;
        4) install_tools ;;
        5) change_mirrors ;;
        6) docker_manage ;;
        0) echo "感谢使用!"; exit 0 ;;
        *) echo "无效选项" ;;
    esac
    read -p "按回车键继续..."
done
