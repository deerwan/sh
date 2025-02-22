#!/bin/bash

# Deer 服务器管理工具 v1.0.0
# 支持: Ubuntu/Debian/CentOS/Alpine/Kali/Arch/RedHat/Fedora/Alma/Rocky

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'#!/bin/bash

# ...existing code...

# 更换软件源功能
change_mirrors() {
    clear
    echo -e "${GREEN}==== 更换软件源 ====${NC}"
    echo "1. 阿里云源"
    echo "2. 清华源"
    echo "3. 中科大源"
    echo "0. 返回主菜单"
    echo
    
    read -p "请选择镜像源 [0-3]: " mirror_choice

    # 备份原有源
    backup_sources() {
        local date_suffix=$(date +%Y%m%d%H%M%S)
        case $OS in
            "ubuntu"|"debian")
                cp /etc/apt/sources.list "/etc/apt/sources.list.bak.$date_suffix"
                ;;
            "centos"|"rhel"|"fedora"|"alma"|"rocky")
                mkdir -p "/etc/yum.repos.d/backup.$date_suffix"
                cp /etc/yum.repos.d/*.repo "/etc/yum.repos.d/backup.$date_suffix/"
                ;;
            "alpine")
                cp /etc/apk/repositories "/etc/apk/repositories.bak.$date_suffix"
                ;;
        esac
        echo -e "${GREEN}已备份原有源文件${NC}"
    }

    # 如果选择返回，直接退出函数
    [ "$mirror_choice" = "0" ] && return

    # 备份原有源
    backup_sources

    case $OS in
        "ubuntu"|"debian")
            local source_file="/etc/apt/sources.list"
            case $mirror_choice in
                1) # 阿里云
                    mirror="mirrors.aliyun.com"
                    ;;
                2) # 清华源
                    mirror="mirrors.tuna.tsinghua.edu.cn"
                    ;;
                3) # 中科大
                    mirror="mirrors.ustc.edu.cn"
                    ;;
                *) 
                    echo -e "${RED}无效选择${NC}"
                    return
                    ;;
            esac
            # 替换源
            if [ "$OS" = "ubuntu" ]; then
                sed -i "s/archive.ubuntu.com/$mirror/g" $source_file
                sed -i "s/security.ubuntu.com/$mirror/g" $source_file
            else
                sed -i "s/deb.debian.org/$mirror/g" $source_file
            fi
            apt update
            ;;
            
        "centos"|"rhel"|"fedora"|"alma"|"rocky")
            case $mirror_choice in
                1) # 阿里云
                    curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-$(rpm -E %{rhel}).repo
                    ;;
                2) # 清华源
                    curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.tuna.tsinghua.edu.cn/repo/centos/$(rpm -E %{rhel})/os/x86_64/
                    ;;
                3) # 中科大
                    curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.ustc.edu.cn/centos/$(rpm -E %{rhel})/os/x86_64/
                    ;;
                *)
                    echo -e "${RED}无效选择${NC}"
                    return
                    ;;
            esac
            yum clean all && yum makecache
            ;;

        "alpine")
            local repo_file="/etc/apk/repositories"
            case $mirror_choice in
                1) mirror="mirrors.aliyun.com" ;;
                2) mirror="mirrors.tuna.tsinghua.edu.cn" ;;
                3) mirror="mirrors.ustc.edu.cn" ;;
                *)
                    echo -e "${RED}无效选择${NC}"
                    return
                    ;;
            esac
            sed -i "s/dl-cdn.alpinelinux.org/$mirror/g" $repo_file
            apk update
            ;;
            
        *)
            echo -e "${RED}暂不支持该系统的换源功能${NC}"
            return
            ;;
    esac
    
    echo -e "${GREEN}软件源更换完成!${NC}"
}

# 修改主菜单
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
    echo "0. 退出"
    echo
}

# 修改主程序部分
while true; do
    show_menu
    read -p "请输入选项 [0-5]: " choice
    case $choice in
        1) system_info ;;
        2) system_update ;;
        3) system_clean ;;
        4) install_tools ;;
        5) change_mirrors ;;
        0) echo "感谢使用!"; exit 0 ;;
        *) echo "无效选项" ;;
    esac
    read -p "按回车键继续..."
done

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

# 显示菜单
show_menu() {
    clear
    echo -e "${GREEN}==== Deer 服务器管理工具 ====${NC}"
    echo "当前系统: $OS $VERSION"
    echo
    echo "1. 系统信息"
    echo "2. 系统更新"
    echo "3. 清理系统"
    echo "4. 安装常用工具"
    echo "0. 退出"
    echo
}

# 系统信息
system_info() {
    echo -e "\n${GREEN}系统信息:${NC}"
    echo "操作系统: $OS $VERSION"
    echo "内核版本: $(uname -r)"
    echo "CPU信息: $(grep 'model name' /proc/cpuinfo | head -n1 | cut -d':' -f2)"
    echo "内存使用: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo "磁盘使用: $(df -h / | awk 'NR==2 {print $3 "/" $2}')"
}

# 系统更新
system_update() {
    echo -e "\n${YELLOW}正在更新系统...${NC}"
    case $PKG_MANAGER in
        "apt")
            apt update && apt upgrade -y
            ;;
        "yum")
            yum update -y
            ;;
        "apk")
            apk update && apk upgrade
            ;;
        "pacman")
            pacman -Syu --noconfirm
            ;;
    esac
}

# 清理系统
system_clean() {
    echo -e "\n${YELLOW}正在清理系统...${NC}"
    case $PKG_MANAGER in
        "apt")
            apt autoremove -y && apt clean
            ;;
        "yum")
            yum clean all
            ;;
        "apk")
            apk cache clean
            ;;
        "pacman")
            pacman -Sc --noconfirm
            ;;
    esac
}

# 安装常用工具
install_tools() {
    echo -e "\n${YELLOW}正在安装常用工具...${NC}"
    TOOLS="curl wget git htop"
    
    case $PKG_MANAGER in
        "apt")
            apt install -y $TOOLS
            ;;
        "yum")
            yum install -y $TOOLS
            ;;
        "apk")
            apk add $TOOLS
            ;;
        "pacman")
            pacman -S --noconfirm $TOOLS
            ;;
    esac
}

# 主程序
while true; do
    show_menu
    read -p "请输入选项 [0-4]: " choice
    case $choice in
        1) system_info ;;
        2) system_update ;;
        3) system_clean ;;
        4) install_tools ;;
        0) echo "感谢使用!"; exit 0 ;;
        *) echo "无效选项" ;;
    esac
    read -p "按回车键继续..."
done
