#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

# 添加一些基本功能
function LOGD() {
    echo -e "${yellow}[调试] $* ${plain}"
}

function LOGE() {
    echo -e "${red}[错误] $* ${plain}"
}

function LOGI() {
    echo -e "${green}[信息] $* ${plain}"
}

# 检查 root 权限
[[ $EUID -ne 0 ]] && LOGE "错误：你必须以 root 用户身份运行此脚本！\n" && exit 1

# 检查操作系统并设置 release 变量
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "无法检查系统操作系统，请联系作者！" >&2
    exit 1
fi

echo "操作系统版本是: $release"

os_version=""
os_version=$(grep "^VERSION_ID" /etc/os-release | cut -d '=' -f2 | tr -d '"' | tr -d '.')

if [[ "${release}" == "arch" ]]; then
    echo "你的操作系统是 Arch Linux"
elif [[ "${release}" == "parch" ]]; then
    echo "你的操作系统是 Parch Linux"
elif [[ "${release}" == "manjaro" ]]; then
    echo "你的操作系统是 Manjaro"
elif [[ "${release}" == "armbian" ]]; then
    echo "你的操作系统是 Armbian"
elif [[ "${release}" == "alpine" ]]; then
    echo "你的操作系统是 Alpine Linux"
elif [[ "${release}" == "opensuse-tumbleweed" ]]; then
    echo "你的操作系统是 OpenSUSE Tumbleweed"
elif [[ "${release}" == "openEuler" ]]; then
    if [[ ${os_version} -lt 2203 ]]; then
        echo -e "${red} 请使用 OpenEuler 22.03 或更高版本 ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "centos" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} 请使用 CentOS 8 或更高版本 ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "ubuntu" ]]; then
    if [[ ${os_version} -lt 2004 ]]; then
        echo -e "${red} 请使用 Ubuntu 20 或更高版本！${plain}\n" && exit 1
    fi
elif [[ "${release}" == "fedora" ]]; then
    if [[ ${os_version} -lt 36 ]]; then
        echo -e "${red} 请使用 Fedora 36 或更高版本！${plain}\n" && exit 1
    fi
elif [[ "${release}" == "amzn" ]]; then
    if [[ ${os_version} != "2023" ]]; then
        echo -e "${red} 请使用 Amazon Linux 2023！${plain}\n" && exit 1
    fi
elif [[ "${release}" == "debian" ]]; then
    if [[ ${os_version} -lt 11 ]]; then
        echo -e "${red} 请使用 Debian 11 或更高版本 ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "almalinux" ]]; then
    if [[ ${os_version} -lt 80 ]]; then
        echo -e "${red} 请使用 AlmaLinux 8.0 或更高版本 ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "rocky" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} 请使用 Rocky Linux 8 或更高版本 ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "ol" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} 请使用 Oracle Linux 8 或更高版本 ${plain}\n" && exit 1
    fi
else
    echo -e "${red}你的操作系统不受此脚本支持。${plain}\n"
    echo "请确保你使用的是以下支持的操作系统之一："
    echo "- Ubuntu 20.04+"
    echo "- Debian 11+"
    echo "- CentOS 8+"
    echo "- OpenEuler 22.03+"
    echo "- Fedora 36+"
    echo "- Arch Linux"
    echo "- Parch Linux"
    echo "- Manjaro"
    echo "- Armbian"
    echo "- AlmaLinux 8.0+"
    echo "- Rocky Linux 8+"
    echo "- Oracle Linux 8+"
    echo "- OpenSUSE Tumbleweed"
    echo "- Amazon Linux 2023"
    exit 1
fi

# 声明变量
log_folder="${XUI_LOG_FOLDER:=/var/log}"
iplimit_log_path="${log_folder}/3xipl.log"
iplimit_banned_log_path="${log_folder}/3xipl-banned.log"

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [默认 $2]: " temp
        if [[ "${temp}" == "" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ "${temp}" == "y" || "${temp}" == "Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "重启面板，注意：重启面板也会重启 xray" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}按回车键返回主菜单：${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.gitmirror.com/GH6324/3xui-cn/main/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    confirm "此功能将强制重新安装最新版本，数据不会丢失。是否继续？" "y"
    if [[ $? != 0 ]]; then
        LOGE "已取消"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    bash <(curl -Ls https://raw.gitmirror.com/GH6324/3xui-cn/main/install.sh)
    if [[ $? == 0 ]]; then
        LOGI "更新完成，面板已自动重启"
        before_show_menu
    fi
}

update_menu() {
    echo -e "${yellow}更新菜单${plain}"
    confirm "此功能将更新菜单到最新更改。" "y"
    if [[ $? != 0 ]]; then
        LOGE "已取消"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi

    wget --no-check-certificate -O /usr/bin/x-ui https://raw.gitmirror.com/GH6324/3xui-cn/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui

    if [[ $? == 0 ]]; then
        echo -e "${green}更新成功。面板已自动重启。${plain}"
        before_show_menu
    else
        echo -e "${red}更新菜单失败。${plain}"
        return 1
    fi
}

legacy_version() {
    echo "输入面板版本（例如 2.4.0）："
    read tag_version

    if [ -z "$tag_version" ]; then
        echo "面板版本不能为空。退出。"
        exit 1
    fi
    # 使用输入的面板版本在下载链接中
    install_command="bash <(curl -Ls "https://raw.gitmirror.com/GH6324/3xui-cn/v$tag_version/install.sh") v$tag_version"

    echo "下载并安装面板版本 $tag_version..."
    eval $install_command
}

# 处理脚本文件删除的函数
delete_script() {
    rm "$0" # 删除脚本文件本身
    exit 1
}

uninstall() {
    confirm "你确定要卸载面板吗？xray 也会被卸载！" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop x-ui
    systemctl disable x-ui
    rm /etc/systemd/system/x-ui.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/x-ui/ -rf
    rm /usr/local/x-ui/ -rf

    echo ""
    echo -e "卸载成功。\n"
    echo "如果你需要重新安装此面板，可以使用以下命令："
    echo -e "${green}bash <(curl -Ls https://raw.gitmirror.com/GH6324/3xui-cn/master/install.sh)${plain}"
    echo ""
    # 捕获 SIGTERM 信号
    trap delete_script SIGTERM
    delete_script
}

reset_user() {
    confirm "你确定要重置面板的用户名和密码吗？" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    read -rp "请设置登录用户名 [默认是随机用户名]： " config_account
    [[ -z $config_account ]] && config_account=$(date +%s%N | md5sum | cut -c 1-8)
    read -rp "请设置登录密码 [默认是随机密码]： " config_password
    [[ -z $config_password ]] && config_password=$(date +%s%N | md5sum | cut -c 1-8)
    /usr/local/x-ui/x-ui setting -username ${config_account} -password ${config_password} >/dev/null 2>&1
    /usr/local/x-ui/x-ui setting -remove_secret >/dev/null 2>&1
    echo -e "面板登录用户名已重置为：${green} ${config_account} ${plain}"
    echo -e "面板登录密码已重置为：${green} ${config_password} ${plain}"
    echo -e "${yellow} 面板登录密钥已禁用 ${plain}"
    echo -e "${green} 请使用新的登录用户名和密码访问 X-UI 面板。请记住它们！${plain}"
    confirm_restart
}

gen_random_string() {
    local length="$1"
    local random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1)
    echo "$random_string"
}

reset_webbasepath() {
    echo -e "${yellow}重置 Web 基础路径${plain}"

    read -rp "你确定要重置 Web 基础路径吗？(y/n): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo -e "${yellow}操作已取消。${plain}"
        return
    fi

    config_webBasePath=$(gen_random_string 10)

    # 应用新的 Web 基础路径设置
    /usr/local/x-ui/x-ui setting -webBasePath "${config_webBasePath}" >/dev/null 2>&1
    
    echo -e "Web 基础路径已重置为：${green}${config_webBasePath}${plain}"
    echo -e "${green}请使用新的 Web 基础路径访问面板。${plain}"
    restart
}

reset_config() {
    confirm "你确定要重置所有面板设置吗？账户数据不会丢失，用户名和密码不会更改。" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -reset
    echo -e "所有面板设置已重置为默认值。"
    restart
}

check_config() {
    local info=$(/usr/local/x-ui/x-ui setting -show true)
    if [[ $? != 0 ]]; then
        LOGE "获取当前设置错误，请检查日志"
        show_menu
        return
    fi
    LOGI "${info}"

    local existing_webBasePath=$(echo "$info" | grep -Eo 'webBasePath: .+' | awk '{print $2}')
    local existing_port=$(echo "$info" | grep -Eo 'port: .+' | awk '{print $2}')
    local existing_cert=$(/usr/local/x-ui/x-ui setting -getCert true | grep -Eo 'cert: .+' | awk '{print $2}')
    local server_ip=$(curl -s https://api.ipify.org)

    if [[ -n "$existing_cert" ]]; then
        local domain=$(basename "$(dirname "$existing_cert")")

        if [[ "$domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo -e "${green}访问 URL: https://${domain}:${existing_port}${existing_webBasePath}${plain}"
        else
            echo -e "${green}访问 URL: https://${server_ip}:${existing_port}${existing_webBasePath}${plain}"
        fi
    else
        echo -e "${green}访问 URL: http://${server_ip}:${existing_port}${existing_webBasePath}${plain}"
    fi
}

set_port() {
    echo && echo -n -e "输入端口号[1-65535]: " && read port
    if [[ -z "${port}" ]]; then
        LOGD "已取消"
        before_show_menu
    else
        /usr/local/x-ui/x-ui setting -port ${port}
        echo -e "端口已设置，请立即重启面板，并使用新端口 ${green}${port}${plain} 访问 Web 面板"
        confirm_restart
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        LOGI "面板正在运行，无需再次启动。如果你需要重启，请选择重启"
    else
        systemctl start x-ui
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            LOGI "x-ui 启动成功"
        else
            LOGE "面板启动失败，可能是因为启动时间超过两秒，请稍后检查日志信息"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        LOGI "面板已停止，无需再次停止！"
    else
        systemctl stop x-ui
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            LOGI "x-ui 和 xray 已成功停止"
        else
            LOGE "面板停止失败，可能是因为停止时间超过两秒，请稍后检查日志信息"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart x-ui
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        LOGI "x-ui 和 xray 已成功重启"
    else
        LOGE "面板重启失败，可能是因为启动时间超过两秒，请稍后检查日志信息"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status x-ui -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable x-ui
    if [[ $? == 0 ]]; then
        LOGI "x-ui 已设置为开机自动启动"
    else
        LOGE "x-ui 设置开机自动启动失败"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable x-ui
    if [[ $? == 0 ]]; then
        LOGI "x-ui 已取消开机自动启动"
    else
        LOGE "x-ui 取消开机自动启动失败"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    echo -e "${green}\t1.${plain} 调试日志"
    echo -e "${green}\t2.${plain} 清除所有日志"
    echo -e "${green}\t0.${plain} 返回主菜单"
    read -p "选择一个选项: " choice

    case "$choice" in
    0)
        show_menu
        ;;
    1)
        journalctl -u x-ui -e --no-pager -f -p debug
        if [[ $# == 0 ]]; then
        before_show_menu
        fi
        ;;
    2)
        sudo journalctl --rotate
        sudo journalctl --vacuum-time=1s
        echo "所有日志已清除。"
        restart
        ;;
    *)
        echo -e "${red}无效选项。请选择一个有效的数字。${plain}\n"
        show_log
        ;;
    esac
}

show_banlog() {
    local system_log="/var/log/fail2ban.log"
    
    echo -e "${green}检查封禁日志...${plain}\n"
    
    if ! systemctl is-active --quiet fail2ban; then
        echo -e "${red}Fail2ban 服务未运行！${plain}\n"
        return 1
    fi

    if [[ -f "$system_log" ]]; then
        echo -e "${green}最近的系统封禁活动来自 fail2ban.log:${plain}"
        grep "3x-ipl" "$system_log" | grep -E "Ban|Unban" | tail -n 10 || echo -e "${yellow}未找到最近的系统封禁活动${plain}"
        echo ""
    fi

    if [[ -f "${iplimit_banned_log_path}" ]]; then
        echo -e "${green}3X-IPL 封禁日志条目:${plain}"
        if [[ -s "${iplimit_banned_log_path}" ]]; then
            grep -v "INIT" "${iplimit_banned_log_path}" | tail -n 10 || echo -e "${yellow}未找到封禁条目${plain}"
        else
            echo -e "${yellow}封禁日志文件为空${plain}"
        fi
    else
        echo -e "${red}封禁日志文件未找到: ${iplimit_banned_log_path}${plain}"
    fi

    echo -e "\n${green}当前封禁状态:${plain}"
    fail2ban-client status 3x-ipl || echo -e "${yellow}无法获取封禁状态${plain}"
}

bbr_menu() {
    echo -e "${green}\t1.${plain} 启用 BBR"
    echo -e "${green}\t2.${plain} 禁用 BBR"
    echo -e "${green}\t0.${plain} 返回主菜单"
    read -p "选择一个选项: " choice
    case "$choice" in
    0)
        show_menu
        ;;
    1)
        enable_bbr
        bbr_menu
        ;;
    2)
        disable_bbr
        bbr_menu
        ;;
    *) 
        echo -e "${red}无效选项。请选择一个有效的数字。${plain}\n"
        bbr_menu
        ;;
    esac
}

disable_bbr() {

    if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf || ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
        echo -e "${yellow}BBR 当前未启用。${plain}"
        before_show_menu
    fi

    # 将 BBR 替换为 CUBIC 配置
    sed -i 's/net.core.default_qdisc=fq/net.core.default_qdisc=pfifo_fast/' /etc/sysctl.conf
    sed -i 's/net.ipv4.tcp_congestion_control=bbr/net.ipv4.tcp_congestion_control=cubic/' /etc/sysctl.conf

    # 应用更改
    sysctl -p

    # 验证 BBR 是否已替换为 CUBIC
    if [[ $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}') == "cubic" ]]; then
        echo -e "${green}BBR 已成功替换为 CUBIC。${plain}"
    else
        echo -e "${red}将 BBR 替换为 CUBIC 失败。请检查系统配置。${plain}"
    fi
}

enable_bbr() {
    if grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf && grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
        echo -e "${green}BBR 已启用！${plain}"
        before_show_menu
    fi

    # 检查操作系统并安装必要的包
    case "${release}" in
    ubuntu | debian | armbian)
        apt-get update && apt-get install -yqq --no-install-recommends ca-certificates
        ;;
    centos | almalinux | rocky | ol)
        yum -y update && yum -y install ca-certificates
        ;;
    fedora | amzn)
        dnf -y update && dnf -y install ca-certificates
        ;;
    arch | manjaro | parch)
        pacman -Sy --noconfirm ca-certificates
        ;;
    *)
        echo -e "${red}不支持的操作系统。请检查脚本并手动安装必要的包。${plain}\n"
        exit 1
        ;;
    esac

    # 启用 BBR
    echo "net.core.default_qdisc=fq" | tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | tee -a /etc/sysctl.conf

    # 应用更改
    sysctl -p

    # 验证 BBR 是否已启用
    if [[ $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}') == "bbr" ]]; then
        echo -e "${green}BBR 已成功启用。${plain}"
    else
        echo -e "${red}启用 BBR 失败。请检查系统配置。${plain}"
    fi
}

update_shell() {
    wget -O /usr/bin/x-ui -N --no-check-certificate https://raw.gitmirror.com/GH6324/3xui-cn/main/x-ui.sh
    if [[ $? != 0 ]]; then
        echo ""
        LOGE "下载脚本失败，请检查机器是否可以连接 Github"
        before_show_menu
    else
        chmod +x /usr/bin/x-ui
        LOGI "升级脚本成功，请重新运行脚本" 
        before_show_menu
    fi
}

# 0: 运行中, 1: 未运行, 2: 未安装
check_status() {
    if [[ ! -f /etc/systemd/system/x-ui.service ]]; then
        return 2
    fi
    temp=$(systemctl status x-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ "${temp}" == "running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled x-ui)
    if [[ "${temp}" == "enabled" ]]; then
        return 0
    else
        return 1
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        LOGE "面板已安装，请勿重新安装"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        LOGE "请先安装面板"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
    0)
        echo -e "面板状态: ${green}运行中${plain}"
        show_enable_status
        ;;
    1)
        echo -e "面板状态: ${yellow}未运行${plain}"
        show_enable_status
        ;;
    2)
        echo -e "面板状态: ${red}未安装${plain}"
        ;;
    esac
    show_xray_status
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "开机自动启动: ${green}是${plain}"
    else
        echo -e "开机自动启动: ${red}否${plain}"
    fi
}

check_xray_status() {
    count=$(ps -ef | grep "xray-linux" | grep -v "grep" | wc -l)
    if [[ count -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

show_xray_status() {
    check_xray_status
    if [[ $? == 0 ]]; then
        echo -e "xray 状态: ${green}运行中${plain}"
    else
        echo -e "xray 状态: ${red}未运行${plain}"
    fi
}

firewall_menu() {
    echo -e "${green}\t1.${plain} ${green}安装${plain} 防火墙"
    echo -e "${green}\t2.${plain} 端口列表 [编号]"
    echo -e "${green}\t3.${plain} ${green}开放${plain} 端口"
    echo -e "${green}\t4.${plain} ${red}删除${plain} 端口列表中的端口"
    echo -e "${green}\t5.${plain} ${green}启用${plain} 防火墙"
    echo -e "${green}\t6.${plain} ${red}禁用${plain} 防火墙"
    echo -e "${green}\t7.${plain} 防火墙状态"
    echo -e "${green}\t0.${plain} 返回主菜单"
    read -p "选择一个选项: " choice
    case "$choice" in
    0)
        show_menu
        ;;
    1)
        install_firewall
        firewall_menu
        ;;
    2)
        ufw status numbered
        firewall_menu
        ;;
    3)
        open_ports
        firewall_menu
        ;;
    4)
        delete_ports
        firewall_menu
        ;;
    5)
        ufw enable
        firewall_menu
        ;;
    6)
        ufw disable
        firewall_menu
        ;;
    7)
        ufw status verbose
        firewall_menu
        ;;
    *) 
        echo -e "${red}无效选项。请选择一个有效的数字。${plain}\n"
        firewall_menu
        ;;
    esac
}

install_firewall() {
    if ! command -v ufw &>/dev/null; then
        echo "ufw 防火墙未安装。正在安装..."
        apt-get update
        apt-get install -y ufw
    else
        echo "ufw 防火墙已安装"
    fi

    # 检查防火墙是否未激活
    if ufw status | grep -q "Status: active"; then
        echo "防火墙已激活"
    else
        echo "激活防火墙..."
        # 开放必要的端口
        ufw allow ssh
        ufw allow http
        ufw allow https
        ufw allow 2053/tcp #webPort
        ufw allow 2096/tcp #subport

        # 启用防火墙
        ufw --force enable
    fi
}

open_ports() {
    # 提示用户输入要开放的端口
    read -p "输入要开放的端口（例如 80,443,2053 或范围 400-500）: " ports

    # 检查输入是否有效
    if ! [[ $ports =~ ^([0-9]+|[0-9]+-[0-9]+)(,([0-9]+|[0-9]+-[0-9]+))*$ ]]; then
        echo "错误：无效输入。请输入逗号分隔的端口列表或端口范围（例如 80,443,2053 或 400-500）。" >&2
        exit 1
    fi

    # 使用 ufw 开放指定的端口
    IFS=',' read -ra PORT_LIST <<<"$ports"
    for port in "${PORT_LIST[@]}"; do
        if [[ $port == *-* ]]; then
            # 将范围拆分为起始端口和结束端口
            start_port=$(echo $port | cut -d'-' -f1)
            end_port=$(echo $port | cut -d'-' -f2)
            # 开放端口范围
            ufw allow $start_port:$end_port/tcp
            ufw allow $start_port:$end_port/udp
        else
            # 开放单个端口
            ufw allow "$port"
        fi
    done

    # 确认端口已开放
    echo "已开放指定的端口:"
    for port in "${PORT_LIST[@]}"; do
        if [[ $port == *-* ]]; then
            start_port=$(echo $port | cut -d'-' -f1)
            end_port=$(echo $port | cut -d'-' -f2)
            # 检查端口范围是否已成功开放
            (ufw status | grep -q "$start_port:$end_port") && echo "$start_port-$end_port"
        else
            # 检查单个端口是否已成功开放
            (ufw status | grep -q "$port") && echo "$port"
        fi
    done
}

delete_ports() {
    # 显示当前规则及其编号
    echo "当前 UFW 规则:"
    ufw status numbered

    # 询问用户如何删除规则
    echo "你想如何删除规则："
    echo "1) 按规则编号删除"
    echo "2) 按端口删除"
    read -p "输入你的选择 (1 或 2): " choice

    if [[ $choice -eq 1 ]]; then
        # 按规则编号删除
        read -p "输入要删除的规则编号 (1, 2, 等): " rule_numbers

        # 验证输入
        if ! [[ $rule_numbers =~ ^([0-9]+)(,[0-9]+)*$ ]]; then
            echo "错误：无效输入。请输入逗号分隔的规则编号列表。" >&2
            exit 1
        fi

        # 将编号拆分为数组
        IFS=',' read -ra RULE_NUMBERS <<<"$rule_numbers"
        for rule_number in "${RULE_NUMBERS[@]}"; do
            # 按编号删除规则
            ufw delete "$rule_number" || echo "删除规则编号 $rule_number 失败"
        done

        echo "已删除选定的规则。"

    elif [[ $choice -eq 2 ]]; then
        # 按端口删除
        read -p "输入要删除的端口（例如 80,443,2053 或范围 400-500）: " ports

        # 验证输入
        if ! [[ $ports =~ ^([0-9]+|[0-9]+-[0-9]+)(,([0-9]+|[0-9]+-[0-9]+))*$ ]]; then
            echo "错误：无效输入。请输入逗号分隔的端口列表或端口范围（例如 80,443,2053 或 400-500）。" >&2
            exit 1
        fi

        # 将端口拆分为数组
        IFS=',' read -ra PORT_LIST <<<"$ports"
        for port in "${PORT_LIST[@]}"; do
            if [[ $port == *-* ]]; then
                # 拆分端口范围
                start_port=$(echo $port | cut -d'-' -f1)
                end_port=$(echo $port | cut -d'-' -f2)
                # 删除端口范围
                ufw delete allow $start_port:$end_port/tcp
                ufw delete allow $start_port:$end_port/udp
            else
                # 删除单个端口
                ufw delete allow "$port"
            fi
        done

        # 确认删除
        echo "已删除指定的端口:"
        for port in "${PORT_LIST[@]}"; do
            if [[ $port == *-* ]]; then
                start_port=$(echo $port | cut -d'-' -f1)
                end_port=$(echo $port | cut -d'-' -f2)
                # 检查端口范围是否已删除
                (ufw status | grep -q "$start_port:$end_port") || echo "$start_port-$end_port"
            else
                # 检查单个端口是否已删除
                (ufw status | grep -q "$port") || echo "$port"
            fi
        done
    else
        echo "${red}错误：${plain} 无效选择。请输入 1 或 2。" >&2
        exit 1
    fi
}

update_geo() {
    echo -e "${green}\t1.${plain} Loyalsoldier (geoip.dat, geosite.dat)"
    echo -e "${green}\t2.${plain} chocolate4u (geoip_IR.dat, geosite_IR.dat)"
    echo -e "${green}\t3.${plain} runetfreedom (geoip_RU.dat, geosite_RU.dat)"
    echo -e "${green}\t0.${plain} 返回主菜单"
    read -p "选择一个选项: " choice

    cd /usr/local/x-ui/bin

    case "$choice" in
    0)
        show_menu
        ;;
    1)
        systemctl stop x-ui
        rm -f geoip.dat geosite.dat
        wget -N https://hub.gitmirror.com/https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
        wget -N https://hub.gitmirror.com/https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
        echo -e "${green}Loyalsoldier 数据集已成功更新！${plain}"
        restart
        ;;
    2)
        systemctl stop x-ui
        rm -f geoip_IR.dat geosite_IR.dat
        wget -O geoip_IR.dat -N https://hub.gitmirror.com/https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geoip.dat
        wget -O geosite_IR.dat -N https://hub.gitmirror.com/https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geosite.dat
        echo -e "${green}chocolate4u 数据集已成功更新！${plain}"
        restart
        ;;
    3)
        systemctl stop x-ui
        rm -f geoip_RU.dat geosite_RU.dat
        wget -O geoip_RU.dat -N https://hub.gitmirror.com/https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geoip.dat
        wget -O geosite_RU.dat -N https://hub.gitmirror.com/https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geosite.dat
        echo -e "${green}runetfreedom 数据集已成功更新！${plain}"
        restart
        ;;
    *)
        echo -e "${red}无效选项。请选择一个有效的数字。${plain}\n"
        update_geo
        ;;
    esac

    before_show_menu
}

install_acme() {
    # 检查是否已安装 acme.sh
    if command -v ~/.acme.sh/acme.sh &>/dev/null; then
        LOGI "acme.sh 已安装。"
        return 0
    fi

    LOGI "正在安装 acme.sh..."
    cd ~ || return 1 # 确保可以切换到主目录

    curl -s https://get.acme.sh | sh
    if [ $? -ne 0 ]; then
        LOGE "安装 acme.sh 失败。"
        return 1
    else
        LOGI "acme.sh 安装成功。"
    fi

    return 0
}

ssl_cert_issue_main() {
    echo -e "${green}\t1.${plain} 获取 SSL 证书"
    echo -e "${green}\t2.${plain} 吊销证书"
    echo -e "${green}\t3.${plain} 强制续期"
    echo -e "${green}\t4.${plain} 显示现有域名"
    echo -e "${green}\t5.${plain} 为面板设置证书路径"
    echo -e "${green}\t0.${plain} 返回主菜单"

    read -p "选择一个选项: " choice
    case "$choice" in
    0)
        show_menu
        ;;
    1)
        ssl_cert_issue
        ssl_cert_issue_main
        ;;
    2)
        local domains=$(find /root/cert/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
        if [ -z "$domains" ]; then
            echo "未找到可吊销的证书。"
        else
            echo "现有域名:"
            echo "$domains"
            read -p "请输入列表中的域名以吊销证书: " domain
            if echo "$domains" | grep -qw "$domain"; then
                ~/.acme.sh/acme.sh --revoke -d ${domain}
                LOGI "域名 $domain 的证书已吊销"
            else
                echo "输入的域名无效。"
            fi
        fi
        ssl_cert_issue_main
        ;;
    3)
        local domains=$(find /root/cert/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
        if [ -z "$domains" ]; then
            echo "未找到可续期的证书。"
        else
            echo "现有域名:"
            echo "$domains"
            read -p "请输入列表中的域名以续期 SSL 证书: " domain
            if echo "$domains" | grep -qw "$domain"; then
                ~/.acme.sh/acme.sh --renew -d ${domain} --force
                LOGI "域名 $domain 的证书已强制续期"
            else
                echo "输入的域名无效。"
            fi
        fi
        ssl_cert_issue_main
        ;;
    4)
        local domains=$(find /root/cert/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
        if [ -z "$domains" ]; then
            echo "未找到证书。"
        else
            echo "现有域名及其路径:"
            for domain in $domains; do
                local cert_path="/root/cert/${domain}/fullchain.pem"
                local key_path="/root/cert/${domain}/privkey.pem"
                if [[ -f "${cert_path}" && -f "${key_path}" ]]; then
                    echo -e "域名: ${domain}"
                    echo -e "\t证书路径: ${cert_path}"
                    echo -e "\t私钥路径: ${key_path}"
                else
                    echo -e "域名: ${domain} - 证书或密钥缺失。"
                fi
            done
        fi
        ssl_cert_issue_main
        ;;
    5)
        local domains=$(find /root/cert/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
        if [ -z "$domains" ]; then
            echo "未找到证书。"
        else
            echo "可用域名:"
            echo "$domains"
            read -p "请选择一个域名以设置面板路径: " domain

            if echo "$domains" | grep -qw "$domain"; then
                local webCertFile="/root/cert/${domain}/fullchain.pem"
                local webKeyFile="/root/cert/${domain}/privkey.pem"

                if [[ -f "${webCertFile}" && -f "${webKeyFile}" ]]; then
                    /usr/local/x-ui/x-ui cert -webCert "$webCertFile" -webCertKey "$webKeyFile"
                    echo "已为域名 $domain 设置面板路径"
                    echo "  - 证书文件: $webCertFile"
                    echo "  - 私钥文件: $webKeyFile"
                    restart
                else
                    echo "未找到域名 $domain 的证书或私钥。"
                fi
            else
                echo "输入的域名无效。"
            fi
        fi
        ssl_cert_issue_main
        ;;

    *)
        echo -e "${red}无效选项。请选择一个有效的数字。${plain}\n"
        ssl_cert_issue_main
        ;;
    esac
}

ssl_cert_issue() {
    local existing_webBasePath=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'webBasePath: .+' | awk '{print $2}')
    local existing_port=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'port: .+' | awk '{print $2}')
    # 首先检查 acme.sh
    if ! command -v ~/.acme.sh/acme.sh &>/dev/null; then
        echo "未找到 acme.sh。我们将安装它"
        install_acme
        if [ $? -ne 0 ]; then
            LOGE "安装 acme 失败，请检查日志"
            exit 1
        fi
    fi

    # 安装 socat
    case "${release}" in
    ubuntu | debian | armbian)
        apt update && apt install socat -y
        ;;
    centos | almalinux | rocky | ol)
        yum -y update && yum -y install socat
        ;;
    fedora | amzn)
        dnf -y update && dnf -y install socat
        ;;
    arch | manjaro | parch)
        pacman -Sy --noconfirm socat
        ;;
    *)
        echo -e "${red}不支持的操作系统。请检查脚本并手动安装必要的包。${plain}\n"
        exit 1
        ;;
    esac
    if [ $? -ne 0 ]; then
        LOGE "安装 socat 失败，请检查日志"
        exit 1
    else
        LOGI "安装 socat 成功..."
    fi

    # 获取域名并验证
    local domain=""
    read -p "请输入你的域名: " domain
    LOGD "你的域名是: ${domain}, 正在检查..."

    # 检查是否已存在证书
    local currentCert=$(~/.acme.sh/acme.sh --list | tail -1 | awk '{print $1}')
    if [ "${currentCert}" == "${domain}" ]; then
        local certInfo=$(~/.acme.sh/acme.sh --list)
        LOGE "系统已存在此域名的证书。无法再次颁发。当前证书详情:"
        LOGI "$certInfo"
        exit 1
    else
        LOGI "你的域名已准备好颁发证书..."
    fi

    # 为证书创建目录
    certPath="/root/cert/${domain}"
    if [ ! -d "$certPath" ]; then
        mkdir -p "$certPath"
    else
        rm -rf "$certPath"
        mkdir -p "$certPath"
    fi

    # 获取独立服务器的端口号
    local WebPort=80
    read -p "请选择要使用的端口（默认是 80）: " WebPort
    if [[ ${WebPort} -gt 65535 || ${WebPort} -lt 1 ]]; then
        LOGE "你的输入 ${WebPort} 无效，将使用默认端口 80。"
        WebPort=80
    fi
    LOGI "将使用端口: ${WebPort} 颁发证书。请确保此端口已开放。"

    # 颁发证书
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    ~/.acme.sh/acme.sh --issue -d ${domain} --listen-v6 --standalone --httpport ${WebPort}
    if [ $? -ne 0 ]; then
        LOGE "颁发证书失败，请检查日志。"
        rm -rf ~/.acme.sh/${domain}
        exit 1
    else
        LOGE "颁发证书成功，正在安装证书..."
    fi

    # 安装证书
    ~/.acme.sh/acme.sh --installcert -d ${domain} \
        --key-file /root/cert/${domain}/privkey.pem \
        --fullchain-file /root/cert/${domain}/fullchain.pem

    if [ $? -ne 0 ]; then
        LOGE "安装证书失败，退出。"
        rm -rf ~/.acme.sh/${domain}
        exit 1
    else
        LOGI "安装证书成功，正在启用自动续期..."
    fi

    # 启用自动续期
    ~/.acme.sh/acme.sh --upgrade --auto-upgrade
    if [ $? -ne 0 ]; then
        LOGE "自动续期失败，证书详情:"
        ls -lah cert/*
        chmod 755 $certPath/*
        exit 1
    else
        LOGI "自动续期成功，证书详情:"
        ls -lah cert/*
        chmod 755 $certPath/*
    fi

    # 提示用户在成功安装证书后设置面板路径
    read -p "你希望为面板设置此证书吗？(y/n): " setPanel
    if [[ "$setPanel" == "y" || "$setPanel" == "Y" ]]; then
        local webCertFile="/root/cert/${domain}/fullchain.pem"
        local webKeyFile="/root/cert/${domain}/privkey.pem"

        if [[ -f "$webCertFile" && -f "$webKeyFile" ]]; then
            /usr/local/x-ui/x-ui cert -webCert "$webCertFile" -webCertKey "$webKeyFile"
            LOGI "已为域名 $domain 设置面板路径"
            LOGI "  - 证书文件: $webCertFile"
            LOGI "  - 私钥文件: $webKeyFile"
            echo -e "${green}访问 URL: https://${domain}:${existing_port}${existing_webBasePath}${plain}"
            restart
        else
            LOGE "错误：未找到域名 $domain 的证书或私钥文件。"
        fi
    else
        LOGI "跳过面板路径设置。"
    fi
}

ssl_cert_issue_CF() {
    local existing_webBasePath=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'webBasePath: .+' | awk '{print $2}')
    local existing_port=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'port: .+' | awk '{print $2}')
    LOGI "****** 使用说明 ******"
    LOGI "请按照以下步骤完成操作："
    LOGI "1. Cloudflare 注册邮箱。"
    LOGI "2. Cloudflare 全局 API 密钥。"
    LOGI "3. 域名。"
    LOGI "4. 证书颁发后，系统会提示你为面板设置证书（可选）。"
    LOGI "5. 脚本还支持安装后自动续期 SSL 证书。"

    confirm "你确认信息并希望继续吗？[y/n]" "y"

    if [ $? -eq 0 ]; then
        # 首先检查 acme.sh
        if ! command -v ~/.acme.sh/acme.sh &>/dev/null; then
            echo "未找到 acme.sh。我们将安装它。"
            install_acme
            if [ $? -ne 0 ]; then
                LOGE "安装 acme 失败，请检查日志。"
                exit 1
            fi
        fi

        CF_Domain=""
        certPath="/root/cert-CF"
        if [ ! -d "$certPath" ]; then
            mkdir -p $certPath
        else
            rm -rf $certPath
            mkdir -p $certPath
        fi

        LOGD "请设置域名:"
        read -p "输入你的域名: " CF_Domain
        LOGD "你的域名设置为: ${CF_Domain}"

        # 设置 Cloudflare API 详情
        CF_GlobalKey=""
        CF_AccountEmail=""
        LOGD "请设置 API 密钥:"
        read -p "输入你的密钥: " CF_GlobalKey
        LOGD "你的 API 密钥是: ${CF_GlobalKey}"

        LOGD "请设置注册邮箱:"
        read -p "输入你的邮箱: " CF_AccountEmail
        LOGD "你的注册邮箱是: ${CF_AccountEmail}"

        # 设置默认 CA 为 Let's Encrypt
        ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
        if [ $? -ne 0 ]; then
            LOGE "默认 CA Let'sEncrypt 失败，脚本退出..."
            exit 1
        fi

        export CF_Key="${CF_GlobalKey}"
        export CF_Email="${CF_AccountEmail}"

        # 使用 Cloudflare DNS 颁发证书
        ~/.acme.sh/acme.sh --issue --dns dns_cf -d ${CF_Domain} -d *.${CF_Domain} --log
        if [ $? -ne 0 ]; then
            LOGE "证书颁发失败，脚本退出..."
            exit 1
        else
            LOGI "证书颁发成功，正在安装..."
        fi

        # 安装证书
        mkdir -p ${certPath}/${CF_Domain}
        if [ $? -ne 0 ]; then
            LOGE "创建目录失败: ${certPath}/${CF_Domain}"
            exit 1
        fi

        ~/.acme.sh/acme.sh --installcert -d ${CF_Domain} -d *.${CF_Domain} \
            --fullchain-file ${certPath}/${CF_Domain}/fullchain.pem \
            --key-file ${certPath}/${CF_Domain}/privkey.pem

        if [ $? -ne 0 ]; then
            LOGE "证书安装失败，脚本退出..."
            exit 1
        else
            LOGI "证书安装成功，正在启用自动更新..."
        fi

        # 启用自动更新
        ~/.acme.sh/acme.sh --upgrade --auto-upgrade
        if [ $? -ne 0 ]; then
            LOGE "自动更新设置失败，脚本退出..."
            exit 1
        else
            LOGI "证书已安装并启用自动续期。具体信息如下:"
            ls -lah ${certPath}/${CF_Domain}
            chmod 755 ${certPath}/${CF_Domain}
        fi

        # 提示用户在成功安装证书后设置面板路径
        read -p "你希望为面板设置此证书吗？(y/n): " setPanel
        if [[ "$setPanel" == "y" || "$setPanel" == "Y" ]]; then
            local webCertFile="${certPath}/${CF_Domain}/fullchain.pem"
            local webKeyFile="${certPath}/${CF_Domain}/privkey.pem"

            if [[ -f "$webCertFile" && -f "$webKeyFile" ]]; then
                /usr/local/x-ui/x-ui cert -webCert "$webCertFile" -webCertKey "$webKeyFile"
                LOGI "已为域名 $CF_Domain 设置面板路径"
                LOGI "  - 证书文件: $webCertFile"
                LOGI "  - 私钥文件: $webKeyFile"
                echo -e "${green}访问 URL: https://${CF_Domain}:${existing_port}${existing_webBasePath}${plain}"
                restart
            else
                LOGE "错误：未找到域名 $CF_Domain 的证书或私钥文件。"
            fi
        else
            LOGI "跳过面板路径设置。"
        fi
    else
        show_menu
    fi
}

run_speedtest() {
    # 检查是否已安装 Speedtest
    if ! command -v speedtest &>/dev/null; then
        # 如果未安装，确定安装方法
        if command -v snap &>/dev/null; then
            # 使用 snap 安装 Speedtest
            echo "正在使用 snap 安装 Speedtest..."
            snap install speedtest
        else
            # 回退到使用包管理器
            local pkg_manager=""
            local speedtest_install_script=""

            if command -v dnf &>/dev/null; then
                pkg_manager="dnf"
                speedtest_install_script="https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh"
            elif command -v yum &>/dev/null; then
                pkg_manager="yum"
                speedtest_install_script="https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh"
            elif command -v apt-get &>/dev/null; then
                pkg_manager="apt-get"
                speedtest_install_script="https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh"
            elif command -v apt &>/dev/null; then
                pkg_manager="apt"
                speedtest_install_script="https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh"
            fi

            if [[ -z $pkg_manager ]]; then
                echo "错误：未找到包管理器。你可能需要手动安装 Speedtest。"
                return 1
            else
                echo "正在使用 $pkg_manager 安装 Speedtest..."
                curl -s $speedtest_install_script | bash
                $pkg_manager install -y speedtest
            fi
        fi
    fi

    speedtest
}

create_iplimit_jails() {
    # 如果未传递 bantime，则使用默认值 => 30 分钟
    local bantime="${1:-30}"

    # 在 fail2ban.conf 中取消注释 'allowipv6 = auto'
    sed -i 's/#allowipv6 = auto/allowipv6 = auto/g' /etc/fail2ban/fail2ban.conf

    # 在 Debian 12+ 上，fail2ban 的默认后端应更改为 systemd
    if [[  "${release}" == "debian" && ${os_version} -ge 12 ]]; then
        sed -i '0,/action =/s/backend = auto/backend = systemd/' /etc/fail2ban/jail.conf
    fi

    cat << EOF > /etc/fail2ban/jail.d/3x-ipl.conf
[3x-ipl]
enabled=true
backend=auto
filter=3x-ipl
action=3x-ipl
logpath=${iplimit_log_path}
maxretry=2
findtime=32
bantime=${bantime}m
EOF

    cat << EOF > /etc/fail2ban/filter.d/3x-ipl.conf
[Definition]
datepattern = ^%%Y/%%m/%%d %%H:%%M:%%S
failregex   = \[LIMIT_IP\]\s*Email\s*=\s*<F-USER>.+</F-USER>\s*\|\|\s*SRC\s*=\s*<ADDR>
ignoreregex =
EOF

    cat << EOF > /etc/fail2ban/action.d/3x-ipl.conf
[INCLUDES]
before = iptables-allports.conf

[Definition]
actionstart = <iptables> -N f2b-<name>
              <iptables> -A f2b-<name> -j <returntype>
              <iptables> -I <chain> -p <protocol> -j f2b-<name>

actionstop = <iptables> -D <chain> -p <protocol> -j f2b-<name>
             <actionflush>
             <iptables> -X f2b-<name>

actioncheck = <iptables> -n -L <chain> | grep -q 'f2b-<name>[ \t]'

actionban = <iptables> -I f2b-<name> 1 -s <ip> -j <blocktype>
            echo "\$(date +"%%Y/%%m/%%d %%H:%%M:%%S")   BAN   [Email] = <F-USER> [IP] = <ip> banned for <bantime> seconds." >> ${iplimit_banned_log_path}

actionunban = <iptables> -D f2b-<name> -s <ip> -j <blocktype>
              echo "\$(date +"%%Y/%%m/%%d %%H:%%M:%%S")   UNBAN   [Email] = <F-USER> [IP] = <ip> unbanned." >> ${iplimit_banned_log_path}

[Init]
name = default
protocol = tcp
chain = INPUT
EOF

    echo -e "${green}IP 限制封禁文件已创建，封禁时间为 ${bantime} 分钟。${plain}"
}

iplimit_remove_conflicts() {
    local jail_files=(
        /etc/fail2ban/jail.conf
        /etc/fail2ban/jail.local
    )

    for file in "${jail_files[@]}"; do
        # 检查封禁文件中是否存在 [3x-ipl] 配置，然后删除它
        if test -f "${file}" && grep -qw '3x-ipl' ${file}; then
            sed -i "/\[3x-ipl\]/,/^$/d" ${file}
            echo -e "${yellow}正在删除封禁文件 (${file}) 中的 [3x-ipl] 冲突！${plain}\n"
        fi
    done
}

ip_validation() {
    ipv6_regex="^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$"
    ipv4_regex="^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]?|0)\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]?|0)$"
}

iplimit_main() {
    echo -e "\n${green}\t1.${plain} 安装 Fail2ban 并配置 IP 限制"
    echo -e "${green}\t2.${plain} 更改封禁时长"
    echo -e "${green}\t3.${plain} 解封所有人"
    echo -e "${green}\t4.${plain} 封禁日志"
    echo -e "${green}\t5.${plain} 封禁一个 IP 地址"
    echo -e "${green}\t6.${plain} 解封一个 IP 地址"
    echo -e "${green}\t7.${plain} 实时日志"
    echo -e "${green}\t8.${plain} 服务状态"
    echo -e "${green}\t9.${plain} 服务重启"
    echo -e "${green}\t10.${plain} 卸载 Fail2ban 和 IP 限制"
    echo -e "${green}\t0.${plain} 返回主菜单"
    read -p "选择一个选项: " choice
    case "$choice" in
    0)
        show_menu
        ;;
    1)
        confirm "继续安装 Fail2ban 和 IP 限制吗？" "y"
        if [[ $? == 0 ]]; then
            install_iplimit
        else
            iplimit_main
        fi
        ;;
    2)
        read -rp "请输入新的封禁时长（分钟）[默认 30]: " NUM
        if [[ $NUM =~ ^[0-9]+$ ]]; then
            create_iplimit_jails ${NUM}
            systemctl restart fail2ban
        else
            echo -e "${red}${NUM} 不是数字！请重试。${plain}"
        fi
        iplimit_main
        ;;
    3)
        confirm "继续解封 IP 限制封禁中的所有用户吗？" "y"
        if [[ $? == 0 ]]; then
            fail2ban-client reload --restart --unban 3x-ipl
            truncate -s 0 "${iplimit_banned_log_path}"
            echo -e "${green}所有用户已成功解封。${plain}"
            iplimit_main
        else
            echo -e "${yellow}已取消。${plain}"
        fi
        iplimit_main
        ;;
    4)
        show_banlog
        iplimit_main
        ;;
    5)
        read -rp "输入要封禁的 IP 地址: " ban_ip
        ip_validation
        if [[ $ban_ip =~ $ipv4_regex || $ban_ip =~ $ipv6_regex ]]; then
            fail2ban-client set 3x-ipl banip "$ban_ip"
            echo -e "${green}IP 地址 ${ban_ip} 已成功封禁。${plain}"
        else
            echo -e "${red}无效的 IP 地址格式！请重试。${plain}"
        fi
        iplimit_main
        ;;
    6)
        read -rp "输入要解封的 IP 地址: " unban_ip
        ip_validation
        if [[ $unban_ip =~ $ipv4_regex || $unban_ip =~ $ipv6_regex ]]; then
            fail2ban-client set 3x-ipl unbanip "$unban_ip"
            echo -e "${green}IP 地址 ${unban_ip} 已成功解封。${plain}"
        else
            echo -e "${red}无效的 IP 地址格式！请重试。${plain}"
        fi
        iplimit_main
        ;;
    7)
        tail -f /var/log/fail2ban.log
        iplimit_main
        ;;
    8)
        service fail2ban status
        iplimit_main
        ;;
    9)
        systemctl restart fail2ban
        iplimit_main
        ;;
    10)
        remove_iplimit
        iplimit_main
        ;;
    *)
        echo -e "${red}无效选项。请选择一个有效的数字。${plain}\n"
        iplimit_main
        ;;
    esac
}

install_iplimit() {
    if ! command -v fail2ban-client &>/dev/null; then
        echo -e "${green}Fail2ban 未安装。正在安装...！${plain}\n"

        # 检查操作系统并安装必要的包
        case "${release}" in
        ubuntu)
            if [[ "${os_version}" -ge 24 ]]; then
                apt update && apt install python3-pip -y
                python3 -m pip install pyasynchat --break-system-packages
            fi
            apt update && apt install fail2ban -y
            ;;
        debian | armbian)
            apt update && apt install fail2ban -y
            ;;
        centos | almalinux | rocky | ol)
            yum update -y && yum install epel-release -y
            yum -y install fail2ban
            ;;
        fedora | amzn)
            dnf -y update && dnf -y install fail2ban
            ;;
        arch | manjaro | parch)
            pacman -Syu --noconfirm fail2ban
            ;;
        *)
            echo -e "${red}不支持的操作系统。请检查脚本并手动安装必要的包。${plain}\n"
            exit 1
            ;;
        esac

        if ! command -v fail2ban-client &>/dev/null; then
            echo -e "${red}Fail2ban 安装失败。${plain}\n"
            exit 1
        fi

        echo -e "${green}Fail2ban 安装成功！${plain}\n"
    else
        echo -e "${yellow}Fail2ban 已安装。${plain}\n"
    fi

    echo -e "${green}正在配置 IP 限制...${plain}\n"

    # 确保没有封禁文件冲突
    iplimit_remove_conflicts

    # 检查日志文件是否存在
    if ! test -f "${iplimit_banned_log_path}"; then
        touch ${iplimit_banned_log_path}
    fi

    # 检查服务日志文件是否存在，以便 fail2ban 不会返回错误
    if ! test -f "${iplimit_log_path}"; then
        touch ${iplimit_log_path}
    fi

    # 创建 IP 限制封禁文件
    # 这里我们没有传递 bantime，以使用默认值
    create_iplimit_jails

    # 启动 fail2ban
    if ! systemctl is-active --quiet fail2ban; then
        systemctl start fail2ban
        systemctl enable fail2ban
    else
        systemctl restart fail2ban
    fi
    systemctl enable fail2ban

    echo -e "${green}IP 限制已成功安装并配置！${plain}\n"
    before_show_menu
}

remove_iplimit() {
    echo -e "${green}\t1.${plain} 仅删除 IP 限制配置"
    echo -e "${green}\t2.${plain} 卸载 Fail2ban 和 IP 限制"
    echo -e "${green}\t0.${plain} 返回主菜单"
    read -p "选择一个选项: " num
    case "$num" in
    1)
        rm -f /etc/fail2ban/filter.d/3x-ipl.conf
        rm -f /etc/fail2ban/action.d/3x-ipl.conf
        rm -f /etc/fail2ban/jail.d/3x-ipl.conf
        systemctl restart fail2ban
        echo -e "${green}IP 限制已成功移除！${plain}\n"
        before_show_menu
        ;;
    2)
        rm -rf /etc/fail2ban
        systemctl stop fail2ban
        case "${release}" in
        ubuntu | debian | armbian)
            apt-get remove -y fail2ban
            apt-get purge -y fail2ban -y
            apt-get autoremove -y
            ;;
        centos | almalinux | rocky | ol)
            yum remove fail2ban -y
            yum autoremove -y
            ;;
        fedora | amzn)
            dnf remove fail2ban -y
            dnf autoremove -y
            ;;
        arch | manjaro | parch)
            pacman -Rns --noconfirm fail2ban
            ;;
        *)
            echo -e "${red}不支持的操作系统。请手动卸载 Fail2ban。${plain}\n"
            exit 1
            ;;
        esac
        echo -e "${green}Fail2ban 和 IP 限制已成功移除！${plain}\n"
        before_show_menu
        ;;
    0)
        show_menu
        ;;
    *)
        echo -e "${red}无效选项。请选择一个有效的数字。${plain}\n"
        remove_iplimit
        ;;
    esac
}

SSH_port_forwarding() {
    local server_ip=$(curl -s https://api.ipify.org)
    local existing_webBasePath=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'webBasePath: .+' | awk '{print $2}')
    local existing_port=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'port: .+' | awk '{print $2}')
    local existing_listenIP=$(/usr/local/x-ui/x-ui setting -getListen true | grep -Eo 'listenIP: .+' | awk '{print $2}')
    local existing_cert=$(/usr/local/x-ui/x-ui setting -getCert true | grep -Eo 'cert: .+' | awk '{print $2}')
    local existing_key=$(/usr/local/x-ui/x-ui setting -getCert true | grep -Eo 'key: .+' | awk '{print $2}')

    local config_listenIP=""
    local listen_choice=""

    if [[ -n "$existing_cert" && -n "$existing_key" ]]; then
        echo -e "${green}面板已通过 SSL 保护。${plain}"
        before_show_menu
    fi
    if [[ -z "$existing_cert" && -z "$existing_key" && (-z "$existing_listenIP" || "$existing_listenIP" == "0.0.0.0") ]]; then
        echo -e "\n${red}警告：未找到证书和密钥！面板不安全。${plain}"
        echo "请获取证书或设置 SSH 端口转发。"
    fi

    if [[ -n "$existing_listenIP" && "$existing_listenIP" != "0.0.0.0" && (-z "$existing_cert" && -z "$existing_key") ]]; then
        echo -e "\n${green}当前 SSH 端口转发配置：${plain}"
        echo -e "标准 SSH 命令："
        echo -e "${yellow}ssh -L 2222:${existing_listenIP}:${existing_port} root@${server_ip}${plain}"
        echo -e "\n如果使用 SSH 密钥："
        echo -e "${yellow}ssh -i <sshkeypath> -L 2222:${existing_listenIP}:${existing_port} root@${server_ip}${plain}"
        echo -e "\n连接后，访问面板："
        echo -e "${yellow}http://localhost:2222${existing_webBasePath}${plain}"
    fi

    echo -e "\n选择一个选项："
    echo -e "${green}1.${plain} 设置监听 IP"
    echo -e "${green}2.${plain} 清除监听 IP"
    echo -e "${green}0.${plain} 返回主菜单"
    read -p "选择一个选项: " num

    case "$num" in
    1)
        if [[ -z "$existing_listenIP" || "$existing_listenIP" == "0.0.0.0" ]]; then
            echo -e "\n未配置监听 IP。选择一个选项："
            echo -e "1. 使用默认 IP (127.0.0.1)"
            echo -e "2. 设置自定义 IP"
            read -p "选择一个选项 (1 或 2): " listen_choice

            config_listenIP="127.0.0.1"
            [[ "$listen_choice" == "2" ]] && read -p "输入要监听的 IP: " config_listenIP

            /usr/local/x-ui/x-ui setting -listenIP "${config_listenIP}" >/dev/null 2>&1
            echo -e "${green}监听 IP 已设置为 ${config_listenIP}。${plain}"
            echo -e "\n${green}SSH 端口转发配置：${plain}"
            echo -e "标准 SSH 命令："
            echo -e "${yellow}ssh -L 2222:${config_listenIP}:${existing_port} root@${server_ip}${plain}"
            echo -e "\n如果使用 SSH 密钥："
            echo -e "${yellow}ssh -i <sshkeypath> -L 2222:${config_listenIP}:${existing_port} root@${server_ip}${plain}"
            echo -e "\n连接后，访问面板："
            echo -e "${yellow}http://localhost:2222${existing_webBasePath}${plain}"
            restart
        else
            config_listenIP="${existing_listenIP}"
            echo -e "${green}当前监听 IP 已设置为 ${config_listenIP}。${plain}"
        fi
        ;;
    2)
        /usr/local/x-ui/x-ui setting -listenIP 0.0.0.0 >/dev/null 2>&1
        echo -e "${green}监听 IP 已清除。${plain}"
        restart
        ;;
    0)
        show_menu
        ;;
    *)
        echo -e "${red}无效选项。请选择一个有效的数字。${plain}\n"
        SSH_port_forwarding
        ;;
    esac
}

show_usage() {
    echo -e "┌───────────────────────────────────────────────────────┐
│  ${blue}x-ui 控制菜单用法（子命令）：${plain}              │
│                                                       │
│  ${blue}x-ui${plain}              - 管理脚本          │
│  ${blue}x-ui start${plain}        - 启动                            │
│  ${blue}x-ui stop${plain}         - 停止                             │
│  ${blue}x-ui restart${plain}      - 重启                          │
│  ${blue}x-ui status${plain}       - 当前状态                   │
│  ${blue}x-ui settings${plain}     - 当前设置                 │
│  ${blue}x-ui enable${plain}       - 启用开机自动启动   │
│  ${blue}x-ui disable${plain}      - 禁用开机自动启动  │
│  ${blue}x-ui log${plain}          - 查看日志                       │
│  ${blue}x-ui banlog${plain}       - 查看 Fail2ban 封禁日志          │
│  ${blue}x-ui update${plain}       - 更新                           │
│  ${blue}x-ui legacy${plain}       - 旧版本                   │
│  ${blue}x-ui install${plain}      - 安装                          │
│  ${blue}x-ui uninstall${plain}    - 卸载                        │
└───────────────────────────────────────────────────────┘"
}

show_menu() {
    echo -e "
╔────────────────────────────────────────────────╗
│   ${green}3X-UI 面板管理脚本${plain}                │
│   ${green}0.${plain} 退出脚本                               │
│────────────────────────────────────────────────│
│   ${green}1.${plain} 安装                                   │
│   ${green}2.${plain} 更新                                    │
│   ${green}3.${plain} 更新菜单                               │
│   ${green}4.${plain} 旧版本                            │
│   ${green}5.${plain} 卸载                                 │
│────────────────────────────────────────────────│
│   ${green}6.${plain} 重置用户名、密码和密钥  │
│   ${green}7.${plain} 重置 Web 基础路径                       │
│   ${green}8.${plain} 重置设置                            │
│   ${green}9.${plain} 更改端口                               │
│  ${green}10.${plain} 查看当前设置                     │
│────────────────────────────────────────────────│
│  ${green}11.${plain} 启动                                     │
│  ${green}12.${plain} 停止                                      │
│  ${green}13.${plain} 重启                                   │
│  ${green}14.${plain} 检查状态                              │
│  ${green}15.${plain} 日志管理                           │
│────────────────────────────────────────────────│
│  ${green}16.${plain} 启用开机自动启动                          │
│  ${green}17.${plain} 禁用开机自动启动                         │
│────────────────────────────────────────────────│
│  ${green}18.${plain} SSL 证书管理                │
│  ${green}19.${plain} Cloudflare SSL 证书                │
│  ${green}20.${plain} IP 限制管理                       │
│  ${green}21.${plain} 防火墙管理                       │
│  ${green}22.${plain} SSH 端口转发管理            │
│────────────────────────────────────────────────│
│  ${green}23.${plain} 启用 BBR                                │
│  ${green}24.${plain} 更新 Geo 文件                          │
│  ${green}25.${plain} Ookla 测速                        │
╚────────────────────────────────────────────────╝
"
    show_status
    echo && read -p "请输入你的选择 [0-25]: " num

    case "${num}" in
    0)
        exit 0
        ;;
    1)
        check_uninstall && install
        ;;
    2)
        check_install && update
        ;;
    3)
        check_install && update_menu
        ;;
    4)
        check_install && legacy_version
        ;;
    5)
        check_install && uninstall
        ;;
    6)
        check_install && reset_user
        ;;
    7)
        check_install && reset_webbasepath
        ;;
    8)
        check_install && reset_config
        ;;
    9)
        check_install && set_port
        ;;
    10)
        check_install && check_config
        ;;
    11)
        check_install && start
        ;;
    12)
        check_install && stop
        ;;
    13)
        check_install && restart
        ;;
    14)
        check_install && status
        ;;
    15)
        check_install && show_log
        ;;
    16)
        check_install && enable
        ;;
    17)
        check_install && disable
        ;;
    18)
        ssl_cert_issue_main
        ;;
    19)
        ssl_cert_issue_CF
        ;;
    20)
        iplimit_main
        ;;
    21)
        firewall_menu
        ;;
    22)
        SSH_port_forwarding
        ;;
    23)
        bbr_menu
        ;;
    24)
        update_geo
        ;;
    25)
        run_speedtest
        ;;
    *)
        LOGE "请输入正确的数字 [0-25]"
        ;;
    esac
}

if [[ $# > 0 ]]; then
    case $1 in
    "start")
        check_install 0 && start 0
        ;;
    "stop")
        check_install 0 && stop 0
        ;;
    "restart")
        check_install 0 && restart 0
        ;;
    "status")
        check_install 0 && status 0
        ;;
    "settings")
        check_install 0 && check_config 0
        ;;
    "enable")
        check_install 0 && enable 0
        ;;
    "disable")
        check_install 0 && disable 0
        ;;
    "log")
        check_install 0 && show_log 0
        ;;
    "banlog")
        check_install 0 && show_banlog 0
        ;;
    "update")
        check_install 0 && update 0
        ;;
    "legacy")
        check_install 0 && legacy_version 0
        ;;
    "install")
        check_uninstall 0 && install 0
        ;;
    "uninstall")
        check_install 0 && uninstall 0
        ;;
    *) show_usage ;;
    esac
else
    show_menu
fi