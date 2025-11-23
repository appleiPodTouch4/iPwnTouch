#!/bin/bash
clear
#############################设置###################################
update=1       #更新
filecheck=1   #检测文件完整性
checkjb=0     #检测越狱
menu_old=0    #老年菜单
isoscheck=1   #系统检查(最好别关,时刻提醒)
sshrdmodcheck=0 #sshrd模式检查,建议打开,当脚本出现bug的时候可以尝试关闭
debugmode=0   #调试模式
ship_platform_check=1 #关闭对macOS版本检查提醒
##########################路径/变量###############################
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  
RED='\033[0;31m'  
GREEN='\033[0;32m'                                           
YELLOW='\033[0;33m'                                          
BLUE='\033[0;34m'
NC='\033[0m'
ssh_port=6414
openssh_port=2222
serverip=127.0.0.1
ipsw_openssh=1
tmp=$script_dir/tmp
saved=$script_dir/saved
activition=$script_dir/bin/System/iOS7Tethered/activation/activition.py
jelbrek="$script_dir/bin/Jailbreak"
resources=$script_dir/bin/resources
##########################################################
trap clean_all EXIT
#trap error_message EXIT
trap "exit 1" INT TERM

if [[ "$debugmode" == "1" ]]; then
    menu_old=1
    set -x
fi

log() {
    GREEN='\033[32m'
    RESET='\033[0m'
    echo -e "${GREEN}[Log]${RESET} ${GREEN}$@${RESET}" > /dev/tty
    eval "$@" >/dev/null 2>&1
}

error() {
    RED='\033[31m'
    RESET='\033[0m'
    echo -e "${RED}[ERROR]${RESET} ${RED}$@${RESET}" > /dev/tty
    eval "$@" >/dev/null 2>&1
}

warning() {
    YELLOW='\033[33m'
    RESET='\033[0m'
    echo -e "${YELLOW}[WARNING]${RESET} ${YELLOW}$@${RESET}" > /dev/tty
    eval "$@" >/dev/null 2>&1
}

debug() {
    local BLUE='\033[38;5;45m'
    RESET='\033[0m'
    echo -e "${BLUE}[DEBUG]${RESET} ${BLUE}$@${RESET}" > /dev/tty
    eval "$@" >/dev/null 2>&1
}

tip() {
    local PURPLE='\033[0;35m'
    local NC='\033[0m'
    echo -e "${PURPLE}$1${NC}"
}

input() {
    YELLOW='\033[33m'
    RESET='\033[0m'
    echo -e "${YELLOW}[Input]${RESET} ${YELLOW}$@${RESET}" > /dev/tty
    eval "$@" >/dev/null 2>&1
}

pause() {
    if [ -z "$1" ]; then
        input "按回车键继续 (按CTRL+C退出)"
    else
        input "$1 (按CTRL+C退出)"
    fi
    read -s
}

error_message() {
    error 程序已退出
}

3s() {
    if [[ -z $1 ]]; then
        log 3s后返回主页
        for i in {3..1}; do
        echo "$i..."
        sleep 1
        done 
        main_choice
    else
        log 三秒后$1
    fi
    for i in {3..1}; do
    echo "$i..."
    sleep 1
    done 
}

timeout() {
    i=0
    while (( i < $1 )); do
        $2
        ((i++))
        sleep 1
    done
}

mkdir_all() {
    mkdir $script_dir/tmp
}

clean_all() {
    rm -rf $script_dir/tmp

}

go_to_menu() {
    if [[ "$1" == "nopause" ]]; then
        :
    else
        pause
    fi
    main_choice
}

exit() {
    rexit=1
    command exit $@
}

oscheck() {
    arch_path=
    if [[ "$isoscheck" == "1" ]]; then
        platform_check=$(uname)
        arch_check=$(uname -m)
        if [[ "$platform_check" == "Darwin" ]]; then
            platform=macos
            if [[ "$arch_check" == "x86_64" ]]; then
                platform_arch=x86_64
            elif [[ "$arch_check" == "arm64" ]]; then
                platform_arch=arm64
            else
                error 什么神秘架构
                exit
            fi
        elif [[ "$platform_check" == "Linux" ]]; then
            platform=linux
            if [[ "$arch_check" == "x86_64" ]]; then
                platform_arch=x86_64
            elif [[ "$arch_check" == "arm64" ]]; then
                platform_arch=arm64
            else
                error 什么神秘架构
                exit
            fi
        else
            error 啥神秘设备
            exit
        fi
        if [[ "$platform" == "macos" ]]; then
            if [[ "$platform_arch" == "arm64" ]]; then
                if [[ "$ship_platform_check" != "1" ]]; then
                    warning 使用M系列芯片可能会出现兼容性问题,请谨慎使用
                    pause 按回车忽略此问题  
                fi
                lib=$script_dir/bin/lib/arm64
            else
                lib=$script_dir/bin/lib
            fi
            macos_ver="${1:-$(sw_vers -productVersion)}"
            macos_major_ver="${macos_ver:0:2}"
            if [[ $macos_major_ver == 10 ]]; then
                macos_minor_ver=${macos_ver:3}
                macos_minor_ver=${macos_minor_ver%.*}
                if (( macos_minor_ver < 11 )); then
                    if [[ "$ship_platform_check" != "1" ]]; then
                        error "你的macOS版本过于老旧,请升级到macOS High Sierra及以上"
                    fi
                fi
                case $macos_minor_ver in
                    #11 ) macos_name="El Capitan";; too old
                    #12 ) macos_name="Sierra";; too old
                    13 ) macos_name="High Sierra";;
                    14 ) macos_name="Mojave";;
                    15 ) macos_name="Catalina";;
                esac
            fi
            case $macos_major_ver in
                11 ) macos_name="Big Sur";;
                12 ) macos_name="Monterey";;
                13 ) macos_name="Ventura";;
                14 ) macos_name="Sonoma";;
                15 ) macos_name="Sequoia";;
                26 ) macos_name="Tahoe";;
            esac
            if (( macos_major_ver > 12 )); then
                warning "使用高于macOS Monterey的设备可能会出现兼容性问题,是否继续?"
                yesno 是否继续
                 if [[ $? == 1 ]]; then
                    :
                else
                    exit
                fi
            fi
            platform_message="macOS ${macos_name}($platform_arch)"
        elif [[ "$platform" == "linux" ]]; then
            warning Linux版还在适配当中,有些功能还未修复,是否继续使用?
            pause 回车继续使用
            check_sudo
            install_depends
            arch_path="linux/"
            linux_name=$(grep '^NAME=' /etc/os-release | cut -d'"' -f2)
            platform_message="${linux_name} ($platform_arch)"
            lib=$script_dir/bin/lib/linux
        fi
    fi

}

########linux part########
install_depends() {
    local packages=(
        aria2 ca-certificates curl git libssl3 libzstd1 
        openssh-client patch python3 sshfs unzip usbmuxd 
        usbutils xxd zenity zip zlib1g
    )
    
    local missing=()
    
    # 检查未安装的包
    for pkg in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            if apt-cache show "$pkg" &>/dev/null; then
                echo "❌ $pkg 未安装"
                missing+=("$pkg")
            else
                echo "⚠️  $pkg 不存在于仓库"
            fi
        else
            echo "✅ $pkg 已安装"
        fi
    done
    
    # 如果没有缺失的包，直接返回
    if [ ${#missing[@]} -eq 0 ]; then
        echo "所有依赖包都已安装！"
        return 0
    else
        #pause 回车安装依赖
        #echo "更新软件包列表并安装依赖..."
        #sudo killall unattended-upgrades
        #sudo rm -f /var/lib/dpkg/lock-frontend
        #sudo rm -f /var/lib/dpkg/lock
        #sudo rm -f /var/lib/apt/lists/lock
        #sudo apt update && sudo apt install -y "${missing[@]}"
        #if [ $? -eq 0 ]; then
        #    echo "✅ 依赖安装完成！"
        #else
        #    echo "❌ 依赖安装失败！"
        #    return 1
        #fi
        :
    fi
    clear
}

select_apt_mirror() {
    echo "请选择镜像源:"
    echo "1) 阿里云 (aliyun)"
    echo "2) 清华 (tuna)"
    echo "3) 中科大 (ustc)"
    echo "4) 华为云 (huaweicloud)"
    echo "5) 网易 (163)"
    echo "6) 恢复默认源"
    read -p "请输入选择 [1-6]: " choice
    
    case $choice in
        1) mirror="aliyun" ;;
        2) mirror="tuna" ;;
        3) mirror="ustc" ;;
        4) mirror="huaweicloud" ;;
        5) mirror="163" ;;
        6) restore_default_sources && return ;;
        *) echo "无效选择" && return 1 ;;
    esac
    
    change_to_mirror $mirror
}

change_to_mirror() {
    local mirror=$1
    source /etc/os-release
    
    # 备份
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
    
    case $ID in
        ubuntu)
            change_ubuntu_mirror $mirror
            ;;
        debian)
            change_debian_mirror $mirror
            ;;
        *)
            echo "不支持的系统"
            return 1
            ;;
    esac
    
    sudo apt update
}

change_ubuntu_mirror() {
    local mirror=$1
    local codename=$(lsb_release -cs)
    local mirror_url=""
    
    case $mirror in
        aliyun) mirror_url="https://mirrors.aliyun.com/ubuntu/" ;;
        tuna) mirror_url="https://mirrors.tuna.tsinghua.edu.cn/ubuntu/" ;;
        ustc) mirror_url="https://mirrors.ustc.edu.cn/ubuntu/" ;;
        huaweicloud) mirror_url="https://repo.huaweicloud.com/ubuntu/" ;;
        163) mirror_url="https://mirrors.163.com/ubuntu/" ;;
    esac
    
    sudo tee /etc/apt/sources.list > /dev/null << EOF
deb $mirror_url $codename main restricted universe multiverse
deb $mirror_url $codename-security main restricted universe multiverse
deb $mirror_url $codename-updates main restricted universe multiverse
deb $mirror_url $codename-backports main restricted universe multiverse
EOF
}

change_debian_mirror() {
    local mirror=$1
    local codename=$(lsb_release -cs)
    local mirror_url=""
    
    case $mirror in
        aliyun) mirror_url="https://mirrors.aliyun.com/debian/" ;;
        tuna) mirror_url="https://mirrors.tuna.tsinghua.edu.cn/debian/" ;;
        ustc) mirror_url="https://mirrors.ustc.edu.cn/debian/" ;;
        huaweicloud) mirror_url="https://repo.huaweicloud.com/debian/" ;;
        163) mirror_url="https://mirrors.163.com/debian/" ;;
    esac
    
    sudo tee /etc/apt/sources.list > /dev/null << EOF
deb $mirror_url $codename main contrib non-free
deb $mirror_url $codename-updates main contrib non-free
deb $mirror_url $codename-backports main contrib non-free
deb $mirror_url $codename-security main contrib non-free
EOF
}

restore_default_sources() {
    if [ -f /etc/apt/sources.list.bak ]; then
        sudo cp /etc/apt/sources.list.bak /etc/apt/sources.list
        log "已恢复默认源"
        sudo apt update
    else
        error "找不到备份文件"
    fi
}

check_sudo() {
    if [ -z "$SUDO_USER" ]; then
        log "请输入本机密码"
        # 尝试获取 sudo 权限
        if sudo -v >/dev/null 2>&1; then
            clear
            return 0
        else
            error "错误: 无法获取 sudo 权限"
            exit 1
        fi
    else
        clear
        return 0
    fi
}

#############################################

set_path() {
    if [[ "$script_dir" =~ [[:space:]] ]]; then
        error "目录路径包含空白字符！" >&2
        error "当前目录: '$script_dir'" >&2
        pause 按回车键退出程序
        exit 1
    fi
    chmod +x $lib/*
    if [[ "$platform" == "macos" ]]; then
        sshpass=
        irecovery=
        iproxy=
        ipwnder=
        idevicerestore=
        futurerestore=
        futurerestore_old=
        ideviceinfo=
        dmg=
        zenity=$lib/zenity
        ideviceactivation=
        ideviceinstaller=
        primepwn=
        gaster=
        iBoot32Patcher=
        xpwntool=
        hfsplus=
        pzb=
        jq=
        ticket=
        validate=
        img4tool=
        irecovery2=
        aria2c=
        tsschecker=
        z7z=
        sha1sum="$(command -v shasum) -a 1"
        bspatch=$(command -v bspatch)
    elif [[ "$platform" == "linux" ]]; then
        export LD_LIBRARY_PATH="$lib/lib"
        sshpass="sudo "
        irecovery="sudo "
        iproxy="sudo "
        ipwnder="sudo "
        idevicerestore="sudo LD_LIBRARY_PATH=$lib/lib "
        futurerestore="sudo "
        futurerestore_old="sudo "
        ideviceinfo="sudo LD_LIBRARY_PATH=$lib/lib "
        dmg="sudo "
        zenity="sudo GSETTINGS_BACKEND=memory $(command -v zenity)"
        ideviceactivation="sudo LD_LIBRARY_PATH=$lib/lib "
        ideviceinstaller="sudo LD_LIBRARY_PATH=$lib/lib "
        primepwn="sudo "
        gaster="sudo "
        iBoot32Patcher="sudo "
        xpwntool="sudo "
        hfsplus="sudo "
        pzb="sudo "
        jq="sudo "
        ticket="sudo "
        validate="sudo "
        img4tool="sudo "
        irecovery2="sudo "
        aria2c="sudo "
        z7z="sudo "
        tsschecker="sudo "
        afc=”sudo“
        bspatch=$lib/bspatch
    fi
    sshpass+=$lib/sshpass
    irecovery+=$lib/irecovery
    iproxy+=$lib/iproxy
    ipwnder+=$lib/ipwnder
    idevicerestore+=$lib/idevicerestore
    futurerestore+=$lib/futurerestore
    futurerestore_old+=$lib/futurerestore_old
    ideviceinfo+=$lib/ideviceinfo
    dmg+=$lib/dmg
    ideviceactivation+=$lib/ideviceactivation
    ideviceinstaller+=$lib/ideviceinstaller
    primepwn+=$lib/primepwn
    gaster+=$lib/gaster
    iBoot32Patcher+=$lib/iBoot32Patcher
    xpwntool+=$lib/xpwntool
    hfsplus+=$lib/hfsplus
    pzb+=$lib/pzb
    jq+=$lib/jq
    ticket+=$lib/ticket
    validate+=$lib/validate
    img4tool+=$lib/img4tool
    irecovery2+=$lib/irecovery2
    aria2c+=$lib/aria2c
    tsschecker+=$lib/tsschecker
    z7z+=$lib/7zz
    afc+=$lib/afc_tool
    sha1sum="$(command -v shasum) -a 1"

}

set_ssh_config() {
    cp $script_dir/bin/Others/ssh_config $script_dir/tmp
    if [[ $(ssh -V 2>&1 | grep -c SSH_8.8) == 1 || $(ssh -V 2>&1 | grep -c SSH_8.9) == 1 ||
          $(ssh -V 2>&1 | grep -c SSH_9.) == 1 || $(ssh -V 2>&1 | grep -c SSH_1) == 1 ]]; then
        echo "    PubkeyAcceptedAlgorithms +ssh-rsa" >> $script_dir/ssh_config
    elif [[ $(ssh -V 2>&1 | grep -c SSH_6) == 1 ]]; then
        cat $script_dir/bin/Others/ssh_config | sed "s,Add,#Add,g" | sed "s,HostKeyA,#HostKeyA,g" > $script_dir/tmp/ssh_config
    fi
    
    sshconfig="-F $script_dir/tmp/ssh_config"
    
    if [ -z "$1" ]; then
        ssh="$sshpass -p alpine ssh $sshconfig"
        scp="$sshpass -p alpine scp $sshconfig"
    fi
    
    if [[ "$1" == "pass" ]]; then
        ssh="$sshpass -p $2 ssh $sshconfig"
        scp="$sshpass -p $2 scp $sshconfig"
    fi
}

sshcheck() {
    local message
    if [[ "$1" == "$ssh_port" ]]; then
        local port=$ssh_port
    elif [[ "$1" == "os9" ]]; then
        return
    else
        local port=$openssh_port
    fi
    message=$($ssh -p $ssh_port root@127.0.0.1 "echo sshtest")
    #$scp -P $port $script_dir/bin/Others/try.txt root@127.0.0.1:/try
    #$scp -P $port root@127.0.0.1:/try.txt $script_dir/bin
    #local try=$script_dir/bin/try.txt
    #local try1=$(find "$fl" -type f -name "bbcl*" 2>/dev/null)
    #if [ -f "$script_dir/bin/try.txt" ]; then
    #    if [[ "$2" == "q" ]]; then
    #        sshyes=yes
    #    else
    #        log SSH链接成功
    #        sshyes=yes
    #        rm -rf $script_dir/bin/try.txt
    #    fi
    #    if [[ "$2" == "pause" ]]; then
    #        pause
    #    else
    #        :
    #    fi
    #else
    #    if [[ "$2" == "q" ]]; then
    #        sshyes=no
    #    else
    #        error SSH链接失败
    #        sshyes=no
    #        warning "检查是否链接设备"
    #        go_to_menu
    #    fi
    #fi
    if [[ "$message" == "sshtest" ]]; then
        if [[ "$2" != "q" ]]; then
            log SSH链接成功
        fi
        sshyes=1
    else
        if [[ "$2" != "q" ]]; then
            log SSH链接失败
        fi
        sshyes=no
        go_to_menu
    fi
}

select_device() {
    local yes
    if [[ "$isdevicecheck" == "1" ]]; then
        deviceinfo $1
    else
        if [[ "$1" != "only" ]]; then
            warning 已关闭设备检验,是否继续?
            yesno 是否继续?
            if [[ $? == 1 ]]; then
                yes=1
            else
                yes=0
                isdevicecheck=1
            fi
        else
            warning Linux无法识别iOS6及其以下的正常模式下的设备信息,请选择设备
            yes=1
        fi
        if [[ "$yes" == "1" ]]; then
            input 请选择设备
            options=("iPod touch1" "iPod touch2" "iPod touch3" "iPod touch4" "iPod touch5" "iPod touch6" "退出")
            select_option "${options[@]}"
            selected="${options[$?]}"
                case $selected in
                    "iPod touch1" ) de=1 ; device_type=iPod1,1 ; device_proc=1 ; device_latest_ver=3.1.3 ;;
                    "iPod touch2" ) de=2 ; device_type=iPod2,1 ; device_proc=1 ; device_latest_ver=4.2.1 ;;
                    "iPod touch3" ) de=3 ; device_type=iPod3,1 ; device_proc=4 ; device_latest_ver=5.1.1 ;;
                    "iPod touch4" ) de=4 ; device_type=iPod4,1 ; device_proc=4 ; device_latest_ver=6.1.6 ;;
                    "iPod touch5" ) de=5 ; device_type=iPod5,1 ; device_proc=5 ; device_latest_ver=9.3.5 ;;
                    "iPod touch6" ) de=6 ; device_type=iPod7,1 ; device_proc=7 ; device_latest_ver=12.5.7;;
                    "退出" ) exit;;
                esac
        else
            deviceinfo $1
        fi
    fi
}

refresh_device() {
    select_device q
    main_choice
}

devicecheck() {
        if [[ "$1" != "q" ]]; then
            log "等待设备连接"
        else
         :
        fi
        last_mode=""
        while true; do
            if [[ "$platform" == "macos" ]]; then
                usb_info=$(system_profiler SPUSBDataType 2>/dev/null)
                device_mode=""
            elif [[ "$platform" == "linux" ]]; then
                usb_info=$(lsusb 2> /dev/null)
                device_mode=""
            else
                error ？
                exit 1
                break
            fi
            if [[ "$platform" == "macos" ]]; then
                if echo "$usb_info" | grep -q ' USB DFU Device'; then
                    device_mode="DFU"
                    de=1
                elif echo "$usb_info" | grep -q ' Apple Mobile Device (DFU Mode)'; then
                    device_mode="DFU"
                elif echo "$usb_info" | grep -q 'Apple Mobile Device (Recovery Mode)'; then
                    device_mode="恢复"
                elif echo "$usb_info" | grep -q ' iPod'; then
                    device_mode="正常"
                elif echo "$usb_info" | grep -q ' iPhone'; then
                    device_mode="正常"
                fi
            elif [[ "$platform" == "linux" ]]; then
                if echo "$usb_info" | grep -q ' USB DFU Device'; then
                    device_mode="DFU"
                    de=1
                elif echo "$usb_info" | grep -q ' Apple, Inc. Mobile Device (DFU Mode)'; then
                    device_mode="DFU"
                elif echo "$usb_info" | grep -q '.*Recovery Mode.*'; then
                    device_mode="恢复"
                elif echo "$usb_info" | grep -q ' iPod'; then
                    device_mode="正常"
                elif echo "$usb_info" | grep -q ' iPhone'; then
                    device_mode="正常"
                fi
            else
                error ?
                exit 1
                break
            fi
            if [[ "$device_mode" != "$last_mode" ]]; then
                if [[ -n "$device_mode" ]]; then
                    if [[ "$1" != "q" ]]; then
                        echo -e "\r设备已进入 ${device_mode} 模式     "  # 用空格覆盖旧内容
                    else
                        : 
                    fi
                else
                    if [[ "$1" != "q" ]]; then
                        echo -ne "\r等待设备连接...\033[K"  # \033[K 清除行尾
                    else
                        : 
                    fi
                fi
                last_mode="$device_mode"
            fi

            if [[ -n "$device_mode" ]]; then
                break
            fi

            sleep 1
        done   
}

deviceinfo() {
    if [[ "$1" == "q" ]]; then
        devicecheck q
    else
        devicecheck
    fi
    while true; do
        if [ "$device_mode" = "DFU" ]; then
            device_pwnd="$($irecovery -q | grep "PWND" | cut -c 7-)"
            if [[ -n $device_pwnd ]]; then
                pwn=是
            else
                pwn=否
            fi
        local os=不检测
        device_type=$($irecovery -q | grep -i "product" | awk -F': ' '{print $2}')
        device_ecid=$($idevicerestore -l 2>/dev/null | grep -i "ECID" | awk '{print $3}')
        break
        elif [ "$device_mode" = "恢复" ]; then
        local os=不检测
        device_type=$($irecovery -q | grep -i "product" | awk -F': ' '{print $2}')
        break
        elif [ "$device_mode" = "正常" ]; then
            if [[ "$sshrdmodcheck" == "1" ]]; then
                sshcheck $ssh_port q &>/dev/null
            fi
            if [[ "$sshyes" == yes ]]; then
                device_mode=SSHRD
                local os=不检测
                device_type=不检测
            else
                device_mode=正常
                os=$($ideviceinfo -k ProductVersion)
                device_type=$($ideviceinfo -k ProductType)
                device_ecid=$($ideviceinfo -s -k UniqueChipID)
            fi
            break
        fi
    done
    if ([[ $os == 不检测 ]] || [[ -z $os ]] || [[ -z "$device_type" ]]) && [[ "$platform" == "linux" ]] && [[ "$device_mode" == "正常" ]]; then
        isdevicecheck=0
        select_device only
    fi
}

checkmode() {
    if [ "$1" = "DFU" ]; then
        if ! (system_profiler SPUSBDataType 2> /dev/null | grep ' Apple Mobile Device (DFU Mode)' >> /dev/null); then
            log "[*] Waiting for device in DFU mode"
        fi
        
        while ! (system_profiler SPUSBDataType 2> /dev/null | grep ' Apple Mobile Device (DFU Mode)' >> /dev/null); do
            sleep 1
        done
    elif [ "$1" = "rec" ]; then
        if ! (system_profiler SPUSBDataType 2> /dev/null | grep ' Apple Mobile Device (Recovery Mode)' >> /dev/null); then
            log "[*] Waiting for device in Recovery mode"
        fi
        
        while ! (system_profiler SPUSBDataType 2> /dev/null | grep ' Apple Mobile Device (Recovery Mode)' >> /dev/null); do
            sleep 1
        done
    elif [ "$1" = "normal" ]; then
        if ! (system_profiler SPUSBDataType 2> /dev/null | grep ' iPod' >> /dev/null); then
            log "[*] Waiting for device in Normal mode"
        fi
        
        while ! (system_profiler SPUSBDataType 2> /dev/null | grep ' iPod' >> /dev/null); do
            sleep 1
        done
    elif [ "$1" = "DFUreal" ]; then
        if ! (system_profiler SPUSBDataType 2> /dev/null | grep ' USB DFU Device' >> /dev/null); then
            log "[*] Waiting for device in DFU mode"
        fi
        
        while ! (system_profiler SPUSBDataType 2> /dev/null | grep ' USB DFU Device' >> /dev/null); do
            sleep 1
        done
    fi
}

checkpwn() {
    device_pwnd="$($irecovery -q | grep "PWND" | cut -c 7-)"
    if [[ -n $device_pwnd ]]; then
        log 设备已进入破解DFU✅
    else
        if [[ "$1" != "noerror" ]]; then
            error 破解DFU失败.确保关闭爱思助手
            return
        fi
    fi
}

pwn_device() {
    i4_check
    checkpwn noerror
    if [[ "$de" == "4" ]]; then
        log 选择破解DFU
        options=("Primepwn" "iPwnder" "返回主页")
        select_option "${options[@]}"
        selected="${options[$?]}"
        if [[ "$selected" == "Primepwn" ]]; then
            $primepwn
        elif [[ "$selected" == "iPwnder" ]]; then
            $ipwnder
        elif [[ "$selected" == "返回主页" ]]; then
            go_to_menu
        fi
    elif [[ "$de" == "3" ]]; then
        $ipwnder
    elif [[ "$de" == "5" ]]; then
        local options1
        local selected1
        if [ "$device_mode" = "正常" ]; then
            can_kdfu_log="/KDFU插件"
        else
            :
        fi
        log A5设备比较特殊,需要使用开发板${can_kdfu_log}进入破解DFU,选择进入破解DFU的方式
        options1=()
        options1+=("开发板")
        if [ "$device_mode" = "正常" ]; then
            options1+=("KDFU")
        fi
        options1+=("返回主页")
        #options1=("开发板" "KDFU" "返回主页")
        select_option "${options1[@]}"
        selected1="${options1[$?]}"
        log $selected1
        if [[ "$selected1" == "开发板" ]]; then
            log 现在请使用开发板进入破解DFU,破解完成/已经进入pwnedibss请回车
            pause
            device_pwnd="$($irecovery -q | grep "PWND" | cut -c 7-)"
            if [ "$device_pwnd" == "checkm8" ]; then
                device_send_unpacked_ibss
            elif [[ -z $device_pwnd ]]; then
                yesno 是否已经进入pwndibss? 1
                if [[ $? == 1 ]]; then
                    return 1
                else
                    pwn_device
                fi
            else
                warning 疑似非开发板破解的DFU?回车尝试发送iBSS
                pause
                device_send_unpacked_ibss
            fi
        fi
    elif [[ "$de" == "6" ]]; then
        $gaster pwn   
    fi
    if [[ "$de" != "5" ]]; then
        checkpwn
        return
    fi
}


DFUhelper() {
    i4_check
    if [ "$device_mode" = "DFU" ]; then
        device_pwnd="$($irecovery -q | grep "PWND" | cut -c 7-)"
        if [[ -n $device_pwnd ]]; then
            if [[ "$de" == "5" ]]; then
                pwn_device
            else
                log 设备已经进入pwn DFU
                return 1
            fi
        else
            if [[ "$1" == "nopwn" ]]; then
                log No Pwn Device
                return 1
            elif [[ "$1" == "pwn" ]]; then
                pwn_device 
            else
                yesno 是否破解DFU 1
                if [[ $? == 1 ]]; then
                    pwn_device 
                else
                    return
                fi
            fi
        fi
    else
        yesno 使用DFUHelper进入DFU 1
        if [[ $? != 1 ]]; then
            log "请手动进入DFU(关闭爱思助手)"
            checkmode DFU
            yesno 进入PwnDFU? 1
            if [[ $? != 1 ]]; then
                log No Pwn Device
                return 1
            else
                :
            fi
        else
            warning 准备开始操作
            for i in {3..1}; do
            echo "$i..."
            sleep 1
            done
            log 同时按住home键和电源键
            for i in {8..1}; do
            echo "$i..."
            sleep 1
            done
            log 松开电源键只按住home键
            for i in {8..1}; do
            echo "$i..."
            sleep 1
            done
            checkmode DFU
        fi
        if [[ "$1" == "nopwn" ]]; then
            log No Pwn Device
            return 1
        elif [[ "$1" == "pwn" ]]; then
            pwn_device 

        else
            yesno 是否破解DFU 1
            if [[ $? == 1 ]]; then
                pwn_device 
            else
                return
            fi
        fi
    fi
}

DFUhelper_legacy() {
    if [ "$device_mode" = "DFU" ]; then
        :
    else
        yesno 使用DFUHelper进入DFU 1
        if [[ $? == 1 ]]; then
            warning 准备开始操作
            for i in {3..1}; do
            echo "$i..."
            sleep 1
            done
            log 同时按住home键和电源键
            for i in {10..1}; do
            echo "$i..."
            sleep 1
            done
            log 松开电源键只按住home键
            for i in {11..1}; do
            echo "$i..."
            sleep 1
            done
            checkmode DFUreal
            device_mode=DFU
        else
            log "请手动进入DFU(关闭爱思助手)"
            checkmode DFUreal
            device_mode=DFU
        fi
    fi
    if [[ "$1" != "nosend" ]]; then
        pwn_device_legacy
    fi
}

pwn_device_legacy() {
    log "Sending patched WTF.s5l8900xall (Pwnage 2.0)"
    $irecovery -f $script_dir/bin/Others/WTF.s5l8900xall.RELEASE.dfu.patched
    checkmode DFU
    sleep 1
    device_srtg="$($irecovery -q | grep "SRTG" | cut -c 7-)"
    log "SRTG: $device_srtg"
    if [[ $device_srtg == "iBoot-636.66.3x" ]]; then
        device_argmode=
        device_type=$($irecovery -q | grep "PRODUCT" | cut -c 10-)
        device_model=$($irecovery -q | grep "MODEL" | cut -c 8-)
        device_model="${device_model%??}"
        device_pwnd="Pwnage 2.0"
    fi
    log $device_pwnd
}

i4_check() {
    local found
    local process_names
    local ok
    local process
    process_names=("i4Tools" "i4Assistant" "Aisi" "爱思" "i4")
    found=false
    for process in "${process_names[@]}"; do
        if pgrep -f "$process" > /dev/null; then
            found=true
        fi
    done
    if [ "$found" = false ]; then
        :
    else
        local target_version="${1:-3.0.3}"
        local plist_file="${2:-/Applications/i4tools.app/Contents/Info.plist}"
        if command -v /usr/libexec/PlistBuddy >/dev/null 2>&1; then
            local version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$plist_file" 2>/dev/null)
            if [ -n "$version" ]; then
                log "爱思版本:$version"
                case $version in
                    1.* | 2.* | 3.0.[1234] ) ok=1;;
                esac
                if [ "$ok" = "1" ]; then
                    :
                else
                    warning "检测到此版本的爱思助手无法破解DFU,请关闭爱思助手或使用老版本(若忽略按回车继续,否则关闭爱思后继续)"
                    go_to_menu
                fi

            fi
        fi
    fi
}

ipsw_etract() {
    local ipsw1="$1"
    local dir
    local ipsw2
    local ipsw
    local target_dir
    ipsw2=$(basename "$ipsw1")
    ipsw="${ipsw2%.ipsw}"
    dir=$(dirname "$ipsw1")
    target_dir="$dir/$ipsw"
    if [[ ! -d "$target_dir" ]]; then
        log "创建解压目录: $target_dir"
        if mkdir -p "$target_dir"; then
            log "解压固件: $ipsw2"
            if unzip -o "$ipsw1" -d "$target_dir" ; then
                log "固件解压成功: $ipsw2"
            else
                error "固件解压失败: $ipsw2"
                return 1
            fi
        else
            error "创建目录失败: $target_dir"
            return 1
        fi
    else
        log "目录已存在，跳过解压: $target_dir"
    fi
}

downloader() {
    log 开始下载
    $aria2c $1 -o $tmp
}


#api by (https://github.com/wzdc/lanzouyunapi/)
lanzou_server() {
    rm -r $tmp/lanzou > /dev/null 2>&1
    cp -R $script_dir/bin/Others/lanzou $tmp > /dev/null 2>&1
    local port=5408  
    (
        nohup php -S 127.0.0.1:$port -t "$tmp/lanzou" > /dev/null 2>&1 &
        php_pid=$!
        echo $php_pid > "$tmp/php_server.pid"
        trap "kill $php_pid 2>/dev/null; exit 0" TERM INT
        wait $php_pid
    ) &
    sleep 2
}

lanzou_download() {
    #if [[ $local_lanzou_server == 1 ]]; then
        lanzou_server
        trap stop_php EXIT INT TERM
    #fi
    local url="" password="" download_all="false" download_file="" quiet_mode="false"
    local tmp_dir=""
    local args=("$@")
    local i=0
    local tmp_dir=$tmp
    while [ $i -lt ${#args[@]} ]; do
        case "${args[i]}" in
            "--u="*)
                url="${args[i]#--u=}"
                ;;
            "--pwd="*)
                password="${args[i]#--pwd=}"
                ;;
            "--download"|"download")
                download_all="true"
                ;;
            "--f="*)
                download_file="${args[i]#--f=}"
                ;;
            "--q"|"q")
                quiet_mode="true"
                ;;
        esac
        ((i++))
    done
    if ! command -v "$jq" &> /dev/null; then
        log "错误: 需要 jq 命令，请先安装"
        return 1
    fi
    if [ -z "$url" ]; then
        error "错误: 未提供URL"
        log "用法: lanzou_download --u=URL [--pwd=密码] [--download] [--f=文件名] [--q]静默下载"
        return 1
    fi
    mkdir -p "$tmp_dir"
    #if [[ $local_lanzou_server == 1 ]]; then
        local api_url="http://127.0.0.1:5408/?url=$url"
    #else
    #    local api_url="https://vercel-chi-kohl.vercel.app/lanzouyunapi.php?url=$url"
    #fi
    if [ -n "$password" ]; then
        api_url="${api_url}&pw=$password"
    fi
    local response http_code json_content
    if [ "$quiet_mode" = "true" ]; then
        response=$(curl -s -w "%{http_code}" "$api_url")
    else
        response=$(curl -s -w "%{http_code}" "$api_url")
    fi
    http_code=${response: -3}
    json_content=${response%???}
    if [ "$http_code" -ne 200 ]; then
        error "错误: HTTP 请求失败，状态码: $http_code"
        return 1
    fi
    local code msg
    code=$(echo "$json_content" | $jq -r '.code')
    msg=$(echo "$json_content" | $jq -r '.msg')
    if [ "$code" -ne 0 ]; then
        log $json_content
        error "API 错误: $msg"
        return 1
    fi
    if echo "$json_content" | $jq -e '.data.list' > /dev/null 2>&1; then
        local folder_name file_count
        folder_name=$(echo "$json_content" | $jq -r '.data.name')
        file_count=$(echo "$json_content" | $jq -r '.data.list | length')
        if [ "$quiet_mode" = "false" ]; then
            log "找到文件夹: $folder_name (包含 $file_count 个文件)"
        fi
        if [ $file_count -eq 0 ]; then
            log "文件夹为空"
            return 0
        fi
        if [ -n "$download_file" ]; then
            if [ "$quiet_mode" = "false" ]; then
                log "正在查找文件: $download_file"
            fi
            local file_found=0
            for ((i=0; i<file_count; i++)); do
                local current_name
                current_name=$(echo "$json_content" | $jq -r ".data.list[$i].name")
                if [ "$current_name" = "$download_file" ]; then
                    file_found=1
                    local file_id file_url filepath
                    file_id=$(echo "$json_content" | $jq -r ".data.list[$i].id")
                    local file_api_url="http://127.0.0.1:5408/?url=https://wwhu.lanzoub.com/$file_id"
                    local file_response file_http_code file_json
                    file_response=$(curl -s -w "%{http_code}" "$file_api_url")
                    file_http_code=${file_response: -3}
                    file_json=${file_response%???}
                    if [ "$file_http_code" -ne 200 ]; then
                        error "错误: 获取文件下载链接失败，状态码: $file_http_code"
                        return 1
                    fi
                    local file_code file_msg
                    file_code=$(echo "$file_json" | $jq -r '.code')
                    file_msg=$(echo "$file_json" | $jq -r '.msg')
                    if [ "$file_code" -ne 0 ]; then
                        log 2
                        error "API 错误: $file_msg"
                        return 1
                    fi
                    file_url=$(echo "$file_json" | $jq -r '.data.url')
                    filepath="$tmp_dir/$download_file"
                    if [ "$quiet_mode" = "false" ]; then
                        log "找到文件: $download_file"
                        log "开始下载: $download_file"
                    fi
                    if [ "$quiet_mode" = "true" ]; then
                        curl --progress-bar -L -o "$filepath" "$file_url"
                    else
                        if curl --progress-bar -L -o "$filepath" "$file_url"; then
                            log "✓ 下载完成: $download_file"
                            log "  文件大小: $(du -h "$filepath" | cut -f1)"
                            log "  保存路径: $filepath"
                        else
                            error "✗ 下载失败: $download_file"
                            rm -f "$filepath"
                            return 1
                        fi
                    fi
                    return 0
                fi
            done
            if [ $file_found -eq 0 ]; then
                error "错误: 在文件夹中未找到文件 '$download_file'"
                log "可用文件列表:"
                for ((i=0; i<file_count; i++)); do
                    local name
                    name=$(echo "$json_content" | $jq -r ".data.list[$i].name")
                    echo "  - $name"
                done
                return 1
            fi
        fi
        if [ "$download_all" = "true" ]; then
            if [ "$quiet_mode" = "false" ]; then
                log "开始批量下载所有文件（自动覆盖）..."
            fi
            for ((i=0; i<file_count; i++)); do
                local file_id file_name file_url filepath
                file_id=$(echo "$json_content" | $jq -r ".data.list[$i].id")
                file_name=$(echo "$json_content" | $jq -r ".data.list[$i].name")
                local file_api_url="http://127.0.0.1:5408/?url=https://wwhu.lanzoub.com/$file_id"
                local file_response file_http_code file_json
                file_response=$(curl -s -w "%{http_code}" "$file_api_url")
                file_http_code=${file_response: -3}
                file_json=${file_response%???}
                if [ "$file_http_code" -ne 200 ]; then
                    error "错误: 获取文件下载链接失败，状态码: $file_http_code"
                    continue
                fi
                local file_code file_msg
                file_code=$(echo "$file_json" | $jq -r '.code')
                file_msg=$(echo "$file_json" | $jq -r '.msg')
                if [ "$file_code" -ne 0 ]; then
                    log 3
                    error "API 错误: $file_msg"
                    continue
                fi
                file_url=$(echo "$file_json" | $jq -r '.data.url')
                filepath="$tmp_dir/$file_name"
                if [ "$quiet_mode" = "false" ]; then
                    log "正在下载: $file_name"
                fi
                if [ "$quiet_mode" = "true" ]; then
                    curl --progress-bar -L -o "$filepath" "$file_url"
                else
                    if curl --progress-bar -L -o "$filepath" "$file_url"; then
                        log "✓ 下载完成: $file_name"
                        log "  文件大小: $(du -h "$filepath" | cut -f1)"
                        log "  保存路径: $filepath"
                    else
                        error "✗ 下载失败: $file_name"
                        rm -f "$filepath"
                    fi
                    echo ""
                fi
            done
            if [ "$quiet_mode" = "false" ]; then
                log "批量下载完成！"
            fi
        else
            if [ "$quiet_mode" = "true" ]; then
                error "错误: 安静模式下不能使用交互菜单，请使用 --download 或 --f 参数"
                return 1
            fi
            input 选择文件下载
            for ((i=0; i<file_count; i++)); do
                local name size
                name=$(echo "$json_content" | $jq -r ".data.list[$i].name")
                size=$(echo "$json_content" | $jq -r ".data.list[$i].size")
                printf "%-3s %-40s %-8s %-12s\\n" "$((i+1))" "$name" "$size"
            done
            local file_options=()
            for ((i=0; i<file_count; i++)); do
                local name size
                name=$(echo "$json_content" | $jq -r ".data.list[$i].name")
                size=$(echo "$json_content" | $jq -r ".data.list[$i].size")
                file_options+=("下载: $name ($size)")
            done
            file_options+=("下载所有文件" "返回" "退出")
            while true; do
                echo ""
                echo "请选择要下载的文件:"
                select_option "${file_options[@]}"
                local choice=$?
                local selected="${file_options[$choice]}"
                case "$selected" in
                    "下载所有文件")
                        log "开始下载所有文件..."
                        for ((i=0; i<file_count; i++)); do
                            local file_id file_name file_url filepath
                            file_id=$(echo "$json_content" | $jq -r ".data.list[$i].id")
                            file_name=$(echo "$json_content" | $jq -r ".data.list[$i].name")
                            local file_api_url="http://127.0.0.1:5408/?url=https://wwhu.lanzoub.com/$file_id"
                            local file_response file_http_code file_json
                            file_response=$(curl -s -w "%{http_code}" "$file_api_url")
                            file_http_code=${file_response: -3}
                            file_json=${file_response%???}
                            if [ "$file_http_code" -ne 200 ]; then
                                error "错误: 获取文件下载链接失败，状态码: $file_http_code"
                                continue
                            fi
                            local file_code file_msg
                            file_code=$(echo "$file_json" | $jq -r '.code')
                            file_msg=$(echo "$file_json" | $jq -r '.msg')
                            if [ "$file_code" -ne 0 ]; then
                                log 4
                                error "API 错误: $file_msg"
                                continue
                            fi
                            file_url=$(echo "$file_json" | $jq -r '.data.url')
                            filepath="$tmp_dir/$file_name"
                            log "正在下载: $file_name"
                            if [ -f "$filepath" ]; then
                                local overwrite_options=("覆盖文件" "跳过下载" "重命名文件")
                                log "文件已存在，请选择:"
                                select_option "${overwrite_options[@]}"
                                local overwrite_choice=$?
                                local overwrite_selected="${overwrite_options[$overwrite_choice]}"
                                case "$overwrite_selected" in
                                    "覆盖文件")
                                        log "覆盖现有文件..."
                                        if curl --progress-bar -L -o "$filepath" "$file_url"; then
                                            log "✓ 下载完成: $file_name"
                                        else
                                            log "✗ 下载失败: $file_name"
                                            rm -f "$filepath"
                                        fi
                                        ;;
                                    "跳过下载")
                                        log "跳过下载: $file_name"
                                        ;;
                                    "重命名文件")
                                        read -p "请输入新文件名: " new_name
                                        if [ -n "$new_name" ]; then
                                            local new_filepath="$tmp_dir/$new_name"
                                            if curl --progress-bar -L -o "$new_filepath" "$file_url"; then
                                                log "✓ 下载完成: $file_name (重命名为: $new_name)"
                                            else
                                                log "✗ 下载失败: $file_name"
                                                rm -f "$new_filepath"
                                            fi
                                        fi
                                        ;;
                                esac
                            else
                                if curl --progress-bar -L -o "$filepath" "$file_url"; then
                                    log "✓ 下载完成: $file_name"
                                else
                                    log "✗ 下载失败: $file_name"
                                    rm -f "$filepath"
                                fi
                            fi
                            echo ""
                        done
                        break
                        ;;
                    "返回")
                        log "返回上级菜单"
                        break
                        ;;
                    "退出")
                        log "退出下载"
                        return 0
                        ;;
                    *)
                        if [[ "$selected" == "下载: "* ]]; then
                            local file_index=$choice
                            if [ $file_index -lt $file_count ]; then
                                local file_id file_name file_url
                                file_id=$(echo "$json_content" | $jq -r ".data.list[$file_index].id")
                                file_name=$(echo "$json_content" | $jq -r ".data.list[$file_index].name")
                                file_url="https://wwhu.lanzoub.com/$file_id"
                                lanzou_download --u="$file_url"
                            fi
                        fi
                        ;;
                esac
            done
        fi
    else
        local name file_url filepath
        name=$(echo "$json_content" | $jq -r '.data.name')
        file_url=$(echo "$json_content" | $jq -r '.data.url')
        filepath="$tmp_dir/$name"
        if [ "$quiet_mode" = "false" ]; then
            log "找到文件: $name"
        fi
        if [ "$download_all" = "true" ] || [ "$quiet_mode" = "true" ]; then
            if [ "$quiet_mode" = "false" ]; then
                log "开始下载: $name"
                log "保存到: $filepath"
            fi
            if [ "$quiet_mode" = "true" ]; then
                curl --progress-bar -L -o "$filepath" "$file_url"
            else
                if curl --progress-bar -L -o "$filepath" "$file_url"; then
                    log "✓ 下载完成: $name"
                    log "  文件大小: $(du -h "$filepath" | cut -f1)"
                    log "  保存路径: $filepath"
                else
                    log "✗ 下载失败: $name"
                    rm -f "$filepath"
                    return 1
                fi
            fi
        else
            local options=("下载文件: $name" "跳过下载" "返回" "退出")
            log "请选择操作:"
            select_option "${options[@]}"
            local choice=$?
            local selected="${options[$choice]}"
            case "$selected" in
                "下载文件: $name")
                    log "开始下载: $name"
                    log "保存到: $filepath"
                    if [ -f "$filepath" ]; then
                        local overwrite_options=("覆盖文件" "跳过下载" "重命名文件")
                        log "文件已存在，请选择:"
                        select_option "${overwrite_options[@]}"
                        local overwrite_choice=$?
                        local overwrite_selected="${overwrite_options[$overwrite_choice]}"
                        case "$overwrite_selected" in
                            "覆盖文件")
                                log "覆盖现有文件..."
                                ;;
                            "跳过下载")
                                log "跳过下载: $name"
                                return 0
                                ;;
                            "重命名文件")
                                read -p "请输入新文件名: " new_name
                                if [ -n "$new_name" ]; then
                                    filepath="$tmp_dir/$new_name"
                                fi
                                ;;
                        esac
                    fi
                    if curl --progress-bar -L -o "$filepath" "$file_url"; then
                        log "✓ 下载完成: $name"
                        log "  文件大小: $(du -h "$filepath" | cut -f1)"
                        log "  保存路径: $filepath"
                    else
                        error "✗ 下载失败: $name"
                        rm -f "$filepath"
                        return 1
                    fi
                    ;;
                "跳过下载")
                    log "跳过下载: $name"
                    return 0
                    ;;
                "返回")
                    log "返回上级菜单"
                    return 0
                    ;;
                "退出")
                    log "退出下载"
                    return 0
                    ;;
            esac
        fi
    fi
    return 0
}



stop_php() {
    if [[ -n "$subshell_pid" ]] && kill -0 $subshell_pid 2>/dev/null; then
        kill $subshell_pid 2>/dev/null
    fi
    if [[ -f "$tmp/php_server.pid" ]]; then
        local pid=$(cat "$tmp/php_server.pid")
        kill $pid 2>/dev/null
        rm -f "$tmp/php_server.pid"
    fi
}

disclaimers() {
    if [ -f "$script_dir/bin/allowed.txt" ]; then
        :
    else
        cat $script_dir/bin/Others/logo
        echo " "
        log "免责声明"
        warning "对于因遵循本指南而对您的设备造成的任何损坏，我们概不负责。请谨慎行事，风险自负！！！"
        yesno 是否同意此条款?
        if [[ $? == 1 ]]; then
            touch $script_dir/bin/allowed.txt
        else
            :
        fi
    fi
}

main() {
    local options
    local selected 
    clear
    tip  "*** iPwnTouch Tools ***"
    tip  "- Script by MrY0000 -"
    tip  "- Thanks XiaoWZ Setup.app -"
    tip  "- $platform_message -"
    tip  "*****主程序版本:$local_main_ver********"
    tip  "*****运行库版本:$local_runtime_ver*****"
    if [[ $1 != none ]]; then 
        if [[ -z $device_type ]]; then
            if [[ $isdevicecheck == 1 ]]; then 
                :
            else
                local de=$de
            fi
        elif [[ $device_type == 无法获取 ]]; then
            local de=$de
        else
            if [[ $device_type == iPhone1,1 ]]; then
                de=1
                device_model=n45
                device_latest_ver=3.1.3
                device_proc=1
            elif [[ $device_type == iPod1,1 ]]; then
                de=1
                device_model=n45
                device_latest_ver=3.1.3
                device_proc=1
            elif [[ $device_type == iPod2,1 ]]; then
                de=2
                device_model=n72
                device_latest_ver=4.2.1
                device_proc=1
            elif [[ $device_type == iPod3,1 ]]; then
                de=3
                device_model=n18
                device_latest_ver=5.1.1
                device_proc=4
            elif [[ $device_type == iPod4,1 ]]; then
                de=4
                device_model=n81
                device_latest_ver=6.1.6
                device_proc=4
            elif [[ $device_type == iPod5,1 ]]; then
                de=5
                device_model=n78
                device_latest_ver=9.3.5
                device_proc=5
            elif [[ $device_type == iPod7,1 ]]; then
                de=6
                device_model=n102
                device_latest_ver=12.5.7
                device_proc=7
            elif [[ $device_type == iPhone3,1 ]]; then
                de=4
                device_model=n81
                device_latest_ver=6.1.6
                if [[ $os != 7.1.2 ]]; then
                    warning 未知设备
                fi
            elif [[ $device_type == iPhone3,3 ]]; then  
                de=4
                if [[ $os != 7.1.2 ]]; then
                    warning 未知设备
                fi
            else
                de=?
                warning 未知设备
            fi
        fi
        if [[ "$checkversion" == "1" ]]; then
            if [[ ! -s $script_dir/bin/Others/newversion.txt ]]; then
                :
            else
                appscriptversion=$(sed '1q;d' "$script_dir/bin/Others/newversion.txt")
                appruntimeversion=$(sed '2q;d' "$script_dir/bin/Others/newversion.txt")
                tip 最新脚本版本:$appscriptversion $iscanbeupdated
                tip 最新运行文件版本:$appruntimeversion $iscanbeupdated1
                rm -rf $script_dir/bin/Others/newversion.txt
            fi
        else
            :
        fi
        tip "设备: iPod touch $de"
        if [[ "$isdevicecheck" == "1" ]]; then
            if [[ $device_mode == 正常 ]]; then
                tip 模式:$device_mode 模式
                tip 型号:$device_type
                if [[ -z $os ]]; then
                    local os=无法获取
                fi
                tip "iOS 版本:$os"
                tip "ECID:$device_ecid"
                if [[ "$checkjb" == "1" ]]; then
                    if [[ "$insshrd" == "1" ]]; then
                        isjb=$(timeout 5 $ideviceinstaller list --all 2>&1)
                    else
                        isjb=$($ideviceinstaller list --all 2>&1)
                    fi
                    if echo "$isjb" | grep -q "Could not start com.apple.mobile.installation_proxy: Service prohibited"; then
                        isjb1=设备未激活
                    fi
                    if echo "$isjb" | grep -q "com.saurik.Cydia"; then
                        isjb1=是
                    else
                        if echo "$isjb" | grep -q "com.apple.AppStore"; then
                            isjb1=否
                        else
                            isjb1=无法获取
                        fi 
                    fi
                    tip 是否越狱:$isjb1
                else
                    :
                fi
                isactive=$($ideviceactivation state)
                if [[ $isactive == *"ActivationState: Activated"* ]]; then
                    isactive1=是
                elif [[ $isactive == *"ActivationState: Unactivated"* ]]; then
                    isactive1=否
                else
                    isactive1=无法获取
                fi
                tip 是否激活:$isactive1


            elif [[ $device_mode == 恢复 ]]; then
                tip 模式:$device_mode 模式
                if [[ $device_type == iPhone1,1 ]]; then
                    tip 型号:iPod1,1
                else
                    tip 型号:$device_type
                fi
            elif [[ $device_mode == DFU ]]; then
                tip 模式:$device_mode 模式
                if [[ $device_type == iPhone1,1 ]]; then
                    tip 型号:iPod1,1
                else
                    tip 型号:$device_type
                fi
                if [[ $device_type == iPhone1,1 ]]; then
                    :
                else
                    tip "ECID:$device_ecid"
                fi
                if [[ "$de" != "1" ]]; then
                    if [[ "$pwn" == "是" ]]; then
                        tip "Pwn:$pwn($device_pwnd)"
                    else
                        tip "Pwn:$pwn"
                    fi
                fi
            elif [[ "$isdevicecheck" != "1" ]]; then
                :
            else
                tip 模式:SSHRD 模式
                tip 型号:$device_type
            fi
        else
            tip 型号:$device_type
        fi
    else
        :
    fi
    if [[ "$os" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        cut_os_vers device $os
    fi
    input "选择选项:"

}


main_choice() {
    local options=()
    local selected
    main
    options+=("恢复/降级" "越狱" "提取SHSH")
    if [[ $isactive1 == 否 ]]; then
        options+=("激活设备(ideviceactivation)")
    fi
    options+=("其他选项" "更新")
    if [[ $device_mode == DFU ]]; then
        options+=("引导启动")
    elif [[ $device_mode == 恢复 ]]; then
        options+=("引导启动")
    fi
    if [[ "$login" == "1" ]]; then
        if [[ ! -f "$script_dir/bin/Others/autologin.txt" ]]; then
            options+=("登录")
        else
            options+=("退出登录")
        fi
    fi
    if [[ "$isdevicecheck" == "1" ]]; then
        options+=("刷新设备")
    else
        :
    fi
    options+=("关于")
    options+=("退出")
    select_option "${options[@]}"
    selected="${options[$?]}"
            case $selected in
            "恢复/降级" ) restore_choice;;
            "恢复/降级" ) restore_choice;;
            "越狱" ) Jailbreak_choice;;
            "其他选项" ) Other_choice;;
            "更新" ) update;;
            "提取SHSH" ) shsh_save ; go_to_menu;;
            "引导启动" ) justboot_choice;;
            "刷新设备" ) refresh_device;;
            "激活设备(ideviceactivation)" ) device_active; go_to_menu;;
            "关于" ) about;;
            "退出" ) exit;;
        esac
}

restore_choice() {
    local options=()
    local selected
    main
    if [[ $de != "1" && $de != "2" && $de != "6" ]]; then
        options+=("降级(有SHSH)")
        options+=("降级(强降)")
    fi
    case $de in
        1)
            options+=("iOS3.1.3")
            options+=("降级(iOS3.0+)")
            options+=("刷入白门固件")
            ;; 
        2)
            options+=("iOS4.2.1")
            ;;    
        3)
            options+=("降级(powdersn0w)")
            options+=("iOS5.1.1")
            ;;
        4)
            options+=("iOS7双系统")
            options+=("iOS7单系统")
            options+=("iOS6.1.6")
            ;;
        5)
            options+=("降级(powdersn0w)")
            options+=("Futurerestore降级(有SHSH)")
            options+=("iOS9.3.5")
            ;;
        6)
            options+=("Futurerestore降级(iOS11.3+)")
            ;;
    esac
    if [[ $de != 6 ]]; then
        options+=("制作自制固件")
        options+=("刷入自制固件")
    fi
    options+=("TEST")
    options+=("返回主页" "退出")
    select_option "${options[@]}"
    selected="${options[$?]}"
            case $selected in
            "TEST" ) restore_files_select noflash;;
            "iOS7双系统" ) ios7_choice_d;;
            "iOS7单系统" ) ios7_choice_t;;
            "降级(有SHSH)" ) restore shsh ; go_to_menu;;
            "降级(强降)" ) restore tethered; pause; 3s;;
            "降级(powdersn0w)" ) restore powder; go_to_menu;;
            "制作自制固件" ) restore make; go_to_menu;;
            "刷入自制固件" ) 
                        local options1=()
                        options1+=("SHSH固件" "强降固件")
                        if [[ $de == "3" ]] || [[ $de == "5" ]]; then
                            options+=("powdersn0w固件")
                        fi
                        select_option "${options1[@]}"
                        selected1="${options1[$?]}"
                        if [[ $selected1 == "SHSH固件" ]]; then
                            restore flashonly=shsh
                        elif [[ $selected1 == "强降固件" ]]; then
                            restore flashonly=tethered
                        elif [[ $selected1 == "powdersn0w固件" ]]; then
                            restore flashonly=powder
                        fi
                        go_to_menu
                        ;;
            "Futurerestore降级(iOS11.3+)" ) restore futurerestore $device_type ; go_to_menu;;
            "Futurerestore降级(有SHSH)" ) restore futurerestore $device_type ; go_to_menu;;
            "刷入白门固件" ) restore_whited00r; go_to_menu;;
            "降级(iOS3.0+)" ) restore_legacy 3.1.3 ; go_to_menu;;
            "iOS3.1.3" ) restore_legacy; go_to_menu;;
            "iOS4.2.1" ) restore_latest_ver; go_to_menu;;
            "iOS5.1.1" ) restore_latest_ver; go_to_menu;;
            "iOS6.1.6" ) restore_latest_ver; go_to_menu;;
            "iOS9.3.5" ) restore_latest_ver; go_to_menu;;
            "iOS12.5.7" ) restore_latest_ver; go_to_menu;;
            "返回主页" ) go_to_menu nopause;;
            "退出" ) exit;;
        esac
    restore_choice
}


Jailbreak_choice() {
    local options=()
    local selected
    main
    options+=("SSHRD越狱(任意版本)")
    case $de in
        2)  :  ;;    
        3)  options+=("iOS5.1.1 SSHRD越狱") ;;
        4)  options+=("iOS6.1.6 SSHRD越狱") ;;
        5)  :   ;;
        6)  :   ;;
    esac
    options+=("返回主页" "退出")
    select_option "${options[@]}"
    selected="${options[$?]}"
            case $selected in
            "SSHRD越狱(任意版本)" ) jailbreak_sshrd; go_to_menu;;
            "iOS6.1.6 SSHRD越狱" ) os6jailbreak; go_to_menu;;
            "iOS5.1.1 SSHRD越狱" ) 511_jb; go_to_menu;;
            #"Aquila越狱" ) aquila_jailbreak;; #懒得加
            "返回主页" ) go_to_menu nopause;;
            "退出" ) exit;;
        esac
    Jailbreak_choice
}

Other_choice() {
    local options=()
    local selected
    main
    case $de in
        1)
            options+=("进入SSHRD(3.1.3)")
            ;;
        2)
            options+=("进入SSHRD(4.2.1)")
            ;;
        3)
            options+=("进入SSHRD(5.1.1)")
            options+=("打开/关闭iBoot漏洞")
            ;;
        4)
            options+=("进入SSHRD(6.1.6)")
            options+=("打开电量显示")
            ;;
        5)
            options+=("进入SSHRD(6.1.3)")
            options+=("打开电量显示")
            ;;
        6)
            options+=("进入SSHRD(SSHRD_Script)")
            options+=("打开电量显示")
            options+=("SSHRD主页")
            ;;
        *)
            options+=("尝试连接SSHRD")
            ;;
    esac
    options+=("激活设备(ideviceactivation)")
    if [[ $de != "6" ]]; then
        options+=("激活设备(伪激活)")
    fi
    options+=("进入SSHRD")
    options+=("DFUHelper")
    options+=("检测SSH链接")
    options+=("SSHRD主页")
    options+=("链接afc shell")
    options+=("蓝奏云文件下载")
    options+=("返回主页")
    options+=("退出")
    #options=("进入SSHRD(6.1.6)" "激活设备(ideviceactivation)" "返回主页" "退出")
    select_option "${options[@]}"
    selected="${options[$?]}"
            case $selected in
            "进入SSHRD(6.1.6)" ) SSHRD; go_to_menu;;
            "进入SSHRD(5.1.1)" ) 511_SSHRD; go_to_menu;;
            "进入SSHRD(3.1.3)" ) 313_SSHRD; go_to_menu;;
            "进入SSHRD(4.2.1)" ) 421_SSHRD_SSHRD; go_to_menu;;
            "进入SSHRD(6.1.3)" ) 613_SSHRD; go_to_menu;;
            "进入SSHRD(SSHRD_Script)" ) sshrd_script ; go_to_menu;;
            "进入SSHRD" ) local_ramdisk ; go_to_menu;;
            "链接afc shell" ) $afc ;;
            "激活设备(ideviceactivation)" ) device_active; go_to_menu;;
            "激活设备(伪激活)" ) 
                    local_ramdisk nomenu 
                    hacktivate_device 
                    ;;
            "DFUHelper" ) 
                    case $de in
                        1 ) 
                            DFUhelper_legacy
                            ;;
                        * ) 
                            DFUhelper
                            ;;
                    esac
                    go_to_menu
                    ;;
            "检测SSH链接" ) log 输入需要检测的端口 ; read serverport ; sshcheck $serverport pause ; go_to_menu;;
            "SSHRD主页" ) 
                    if [[ $de == "6" ]]; then
                        SSHRD_choice_64
                    else
                        SSHRD_choice
                    fi
                    ;;
            "打开/关闭iBoot漏洞" ) 
                    menu_items=("打开iBoot漏洞" "关闭iBoot漏洞" "Go Back")
                    select_option "${menu_items[@]}"
                    selected1="${menu_items[$?]}"
                    case $selected1 in
                        "打开iBoot漏洞" ) 
                            rec=2
                            511_SSHRD nomenu
                            sleep 3
                            device_ramdisk_setnvram
                            ;; #关闭
                        "关闭iBoot漏洞" ) 
                            rec=0
                            511_SSHRD nomenu
                            sleep 3
                            device_ramdisk_setnvram
                            ;;  #打开
                    esac
                        go_to_menu
                        ;;
            "打开电量显示" ) 
                    local options1=()
                    local selected1
                    case $de in
                        6 ) log 由于64位的SSHRD挂载十分困难,遂删除掉此部分,请使用OpenSSH修改 ;;
                    esac
                    options1+=("OpenSSH修改")
                    select_option "${options1[@]}"
                    selected1="${options1[$?]}"
                    case $selected1 in
                        "SSHRD修改" ) 
                            case $de in
                               #6 ) sshrd_script $os nomenu ; device_add_battery_percentage sshrdscript;;
                                5 ) 613_SSHRD nomenu ; device_add_battery_percentage  ;;
                                4 )  SSHRD nomenu ; device_add_battery_percentage   ;;
                                3 )  511_SSHRD nomenu ; device_add_battery_percentage  ;;
                                * ) error 不支持此设备 ; go_to_menu ;;
                            esac
                            ;;
                        "OpenSSH修改" ) device_add_battery_percentage_openssh ;;
                    esac
                        ;;
            "蓝奏云文件下载" ) 
                    options9=("使用本地服务器(需要安装PHP)")
                    select_option "${options9[@]}"
                    selected9="${options9[$?]}"
                    if [[ $selected9 == "使用本地服务器(需要安装PHP)" ]]; then
                        local_lanzou_server=1
                    else
                        local_lanzou_server=0
                    fi
                    while true; do
                        log 输入蓝奏云分享链接
                        read lanzou_url
                        if [ -z "$lanzou_url" ]; then
                            error 未输入链接,请重新输入
                        else
                            break
                        fi
                    done
                    log "输入密码(没有则直接回车)"
                    read lanzou_pwd
                    if [ -z "$lanzou_pwd" ]; then
                        lanzou_arg="--u="$lanzou_url""
                    else
                        lanzou_arg="--u="$lanzou_url" --pwd="$lanzou_pwd""
                    fi
                    lanzou_download $lanzou_arg
                    go_to_menu
                        ;;          
            "返回主页" ) go_to_menu nopause;;
            "尝试连接SSHRD" ) SSHRD_choice; go_to_menu;;
            "退出" ) exit;;
        esac
    Other_choice
}

SSHRD_choice() {
    local exit
    clear
    log 正在连接SSH
    sleep 5
    sshcheck $ssh_port
    clear
    main none
    insshrd=1
    local options
    local selected
    options=("链接SSH" "越狱" "激活设备" "伪激活设备TEST" "备份激活文件" "还原激活文件" "查看iOS版本" "启用电量百分比" "清除nvram" "重启" "返回主页")
    select_option "${options[@]}"
    selected="${options[$?]}"
            case $selected in
            "链接SSH" ) sshrdconnect; pause;;
            "激活设备" ) activition; pause;;
            "伪激活设备TEST" ) hacktivate_device; go_to_menu ;;
            "越狱" ) jailbreak_sshrd; pause;;
            "备份激活文件" ) activition_backup; pause;;
            "还原激活文件" ) activition_restore; pause;;
            "还原激活文件" ) activition_restore; pause;;
            "查看iOS版本" ) check_iosvers; pause;;
            "启用电量百分比" ) device_add_battery_percentage ; pause;; #support witout ios7-ios9.3.5,OpenSSH mode is support all ios version
            "清除nvram" ) $ssh -p $ssh_port root@127.0.0.1 "nvram -c" ;;
            "重启" ) $ssh -p $ssh_port root@127.0.0.1 "reboot_bak"; go_to_menu;;
            "返回主页" ) exit=1 ; go_to_menu nopause  ;;
       esac
    if [[ "$exit" != "1" ]]; then
        SSHRD_choice
    fi
}

SSHRD_choice_64() {
    clear
    #sshcheck 2222
    main none
    insshrd=1
    local options
    local selected
    options=("链接SSH" "提取SHSH" "获取iOS版本" "重启" "返回主页" "退出")
    select_option "${options[@]}"
    selected="${options[$?]}"
            case $selected in
            "链接SSH" ) cd $script_dir/bin/SSHRD/SSHRD_Script ; check_sudo ; sudo ./sshrd.sh ssh ;;
            "提取SHSH" ) sshrd_script none dumpshsh; pause;;
            "获取iOS版本" ) check_iosvers sshrdscript $1; pause;;
            #"启用电量百分比" ) device_add_battery_percentage sshrdscript ; pause;;    #remove this part,because it's really difficult to mount device
            "重启" ) cd $script_dir/bin/SSHRD/SSHRD_Script ; sudo ./sshrd.sh reboot ;go_to_menu;;
            "返回主页" ) go_to_menu nopause ;;
            "退出" ) exit;;
       esac
}

ios7_choice_d() {
    local options
    local selected
    main
    if [[ $isdevicecheck != 1 ]]; then
        :
    else
        case $os in
            6.* ) :;;
            * ) warning iOS ${os}无法安装iOS7双系统,请刷入iOS6.1.6再试 ; go_to_menu ;;
        esac
    fi
    warning 安装完iOS7双系统后若cydia无法打开请重新安装
    options=("准备工作" "分区" "写入分区表" "安装系统" "工厂激活" "安装cydia" "运营商美化" "抹除iOS7双系统" "返回主页" "退出")
    select_option "${options[@]}"
    selected="${options[$?]}"
            case $selected in
            "准备工作" ) prepareworks;;
            "分区" ) cutdisk;;
            "写入分区表" ) writediskinf;;
            "安装系统" ) installsystem;;
            "工厂激活" ) factoryactivation;;
            "安装cydia" ) installcydia;;
            "运营商美化" ) Beauty;;
            "抹除iOS7双系统" ) erase_os7;;
            "返回主页" ) go_to_menu nopause;;
            "退出" ) exit;;
        esac
    ios7_choice_d
}

ios7_choice_t() {
    local options
    local selected
    main
    warning "因为强刷iOS7.0十分不稳定,遂取消刷入iOS7.0(可回到老版本刷写)"
    options=("开始刷入" "美化/修复WIFI" "越狱" "引导启动" "激活" "返回主页" "退出")
    select_option "${options[@]}"
    selected="${options[$?]}"
            case $selected in
            "开始刷入" ) 712Tethered;;
            "美化/修复WIFI" ) beauty7;;
            "越狱" ) jailbreak7;;
            "引导启动" ) boot712;;
            "激活" ) active712;;
            "返回主页" ) go_to_menu nopause;;
            "退出" ) exit;;
        esac
    ios7_choice_t
}

justboot_choice() {
    local options
    local selected
    if [[ $de == 4 ]]; then
        options=("iOS7引导" "其他系统引导" "回到主页")
    else
        options=("其他系统引导" "回到主页")
    fi
    #options=("iOS7引导" "其他系统引导" "回到主页")
    select_option "${options[@]}"
    selected="${options[$?]}"
            case $selected in
            "iOS7引导" ) boot712; go_to_menu;;
            "其他系统引导" ) justboot ; go_to_menu;;
            "返回主页" ) go_to_menu nopause;;
            "退出" ) exit;;
        esac
}

files_select() {
    local options=()
    local selected
    local finall_select
    local files_complete
    ipsw_select_path=
    for i in "$@"; do
        case $i in
            firmware )
            options+=("选择固件")
            ;;
            fs=* )
            finall_select="${i#fs=}"
            ;;
            fd=* )
            finall_do="${i#fd=}"
            ;;
        esac
    done
    while true; do
        clear
        main
        files_complete=false
        for i in "$@"; do
            case $i in
                firmware )
                if [[ -n "$ipsw_select_path" ]]; then
                    files_complete=true
                fi
            esac
        done
        if $files_complete; then
            options+=("${finall_select}")
        fi
        select_option "${options[@]}"
        selected="${options[$?]}"
        case $selected in
            "选择固件" ) 
                ipsw_select select
                ;;
            "${finall_select}" )
                if [ -z "$final_do" ]; then
                    break
                else
                    $final_do
                fi
                ;;
        esac
    done
}

restore_files_select() {
    #clear
    #main
    local ver
    local options=()
    local selected
    local files_complete=false
    local text="恢复"
    while true; do
        clear
        main
        options=()  # 清空选项数组
        options+=("选择目标固件")
        for i in "$@"; do
            case $i in
                shsh )
                    options+=("选择目标SHSH")
                    options+=("选择目标固件")
                    ;;
                tethered )
                    options+=("选择目标固件")
                    ;;
                powder )
                    options+=("选择目标固件")
                    case $device_type in
                        "iPod3,1" ) ver=5.1.1 ;;       
                        "iPod5,1" ) ver=7.1.x ;;
                        * ) error "本设备无法使用powdersn0w降级,可以使用SHSH/强制降级" ; exit 1 ;;
                    esac
                    options+=("选择iOS${ver}固件")
                    if [[ $ver != 5.1.1 ]]; then
                        options+=("选择iOS${ver}SHSH")
                    fi
                    ;;
                noflash | make )
                    local text="制作"
                    local no_flash=1
                    ;;
                
            esac
        done
        # 检查文件是否完整
        files_complete=false
        for i in "$@"; do
            case $i in
                shsh )
                    if [[ -n "$ipsw_path" && -n "$shsh_path" ]]; then
                        files_complete=true
                    fi
                    ;;
                tethered )
                    if [[ -n "$ipsw_path" ]]; then
                        files_complete=true
                    fi
                    ;;
                powder )
                    case $device_type in
                        "iPod3,1" ) ver=5.1.1 ;;       
                        "iPod5,1" ) ver=7.1.x ;;
                        * ) error "本设备无法使用powdersn0w降级,可以使用SHSH/强制降级" ; exit 1 ;;
                    esac
                    if [[ $ver != 5.1.1 ]]; then
                        if [[ -n "$ipsw_path" && -n "$ipsw_base_path" && -n "$shsh_path" ]]; then
                            files_complete=true
                        fi
                    else
                        if [[ -n "$ipsw_path" && -n "$ipsw_base_path" ]]; then
                            files_complete=true
                        fi
                    fi
                    ;;
            esac
        done
        if $files_complete; then
            if [[ $no_flash != 1 ]]; then
                options+=("开始恢复")
            else
                options+=("开始制作")
            fi
        fi
        select_option "${options[@]}"
        selected="${options[$?]}"
        case $selected in
            "选择目标固件" ) 
                ipsw_select target 
                ;;
            "选择iOS${ver}固件" )
                ipsw_select base 
                ;;
            "选择目标SHSH" ) 
                shsh_select  
                ;;
            "选择iOS${ver}SHSH" )
                shsh_select  
                ;;
            "开始${text}" ) 
                restore $@
                go_to_menu
                return
                ;;
            "返回主菜单" )
                return
                ;;
        esac
    done
}

restore() {
    local use_shsh=0
    local use_tethered=0
    local use_powder=0
    local use_jailbreak=0
    local skip_jailbreak=0
    local just_flash=0
    local no_flash=0
    local just_boot=0
    local send_pwnibss=0
    local show_usage=0
    local use_futurerestore=0
    local device_arg=""
    local only_flash=0
    local flash_mode=""
    local just_make=0
    
    if [[ $isdevicecheck != 1 ]]; then
        warning "请链接设备后再试"
        go_to_menu
    fi
    
    # 解析参数
    for i in "$@"; do
        case "$i" in
            "--shsh"|"shsh")
                use_shsh=1
                ;;
            "--tethered"|"tethered")
                use_tethered=1
                ;;
            "--powder"|"powder")
                use_powder=1
                ;;
            "--jb"|"jb")
                use_jailbreak=1
                ;;
            "--nojb"|"nojb")
                skip_jailbreak=1
                ;;
            "--flash"|"flash")
                just_flash=1
                ;;
            "--flashonly=shsh"|"flashonly=shsh")
                only_flash=1
                flash_mode="shsh"
                ;;
            "--flashonly=tethered"|"flashonly=tethered")
                only_flash=1
                flash_mode="tethered"
                ;;
            "--flashonly=powder"|"flashonly=powder")
                only_flash=1
                flash_mode="powder"
                ;;
            "--noflash"|"noflash")
                no_flash=1
                ;;
            "--justboot"|"justboot")
                just_boot=1
                ;;
            "--sendpwnibss"|"sendpwnibss")
                send_pwnibss=1
                ;;
            "--usage"|"--help"|"usage"|"help")
                show_usage=1
                ;;
            "--futurerestore"|"futurerestore")
                use_futurerestore=1
                ;;
            "--device=iPod5,1"|"iPod5,1")
                device_arg="iPod5,1"
                ;;
            "--device=iPod7,1"|"iPod7,1")
                device_arg="iPod7,1"
                ;;
            "--version")
                echo "restore.sh v1.2"
                return 0
                ;;
            "--verbose")
                ipsw_verbose=1
                ;;
            "--make"|"make")
                just_make=1
                ;;
        esac
    done

    # 获取设备信息（排除 usage/help/sendpwnibss 情况）
    if [[ $send_pwnibss == 0 ]] && [[ $show_usage == 0 ]]; then
        deviceinfo q
    fi

    log "restore.sh v1.2"
    log "transplant by MrY0000"
    log "transplant from Legacy iOS Kit"
    log "For iPod touch$de"
    all_flash="Firmware/all_flash/all_flash.${device_model}ap.production"
    
    # 主要功能逻辑
    if [[ $send_pwnibss == 1 ]]; then
        device_send_unpacked_ibss
    elif [[ $just_boot == 1 ]]; then
        DFUhelper pwn
        device_justboot
    elif [[ $only_flash == 1 ]]; then
        DFUhelper pwn
        restore_idevicerestore "$flash_mode"
    elif [[ $use_futurerestore == 1 ]]; then
        DFUhelper pwn
        if [[ "$device_arg" == "iPod5,1" ]]; then
            restore_futurerestore --use-pwndfu
        elif [[ "$device_arg" == "iPod7,1" ]]; then
            restore_futurerestore --use-pwndfu --skip-blob
        fi
    elif [[ $just_flash == 1 ]] && [[ -n "$device_arg" ]]; then
        restore_idevicerestore "$device_arg"
    elif [[ $just_flash == 1 ]]; then
        restore_idevicerestore
    elif [[ $just_make == 1 ]]; then
        # 仅制作固件模式
        ipsw_custom="${device_type}_${device_target_vers}_${device_target_build}_Custom"
        
        if [[ $use_tethered == 1 ]]; then
            device_target_tethered=1
            ipsw_custom+="T"
        elif [[ $use_shsh == 1 ]]; then
            # 移除 shsh_select 调用
            :
        elif [[ $use_powder == 1 ]]; then
            if [[ "$de" == "3" ]] || [[ "$de" == "5" ]]; then
                # 移除 shsh_select 调用
                device_target_powder=1
                ipsw_custom+="P"
                ipsw_verbose=0
            else
                warning "本设备不支持 powdersn0w 降级"
            fi
        else
            yesno "是否使用 SHSH 降级?" 1
            if [[ $? == 1 ]]; then
                # 移除 shsh_select 调用
                :
            else
                device_target_tethered=1
                ipsw_custom+="T"
            fi
        fi

        # 越狱选项处理
        if [[ $use_jailbreak == 1 ]]; then
            if [[ $ipsw_canjailbreak == 1 ]]; then
                ipsw_jailbreak=1
                ipsw_custom+="J"
            else
                log "目标固件无法自制越狱固件，请刷入后使用工具越狱"
                ipsw_jailbreak=0
                ipsw_custom+="V"
            fi
        elif [[ $skip_jailbreak == 1 ]]; then
            ipsw_jailbreak=0
            ipsw_custom+="V"
        else
            if [[ $ipsw_canjailbreak == 1 ]]; then
                yesno "是否制作越狱固件?" 1
                if [[ $? == 1 ]]; then
                    ipsw_jailbreak=1
                    ipsw_custom+="J"
                else
                    ipsw_jailbreak=0
                    ipsw_custom+="V"
                fi
            else
                log "目标固件无法自制越狱固件，请刷入后使用工具越狱"
                ipsw_jailbreak=0
                ipsw_custom+="V"
            fi
        fi

        # 制作固件
        if [[ ! -f "$saved/ipsws/$ipsw_custom.ipsw" ]]; then
            log "确认信息"
            log "本机型号: $device_type"
            log "目标版本: $device_target_vers"
            log "目标构建版本: $device_target_build"
            log "固件将保存为: $saved/ipsws/$ipsw_custom.ipsw"
            pause
            ipsw_prepare
            if [[ -f "$saved/ipsws/$ipsw_custom.ipsw" ]]; then
                log "制作完成 ✅"
                log "固件已经保存至 \"$saved/ipsws/$ipsw_custom.ipsw\""
            else
                error "固件制作失败"
                return 1
            fi
        else
            log "固件已自制过: $saved/ipsws/$ipsw_custom.ipsw"
        fi
    elif [[ -z "$*" ]] || [[ $use_shsh == 1 ]] || [[ $use_tethered == 1 ]] || [[ $use_powder == 1 ]]; then
        # 自定义固件制作逻辑
        ipsw_custom="${device_type}_${device_target_vers}_${device_target_build}_Custom"
        
        if [[ $use_tethered == 1 ]]; then
            device_target_tethered=1
            ipsw_custom+="T"
        elif [[ $use_shsh == 1 ]]; then
            # 移除 shsh_select 调用
            :
        elif [[ $use_powder == 1 ]]; then
            if [[ "$de" == "3" ]] || [[ "$de" == "5" ]]; then
                # 移除 shsh_select 调用
                device_target_powder=1
                ipsw_custom+="P"
                ipsw_verbose=0
            else
                warning "本设备不支持 powdersn0w 降级"
            fi
        else
            yesno "是否使用 SHSH 降级?" 1
            if [[ $? == 1 ]]; then
                # 移除 shsh_select 调用
                :
            else
                device_target_tethered=1
                ipsw_custom+="T"
            fi
        fi

        # 越狱选项处理
        if [[ $use_jailbreak == 1 ]]; then
            if [[ $ipsw_canjailbreak == 1 ]]; then
                ipsw_jailbreak=1
                ipsw_custom+="J"
            else
                log "目标固件无法自制越狱固件，请刷入后使用工具越狱"
                ipsw_jailbreak=0
                ipsw_custom+="V"
            fi
        elif [[ $skip_jailbreak == 1 ]]; then
            ipsw_jailbreak=0
            ipsw_custom+="V"
        else
            if [[ $ipsw_canjailbreak == 1 ]]; then
                yesno "是否制作越狱固件?" 1
                if [[ $? == 1 ]]; then
                    ipsw_jailbreak=1
                    ipsw_custom+="J"
                else
                    ipsw_jailbreak=0
                    ipsw_custom+="V"
                fi
            else
                log "目标固件无法自制越狱固件，请刷入后使用工具越狱"
                ipsw_jailbreak=0
                ipsw_custom+="V"
            fi
        fi

        # 固件制作和刷入逻辑
        if [[ ! -f "$saved/ipsws/$ipsw_custom.ipsw" ]]; then
            log "确认信息"
            log "本机型号: $device_type"
            log "目标版本: $device_target_vers"
            log "目标构建版本: $device_target_build"
            log "固件将保存为: $saved/ipsws/$ipsw_custom.ipsw"
            pause
            ipsw_prepare
            if [[ -f "$saved/ipsws/$ipsw_custom.ipsw" ]]; then
                log "制作完成 ✅"
                log "固件已经保存至 \"$saved/ipsws/$ipsw_custom.ipsw\""
            else
                error "固件制作失败"
                return 1
            fi
            # 如果指定了 flash 参数，则刷入固件
            if [[ $just_flash == 1 ]]; then
                DFUhelper pwn
                restore_idevicerestore
            fi
        else
            # 如果固件已存在且指定了 flash 参数，则刷入固件
            if [[ $just_flash == 1 ]]; then
                log "固件已自制过，准备开始刷入"
                DFUhelper pwn
                restore_idevicerestore
            else
                log "固件已自制过: $saved/ipsws/$ipsw_custom.ipsw"
            fi
        fi

        # 如果没有指定 noflash 且没有指定 flash，则询问是否刷入
        if [[ $no_flash == 0 ]] && [[ $just_flash == 0 ]]; then
            yesno "是否刷入固件?" 1
            if [[ $? == 1 ]]; then 
                DFUhelper pwn
                restore_idevicerestore
            fi
        elif [[ $no_flash == 1 ]]; then
            log "已选择仅制作不刷入模式，跳过刷入步骤"
        fi
    fi
}

get_local_ver() {
    local_main_ver=$(head -n 1 $script_dir/bin/Others/version.txt)
    local_runtime_ver=$(head -n 2 $script_dir/bin/Others/version.txt | tail -n 1)
}


update() {
    get_local_ver
    log 正在获取更新
    lanzou_download --u="https://wwhu.lanzoub.com/b0w990wjc" --pwd="3sut" --f=version.txt --q
    #cd $tmp
    main_ver=$($jq -r '.main_ver' $tmp/version.txt 2>/dev/null)
    runtime_ver=$($jq -r '.runtime_ver' $tmp/version.txt 2>/dev/null)
    main_updatelog=$($jq -r '.main_updatelog[]?' $tmp/version.txt 2>/dev/null)
    runtime_updatelog=$($jq -r '.runtime_updatelog[]?' $tmp/version.txt 2>/dev/null)
    if [ -z "$main_ver" ] || [ -z "$runtime_ver" ]; then
        error "错误: 无法获取版本信息"
        return
    fi
    if [ -z "$main_updatelog" ]; then
        echo "警告: 主程序更新日志为空"
        main_updatelog="暂无更新日志"
    fi
    if [ -z "$runtime_updatelog" ]; then
        echo "警告: 运行时更新日志为空"
        runtime_updatelog="暂无更新日志"
    fi
    log "成功获取版本信息"
    echo "主版本: $main_ver"
    echo "运行时版本: $runtime_ver"
    if (( $(echo "$main_ver >= $local_main_version" | bc) )); then
        log 更新日志
        echo $main_updatelog
        yesno 是否更新?
        if [[ $? == 1 ]]; then
            lanzou_download --u="https://wwhu.lanzoub.com/b0w9903va" --pwd="317n" --f=latest.txt --q
            if [[ ! -f "$tmp/latest.txt" ]]; then
                error 下载失败,回车返回主页
                go_to_menu
            else
                cp $tmp/latest.txt $script_dir/latest.txt
                mv $script_dir/restore.sh $script_dir/restore_${local_main_version}.sh
                mv $script_dir/latest.txt $script_dir/restore.sh
                chmod +x $script_dir/restore.sh
            fi
        else
            :
        fi
    else
        log 主程序为最新版本
    fi
    log $runtime_ver
    log $local_runtime_ver
    if (( $(echo "$runtime_ver >= $local_runtime_ver" | bc -l) )); then
        log 更新日志
        echo $runtime_updatelog
        yesno 是否更新?
        if [[ $? == 1 ]]; then
            lanzou_download --u="https://wwhu.lanzoub.com/b0w9903uj" --pwd="fn2h" --f="OTA_${runtime_ver}.tar" --q
            if [[ ! -f "$tmp/OTA_${runtime_ver}.tar" ]]; then
                error 下载失败,回车返回主页
                go_to_menu
            else
                cp $tmp/OTA_${runtime_ver}.tar $script_dir/OTA_${runtime_ver}.tar
                cd $script_dir
                tar -xf OTA_${runtime_ver}.tar
                if [ -f "$script_dir/ota.sh" ]; then
                    chmod +x $script_dir/ota.sh
                    ./ota.sh
                fi
            fi
        else
            go_to_menu
        fi
    else
        log 运行库为最新版本
    fi
    log 更新完成,请重新打开本脚本  
    exit 1

}



trytocd() {
    log 尝试连接设备
    pkill -9 -f "iproxy.*" 2>/dev/null
    $iproxy $ssh_port 22 -s 127.0.0.1 >/dev/null &
    rm ~/.ssh/known_hosts
if $ssh -p $ssh_port root@127.0.0.1 "echo 'SSH 连接成功'" &>/dev/null; then
    log "✅ SSH Ramdisk成功链接"
    log 输入reboot_bak重启
    log 输入mount.sh 挂载分区
    $ssh -p $ssh_port root@127.0.0.1
else
    error "❌ SSH Ramdisk链接失败(有可能是假的)"
fi
}

activition_backup() {
    local time=$(date +%Y-%m-%d-%H%M)
    mkdir $saved/activition/${time}_iPod_Touch_$de
    log 挂载设备
    $ssh -p $ssh_port root@127.0.0.1 "mount.sh"
    log com.apple.commcenter.device_specific_nobackup.plist
    $scp -r -P $ssh_port root@127.0.0.1:/mnt2/wireless/Library/Preferences/com.apple.commcenter.device_specific_nobackup.plist $saved/activition/${time}_iPod_Touch_$de
    log IC-Info.sisv
    $scp -r -P $ssh_port root@127.0.0.1:/mnt2/mobile/Library/FairPlay/iTunes_Control/iTunes/IC-Info.sisv $saved/activition/${time}_iPod_Touch_$de
    log Lockdown
    $scp -r -P $ssh_port root@127.0.0.1:/mnt2/root/Library/Lockdown $saved/activition/${time}_iPod_Touch_$de
    log lockdownd
    $scp -r -P $ssh_port root@127.0.0.1:/mnt1/usr/libexec/lockdownd $saved/activition/${time}_iPod_Touch_$de
    log 备份完成
    go_to_menu
}

activition_restore() {
    log 确保已经进入了SSHRD
    pause 回车继续
    log 挂载设备
    $ssh -p $ssh_port root@127.0.0.1 "mount.sh"
    log com.apple.commcenter.device_specific_nobackup.plist
    $scp -v -P $ssh_port $saved/activition/${time}_iPod_Touch_$de/com.apple.commcenter.device_specific_nobackup.plist root@127.0.0.1:/mnt2/wireless/Library/Preferences
    log IC-Info.sisv
    $scp -v -P $ssh_port $saved/activition/${time}_iPod_Touch_$de/IC-Info.sisv root@127.0.0.1:/mnt2/mobile/Library/FairPlay/iTunes_Control/iTunes
    log Lockdown
    $scp -v -P $ssh_port $saved/activition/${time}_iPod_Touch_$de/Lockdown root@127.0.0.1:/mnt2/root/Library
    log lockdownd
    $scp -v -P $ssh_port $saved/activition/${time}_iPod_Touch_$de/lockdownd root@127.0.0.1:/mnt1/usr/libexec
    log 还原完成
    go_to_menu
}

device_active() {
    log 回车开始激活
    pause 开始激活
    DEVICE_INFO=$($ideviceactivation state)
if [[ $DEVICE_INFO == *"ActivationState: Activated"* ]]; then
    log "设备已激活"
    3s
elif [[ $DEVICE_INFO == *"ActivationState: Unactivated"* ]]; then
    log "设备未激活"
    log 开始激活
    case $os in
        1.* ) $ideviceactivation itunes ;;
        2.* ) $ideviceactivation itunes ;;
        3.* ) $ideviceactivation itunes ;;
        * ) $ideviceactivation activate ;;
    esac
    sleep 2
    if [[ $DEVICE_INFO == *"ActivationState: Activated"* ]]; then
        log "设备已激活"
        3s
    elif [[ $DEVICE_INFO == *"ActivationState: Unactivated"* ]]; then
        log 设备若未激活请重新尝试,或者使用SSHRD选项-激活设备来伪激活设备
        go_to_menu
    fi
fi
}

hacktivate_device() {
    local ver
    local build
    local 
    log 开始伪激活设备
    log 获取iOS版本
    check_iosvers
    cut_os_vers $device_vers
    case $major_ver in
        [789]* )
            log 挂载分区
            $ssh -p $ssh_port root@127.0.0.1 "mount.sh"
            log 提取所需文件
            #local message=$($ssh -p $ssh_port root@127.0.0.1 "ls /mnt2/mobile/Media/com.apple.MobileGestalt.plist")
            #if [[ $message != "/mnt2/mobile/Media/com.apple.MobileGestalt.plist" ]]; then
                $ssh -p $ssh_port root@127.0.0.1 "mv /mnt2/mobile/Library/Caches/com.apple.MobileGestalt.plist /mnt2/mobile/Media"
                local message=$($ssh -p $ssh_port root@127.0.0.1 "ls /mnt2/mobile/Media/com.apple.MobileGestalt.plist")
                if [[ $message != "/mnt2/mobile/Media/com.apple.MobileGestalt.plist" ]]; then
                    error 提取失败
                    pause 按回车退出
                    return
                else
                    log 正在重启
                    pause
                    $ssh -p $ssh_port root@127.0.0.1 "reboot_bak"
                    sleep 5
                    checkmode normal
                    log 请信任设备后按回车
                    pause
                    $afc download /com.apple.MobileGestalt.plist $tmp
                    if [[ ! -f "$tmp/com.apple.MobileGestalt.plist" ]]; then
                        error 下载失败
                        pause 按回车退出
                        return
                    else
                        log 修补文件
                        $activition $tmp/com.apple.MobileGestalt.plist
                        log 上传文件
                        $afc upload $tmp/com.apple.MobileGestalt.plist /
                    fi
                fi
                log 重新进入SSHRD
                local_ramdisk nomenu
                sleep 5
                log 挂载分区
                $ssh -p $ssh_port root@127.0.0.1 "mount.sh"
            #fi
            log 重命名Setup.app
            $ssh -p $ssh_port root@127.0.0.1 "mv /mnt1/Applications/Setup.app /mnt1/Applications/Setup.app.bak"
            log 替换源文件
            $ssh -p $ssh_port root@127.0.0.1 "mv /mnt2/mobile/Library/Caches/com.apple.MobileGestalt.plist /mnt2/mobile/Library/Caches/com.apple.MobileGestalt.plist.bak"
            $ssh -p $ssh_port root@127.0.0.1 "mv /mnt2/mobile/Media/com.apple.MobileGestalt.plist /mnt2/mobile/Library/Caches"
            log 正在重启
            $ssh -p $ssh_port root@127.0.0.1 "reboot_bak"
            go_to_menu

            ;;
        [56]* )
            if [[ -n $($ssh -p $ssh_port root@127.0.0.1 "ls /mnt1/bin/bash 2>/dev/null") ]]; then
                log 本设备已越狱
            else
                yesno 由于iOS5-6的伪激活必须越狱,是否越狱?
                if [[ $? == 1 ]]; then
                    jailbreak_sshrd noreboot
                else
                    pause 回车重启设备
                    $ssh -p $ssh_port root@127.0.0.1 "reboot_bak"
                    go_to_menu
                fi
            fi
            log 挂载分区
            $ssh -p $ssh_port root@127.0.0.1 "mount.sh"
            log 重命名源文件
            $ssh -p $ssh_port root@127.0.0.1 "mv /mnt1/usr/libexec/lockdownd /mnt1/usr/libexec/lockdownd.bak"
            log 上传文件
            $scp -P $ssh_port $script_dir/bin/Others/lockdownd root@127.0.0.1:/mnt1/usr/libexec
            log 设置权限
            $ssh -p $ssh_port root@127.0.0.1 "chmod 755 /mnt1/usr/libexec/lockdownd"
            log 正在重启
            $ssh -p $ssh_port root@127.0.0.1 "reboot_bak"
            go_to_menu
            ;;
        * )
            warning 本设备暂不支持
            go_to_menu
            ;;
    esac
}

cut_os_vers() {
    if [[ $1 != device ]]; then
        device_det=$(echo "$1" | cut -c 1)
        device_det2=$(echo "$1" | cut -c -2)
        device_det3=$(echo "$1" | cut -c 3)
        device_det4=$(echo "$1" | cut -c 4)
        device_det5=$(echo "$1" | cut -c 4-5)
        device_det6=$(echo "$1" | cut -c 5-6)
    else
        device_det=$(echo "$2" | cut -c 1)
        device_det2=$(echo "$2" | cut -c -2)
        device_det3=$(echo "$2" | cut -c 3)
        device_det4=$(echo "$2" | cut -c 4)
        device_det5=$(echo "$2" | cut -c 4-5)
        device_det6=$(echo "$2" | cut -c 5-6)
    fi
    if [[ $1 != device ]]; then
        if [[ $device_det == 1 ]]; then
            major_ver=$device_det2
            minor_ver=$device_det4
            nano_ver=$device_det6
            nano_ver_wtd=$(echo "$nano_ver" | cut -c 2)
        else
            major_ver=$device_det
            minor_ver=$device_det3
            nano_ver=$device_det5
            nano_ver_wtd=$(echo "$nano_ver" | cut -c 2)
        fi
    else
        if [[ $device_det == 1 ]]; then
            device_major_ver=$device_det2
            device_minor_ver=$device_det4
            device_nano_ver=$device_det6
            device_nano_ver_wtd=$(echo "$device_nano_ver" | cut -c 2)
        else
            device_major_ver=$device_det
            device_minor_ver=$device_det3
            device_nano_ver=$device_det5
            device_nano_ver_wtd=$(echo "$device_nano_ver" | cut -c 2)
        fi
    fi
}

shsh_save() {
    if [[ "$de" == "6" ]]; then
        if [[ $insshrd == 1 ]]; then
            sshrd_script none dumpshsh
        else
            sshrd_script 12.0 dumpshsh
        fi
    else
        #cd $saved
        #./shshsave.sh $device_type
        #while true; do
        #    log 选择本机固件
        #    ipsw_shsh_path="$($zenity --file-selection --multiple --file-filter='IPSW | *.ipsw' --title="Select IPSW file(s)")"
        #    if [ ! -f "$ipsw_path" ]; then
        #        error "错误：文件 $ipsw_path 不存在！"
        #    else
        #        break
        #    fi
        #done
        files_select firmware fs="开始保存SHSH"
        unzip -p "$ipsw_select_path" "BuildManifest.plist" > /tmp/BuildManifest.plist 2>/dev/null
        if [ $? -ne 0 ]; then
            error "错误：无法从 IPSW 提取 BuildManifest.plist！"
        fi
        device_shsh_vers=$(plutil -extract "ProductVersion" xml1 -o - /tmp/BuildManifest.plist | sed -n 's/<string>\(.*\)<\/string>/\1/p')
        get_ipsw_info target $ipsw_select_path
        log 开始保存SHSH
        DFUhelper pwn
        shsh_save_onboard
    fi
}

shsh_save_tss() {
    local shsh
    local localshshpath=$lib/shsh
    local saved=$script_dir/../../Save/SHSH
    if [ -z "$localshshpath" ]; then
        log Creat SHSH files
        mkdir -p $localshshpath
    else
        :
    fi
    if [ "$device_proc" = "4" ]; then
        if [ -f "$saved/$ECID-$device_type-${device_latest_vers}.shsh" ]; then
            log 已经保存过SHSH,跳过下载
            cp $saved/$ECID-$device_type-${device_latest_vers}.shsh $localshshpath/$ECID-$device_type-$device_target_vers.shsh
        else
            log Save iOS${device_latest_vers} SHSH
            $tsschecker -d $device_type -e $ECID -i ${device_latest_vers} -s --save-path $tmp
            shsh=$(find "$tmp" -type f -name "*.shsh2" 2>/dev/null)
            if [ -z "$shsh" ]; then
                error Couldn‘t find iOS${device_latest_vers} SHSH,please check the Internat connection
                exit 1
            else
                log Save iOS${device_latest_vers} SHSH success
                cp $shsh $saved/$ECID-${device_type}-${device_latest_vers}.shsh
                mv $shsh $localshshpath/$ECID-${device_type}-${device_target_vers}.shsh
            fi
        fi
    else
        if [ -f "$saved/$ECID-$device_type-${device_latest_vers}.shsh2" ]; then
            log 已经保存过SHSH,跳过下载
            cp $saved/$ECID-$device_type-${device_latest_vers}.shsh2 $localshshpath/$ECID-$device_type-$device_target_vers.shsh
        else
            ipsw_get_url ${device_latest_build}
            log "Downloading BuildManifest for ${device_latest_vers}..."
            cd $tmp
            "$pzb" -g BuildManifest.plist -o BuildManifest.plist "$ipsw_url"
            if [ -f "$tmp/BuildManifest.plist" ]; then
                mv $tmp/BuildManifest.plist $tmp/${device_latest_build}.plist
            else
                error 下载失败
                exit 1
            fi
            log Save iOS${device_latest_vers} SHSH
            $tsschecker -d $device_type -e $ECID -i ${device_latest_vers} -s -m $tmp/${device_latest_build}.plist -o -s -B ${device_model}ap -b -g 0x1111111111111111 --save-path $tmp
            shsh=$(find "$tmp" -type f -name "*.shsh2" 2>/dev/null)
            if [ -z "$shsh" ]; then
                error Couldn‘t find iOS${device_latest_vers} SHSH,please check the Internat connection
                exit 1
            else
                log Save iOS${device_latest_vers} SHSH success
                cp $shsh $saved/$ECID-${device_type}-${device_latest_vers}.shsh2
                mv $shsh $localshshpath/$ECID-${device_type}-${device_target_vers}.shsh
            fi
        fi
    fi
}

shsh_save_onboard() {
    if [[ $device_proc == 4 && $device_pwnrec != 1 ]]; then
        patch_ibss
        log "Sending iBSS..."
        $irecovery -f $tmp/pwnediBSS.dfu
    fi
    sleep 2
    patch_ibec
    log "Sending iBEC..."
    $irecovery -f $tmp/pwnediBEC.dfu
    if [[ $device_pwnrec == 1 ]]; then
        $irecovery -c "go"
    fi
    sleep 3
    if ! (system_profiler SPUSBDataType 2> /dev/null | grep ' Apple Mobile Device (Recovery Mode)' >> /dev/null); then
        echo "[*] Waiting for device in Recovery mode"
    fi
    
    while ! (system_profiler SPUSBDataType 2> /dev/null | grep ' Apple Mobile Device (Recovery Mode)' >> /dev/null); do
        sleep 1
    done
    log "Dumping raw dump now"
    (echo -e "/send $script_dir/bin/Others/payload\ngo blobs\n/exit") | $irecovery2 -s
    $irecovery2 -g $tmp/dump.raw
    log "Rebooting device"
    $irecovery -n
    local raw
    local err
    shsh_convert_onboard $1
    err=$?
    if [[ $1 == "dump" ]]; then
        raw="$script_dir/SHSH/rawdump_${device_ecid}-${device_type}_$(date +%Y-%m-%d-%H%M)_${shsh_onboard_iboot}.raw"
    else
        raw="$script_dir/SHSH/rawdump_${device_ecid}-${device_type}-${device_target_vers}-${device_target_build}_$(date +%Y-%m-%d-%H%M)_${shsh_onboard_iboot}.raw"
    fi
    if [[ $1 == "dump" ]] || [[ $err != 0 && -s $tmp/dump.raw ]]; then
        mv $tmp/dump.raw $raw
        log "Raw dump saved at: $raw"
    fi
}

shsh_convert_onboard() {
    local shsh="$saved/SHSH/${device_ecid}-${device_type}_$(date +%Y-%m-%d-%H%M).shsh"
    if (( device_proc < 7 )); then
        shsh="$saved/SHSH/${device_ecid}-${device_type}-${device_target_vers}-${device_target_build}.shsh"
        # remove ibob for powdersn0w/dra downgraded devices. fixes unknown magic 69626f62
        local blob=$(xxd -p $tmp/dump.raw | tr -d '\n')
        local bobi="626f6269"
        local blli="626c6c69"
        if [[ $blob == *"$bobi"* ]]; then
            log "Detected \"ibob\". Fixing... (This happens on DRA/powdersn0w downgraded devices)"
            rm -f $tmp/dump.raw
            printf "%s" "${blob%"$bobi"*}${blli}${blob##*"$blli"}" | xxd -r -p > $tmp/dump.raw
        fi
        shsh_onboard_iboot="$(cat $tmp/dump.raw | strings | grep iBoot | head -1)"
        log "Raw dump iBoot version: $shsh_onboard_iboot"
        if [[ $1 == "dump" ]]; then
            return
        fi
        log "Converting raw dump to SHSH blob"
        "$ticket" $tmp/dump.raw $tmp/dump.shsh "$ipsw_select_path" -z
    else
        "$img4tool" --convert -s $tmp/dump.shsh $tmp/dump.raw
    fi
    if [[ ! -s $tmp/dump.shsh ]]; then
        warning "Converting onboard SHSH blobs failed."
        return 1
    fi
    mv $tmp/dump.shsh $shsh
    log "Successfully saved $device_target_vers blobs: $shsh"
}

jailbreak_sshrd() {
    local vers
    local build
    local untether
    if [[ "$de" == "1" ]]; then
        device_type=iPod1,1
    elif [[ "$de" == "2" ]]; then
        device_type=iPod2,1
    elif [[ "$de" == "4" ]]; then
        device_type=iPod4,1
    elif [[ "$de" == "3" ]]; then
        device_type=iPod3,1
    elif [[ "$de" == "5" ]]; then
        device_type=iPod5,1
    else
        error 不支持的设备
        go_to_menu
    fi
    jelbrek=$script_dir/bin/Jailbreak
    sshcheck $ssh_port q
    if [[ "$sshyes" == "yes" ]]; then
        :
    else
        log 进入SSHRD
        if [[ "$de" == "2" ]]; then
            SSHRD nomenu
            sleep 2
            sshcheck $ssh_port
        elif [[ "$de" == "4" ]]; then
            SSHRD nomenu
            sleep 2
            sshcheck $ssh_port
        elif [[ "$de" == "3" ]]; then
            511_SSHRD nomenu
            sleep 2
            sshcheck $ssh_port
        elif [[ "$de" == "5" ]]; then
            613_SSHRD nomenu
            sleep 2
            sshcheck $ssh_port
        fi
    fi
    check_iosvers
    vers=$device_vers
    build=$device_build

    if [[ -n $($ssh -p $ssh_port root@127.0.0.1 "ls /mnt1/bin/bash 2>/dev/null") ]]; then
        warning "Your device seems to be already jailbroken. Cannot continue."
        $ssh -p "$ssh_port" root@127.0.0.1 "reboot_bak"
        return
    fi

    case $vers in
        9.3.[4231] | 9.3 ) untether="untetherhomedepot.tar";;
        9.2* | 9.1 )       untether="untetherhomedepot921.tar";;
        9.0* )             untether="everuntether.tar";;
        8* )               untether="daibutsu/untether.tar";;
        7.1* )
            case $device_type in
                iPod* ) untether="panguaxe-ipod.tar";;
                *     ) untether="panguaxe.tar";;
            esac
        ;;
        7.0* ) # remove for lyncis 7.0.x
            untether="evasi0n7-untether.tar"
            if [[ $device_type == "iPhone5,3" || $device_type == "iPhone5,4" ]] && [[ $vers == "7.0" ]]; then
                untether="evasi0n7-untether-70.tar"
            fi
            ;;
        6.1.[6543] )       untether="p0sixspwn.tar";;
        6* )               untether="evasi0n6-untether.tar";;
        5* )               untether="g1lbertJB/${device_type}_${build}.tar";;
        4.2.[8761] | 4.[10]* | 3.2* | 3.1.3 )
            untether="greenpois0n/${device_type}_${build}.tar"
        ;;
        4.[32]* )
            case $device_type in
                # untether=1 means no untether package, but the var still needs to be set
                iPad2,* | iPhone3,3 ) untether=1;;
                * ) untether="g1lbertJB/${device_type}_${build}.tar";;
            esac
        ;;
        3* ) [[ $device_type == "iPhone2,1" ]] && untether=1;;
        '' )
            warning "Something wrong happened. Failed to get iOS version."
            $ssh -p $ssh_port root@127.0.0.1 "reboot_bak"
        ;;
    esac

    if [[ -z $untether ]]; then
        warning "iOS $vers is not supported for jailbreaking with SSHRD."
        $ssh -p $ssh_port root@127.0.0.1 "reboot_bak"
        return
    fi
    log "Nice, iOS $vers is compatible."
    log "Mounting data partition"
    $ssh -p $ssh_port root@127.0.0.1 "mount.sh pv"

    # do stuff
    case $vers in
        6* )    device_send_rdtar fstab_rw.tar;;
        4.2.[8761] )
            log "launchd to punchd"
            $ssh -p $ssh_port root@127.0.0.1 "[[ ! -e /mnt1/sbin/punchd ]] && mv /mnt1/sbin/launchd /mnt1/sbin/punchd"
        ;;
    esac
    case $vers in
        5* ) device_send_rdtar g1lbertJB.tar;;
        [43]* )
            log "fstab"
            local fstab="fstab_new" # disk0s2s1 data
            if [[ $device_proc == 1 || $device_type == "iPod2,1" ]]; then
                fstab="fstab_old" # disk0s2 data
            fi
            $scp -P $ssh_port $jelbrek/$fstab root@127.0.0.1:/mnt1/private/etc/fstab
            $ssh -p $ssh_port root@127.0.0.1 "rm /mnt1/private/var/mobile/Library/Caches/com.apple.mobile.installation.plist" # idk if this is really needed but ill keep it
        ;;
    esac

    log "Sending $untether"
    $scp -P $ssh_port $jelbrek/$untether root@127.0.0.1:/mnt1
    case $vers in
        [543]* ) untether="${device_type}_${build}.tar";; # remove folder name after sending tar
    esac
    # 3.1.3–4.1 untether must be extracted before data partition mount
    case $vers in
        4.[10]* | 3.2* | 3.1.3 )
            log "Extracting $untether"
            $ssh -p $ssh_port root@127.0.0.1 "tar -xvf /mnt1/$untether -C /mnt1; rm /mnt1/$untether"
        ;;
    esac
    # untether extraction
    case $vers in
        4.[10]* | 3* ) :;; # already extracted
        * )
            if [[ $untether != 1 ]]; then
                log "Extracting $untether"
                $ssh -p $ssh_port root@127.0.0.1 "tar -xvf /mnt1/$untether -C /mnt1; rm /mnt1/$untether"
            fi
        ;;
    esac
    device_send_rdtar freeze.tar data
    if [[ $vers == "9"* ]]; then
        # required stuff for everuntether and untetherhomedepot
        [[ $vers != "9.0"* ]] && device_send_rdtar daemonloader.tar
        device_send_rdtar launchctl.tar
    fi
    if [[ $ipsw_openssh == 1 ]]; then
        device_send_rdtar sshdeb.tar
    fi
    case $vers in
        [543]* ) device_send_rdtar cydiasubstrate.tar;;
    esac
    case $vers in
        3* ) device_send_rdtar cydiahttpatch.tar;;
    esac
    if [[ $1 != noreboot ]]; then
        log "Rebooting"
        $ssh -p $ssh_port root@127.0.0.1 "reboot_bak"
    fi

    log "越狱完成✅"
}

device_ramdisk_setnvram() {
    log "Sending commands for setting NVRAM variables..."
    $ssh -p $ssh_port root@127.0.0.1 "nvram -c; nvram boot-partition=$rec"
    local nvram="nvram boot-ramdisk=/a/b/c/d/e/f/g/h/i"
    if [[ $rec == 2 ]]; then
        case $device_type in
            iPhone3,3 ) $ssh -p $ssh_port root@127.0.0.1 "$nvram/disk.dmg";;
            iPad2,4   ) $ssh -p $ssh_port root@127.0.0.1 "$nvram/j/k/l/m/n/o/p/q/r/s/t/disk.dmg";;
            iPhone4,1 ) $ssh -p $ssh_port root@127.0.0.1 "$nvram/j/k/l/m/n/o/p/q/r/disk.dmg";;
            iPod5,1   ) $ssh -p $ssh_port root@127.0.0.1 "$nvram/j/k/l/m/disk.dmg";;
            iPhone5,* )
                local selection=("iOS 7.1.x" "iOS 7.0.x")
                input "Select this device's base version:"
                select_option "${selection[@]}"
                case $? in
                    1 ) $ssh -p $ssh_port root@127.0.0.1 "$nvram/j/k/l/m/disk.dmg";;
                    * ) $ssh -p $ssh_port root@127.0.0.1 "$nvram/j/k/l/m/n/o/p/q/r/s/t/u/v/w/disk.dmg";;
                esac
            ;;
            iPad1,1 | iPod3,1 )
                device_ramdisk_iosvers
                if [[ $device_vers == "3"* ]]; then
                    device_ramdisk_ios3exploit
                fi
            ;;
        esac
    fi
    log "Done"
}

device_ramdisk_ios3exploit() {
    log "iOS 3.x detected, running exploit commands"
    local offset="$($ssh -p $ssh_port root@127.0.0.1 "echo -e 'p\nq\n' | fdisk -e /dev/rdisk0" | grep AF | head -1)"
    offset="${offset##*-}"
    offset="$(echo ${offset%]*} | tr -d ' ')"
    offset=$((offset+64))
    log "Got offset $offset"
    $ssh -p $ssh_port root@127.0.0.1 "echo -e 'e 3\nAF\n\n${offset}\n8\nw\ny\nq\n' | fdisk -e /dev/rdisk0"
    echo
    log "Writing exploit ramdisk"
    $scp -P $ssh_port ../resources/firmware/src/target/$device_model/9B206/exploit root@127.0.0.1:/
    $ssh -p $ssh_port root@127.0.0.1 "dd of=/dev/rdisk0s3 if=/exploit bs=64k count=1"
    if [[ $device_type == "iPad1,1" ]]; then
        $scp -P $ssh_port ../saved/iPad1,1/iBoot3_$device_ecid root@127.0.0.1:/mnt1/iBEC
    fi
    log "fstab"
    $scp -P $ssh_port $jelbrek/fstab_new root@127.0.0.1:/mnt1/private/etc/fstab
    case $device_vers in
        3.1.3 | 3.2* ) opt='y';;
    esac
    if [[ $opt == 'y' ]]; then
        untether="${device_type}_${device_build}.tar"
        log "Sending $untether"
        $scp -P $ssh_port $jelbrek/greenpois0n/$untether root@127.0.0.1:/mnt1
        log "Extracting $untether"
        $ssh -p $ssh_port root@127.0.0.1 "tar -xvf /mnt1/$untether -C /mnt1; rm /mnt1/$untether"
        : '
        log "Mounting data partition"
        $ssh -p $ssh_port root@127.0.0.1 "mount.sh pv"
        device_send_rdtar cydiasubstrate.tar
        device_send_rdtar cydiahttpatch.tar
        if [[ $device_vers == "3.1.3" || $device_vers == "3.2" ]]; then
            device_send_rdtar freeze.tar data
        fi
        if [[ $ipsw_openssh == 1 ]]; then
            device_send_rdtar sshdeb.tar
        fi
        '
    fi
}

device_datetime_cmd() {
    log "Running command to Update DateTime"
    $ssh -p $ssh_port root@127.0.0.1 "date -s @$(date +%s)"
    if [[ $1 != "nopause" ]]; then
        log "Done"
        pause
    fi
}

check_iosvers() {
    local options
    local selected
    device_datetime_cmd nopause
    if [[ $1 == sshrdscript ]]; then
        local ssh_port=2222
        if [[ -z $2 ]]; then
            local mount_command="/usr/bin/mount_filesystems"
        else
            cut_os_vers $2
            if (( major_ver == 10 && minor_ver >= 0 && minor_ver <= 2 )); then
                local mount_command="mount_hfs /dev/disk0s1s1 /mnt1 && /usr/libexec/seputil --load /mnt1/usr/standalone/firmware/sep-firmware.img4 && mount_hfs /dev/disk0s1s2 /mnt2"
            else
                local mount_command="/usr/bin/mount_filesystems"
            fi
        fi
    else
        local mount_command="mount.sh root"
    fi
    device_vers=
    device_build=
    log "Mounting root filesystem"
    $ssh -p $ssh_port root@127.0.0.1 "$mount_command"
    sleep 1
    log "Getting iOS version"
    $scp -P $ssh_port root@127.0.0.1:/mnt1/System/Library/CoreServices/SystemVersion.plist $tmp
    rm -f $tmp/BuildVer $tmp/Version
    plutil -extract 'ProductVersion' xml1 $tmp/SystemVersion.plist -o $tmp/Version
    device_vers=$(cat $tmp/Version | sed -ne '/<string>/,/<\/string>/p' | sed -e "s/<string>//" | sed "s/<\/string>//" | sed '2d')
    plutil -extract 'ProductBuildVersion' xml1 $tmp/SystemVersion.plist -o $tmp/BuildVer
    device_build=$(cat $tmp/BuildVer | sed -ne '/<string>/,/<\/string>/p' | sed -e "s/<string>//" | sed "s/<\/string>//" | sed '2d')
    #linux waiting for next version
    #device_vers=$(cat $tmp/SystemVersion.plist | grep -i ProductVersion -A 1 | grep -oPm1 "(?<=<string>)[^<]+")
    #device_build=$(cat $tmp/SystemVersion.plist | grep -i ProductBuildVersion -A 1 | grep -oPm1 "(?<=<string>)[^<]+")
    if [[ -n $device_vers ]]; then
        log "成功获取iOS版本"
        tip "* iOS Version: $device_vers ($device_build)"
    else
        error "无法获取iOS版本"
    fi
}

check_iosvers_openssh() {
    local ssh_port
    device_vers=
    device_build=
    if [[ -z $1 ]]; then
        while true; do
            log "输入OpenSSH的端口(默认2222)"
            read -r -p "端口: " ssh_port
            ssh_port=${ssh_port:-2222}
            
            if [[ $ssh_port =~ ^[0-9]+$ ]] && [ "$ssh_port" -ge 1 ] && [ "$ssh_port" -le 65535 ]; then
                break
            else
                error "错误: 端口号必须为1-65535之间的数字"
            fi
        done
    else
        local ssh_port=$1
    fi
    log "SSH端口: $ssh_port"
    sshcheck $ssh_port
    log "Getting iOS version"
    $scp -P $ssh_port root@127.0.0.1:/System/Library/CoreServices/SystemVersion.plist $tmp
    rm -f $tmp/BuildVer $tmp/Version
    plutil -extract 'ProductVersion' xml1 $tmp/SystemVersion.plist -o $tmp/Version
    device_vers=$(cat $tmp/Version | sed -ne '/<string>/,/<\/string>/p' | sed -e "s/<string>//" | sed "s/<\/string>//" | sed '2d')
    plutil -extract 'ProductBuildVersion' xml1 $tmp/SystemVersion.plist -o $tmp/BuildVer
    device_build=$(cat $tmp/BuildVer | sed -ne '/<string>/,/<\/string>/p' | sed -e "s/<string>//" | sed "s/<\/string>//" | sed '2d')
    #linux waiting for next version
    #device_vers=$(cat $tmp/SystemVersion.plist | grep -i ProductVersion -A 1 | grep -oPm1 "(?<=<string>)[^<]+")
    #device_build=$(cat $tmp/SystemVersion.plist | grep -i ProductBuildVersion -A 1 | grep -oPm1 "(?<=<string>)[^<]+")
    if [[ -n $device_vers ]]; then
        log "成功获取iOS版本"
        tip "* iOS Version: $device_vers ($device_build)"
    else
        error "无法获取iOS版本"
    fi
}

device_send_rdtar() {
    local target="/mnt1"
    jelbrek=$script_dir/bin/Jailbreak
    if [[ $2 == "data" ]]; then
        target+="/private/var"
    fi
    log "Sending $1"
    $scp -P $ssh_port $jelbrek/$1 root@127.0.0.1:$target
    log "Extracting $1"
    $ssh -p $ssh_port root@127.0.0.1 "tar -xvf $target/$1 -C /mnt1; rm $target/$1"
}

device_add_battery_percentage() {
    if [[ "$1" == "sshrdscript" ]]; then
        local ssh_port=2222
    fi
    #log 输入devicever
    #read device_vers
    check_iosvers $1
    cut_os_vers $device_vers
    if (( major_ver >= 7 )); then
        final_ver=${major_ver}.${minor_ver}${nano_ver}
        log 当前iOS版本: $final_ver
        if (( major_ver >= 7 && major_ver <= 9 )); then
            warning iOS7.0 不支持挂载/mnt2,请使用OpenSSH
        else
            log 挂载设备
            #remove this part,because it's really difficult to mount device
            #if (( major_ver == 10 && minor_ver >= 0 && minor_ver <= 2 )); then
            #    $ssh -p $ssh_port root@127.0.0.1 "mount_hfs /dev/disk0s1s1 /mnt1 && /usr/libexec/seputil --load /mnt1/usr/standalone/firmware/sep-firmware.img4 && mount_hfs /dev/disk0s1s2 /mnt2"
            #else
            #    $ssh -p $ssh_port root@127.0.0.1 "/usr/bin/mount_filesystems"
            #fi
            $ssh -p $ssh_port root@127.0.0.1 "mount.sh"
            log 提取com.apple.springboard.plist
            $scp -r -P $ssh_port root@127.0.0.1:/mnt2/mobile/Library/Preferences/com.apple.springboard.plist $tmp
            if [ ! -f "$tmp/com.apple.springboard.plist" ]; then
                error 提取com.apple.springboard.plist失败
                return 1
            fi
            log 开始修补
            cp $script_dir/bin/Others/add_battery_key.py $tmp/add_battery_key.py
            cd $tmp
            python3 add_battery_key.py $tmp/com.apple.springboard.plist
            if [ ! -f "$tmp/com.apple.springboard.plist.backup" ]; then
                error 修补失败
                return 1
            fi
            $ssh -p $ssh_port root@127.0.0.1 "rm -rf /mnt2/mobile/Library/Preferences/com.apple.springboard.plist"
            $scp -v -P $ssh_port $tmp/com.apple.springboard.plist root@127.0.0.1:/mnt2/mobile/Library/Preferences
            if $ssh -p $ssh_port root@127.0.0.1 "find /mnt2 -name com.apple.springboard.plist -quit" >/dev/null 2>&1; then
                log 上传成功
            else
                error 上传失败
            fi
            log 正在重启
            $ssh -p $ssh_port root@127.0.0.1 "reboot"
            log 开启成功
        fi
    else
        log 挂载设备
        $ssh -p $ssh_port root@127.0.0.1 "mount.sh"
        if [[ -z $device_model ]]; then
            error 未获取到设备型号
            return 1
        else
            device_model_num=$(echo "$device_model" | cut -c 2-3)
            $plist_name=N${device_model_num}AP.plist
        fi
        $scp -r -P $ssh_port root@127.0.0.1:/mnt1/System/Library/CoreServices/SpringBoard.app/$plist_name $tmp
        if [ ! -f "$tmp/$plist_name" ]; then
            error 获取plist失败
        else
            cp $script_dir/bin/Others/add_gas_gauge.py $tmp
            cd $tmp
            python3 add_gas_gauge.py $tmp/$plist_name
            pause
            $ssh -p $ssh_port root@127.0.0.1 "mv /mnt1/System/Library/CoreServices/SpringBoard.app/$plist_name /mnt1/System/Library/CoreServices/SpringBoard.app/${plist_name}.backup"
            $scp -v -P $ssh_port $tmp/$plist_name root@127.0.0.1:/mnt1/System/Library/CoreServices/SpringBoard.app
            if $ssh -p $ssh_port root@127.0.0.1 "find /mnt1/System/Library/CoreServices/SpringBoard.app -name $plist_name -quit" >/dev/null 2>&1; then
                log 上传成功
            else
                error 上传失败
                pause
            fi
            log 正在重启
            $ssh -p $ssh_port root@127.0.0.1 "reboot"
            log "开启成功(希望是)"
        fi
    fi
}

device_add_battery_percentage_openssh() {
    local ssh_port
    cut_os_vers $os
    log 当前设备版本:$os
    if (( major_ver >= 7 )); then
        log 1
        pause
        while true; do
            log "输入OpenSSH的端口(默认2222)"
            read -r -p "端口: " ssh_port
            ssh_port=${ssh_port:-2222}
            
            if [[ $ssh_port =~ ^[0-9]+$ ]] && [ "$ssh_port" -ge 1 ] && [ "$ssh_port" -le 65535 ]; then
                break
            else
                error "错误: 端口号必须为1-65535之间的数字"
            fi
        done
        log "SSH端口: $ssh_port"
        sshcheck $ssh_port
        check_iosvers_openssh $ssh_port
        log 提取com.apple.springboard.plist
        $scp -r -P $ssh_port root@127.0.0.1:/private/var/mobile/Library/Preferences/com.apple.springboard.plist $tmp
        if [ ! -f "$tmp/com.apple.springboard.plist" ]; then
            error 提取com.apple.springboard.plist失败
            return 1
        fi
        log 开始修补
        cp $script_dir/bin/Others/add_battery_key.py $tmp/add_battery_key.py
        cd $tmp
        python3 add_battery_key.py $tmp/com.apple.springboard.plist
        if [ ! -f "$tmp/com.apple.springboard.plist.backup" ]; then
            error 修补失败
            return 1
        fi
        $ssh -p $ssh_port root@127.0.0.1 "mv /private/var/mobile/Library/Preferences/com.apple.springboard.plist /private/var/mobile/Library/Preferences/com.apple.springboard.plist.backup"
        $scp -v -P $ssh_port $tmp/com.apple.springboard.plist root@127.0.0.1:/private/var/mobile/Library/Preferences
        if $ssh -p $ssh_port root@127.0.0.1 "find /private/var -name com.apple.springboard.plist -quit" >/dev/null 2>&1; then
            log 上传成功
        else
            error 上传失败
            pause
        fi
        log 正在重启
        $ssh -p $ssh_port root@127.0.0.1 "reboot"
        log "开启成功(希望是)"
    else
        log 2
        pause
        while true; do
            log "输入OpenSSH的端口(默认2222)"
            read -r -p "端口: " ssh_port
            ssh_port=${ssh_port:-2222}
            
            if [[ $ssh_port =~ ^[0-9]+$ ]] && [ "$ssh_port" -ge 1 ] && [ "$ssh_port" -le 65535 ]; then
                break
            else
                error "错误: 端口号必须为1-65535之间的数字"
            fi
        done
        pause
        log 获取设备plist
        if [[ -z $device_model ]]; then
            error 未获取到设备型号
            return 1
        else
            device_model_num=$(echo "$device_model" | cut -c 2-3)
            plist_name="N${device_model_num}AP.plist"
        fi
        $scp -r -P $ssh_port root@127.0.0.1:/System/Library/CoreServices/SpringBoard.app/$plist_name $tmp
        if [ ! -f "$tmp/$plist_name" ]; then
            error 获取plist失败
        else
            cp $script_dir/bin/Others/add_gas_gauge.py $tmp
            cd $tmp
            python3 add_gas_gauge.py $tmp/$plist_name
            $ssh -p $ssh_port root@127.0.0.1 "mv /System/Library/CoreServices/SpringBoard.app/$plist_name /System/Library/CoreServices/SpringBoard.app/${plist_name}.backup"
            $scp -v -P $ssh_port $tmp/$plist_name root@127.0.0.1:/System/Library/CoreServices/SpringBoard.app
            if $ssh -p $ssh_port root@127.0.0.1 "find /System/Library/CoreServices/SpringBoard.app -name $plist_name -quit" >/dev/null 2>&1; then
                log 上传成功
            else
                error 上传失败
                pause
            fi
            log 正在重启
            $ssh -p $ssh_port root@127.0.0.1 "reboot"
            log "开启成功(希望是)"
        fi
        pause
    fi
}

get_firmware_info() {
    local version=
    local build=
    buildid=
    filesize=
    sha1=
    sha256=
    md5=
    signed=
    releasedate=
    uploaddate=
    curl -s -L "https://api.ipsw.me/v4/device/$device_type?type=ipsw" -o $tmp/tmp.json
    JSON_FILE=$tmp/tmp.json
    if [[ ! -f "$tmp/tmp.json" ]]; then
        error 下载失败
        go_to_menu
    fi
    if [[ $1 == "ver" ]]; then
        version=$2
        if [[ "$de" == "4" && "$version" == "4.1" ]]; then
            log 选择版本
            options=("8B117" "8B118")
            select_option "${options[@]}"
            selected_index=$?
            selected="${options[$selected_index]}"
            
            case $selected in
                "8B117" ) 
                    get_firmware_info build 8B117
                    return $?
                    ;;
                "8B118" ) 
                    get_firmware_info build 8B118
                    return $?
                    ;;
            esac
        fi
    elif [[ $1 == "build" ]]; then
        build=$2
    fi
    if [[ $1 == "ver" ]]; then
        buildid=$($jq -r ".firmwares[] | select(.version == \"$version\") | .buildid" "$JSON_FILE")
        filesize=$($jq -r ".firmwares[] | select(.version == \"$version\") | .filesize" "$JSON_FILE")
        url=$($jq -r ".firmwares[] | select(.version == \"$version\") | .url" "$JSON_FILE")
        sha1=$($jq -r ".firmwares[] | select(.version == \"$version\") | .sha1sum" "$JSON_FILE")
        sha256=$($jq -r ".firmwares[] | select(.version == \"$version\") | .sha256sum" "$JSON_FILE")
        md5=$($jq -r ".firmwares[] | select(.version == \"$version\") | .md5sum" "$JSON_FILE")
        signed=$($jq -r ".firmwares[] | select(.version == \"$version\") | .signed" "$JSON_FILE")
        releasedate=$($jq -r ".firmwares[] | select(.version == \"$version\") | .releasedate" "$JSON_FILE")
        uploaddate=$($jq -r ".firmwares[] | select(.version == \"$version\") | .uploaddate" "$JSON_FILE")
    elif [[ $1 == "build" ]]; then
        buildid="$build"
        filesize=$($jq -r ".firmwares[] | select(.buildid == \"$build\") | .filesize" "$JSON_FILE")
        url=$($jq -r ".firmwares[] | select(.buildid == \"$build\") | .url" "$JSON_FILE")
        sha1=$($jq -r ".firmwares[] | select(.buildid == \"$build\") | .sha1sum" "$JSON_FILE")
        sha256=$($jq -r ".firmwares[] | select(.buildid == \"$build\") | .sha256sum" "$JSON_FILE")
        md5=$($jq -r ".firmwares[] | select(.buildid == \"$build\") | .md5sum" "$JSON_FILE")
        signed=$($jq -r ".firmwares[] | select(.buildid == \"$build\") | .signed" "$JSON_FILE")
        releasedate=$($jq -r ".firmwares[] | select(.buildid == \"$build\") | .releasedate" "$JSON_FILE")
        uploaddate=$($jq -r ".firmwares[] | select(.buildid == \"$build\") | .uploaddate" "$JSON_FILE")
    fi
}

restore_legacy() {
    local options
    local selected
    local options1
    local selected1
    local ver
    local ipsw_name
    options=("选择固件" "下载固件" "返回主页")
    select_option "${options[@]}"
    selected="${options[$?]}"
    if [[ $1 != "3.1.3" ]]; then
        if [[ "$selected" == "选择固件" ]]; then
            ipsw="$($zenity --file-selection --multiple --file-filter='IPSW | *.ipsw' --title="Select IPSW file(s)")"
            ipsw_name=$(basename $ipsw)
            cp $ipsw $tmp/${ipsw_name}
        elif [[ "$selected" == "下载固件" ]]; then
            input 输入iOS版本
            read ver
            if [[ $ver =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
                cut_os_vers $ver
            else
                error 输入格式不对 
                go_to_menu     
            fi
            if (( major_ver >= 1 && major_ver <= 2 )); then
                error iOS3.0以下版本无法刷入,请使用iTunes刷入
            else
                if [[ "$de" == "1" ]]; then
                    case $ver in
                        3.0 ) ipsw_name=iPod1,1_3.0_7A341_Restore.ipsw ;;
                        3.1.1 ) ipsw_name=iPod1,1_3.1.1_7C145_Restore.ipsw ;;
                        3.1.2 ) ipsw_name=iPod1,1_3.1.2_7D11_Restore.ipsw ;;
                        3.1.3 ) ipsw_name=iPod1,1_3.1.3_7E18_Restore.ipsw ;;
                    esac
                elif [[ "$de" == "2" ]]; then
                    case $ver in
                        3.0 ) ipsw_name=iPod2,1_3.0_7A341_Restore.ipsw ;;
                        3.1.1 ) ipsw_name=iPod2,1_3.1.1_7C145_Restore.ipsw ;;
                        3.1.2 ) ipsw_name=iPod2,1_3.1.2_7D11_Restore.ipsw ;;
                        3.1.3 ) ipsw_name=iPod2,1_3.1.3_7E18_Restore.ipsw ;;
                    esac
                fi
                if [ -f "$script_dir/bin/Firmware/$ipsw_name" ]; then
                    $aria2c https://invoxiplaygames.uk/ipsw/$ipsw_name -o $tmp/$ipsw_name
                    if [ -f "$tmp/${ipsw_name}" ]; then
                        cp $tmp/${ipsw_name} $script_dir/bin/Firmware/$ipsw_name
                        if [ ! -f "$script_dir/bin/Firmware/$ipsw_name" ]; then
                            error 复制失败
                            go_to_menu
                        else
                            log 固件保存至$script_dir/bin/Firmware/$ipsw_name
                        fi
                    else
                        error 下载失败
                        go_to_menu
                    fi
                else
                    cp $script_dir/bin/Firmware/$ipsw_name $tmp/${ipsw_name}
                fi
            fi
        fi
    else
        ipsw_name=iPod1,1_3.1.3_7E18_Restore.ipsw
        if [[ "$selected" == "选择固件" ]]; then
            ipsw="$($zenity --file-selection --multiple --file-filter='IPSW | *.ipsw' --title="Select IPSW file(s)")"
            ipsw_name=$(basename $ipsw)
            cp $ipsw $tmp/${ipsw_name}
        else
            if [ ! -f "$script_dir/bin/Firmware/${ipsw_name}" ]; then
                $aria2c https://invoxiplaygames.uk/ipsw/${ipsw_name} -o $tmp/${ipsw_name}
                if [ -f "$tmp/${ipsw_name}" ]; then
                    cp $tmp/${ipsw_name} $script_dir/bin/Firmware/${ipsw_name}
                    if [ ! -f "$script_dir/bin/Firmware/${ipsw_name}" ]; then
                        error 复制失败
                        go_to_menu
                    else
                        log 固件保存至$script_dir/bin/Firmware/${ipsw_name}
                    fi
                else
                    error 下载失败
                    go_to_menu
                fi
            else
                cp $script_dir/bin/Firmware/${ipsw_name} $tmp/${ipsw_name}
            fi
        fi
    fi
    log 解压固件
    ipsw_etract "$tmp/${ipsw_name}"
    DFUhelper_legacy nosend
    log 开始恢复
    if [[ $de == 1 ]]; then
        log "Sending iBSS..."
        $irecovery -f "$tmp/${ipsw_name}/Firmware/dfu/iBSS.n45ap.RELEASE.dfu"
    fi
    $idevicerestore -e -c $tmp/${ipsw_name}
    log 恢复完成✅
    go_to_menu
}


restore_latest_ver() {
    local options
    local selected
    local options1
    local selected1
    local ipsw
    local sha256 
    local ipsw_sha256
    options=("选择固件" "下载固件" "返回主页")
    select_option "${options[@]}"
    selected="${options[$?]}"
    get_firmware_info ver $device_latest_ver
    if [[ "$selected" == "选择固件" ]]; then
        ipsw="$($zenity --file-selection --multiple --file-filter='IPSW | *.ipsw' --title="Select IPSW file(s)")"
    elif [[ "$selected" == "下载固件" ]]; then
        if [ ! -f "$script_dir/bin/Firmware/${device_type}_${device_latest_ver}_${buildid}_Restore.ipsw" ]; then
            log 开始下载固件
            $aria2c $url -o $tmp/${device_latest_ver}.ipsw
            if [ -f "$tmp/${device_latest_ver}.ipsw" ]; then
                cp $tmp/${device_latest_ver}.ipsw $script_dir/bin/Firmware/${device_type}_${device_latest_ver}_${buildid}_Restore.ipsw
                if [ -f "$script_dir/bin/Firmware/${device_type}_${device_latest_ver}_${buildid}_Restore.ipsw" ]; then
                    log 固件保存至$script_dir/bin/Firmware/${device_type}_${device_latest_ver}_${buildid}_Restore.ipsw
                else
                    error 保存失败
                    go_to_menu
                fi
            else
                error 下载失败
                go_to_menu
            fi
            ipsw=$tmp/${device_latest_ver}.ipsw
        else
            cp $script_dir/bin/Firmware/${device_type}_${device_latest_ver}_${buildid}_Restore.ipsw $tmp/${device_latest_ver}.ipsw
            ipsw=$tmp/${device_latest_ver}.ipsw
        fi
    fi
    if [[ "$filecheck" == "1" ]]; then
        log 校验固件
        ipsw_sha256=$(shasum -a 256 "$ipsw" | cut -d ' ' -f1)
        log $ipswsha256
        log $sha256
        if [ "$ipsw_sha256" = "$sha256" ]; then
            log "✅ SHA256 校验通过"
        else
            log "❌ SHA256 校验失败,请重新下载"
            go_to_menu
        fi
    fi
    DFUhelper nopwn
    log 开始恢复
    $idevicerestore -l -e $ipsw
    log 恢复完成
    go_to_menu
}

restore_whited00r() {
    local options
    local selected
    local options1
    local selected1
    local ipsw
    local url
    local pwd
    local sha256 
    local ipsw_sha256
    options=("选择固件" "下载固件" "返回主页")
    select_option "${options[@]}"
    selected="${options[$?]}"
    if [[ "$selected" == "选择固件" ]]; then
        ipsw="$($zenity --file-selection --multiple --file-filter='IPSW | *.ipsw' --title="Select IPSW file(s)")"
    elif [[ "$selected" == "下载固件" ]]; then
        input 选择版本
        options1=("5.1" "5.2.1" "6.0" "7.0" "7.1")
        select_option "${options1[@]}"
        selected1="${options1[$?]}"
        case $selected1 in
            5.1 ) 
                url=https://wwhu.lanzoub.com/b0w994o4d
                pwd=crbo
                sha256=4cb3b290574e7a4b2a11d419c86d05fc58eae7712e96c9eaf0a63ad512a7b2b5
                ;;
            5.2.1 ) 
                url=https://wwhu.lanzoub.com/b0w994oih
                pwd=2mvr
                sha256=f98863b872bf5027274fdc6cef34b4645b911c618d1e7275ca423e8030fb7222
                ;;
            6.0 ) 
                url=https://wwhu.lanzoub.com/b0w994oji
                pwd=8tnx
                sha256=6e30dd6cfb0400c9635a0a7288d80333b809ec973862ff2affc27f9af3d72069
                ;;
            7.0 ) 
                url=https://wwhu.lanzoub.com/b0w994okj
                pwd=1rwk
                sha256=81da66812cb0f6950101e7dffb5ba78add13e0d73aa3f3cd9e278a49dadde6e7
                ;;
            7.1 ) 
                url=https://wwhu.lanzoub.com/b0w994ola
                pwd=4lby
                sha256=405b9698f2a7f9c132dbbe68849a450b1ffbd2dd5bea6f7d5ef27076f8a53885
                ;;
        esac
        if [ ! -f "$script_dir/bin/Firmware/${selected1}_whited00r.ipsw" ]; then
            log 开始下载固件
            lanzou_download --u="$url" --pwd="$pwd" --download --q
            if [ -f "$tmp/${selected1}.zip" ] && [ -f "$tmp/${selected1}z01.zip" ] && [ -f "$tmp/${selected1}z02.zip" ]; then
                log 下载成功
                log 解压压缩包
                mv $tmp/${selected1}z01.zip $tmp/${selected1}.z01
                mv $tmp/${selected1}z02.zip $tmp/${selected1}.z02
                $z7z x $tmp/${selected1}.z01 -o"$tmp"
                if [ ! -f "$tmp/${selected1}.ipsw" ]; then
                    error 整合压缩包失败,请重新下载
                else
                    log 解压成功
                    log 检测固件是否完整
                    ipsw_sha256=$(shasum -a 256 "$tmp/${selected1}.ipsw" | cut -d ' ' -f1)
                    if [ "$ipsw_sha256" = "$sha256" ]; then
                        log "✅ SHA256 校验通过"
                        cp $tmp/${selected1}.ipsw $script_dir/bin/Firmware/${selected1}_whited00r.ipsw
                    else
                        log "❌ SHA256 校验失败,请重新下载"
                        go_to_menu
                    fi
                fi
            else
                error 下载失败
                go_to_menu
            fi
        else
            log 找到本地固件
            log 检查固件是否完整
            ipsw_sha256=$(shasum -a 256 "$script_dir/bin/Firmware/${selected1}_whited00r.ipsw" | cut -d ' ' -f1)
                if [ "$ipsw_sha256" = "$sha256" ]; then
                    log "✅ SHA256 校验通过"
                    cp $script_dir/bin/Firmware/${selected1}_whited00r.ipsw $tmp/${selected1}.ipsw
                else
                    log "❌ SHA256 校验失败,请重新下载"
                    go_to_menu
                fi
        fi
    elif [[ "$selected" == "返回主页" ]]; then
        go_to_menu nopause
    fi
    log 解压固件
    ipsw_etract "$tmp/${selected1}.ipsw"
    DFUhelper_legacy nosend
    log 开始恢复
    log "Sending iBSS..."
    $irecovery -f "$tmp/${selected1}/Firmware/dfu/iBSS.n45ap.RELEASE.dfu"
    #checkmode recovery
    $idevicerestore -e -c $tmp/${selected1}.ipsw
    log 恢复完成✅
    go_to_menu
}

about() {
    local options
    local selected
    main none
    #cat $script_dir/bin/Others/logo
    echo 本脚本原名为"Open Touch 4th Tools",后改名为"iPwnTouch Tools"
    echo 本脚本立志于成为功能最全面的适用于所有iPod touch设备的工具
    echo 感谢@XiaoWZ @Setup.app对本工具的支持
    echo 项目Github地址:https://github.com/appleiPodTouch4/iPwnTouch
    echo 目前适配进度:
    echo "iPod touch 1-2,7未适配(有钱了再说)"
    echo iPod touch 3:任意系统越狱✅ 有SHSH降级✅ 强制降级并引导启动✅ 启动固定版本SSHRD✅ 使用powdersn0w降级❌ 启动指定版本SSHRD❌ 
    echo iPod touch 4:任意系统越狱✅ 有SHSH降级✅ 强制降级并引导启动✅ 启动固定版本SSHRD✅ 半自动输入iOS7.1.2双系统✅ 自动刷入iOS7.1.2单系统✅ 启动指定版本SSHRD❌ 
    echo "eg:部分代码源自于Legacy iOS Kit(https://github.com/LukeZGD/Legacy-iOS-Kit),再次感谢"
    options=("返回主页")
    select_option "${options[@]}"
    selected="${options[$?]}"
            case $selected in
            "返回主页" ) go_to_menu nopause;;
            "退出" ) exit;;
        esac
}
########touch1###########



########touch2###########



########touch3###########



ios5.1.1_flash() {
    if [ ! -f "$script_dir/bin/Firmware/iPod3,1_5.1.1_9B206_Restore.ipsw" ]; then
        log 选择选项
        options=("选择本地固件" "在线下载固件" "返回主页")
        select_option "${options[@]}"
        selected="${options[$?]}"
        if [[ "$selected" == "选择本地固件" ]]; then
        log 选择iOS5.1.1固件
        ipsw="$($zenity --file-selection --multiple --file-filter='IPSW | 6.1.6*.ipsw' --title="Select iOS5.1.1 iPSW file(s)")"
        elif [[ "$selected" == "在线下载固件" ]]; then
            log 正在下载固件
            aria2c https://appldnld.apple.com/iOS6.1/031-3211.20140221.Placef/iPod3,1_5.1.1_9B206_Restore.ipsw -o $script_dir/bin/Firmware/iPod3,1_5.1.1_9B206_Restore.ipsw
            ipsw=$script_dir/bin/Firmware/iPod3,1_5.1.1_9B206_Restore.ipsw
        elif [[ "$selected" == "返回主页" ]]; then
            go_to_menu
        fi
    else
        log 找到本地固件,开始刷入
        ipsw=$script_dir/bin/Firmware/iPod3,1_5.1.1_9B206_Restore.ipsw
    fi
    #log 选择iOS6.1.6固件
    #ipsw="$($zenity --file-selection --multiple --file-filter='IPSW | *.ipsw' --title="Select iOS5.1.1 iPSW file(s)")"
    #while true; do
    #    if [ ! -f "$script_dir/bin/Firmware/iPod3,1_5.1.1_9B206_Restore.ipsw" ]; then
    #            log 未检测到固件
    #            log "可以选择使用在线下载,使用"
    #            read -p "是否继续执行？(yes/no) [默认: yes]: " user_input
    #            user_input=${user_input:-yes}  # 如果用户未输入，则使用默认值 "yes"
    #            user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
    #                # 判断用户输入
    #            if [[ "$user_input" == "yes" || "$user_input" == "y" ]]; then
    #            log 正在下载固件
    #            aria2c https://appldnld.apple.com/iOS6.1/031-3211.20140221.Placef/iPod3,1_5.1.1_9B206_Restore.ipsw -o /$script_dir/bin/Firmware/iPod3,1_5.1.1_9B206_Restore.ipsw
    #        else 
    #            log 下载完成后请复制到/bin/Firmware文件夹下
    #        fi
    #        pause "按回车键重新检测..."
    #    else
    #        log "检测到压缩包，继续执行..."
    #        break 
    #    fi
    #done
    filesha256=$(shasum -a 256 "$ipsw" | cut -d ' ' -f1)
    sha256=45ac2643a34fdeffb74028d78bc1f574e942e1c07cb58f681f61c500a8851dab
    if [ "$filesha256" = "$sha256" ]; then
        log "✅ SHA256 校验通过"
    else
        log "❌ SHA256 校验失败,请重新下载"
    fi
    log 开始恢复
    DFUhelper pwn
    $idevicerestore -l -e $ipsw
    log 恢复完成
    go_to_menu
}

511_jb() {
    511_SSHRD nomenu
    pause 回车开始越狱
    $ssh -p $ssh_port root@127.0.0.1 "date -s @1755676579"
    $ssh -p $ssh_port root@127.0.0.1 "mount.sh root"
    $scp -v -P $ssh_port $script_dir/bin/Jailbreak/g1lbertJB/iPod3,1_9B206.tar root@127.0.0.1:/mnt1
    $ssh -p $ssh_port root@127.0.0.1 "mount.sh pv"
    $scp -v -P $ssh_port $script_dir/bin/Jailbreak/g1lbertJB.tar root@127.0.0.1:/mnt1
    $ssh -p $ssh_port root@127.0.0.1 "cd /mnt1; tar -xvf g1lbertJB.tar"
    $ssh -p $ssh_port root@127.0.0.1 "cd /mnt1; tar -xvf iPod3,1_9B206.tar"
    $scp -v -P $ssh_port $script_dir/bin/Jailbreak/freeze.tar root@127.0.0.1:/mnt1/private/var
    $ssh -p $ssh_port root@127.0.0.1 "tar -xvf /mnt1/private/var/freeze.tar -C /mnt1"
    $scp -v -P $ssh_port $script_dir/bin/Jailbreak/sshdeb.tar root@127.0.0.1:/mnt1
    $ssh -p $ssh_port root@127.0.0.1 "cd /mnt1; tar -xvf sshdeb.tar"
    $scp -v -P $ssh_port $script_dir/bin/Jailbreak/cydiasubstrate.tar root@127.0.0.1:/mnt1
    $ssh -p $ssh_port root@127.0.0.1 "cd /mnt1; tar -xvf cydiasubstrate.tar"
    #log 是否直接激活设备
    #pause "是否继续执行？(yes/no) [默认: yes]: " user_input
    #user_input=${user_input:-yes}
    #user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
    #if [[ "$user_input" == "yes" || "$user_input" == "y" ]]; then
    log 激活设备
    yn 激活设备 "ac=1" "ac=0"
if [[ $ac == 1 ]]; then
    $ssh -p $ssh_port root@127.0.0.1 "rm -rf /mnt1/usr/libexec/lockdownd"
    $scp -v -P $ssh_port $script_dir/bin/Others/lockdownd root@127.0.0.1:/mnt1/usr/libexec
    $ssh -p $ssh_port root@127.0.0.1 "chmod 755 /mnt1/usr/libexec/lockdownd"
else 
    log 跳过激活 
fi           
    $ssh -p $ssh_port root@127.0.0.1 "reboot_bak"    
    go_to_menu
}

########touch4###########

prepareworks() {
    rm ~/.ssh/known_hosts
    sshcheck 2222
    log 准备开始安装debs
    warning 请在爱思助手-工具箱-打开ssh通道 打开ssh通道
    pause 回车继续
    rm ~/.ssh/known_hosts
    log 上传所需的DEB文件
    $scp -v -P 2222 -o StrictHostKeyChecking=no $script_dir/bin/System/iOS7dualsystem/debs/dualbootstuff.deb root@127.0.0.1:/
    $scp -v -P 2222 -o StrictHostKeyChecking=no $script_dir/bin/System/iOS7dualsystem/debs/diskdev.deb root@127.0.0.1:/
    $scp -v -P 2222 -o StrictHostKeyChecking=no $script_dir/bin/System/iOS7dualsystem/debs/wayout.deb root@127.0.0.1:/
    log 安装DEB
    $ssh -p $ssh_port root@127.0.0.1 "dpkg -i /wayout.deb"
    $ssh -p $ssh_port root@127.0.0.1 "dpkg -i /diskdev.deb"
    $ssh -p $ssh_port root@127.0.0.1 "dpkg -i /dualbootstuff.deb"
    log 确保桌面上有WayOut APP图标后回车返回主页
    pause 回车返回主页
}


cutdisk() {
    warning 请在爱思助手-工具箱-打开ssh通道 打开ssh通道
    pause 回车以开始分区
    rm ~/.ssh/known_hosts
    sshcheck 2222
    $ssh -p $openssh_port root@127.0.0.1 "mkdir /mnt1"
    $ssh -p $openssh_port root@127.0.0.1 "mkdir /mnt2"
    $ssh -p $openssh_port root@127.0.0.1 "df -B1"
    echo "输入上面输出文本中/dev/disk0s1s2中1B-blocks的值";read datasize
    value=$(echo "$datasize / 1073741824" | bc)
    echo "您的iPodtouch4的磁盘大小为$value GB"
    echo "请填写想分区的大小";read finalused
    value1=$(echo "scale=16; $value - $finalused" | bc)
    integer_part=$(echo "$value1 * 1073741824" | bc)
    pause 完成后回车
    echo $integer_part
    warning 请将上面的值复制到helpful.sh中
        osascript <<EOF
        tell application "Terminal"
        activate
        do script "bash $script_dir/bin/System/iOS7dualsystem/helpful.sh"
        end tell
EOF
        pause 完成后回车开始分区
        $ssh -p $openssh_port root@127.0.0.1 "hfs_resize /private/var $integer_part"
        log 执行完毕，请前往设置-通用-用量中查看分区是否已经是分区完的大小，若是则回车继续，否则重新执行
        pause 按回车继续
}


installsystem() {
    local options
    local selected
    log 准备开始安装系统，3s后开始安装
    for i in {3..1}; do
    echo "$i..."
    sleep 1
    done
    log 请在爱思助手-工具箱-打开ssh通道 打开ssh通道
    pause 回车开始安装系统
    #sshcheck 2222
    log 请选择如何获取固件
    options=("选择本地固件" "在线制作固件")
    select_option "${options[@]}"
    selected="${options[$?]}"
    if [[ $selected == "选择本地固件" ]]; then
        log 选择UDZO.dmg
        udzo="$($zenity --file-selection --multiple --file-filter='IPSW | *.dmg' --title="Select UDZO.dmg file(s)")"
        if [ "$filecheck" -eq 1 ]; then
            sha256=1cd702c592deb1ab2e85640573f0173f6fa4f982feb74182853bad92f18bdf23
            filesha256=$(shasum -a 256 $udzo | cut -d ' ' -f1)
            if [ "$filesha256" = "$sha256" ]; then
            log "✅ SHA256 校验通过"
            else
                error "❌ SHA256校验失败,请检查文件是否完整"
                exit
            fi
        else
            warning 关闭校验，可能导致安装出错
        fi
    else
        if [[ ! -f $saved/UDZO.dmg ]]; then

            log 下载058-4520-010.dmg
            cd $tmp
            while true; do
                if [[ ! -f $tmp/origin.dmg ]]; then
                    "$pzb" -g "058-4520-010.dmg" -o "origin.dmg" "http://appldnld.apple.com/iOS7.1/031-4812.20140627.cq6y8/iPhone3,1_7.1.2_11D257_Restore.ipsw"
                fi
                if [[ ! -f $tmp/origin.dmg ]]; then
                    error 下载失败,是否重新下载?
                    yesno 是否继续
                    if [[ $? == 1 ]]; then
                        :
                    else
                        return
                    fi
                else
                    log 下载成功
                    break
                fi
            done
            cd $tmp
            log 解压固件
            $dmg extract origin.dmg decrypted.dmg -k 38d0320d099b9dd34ffb3308c53d397f14955b347d6a433fe173acc2ced1ae78756b3684
            log 转换固件
            $dmg build decrypted.dmg UDZO.dmg
            if [[ -f $tmp/UDZO.dmg ]]; then
                cp $tmp/UDZO.dmg $saved/UDZO.dmg
                if [[ ! -f $saved/UDZO.dmg ]]; then
                    warning 复制失败
                    pause
                fi
            else
                error 转化失败,源固件疑似损坏,请重新下载
                pause 回车返回主页
                return
            fi
        else
            log 找到生成过的固件,跳过制作
            cp $saved/UDZO.dmg $tmp/UDZO.dmg
        fi
        udzo=$tmp/UDZO.dmg
    fi
    $ssh -p $openssh_port root@127.0.0.1 "/sbin/newfs_hfs -s -v System -J -b 8192 -n a=8192,c=8192,e=8192 /dev/disk0s1s3"
    $ssh -p $openssh_port root@127.0.0.1 "/sbin/newfs_hfs -s -v Data -J -b 8192 -n a=8192,c=8192,e=8192 /dev/disk0s1s4"
    $ssh -p $openssh_port root@127.0.0.1 "mount_hfs /dev/disk0s1s4 /mnt2"
    $scp -v -P $openssh_port $udzo root@127.0.0.1:/mnt2
    $ssh -p $openssh_port root@127.0.0.1 "asr restore --source /mnt2/UDZO.dmg --target /dev/disk0s1s3 --erase"
    $ssh -p $openssh_port root@127.0.0.1 "umount /mnt2"
    $ssh -p $openssh_port root@127.0.0.1 "mount_hfs /dev/disk0s1s3 /mnt1"
    $ssh -p $openssh_port root@127.0.0.1 "/sbin/newfs_hfs -s -v Data -J -P -b 8192 -n a=8192,c=8192,e=8192 /dev/disk0s1s4"
    $ssh -p $openssh_port root@127.0.0.1 "mount_hfs /dev/disk0s1s4 /mnt2"
    $ssh -p $openssh_port root@127.0.0.1 "mv -v /mnt1/private/var/* /mnt2"
    $ssh -p $openssh_port root@127.0.0.1 "rm -rf /mnt2/mobile/Library/PreinstalledAssets/*"
    $ssh -p $openssh_port root@127.0.0.1 "rm -rf /mnt2/mobile/Library/Preferences/.GlobalPreferences.plist"
    $ssh -p $openssh_port root@127.0.0.1 "mkdir /mnt2/keybags"
    $ssh -p $openssh_port root@127.0.0.1 "cp -a /var/keybags/systembag.kb /mnt2/keybags"
    $ssh -p $openssh_port root@127.0.0.1 "umount /mnt2"
    $ssh -p $openssh_port root@127.0.0.1 "rm -rf /mnt1/private/etc/fstab"
    $scp -v -P $openssh_port $script_dir/bin/System/iOS7dualsystem/fstab root@127.0.0.1:/mnt1/private/etc
    $ssh -p $openssh_port root@127.0.0.1 "rm -rf /mnt1/usr/share/firmware/wifi"
    $scp -v -r -P $openssh_port $script_dir/bin/System/iOS7dualsystem/drives/wifi root@127.0.0.1:/mnt1/usr/share/firmware
    $scp -v -P $openssh_port $script_dir/bin/System/iOS7dualsystem/drives/bootchain/applelogo root@127.0.0.1:/mnt1
    $scp -v -P $openssh_port $script_dir/bin/System/iOS7dualsystem/drives/bootchain/devicetree root@127.0.0.1:/mnt1
    $scp -v -P $openssh_port $script_dir/bin/System/iOS7dualsystem/drives/bootchain/kernelcache root@127.0.0.1:/mnt1
    $scp -v -P $openssh_port $script_dir/bin/System/iOS7dualsystem/drives/bootchain/ramdisk root@127.0.0.1:/mnt1
    $scp -v -P $openssh_port $script_dir/bin/System/iOS7dualsystem/drives/bootloader/iBSS root@127.0.0.1:/
    $scp -v -P $openssh_port $script_dir/bin/System/iOS7dualsystem/drives/bootloader/iBEC7 root@127.0.0.1:/
    echo 安装成功 
    go_to_menu
}


factoryactivation() {
    log 准备开始工厂激活，3s后开始操作
    for i in {3..1}; do
    echo "$i..."
    sleep 1
    done
    log 请在爱思助手-工具箱-打开ssh通道 打开ssh通道
    pause 回车开始工厂激活
    sshcheck 2222
    $ssh -p $openssh_port root@127.0.0.1 "mount_hfs /dev/disk0s1s4 /mnt2"
    $scp -v -r -P $openssh_port $script_dir/bin/System/iOS7dualsystem/Factoryactivation/Lockdown root@127.0.0.1:/mnt2/root/Library
    $ssh -p $openssh_port root@127.0.0.1 "rm -rf /mnt2/root/Library/Lockdown/data_ark.plist"
    $scp -v -P $openssh_port $script_dir/bin/System/iOS7dualsystem/Factoryactivation/data_ark.plist root@127.0.0.1:/mnt2/root/Library/Lockdown/
    go_to_menu
}


installcydia() {
    log 准备开始安装cydia，3s后开始操作
    for i in {3..1}; do
    echo "$i..."
    sleep 1
    done
    log 请在爱思助手-工具箱-打开ssh通道 打开ssh通道
    pause 回车开始安装cydia
    sshcheck 2222
    $ssh -p $openssh_port root@127.0.0.1 "umount /mnt1"
    $ssh -p $openssh_port root@127.0.0.1 "mount_hfs /dev/disk0s1s3 /mnt1"
    $ssh -p $openssh_port root@127.0.0.1 "mount_hfs /dev/disk0s1s4 /mnt1/private/var"
    $ssh -p $openssh_port root@127.0.0.1 "rm -rf /mnt1/kernelcache"
    $scp -v -P $openssh_port $script_dir/bin/System/iOS7dualsystem/ios7jailbreak/kernelcache root@127.0.0.1:/mnt1
    $scp -v -P $openssh_port $script_dir/bin/System/iOS7dualsystem/ios7jailbreak/cydia.tar.lzma root@127.0.0.1:/mnt1
    $scp -v -P $openssh_port $script_dir/bin/System/iOS7dualsystem/ios7jailbreak/jbloader.tar.lzma root@127.0.0.1:/mnt1
    $ssh -p $openssh_port root@127.0.0.1 "cd /mnt1; tar --lzma -xvf cydia.tar.lzma"
    $ssh -p $openssh_port root@127.0.0.1 "cd /mnt1; tar --lzma -xvf jbloader.tar.lzma"   
    go_to_menu                
}


factoryactivation() {
    log 准备开始工厂激活，3s后开始操作
    for i in {3..1}; do
    echo "$i..."
    sleep 1
    done
    warning 请在爱思助手-工具箱-打开ssh通道 打开ssh通道
    pause 回车开始工厂激活
    rm ~/.ssh/known_hosts
    sshcheck 2222
    $ssh -p $openssh_port root@127.0.0.1 "umount /mnt2"                
    $ssh -p $openssh_port root@127.0.0.1 "mount_hfs /dev/disk0s1s4 /mnt2"
    $scp -v -r -P $openssh_port $script_dir/bin/System/iOS7dualsystem/Factoryactivation/Lockdown root@127.0.0.1:/mnt2/root/Library
    $ssh -p $openssh_port root@127.0.0.1 "rm -rf /mnt2/root/Library/Lockdown/data_ark.plist"
    $scp -v -P $openssh_port $script_dir/bin/System/iOS7dualsystem/Factoryactivation/data_ark.plist root@127.0.0.1:/mnt2/root/Library/Lockdown/
    go_to_menu
}


installcydia() {
    log 准备开始安装cydia，3s后开始操作
    for i in {3..1}; do
    echo "$i..."
    sleep 1
    done
    warning 请在爱思助手-工具箱-打开ssh通道 打开ssh通道
    pause 回车开始安装cydia
    rm ~/.ssh/known_hosts
    sshcheck 2222
    $ssh -p $openssh_port root@127.0.0.1 "umount /mnt1"
    $ssh -p $openssh_port root@127.0.0.1 "mount_hfs /dev/disk0s1s3 /mnt1"
    $ssh -p $openssh_port root@127.0.0.1 "mount_hfs /dev/disk0s1s4 /mnt1/private/var"
    $ssh -p $openssh_port root@127.0.0.1 "rm -rf /mnt1/kernelcache"
    $scp -v -P $openssh_port $script_dir/bin/System/iOS7dualsystem/ios7jailbreak/kernelcache root@127.0.0.1:/mnt1
    $scp -v -P $openssh_port $script_dir/bin/System/iOS7dualsystem/ios7jailbreak/cydia.tar.lzma root@127.0.0.1:/mnt1
    $scp -v -P $openssh_port $script_dir/bin/System/iOS7dualsystem/ios7jailbreak/jbloader.tar.lzma root@127.0.0.1:/mnt1
    $ssh -p $openssh_port root@127.0.0.1 "cd /mnt1; tar --lzma -xvf cydia.tar.lzma"
    $ssh -p $openssh_port root@127.0.0.1 "cd /mnt1; tar --lzma -xvf jbloader.tar.lzma" 
    go_to_menu                        
}

writediskinf() {
    log 由于ssh命令的限制,写入分区表的操作只能手动操作，请根据helpful.sh操作
    warning 请在爱思助手-工具箱-打开ssh通道 打开ssh通道
    pause 回车开始写入分区表
    rm ~/.ssh/known_hosts
    sshcheck 2222
    $ssh -p $openssh_port root@127.0.0.1 "gptfdisk /dev/rdisk0s1"  
    log 正在重启
    $ssh -p $openssh_port root@127.0.0.1 "reboot"
    go_to_menu                      
}

Beauty() {
    warning 请在爱思助手-工具箱-打开ssh通道 打开ssh通道
    pause 回车开始美化
    $ssh -p $openssh_port root@127.0.0.1 "umount /mnt1"
    $ssh -p $openssh_port root@127.0.0.1 "mount_hfs /dev/disk0s1s3 /mnt1"
    $ssh -p $openssh_port root@127.0.0.1 "rm -rf /mnt1/System/Library/CoreServices/SpringBoard.app/zh_CN.lproj/SpringBoard.strings"
    $scp -v -P $openssh_port $script_dir/bin/System/iOS7dualsystem/beauty/SpringBoard.strings root@127.0.0.1:/mnt1/System/Library/CoreServices/SpringBoard.app/zh_CN.lproj
    $ssh -p $openssh_port root@127.0.0.1 "rm -rf /mnt1/System/Library/PrivateFrameworks/SpringBoardUIServices.framework/zh_CN.lproj/SpringBoardUIServices.strings"
    $scp -v -P $openssh_port $script_dir/bin/System/iOS7dualsystem/beauty/SpringBoardUIServices.strings root@127.0.0.1:/mnt1/System/Library/PrivateFrameworks/SpringBoardUIServices.framework/zh_CN.lproj
    $ssh -p $openssh_port root@127.0.0.1 "rm -rf /mnt1/Applications/MobilePhone.app"  
    go_to_menu          
}

erase_os7() {
    log 开始清除
    $ssh -p $openssh_port root@127.0.0.1 "/sbin/newfs_hfs -s -v System -J -b 8192 -n a=8192,c=8192,e=8192 /dev/disk0s1s3"
    $ssh -p $openssh_port root@127.0.0.1 "/sbin/newfs_hfs -s -v Data -J -b 8192 -n a=8192,c=8192,e=8192 /dev/disk0s1s4"
    log 清除完成
}

sshrdconnect() {
    clear
    rm ~/.ssh/known_hosts
    if $ssh -p $ssh_port root@127.0.0.1 "echo 'SSH 连接成功'" &>/dev/null; then
        log "✅ SSH Ramdisk成功链接"
        log 输入reboot_bak重启
        log 输入mount.sh 挂载分区
        $ssh -p $ssh_port root@127.0.0.1
    else
        error "❌ SSH Ramdisk链接失败(有可能是假的)"
    fi
}



712Tethered() {
            local ipsw
           log 请选择固件
           ipsw="$($zenity --file-selection --multiple --file-filter='IPSW | *.ipsw' --title="Select IPSW file(s)")"
           #ipsws=$(find "$script_dir/bin/Firmware" -type f -name "*.ipsw" 2>/dev/null)
            if [ -z "$ipsw" ]; then
                error "未找到固件"
                go_to_menu
            else
                log 找到固件,继续
            fi
           log 检查固件是否完整
            if [ "$filecheck" -eq 1 ]; then
                sha256=44db09c65f5cfbb04044353129eb6d5bbfd3993fbbc6b19cfb93c628bf62866e
                filesha256=$(shasum -a 256 "$ipsw" | cut -d ' ' -f1)
                if [ "$filesha256" = "$sha256" ]; then
                log "✅ SHA256 校验通过"
                else
                    error "❌ SHA256校验失败,请检查文件是否完整"
                    exit
                fi
            else
                warning 关闭校验，可能导致安装出错
            fi
           DFUhelper pwn
           $idevicerestore -ec "$ipsw"
           go_to_menu
}

boot712() {
        local ipsw
        log 请选择引导固件
        ipsw="$($zenity --file-selection --multiple --file-filter='IPSW | *.ipsw' --title="Select IPSW file(s)")"
        osascript <<EOF
        tell application "Terminal"
        activate
        do script "bash $script_dir/bin/System/iOS7Tethered/7.1.2/server.sh"
        end tell
EOF
        pause 输入完密码后回车继续引导
        log 将设备进入dfu模式
        DFUhelper pwn
        $futurerestore --use-pwndfu --just-boot="-v" "$ipsw"
        go_to_menu
}

beauty7() {
                DFUhelper pwn
                log 发送iBSS
                $irecovery -f $script_dir/bin/SSHRD/6.1.6/iBSS
                sleep 2
                log 发送iBEC
                $irecovery -f $script_dir/bin/SSHRD/6.1.6/iBEC
                sleep 3
                log 发送Ramdisk
                $irecovery -f $script_dir/bin/SSHRD/6.1.6/Ramdisk.dmg
                $irecovery -c "ramdisk"
                sleep 2
                log 发送devicetree
                $irecovery -f $script_dir/bin/SSHRD/6.1.6/DeviceTree.dec
                $irecovery -c "devicetree"
                sleep 1
                log 发送Kernelcache
                $irecovery -f $script_dir/bin/SSHRD/6.1.6/Kernelcache.dec
                $irecovery -c "bootx"
                log "等待设备启动(约10秒)..."
                sleep 10
                log "设置SSH端口($ssh_port)"
                pkill -9 -f "iproxy.*$ssh_port" 2>/dev/null
                $iproxy $ssh_port 22 -s 127.0.0.1 >/dev/null &
                HOST="127.0.0.1"
                if $ssh -p $ssh_port root@127.0.0.1 "echo 'SSH 连接成功'" &>/dev/null; then
                log "✅ SSH Ramdisk成功链接"
            else
                error "❌ SSH Ramdisk链接失败(有可能是假的)"
                
            fi           
            pause 回车开始美化
            rm ~/.ssh/known_hosts
            log 挂载磁盘
            $ssh -p $ssh_port root@127.0.0.1 "umount /mnt1"
            $ssh -p $ssh_port root@127.0.0.1 "umount /mnt2"
            $ssh -p $ssh_port root@127.0.0.1 "mount.sh"
            log 正在美化
            $ssh -p $ssh_port root@127.0.0.1 "rm -rf /mnt1/System/Library/CoreServices/SpringBoard.app/zh_CN.lproj/SpringBoard.strings"
            $scp -v -P $ssh_port $script_dir/bin/System/iOS7dualsystem/beauty/SpringBoard.strings root@127.0.0.1:/mnt1/System/Library/CoreServices/SpringBoard.app/zh_CN.lproj
            $ssh -p $ssh_port root@127.0.0.1 "rm -rf /mnt1/System/Library/PrivateFrameworks/SpringBoardUIServices.framework/zh_CN.lproj/SpringBoardUIServices.strings"
            $scp -v -P $ssh_port $script_dir/bin/System/iOS7dualsystem/beauty/SpringBoardUIServices.strings root@127.0.0.1:/mnt1/System/Library/PrivateFrameworks/SpringBoardUIServices.framework/zh_CN.lproj
            #$ssh -p $ssh_port root@127.0.0.1 "rm -rf /mnt1/mobile/Library/Caches/com.apple.MobileGestalt.plist"
            #$scp -v -P $ssh_port $script_dir/bin/System/iOS7Tethered/activation/com.apple.MobileGestalt.plist root@127.0.0.1:/mnt2/mobile/Library/Caches
            log 正在修复WiFi
            $ssh -p $ssh_port root@127.0.0.1 "rm -rf /mnt1/usr/share/firmware/wifi"
            $scp -v -r -P $ssh_port $script_dir/bin/System/iOS7dualsystem/drives/wifi root@127.0.0.1:/mnt1/usr/share/firmware
            log 正在重启
            $ssh -p $ssh_port root@127.0.0.1 "reboot_bak"
            go_to_menu

}

active712() {
                rm ~/.ssh/known_hosts
                log 请将爱思助手关闭后再开始越狱操作，否则可能会越狱失败
                DFUhelper pwn
                log 发送iBSS
                $irecovery -f $script_dir/bin/SSHRD/6.1.6/iBSS
                sleep 2
                log 发送iBEC
                $irecovery -f $script_dir/bin/SSHRD/6.1.6/iBEC
                sleep 3
                log 发送Ramdisk
                $irecovery -f $script_dir/bin/SSHRD/6.1.6/Ramdisk.dmg
                $irecovery -c "ramdisk"
                sleep 2
                log 发送devicetree
                $irecovery -f $script_dir/bin/SSHRD/6.1.6/DeviceTree.dec
                $irecovery -c "devicetree"
                sleep 1
                log 发送Kernelcache
                $irecovery -f $script_dir/bin/SSHRD/6.1.6/Kernelcache.dec
                $irecovery -c "bootx"
                log "等待设备启动(约10秒)..."
                sleep 10
                log "设置SSH端口($ssh_port)"
                pkill -9 -f "iproxy.*$ssh_port" 2>/dev/null
                $iproxy $ssh_port 22 -s 127.0.0.1 >/dev/null &
                HOST="127.0.0.1"
                if $ssh -p $ssh_port root@127.0.0.1 "echo 'SSH 连接成功'" &>/dev/null; then
                    log "✅ SSH Ramdisk成功链接"
                else
                    error "❌ SSH Ramdisk链接失败(有可能是假的)"
                    
                fi           
                pause 回车开始激活
                rm ~/.ssh/known_hosts
                log 挂载磁盘
                $ssh -p $ssh_port root@127.0.0.1 "umount /mnt1"
                $ssh -p $ssh_port root@127.0.0.1 "umount /mnt2"
                $ssh -p $ssh_port root@127.0.0.1 "mount.sh"
                log 正在激活
                plistbackup=$(find "$script_dir/bin/System/iOS7Tethered/activation" -type f -name "*.backup" 2>/dev/null)
                if [ -z "$plistbackup" ]; then
                    echo 1
                else
                    log 删除原有的激活文件
                    rm -rf $script_dir/bin/System/iOS7Tethered/activation/com.apple.MobileGestalt.plist.backup
                    rm -rf $script_dir/bin/System/iOS7Tethered/activation/com.apple.MobileGestalt.plist
                fi
                $scp -r -P $ssh_port root@127.0.0.1:/mnt2/mobile/Library/Caches/com.apple.MobileGestalt.plist $script_dir/bin/System/iOS7Tethered/activation
                plist=$(find "$script_dir/bin/System/iOS7Tethered/activation" -type f -name "*.plist" 2>/dev/null)
                if [ -z "$plist" ]; then
                    error "未找到激活文件"
                    go_to_menu

                else
                    $ssh -p $ssh_port root@127.0.0.1 "rm -rf /mnt2/mobile/Library/Caches/com.apple.MobileGestalt.plist"
                    plistfile=$script_dir/bin/System/iOS7Tethered/activation/com.apple.MobileGestalt.plist
                    $activation $plistfile
                    #$activation $script_dir/bin/System/iOS7Tethered/activation/com.apple.MobileGestalt.plist
                    $script_dir/bin/System/iOS7Tethered/activation/activition.py $script_dir/bin/System/iOS7Tethered/activation/com.apple.MobileGestalt.plist
                    $scp -v -P $ssh_port $script_dir/bin/System/iOS7Tethered/activation/com.apple.MobileGestalt.plist root@127.0.0.1:/mnt2/mobile/Library/Caches
                fi
                log 正在重启
                $ssh -p $ssh_port root@127.0.0.1 "reboot_bak"
                go_to_menu

}

jailbreak7() {
                #echo step1
                #for i in {3..1}; do
                #echo "$i..."
                #sleep 1
                #echo step1
                #for i in {8..1}; do
                #echo "$i..."
                #sleep 1
                #echo step2
                #for i in {8..1}; do
                #echo "$i..."
                #log 请手动将设备进入DFU模式
                #sleep 5
                #$ipwnder
                DFUhelper pwn
                log 发送iBSS
                $irecovery -f $script_dir/bin/SSHRD/6.1.6/iBSS
                sleep 2
                log 发送iBEC
                $irecovery -f $script_dir/bin/SSHRD/6.1.6/iBEC
                sleep 3
                log 发送Ramdisk
                $irecovery -f $script_dir/bin/SSHRD/6.1.6/Ramdisk.dmg
                $irecovery -c "ramdisk"
                sleep 2
                log 发送devicetree
                $irecovery -f $script_dir/bin/SSHRD/6.1.6/DeviceTree.dec
                $irecovery -c "devicetree"
                sleep 1
                log 发送Kernelcache
                $irecovery -f $script_dir/bin/SSHRD/6.1.6/Kernelcache.dec
                $irecovery -c "bootx"
                log "等待设备启动(约10秒)..."
                sleep 10
                log "设置SSH端口($ssh_port)"
                pkill -9 -f "iproxy.*$ssh_port" 2>/dev/null
                $iproxy $ssh_port 22 -s 127.0.0.1 >/dev/null &
                pause 回车开始越狱
                $ssh -p $ssh_port root@127.0.0.1 "mount.sh root"
                $scp -v -P $ssh_port $script_dir/bin/Jailbreak/lyncis.tar root@127.0.0.1:/mnt1
                $ssh -p $ssh_port root@127.0.0.1 "mount.sh pv"
                $ssh -p $ssh_port root@127.0.0.1 "cd /mnt1; tar -xvf lyncis.tar"
                $ssh -p $ssh_port root@127.0.0.1 "cd /mnt1; ./install.sh"
                $scp -v -P $ssh_port $script_dir/bin/Jailbreak/fstab7.tar root@127.0.0.1:/mnt1
                $ssh -p $ssh_port root@127.0.0.1 "cd /mnt1; tar -xvf fstab7.tar"
                $scp -v -P $ssh_port $script_dir/bin/Jailbreak/freeze.tar root@127.0.0.1:/mnt1/private/var
                $ssh -p $ssh_port root@127.0.0.1 "tar -xvf /mnt1/private/var/freeze.tar -C /mnt1"
                $scp -v -P $ssh_port $script_dir/bin/Jailbreak/sshdeb.tar root@127.0.0.1:/mnt1
                $ssh -p $ssh_port root@127.0.0.1 "cd /mnt1; tar -xvf sshdeb.tar" 
                log 正在重启        
                $ssh -p $ssh_port root@127.0.0.1 "reboot_bak"
                go_to_menu
}

activition() {
                log 确保设备已经越狱，并已经载入SSH Ramdisk
                pause 回车继续
                $ssh -p $ssh_port root@127.0.0.1 "mount.sh"
                $ssh -p $ssh_port root@127.0.0.1 "rm -rf /mnt1/usr/libexec/lockdownd"
                $scp -v -P $ssh_port $script_dir/bin/Others/lockdownd root@127.0.0.1:/mnt1/usr/libexec
                $ssh -p $ssh_port root@127.0.0.1 "chmod 755 /mnt1/usr/libexec/lockdownd"
                log 激活完成
                go_to_menu

}

ios6.1.6_flash() {
    local ipsw
    local options
    local selected
    log 选择选项
    options=("选择本地固件" "在线下载固件" "返回主页")
    select_option "${options[@]}"
    selected="${options[$?]}"
    if [[ "$selected" == "选择本地固件" ]]; then
    log 选择iOS6.1.6固件
    ipsw="$($zenity --file-selection --multiple --file-filter='IPSW | 6.1.6*.ipsw' --title="Select iOS6.1.6 iPSW file(s)")"
    elif [[ "$selected" == "在线下载固件" ]]; then
        log 正在下载固件
        aria2c https://appldnld.apple.com/iOS6.1/031-3211.20140221.Placef/iPod4,1_6.1.6_10B500_Restore.ipsw -o $script_dir/bin/Firmware/iPod4,1_6.1.6_10B500_Restore.ipsw

        ipsw=$script_dir/bin/Firmware/iPod4,1_6.1.6_10B500_Restore.ipsw
    elif [[ "$selected" == "返回主页" ]]; then
        go_to_menu
    fi
    log 选择iOS6.1.6固件
    ipsw="$($zenity --file-selection --multiple --file-filter='IPSW | 6.1.6*.ipsw' --title="Select iOS6.1.6 iPSW file(s)")"
    filesha256=$(shasum -a 256 "$ipsw" | cut -d ' ' -f1)
    sha256=1f6096c3298c87172f431e4924a4cf3c53298e5920f4b6c817929aa32d90c5ff
    if [ "$filesha256" = "$sha256" ]; then
        log "✅ SHA256 校验通过"
    else
        log "❌ SHA256 校验失败,请重新下载"
    fi
    log 开始恢复
    DFUhelper pwn
    $idevicerestore -l -e $ipsw
    log 恢复完成
    go_to_menu
}

##################touch5########################



ios9.3.5_flash() {
    if [ ! -f "$script_dir/bin/Firmware/iPod5,1_9.3.5_13G36_Restore.ipsw" ]; then
        log 选择选项
        options=("选择本地固件" "在线下载固件" "返回主页")
        select_option "${options[@]}"
        selected="${options[$?]}"
        if [[ "$selected" == "选择本地固件" ]]; then
        log 选择iOS9.3.5固件
        ipsw="$($zenity --file-selection --multiple --file-filter='IPSW | *.ipsw' --title="Select iOS9.3.5 iPSW file(s)")"
        elif [[ "$selected" == "在线下载固件" ]]; then
            log 正在下载固件
            aria2c https://secure-appldnld.apple.com/iOS9.3.5/031-73183-20160825-6A2D8488-6711-11E6-9C7E-1B3834D2D062/iPod5,1_9.3.5_13G36_Restore.ipsw -o /$script_dir/bin/Firmware/iPod5,1_9.3.5_13G36_Restore.ipsw
            ipsw=$script_dir/bin/Firmware/iPod5,1_9.3.5_13G36_Restore.ipsw
        elif [[ "$selected" == "返回主页" ]]; then
            go_to_menu
        fi
    else
        log 找到本地固件,开始刷入
        ipsw=$script_dir/bin/Firmware/iPod5,1_9.3.5_13G36_Restore.ipsw
    fi
    filesha256=$(shasum -a 256 "$ipsw" | cut -d ' ' -f1)
    sha256=4a4857db19d68ca135e91b800f351cda7c96c1ae63b29ab0cf0eccaebb14f7e7
    if [ "$filesha256" = "$sha256" ]; then
        log "✅ SHA256 校验通过"
    else
        log "❌ SHA256 校验失败,请重新下载"
    fi
    log 开始恢复
    DFUhelper nopwn
    $idevicerestore -l -e $ipsw
    log 恢复完成
    go_to_menu
}

device_send_unpacked_ibss() {
    log $primepwn
    pause
    local pwnrec="pwned iBSS"
    device_rd_build=
    patch_ibss
    log "Sending unpacked iBSS..."
    $primepwn $tmp/pwnediBSS
    local tool_pwned=$?
    if [[ $tool_pwned != 0 ]]; then
        error "Failed to send iBSS. Your device has likely failed to enter PWNED DFU mode." \
        "* You might need to exit DFU and (re-)enter PWNED DFU mode before retrying."
    fi
    sleep 1
    log "Checking for device"
    local irec="$($irecovery -q 2>&1)"
    device_pwnd="$(echo "$irec" | grep "PWND" | cut -c 7-)"
    if [[ -z $device_pwnd && $irec != "ERROR"* ]]; then
        log "Device should now be in $pwnrec mode."
    else
        error "Device failed to enter $pwnrec mode."
        exit
    fi
}

pwn_kdfu() {
        local sendfiles=()
        local ip="127.0.0.1"
        if [[ $device_mode != "Normal" ]]; then
            device_enter_mode pwnDFU
            return
        fi
        echo "chmod +x /tmp/kloader*" > kloaders
        echo "/tmp/kloader /tmp/pwnediBSS" >> kloaders
        sendfiles+=("../resources/kloader/kloader")
        sendfiles+=("kloaders" "pwnediBSS")
        patch_ibss

        device_iproxy
        if [[ $device_jailbrokenselected != 1 ]]; then
            device_ssh_message
            print "3. On entering kDFU mode, the device will disconnect."
            print "  - Proceed to unplug and replug the device when prompted."
            print "  - Alternatively, press the TOP or HOME button."
            device_sshpass alpine
        fi

        log "Entering kDFU mode..."
        print "* This may take a while, but should not take longer than a minute."
        log "Sending files to device: ${sendfiles[*]}"
        if [[ $device_det == 10 ]]; then
            for file in "${sendfiles[@]}"; do
                cat $file | $ssh -p $ssh_port root@127.0.0.1 "cat > /tmp/$(basename $file)" &>scp.log &
            done
            sleep 3
            cat scp.log
            check="$(cat scp.log | grep -c "Connection reset")"
        else
            $scp -P $ssh_port ${sendfiles[@]} root@127.0.0.1:/tmp
            check=$?
        fi
        if [[ $check == 0 ]]; then
            log "Running kloader"
            $ssh -p $ssh_port root@127.0.0.1 "bash /tmp/kloaders" &
        else
            warning "Failed to connect to device via USB SSH."
            if [[ $device_det == 10 ]]; then
                print "* Try to re-install both OpenSSH and Dropbear, reboot, re-jailbreak, and try again."
                print "* Alternatively, place your device in DFU mode (see \"Troubleshooting\" wiki page for details)"
                print "* Troubleshooting link: https://github.com/LukeZGD/Legacy-iOS-Kit/wiki/Troubleshooting#dfu-advanced-menu-for-32-bit-devices"
            elif (( device_det <= 5 )); then
                print "* Try to re-install OpenSSH, reboot, and try again."
            else
                print "* Try to re-install OpenSSH, reboot, re-jailbreak, and try again."
                print "* Alternatively, you may use kDFUApp from my Cydia repo (see \"Troubleshooting\" wiki page for details)"
                print "* Troubleshooting link: https://github.com/LukeZGD/Legacy-iOS-Kit/wiki/Troubleshooting#dfu-advanced-menu-kdfu-mode"
            fi
            input "Press Enter/Return to try again with Wi-Fi SSH (or press Ctrl+C to cancel and try again)"
            read -s
            log "Trying again with Wi-Fi SSH..."
            print "* Make sure that your iOS device and PC/Mac are on the same network."
            print "* To get your iOS device's IP Address, go to: Settings -> Wi-Fi/WLAN -> tap the 'i' or '>' next to your network name"
            ip=
            until [[ -n $ip ]]; do
                read -p "$(input 'Enter the IP Address of your device: ')" ip
            done
            log "Sending files to device: ${sendfiles[*]}"
            $scp ${sendfiles[@]} root@$ip:/tmp
            if [[ $? != 0 ]]; then
                error "Failed to connect to device via SSH, cannot continue."
            fi
            log "Running kloader"
            $ssh root@$ip "bash /tmp/kloaders" &
        fi

        local attempt=1
        local device_in
        local port
        if [[ $ip == "127.0.0.1" ]]; then
            port="-p $ssh_port"
        fi
        while (( attempt <= 5 )); do
            log "Finding device in kDFU mode... (Attempt $attempt of 5)"
            if [[ $($irecovery -q 2>/dev/null | grep -w "MODE" | cut -c 7-) == "DFU" ]]; then
                device_in=1
            fi
            if [[ $device_in == 1 ]]; then
                log "Found device in kDFU mode."
                device_mode="DFU"
                break
            fi
            if [[ $opt == "kloader_axi0mX" ]]; then
                print "* Keep the device plugged in"
                $ssh $port root@$ip "bash /tmp/kloaders" &
            else
                print "* Unplug and replug your device now"
            fi
            ((attempt++))
        done
        if (( attempt > 5 )); then
            error "Failed to find device in kDFU mode. Please run the script again"
        fi
        kill $iproxy_pid
}

##################touch6########################

sshrd_script() {
    if [ -d "$script_dir/bin/SSHRD/SSHRD_Script" ]; then
        :
    else
        log "下载SSHRD_Script(github)"
        cd $script_dir/bin/SSHRD
        git clone https://github.com/iPh0ne4s/SSHRD_Script.git
        if [ -d "$script_dir/bin/SSHRD/SSHRD_Script" ]; then
            log 下载成功
        else
            error 下载失败,检查网络后再试
            go_to_menu
        fi
    fi
    cd $script_dir/bin/SSHRD/SSHRD_Script
    check_sudo
    if [[ $1 == none ]]; then
        :
    else
        DFUhelper nopwn
        local device_ecid=$($idevicerestore -l 2>/dev/null | grep -i "ECID" | awk '{print $3}')
        log $device_ecid
        if [ -z "$1" ]; then
            options=()
            if [[ -z $os ]]; then
                local os
                log "输入本机系统版本(不知道直接回车)"
                read os
                if [[ -z $os ]]; then
                    os=
                fi
            fi
            case $os in
                [789].* ) 
                    options+=("启动默认版本(iOS12.0)");;
                * ) 
                    if [[ -z $os ]]; then
                        :
                    else  
                        options+=("启动默认版本($os)")
                    fi
                    ;;
            esac
            options+=("启动指定版本" "返回主页")
            select_option "${options[@]}"
            selected="${options[$?]}"
            if [[ "$selected" == "启动默认版本($os)" ]]; then
                version=$os
            elif [[ "$selected" == "启动默认版本(iOS12.0)" ]]; then
                version=12.0
            elif [[ "$selected" == "启动指定版本" ]]; then
                log "输入想要启动的SSHRD版本(默认12.0)"
                read ver
                if [[ -z $ver ]]; then
                    version=12.0
                else
                    version=$ver
                fi
            elif [[ "$selected" == "返回主页" ]]; then
                go_to_menu
            fi 
        else
            version=$1
        fi
        local local_rd_ver=
        sudo ./sshrd.sh $version
        cd $script_dir/bin/SSHRD/SSHRD_Script
        sudo ./sshrd.sh boot
        log 等待设备启动
        sleep 13
        $iproxy 2222 22 #&>/dev/null &
        sleep 5
        insshrd=1
    fi
    if [ -z "$2" ]; then
        cd $script_dir/bin/SSHRD/SSHRD_Script
        SSHRD_choice_64 $version
    fi
    if [[ $2 == dumpshsh ]]; then
        cd $script_dir/bin/SSHRD/SSHRD_Script
        sudo ./sshrd.sh dump-blobs
        if [ -f "$script_dir/bin/SSHRD/SSHRD_Script/dumped.shsh2" ]; then
            local time=$(date +%Y-%m-%d-%H%M)
            mv $script_dir/bin/SSHRD/SSHRD_Script/dumped.shsh2 $saved/SHSH/$device_ecid-$device_type-${time}.shsh2
            if [ -f "$saved/SHSH/$device_type-${time}.shsh2" ]; then
                log 保存SHSH成功
                cd $script_dir/bin/SSHRD/SSHRD_Script
                sudo ./sshrd.sh reboot
            else
                error 保存失败,SHSH文件处于$script_dir/bin/SSHRD/SSHRD_Script/dumped.shsh2
                cd $script_dir/bin/SSHRD/SSHRD_Script
                sudo ./sshrd.sh reboot
            fi
        else
            error 保存SHSH失败
            cd $script_dir/bin/SSHRD/SSHRD_Script
            sudo ./sshrd.sh reboot
        fi
    elif [[ $2 == nomenu ]]; then
        log No Menu
    fi
    cd $script_dir/bin/SSHRD/SSHRD_Script
    sudo ./sshrd.sh clean
}

################Patch Tools#####################

get_ipsw_info() {
    local ipsw_file
    local manifest_file="/tmp/BuildManifest.plist"
    
    # 确定要处理的IPSW文件
    if [[ $1 == "base" ]]; then
        ipsw_file="$ipsw_base_path"
    else
        if [[ $1 == "target" ]]; then
            ipsw_file="$2"
        else
            ipsw_file="$ipsw_path"
        fi
    fi    
    if [ -z "$ipsw_file" ]; then
        warning 无法获取固件路径
        go_to_menu
    fi
    # 提取BuildManifest.plist
    unzip -p "$ipsw_file" "BuildManifest.plist" > "$manifest_file" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "错误：无法从 IPSW 提取 BuildManifest.plist！"
        return 1
    fi
    
    # 解析固件信息
    if [[ $platform == "macos" ]]; then
        device_type_ipsw_temp=$(plutil -extract "SupportedProductTypes" xml1 -o - "$manifest_file" | sed -n 's/<string>\(.*\)<\/string>/\1/p')
        device_vers=$(plutil -extract "ProductVersion" xml1 -o - "$manifest_file" | sed -n 's/<string>\(.*\)<\/string>/\1/p')
        device_build=$(plutil -extract "ProductBuildVersion" xml1 -o - "$manifest_file" | sed -n 's/<string>\(.*\)<\/string>/\1/p')
        device_type_ipsw=$(echo "$device_type_ipsw_temp" | tr -d '\n\r' | xargs)
    else
        device_type_ipsw_temp=$(cat $manifest_file | grep -i SupportedProductTypes -A 1 | grep -oPm1 "(?<=<string>)[^<]+")
        device_vers=$(cat $manifest_file | grep -i ProductVersion -A 1 | grep -oPm1 "(?<=<string>)[^<]+")
        device_build=$(cat $manifest_file | grep -i ProductBuildVersion -A 1 | grep -oPm1 "(?<=<string>)[^<]+")
        device_type_ipsw=$(echo "$device_type_ipsw_temp" | tr -d '\n\r' | xargs)
    fi
    # 设置相应的变量
    if [[ $1 == "base" ]]; then
        device_type_ipswbase="$device_type_ipsw"
        device_base_vers="$device_vers"
        device_base_build="$device_build"
        # 检查设备类型是否匹配
        if [[ "$device_type" != "$device_type_ipswbase" ]]; then
            ipsw_base_select_wrong=1
            return 1
        else
            ipsw_base_select_wrong=0
        fi
    else
        device_type_ipsw="$device_type_ipsw"
        device_target_vers="$device_vers"
        device_target_build="$device_build"
        # 检查设备类型是否匹配
        if [[ "$device_type" != "$device_type_ipsw" ]]; then
            ipsw_select_wrong=1
            return 1
        else
            ipsw_select_wrong=0
        fi
    fi
    
    rm -f "$manifest_file"
    return 0
}

device_fw_key_check() {
    # check and download keys for device_target_build, then set the variable device_fw_key (or device_fw_key_base)
    if [[ -n "$ipsw_path_cs" ]]; then
        local ipsw_path=$ipsw_path_cs
    fi
    if [[ ! -n "$2" ]]; then
        if [[ $1 == base ]]; then
            unzip -p "$ipsw_base_path" "BuildManifest.plist" > /tmp/BuildManifest.plist 2>/dev/null
            if [ $? -ne 0 ]; then
                echo "错误：无法从 IPSW 提取 BuildManifest.plist！"
                exit 1
            fi
            local device_base_vers=$(plutil -extract "ProductVersion" xml1 -o - /tmp/BuildManifest.plist | sed -n 's/<string>\(.*\)<\/string>/\1/p')
            local device_base_build=$(plutil -extract "ProductBuildVersion" xml1 -o - /tmp/BuildManifest.plist | sed -n 's/<string>\(.*\)<\/string>/\1/p')
        fi
        unzip -p "$ipsw_path" "BuildManifest.plist" > /tmp/BuildManifest.plist 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "错误：无法从 IPSW 提取 BuildManifest.plist！"
            exit 1
        fi
        local device_target_vers=$(plutil -extract "ProductVersion" xml1 -o - /tmp/BuildManifest.plist | sed -n 's/<string>\(.*\)<\/string>/\1/p')
        local device_target_build=$(plutil -extract "ProductBuildVersion" xml1 -o - /tmp/BuildManifest.plist | sed -n 's/<string>\(.*\)<\/string>/\1/p')
        log "目标iOS版本: $device_target_vers"
        log "目标iOS构建版本: $device_target_build"
        rm -f /tmp/BuildManifest.plist
    fi
    local key
    #local build="$device_target_build"
    local keys_path="$script_dir/tmp"
    if [ -z "$keys_path" ]; then
        mkdir -p $keys_path
    fi
    if [[ $1 == "base" ]]; then
        build="$device_base_build"
    elif [[ $1 == "temp" ]]; then
        build="$2"
    fi
    log "Checking firmware keys in $keys_path"
    if [[ $(cat "$keys_path/index.html" 2>/dev/null | grep -c "$device_target_build") != 1 ]]; then
        rm -f "$keys_path/index.html"
    fi
    if [[ $1 == "base" ]]; then
        mkdir -p $keys_path/base
        cp $resources/keys/$device_type/$device_base_build/index.html "$keys_path/base/index.html"
        device_fw_key_base="$(cat $keys_path/base/index.html)"
    elif [[ $1 == "temp" ]]; then
        cp $resources/keys/$device_type/$2/index.html "$keys_path/index.html"
        device_fw_key_temp="$(cat $keys_path/index.html)"
    elif [[ $1 == "server" ]]; then
        mkdir -p $keys_path/firmware/$device_type/$device_target_build
        cp $resources/keys/$device_type/$device_target_build/index.html "$keys_path/firmware/$device_type/$device_target_build/index.html"
        device_fw_key="$(cat $keys_path/firmware/$device_type/$device_target_build/index.html)"
    else
        cp $resources/keys/$device_type/$device_target_build/index.html "$keys_path/index.html"
        device_fw_key="$(cat $keys_path/index.html)"
    fi
}

ipsw_get_url() {
    local device_fw_dir=$saved/urls/${device_type}
    local build_id="$1"
    local version="$2"
    local url="$(cat "$device_fw_dir/$build_id/url" 2>/dev/null)"
    local url_local="$url"
    ipsw_url=
    log "Checking URL in $device_fw_dir/$build_id/url"
    if [[ $(echo "$url" | grep -c '<') != 0 || $url != *"$build_id"* ]]; then
        rm -f "$device_fw_dir/$build_id/url"
        url=
    fi
    if [[ -z $url ]]; then
        log "Getting URL for $device_type-$build_id"
        local phone="OS" # iOS
        case $build_id in
            2[0123]* | 7B405 | 7B500 ) :;;
            1[AC]* | [2345]* ) phone="Phone%20Software";; # iPhone Software
            7* ) phone="Phone%20OS";; # iPhone OS
        esac
        url="$(curl "https://raw.githubusercontent.com/littlebyteorg/appledb/refs/heads/gh-pages/ios/i${phone};$build_id.json" | $jq -r ".sources[] | select(.type == \"ipsw\" and any(.deviceMap[]; . == \"$device_type\")) | .links[0].url")"
        local url2="$(echo "$url" | tr '[:upper:]' '[:lower:]')"
        local build_id2="$(echo "$build_id" | tr '[:upper:]' '[:lower:]')"
        if [[ $(echo "$url" | grep -c '<') != 0 || $url2 != *"$build_id2"* ]]; then
            if [[ -n $url_local ]]; then
                url="$url_local"
                log "Using saved URL for this IPSW: $url"
                mkdir -p $device_fw_dir/$build_id
                echo "$url" > $device_fw_dir/$build_id/url
                ipsw_url="$url"
                return
            fi
        fi
        mkdir -p $device_fw_dir/$build_id 2>/dev/null
        echo "$url" > $device_fw_dir/$build_id/url
    fi

    ipsw_url="$url"
}

download_comp() {
    # usage: download_comp [build_id] [comp]
    local build_id="$1"
    local comp="$2"
    #device_model=n78
    ipsw_get_url $build_id
    download_targetfile="$comp.$device_model"
    if [[ $build_id != "12"* ]]; then
        download_targetfile+="ap"
    fi
    download_targetfile+=".RELEASE"
    log "Downloading ${comp}..."
    log $ipsw_url
    cd $tmp
    "$pzb" -g "Firmware/dfu/$download_targetfile.dfu" -o ${comp} "$ipsw_url"
    cp $tmp/${comp} $tmp/$download_targetfile.dfu
}

patch_ibss() {
    # creates file pwnediBSS to be sent to device
    log $saved/patches/pwnedibss/$device_type/pwnediBSS
    pause
    if [ ! -f "$saved/patches/pwnedibss/$device_type/pwnediBSS" ]; then
        if [[ -z $device_type ]]; then
            warning 无法获取设备型号
        else
            mkdir -p $saved/patches/pwnedibss/$device_type
        fi
        local build_id
        case $device_type in
            iPad1,1 | iPod3,1 ) build_id="9B206";;
            iPhone2,1 | iPod4,1 ) build_id="10B500";;
            iPhone3,[123] ) build_id="11D257";;
            * ) build_id="12H321";;
        esac
        if [[ -n $device_rd_build ]]; then
            build_id="$device_rd_build"
        fi
        download_comp $build_id iBSS
        device_fw_key_check temp $build_id
        local iv=$(echo $device_fw_key_temp | $jq -j '.keys[] | select(.image == "iBSS") | .iv')
        local key=$(echo $device_fw_key_temp | $jq -j '.keys[] | select(.image == "iBSS") | .key')
        log $iv
        log $key
        log "Decrypting iBSS..."
        "$xpwntool" $tmp/iBSS $tmp/iBSS.dec -iv $iv -k $key
        log "Patching iBSS..."
        "$iBoot32Patcher" $tmp/iBSS.dec $tmp/pwnediBSS --rsa
        "$xpwntool" $tmp/pwnediBSS $tmp/pwnediBSS.dfu -t $tmp/iBSS
        cp $tmp/pwnediBSS $saved/patches/pwnedibss/$device_type/pwnediBSS
        log "Pwned iBEC img3 saved at: $saved/patches/pwnedibss/$device_type/pwnediBSS"
    else
        if [[ -z $device_type ]]; then
            warning 无法获取设备型号
        else
            cp $saved/patches/pwnedibss/$device_type/pwnediBSS $tmp/pwnediBSS
        fi
    fi
}

patch_ibec() {
    # creates file pwnediBEC to be sent to device for blob dumping
    if [ ! -f "$saved/patches/pwnedibec/$device_type/pwnediBEC.dfu" ]; then
        if [[ -z $device_type ]]; then
            warning 无法获取设备型号
        else
            mkdir -p $saved/patches/pwnedibec/$device_type
        fi
        local build_id
        case $device_type in
            iPad1,1 | iPod3,1 )
                build_id="9B206";;
            iPhone2,1 | iPhone3,[123] | iPod4,1 | iPad3,1 )
                build_id="10A403";;
            iPad2,[367] | iPad3,[25] )
                build_id="12H321";;
            iPhone5,3 )
                build_id="11B511";;
            iPhone5,4 )
                build_id="11B651";;
            * )
                build_id="10B329";;
        esac
        if [[ -n $device_rd_build ]]; then
            build_id="$device_rd_build"
        fi
        download_comp $build_id iBEC
        device_fw_key_check temp $build_id
        local name="iBEC"
        local iv=$(echo $device_fw_key_temp | $jq -j '.keys[] | select(.image == "iBEC") | .iv')
        local key=$(echo $device_fw_key_temp | $jq -j '.keys[] | select(.image == "iBEC") | .key')
        local address="0x80000000"
        if [[ $device_proc == 4 ]]; then
            address="0x40000000"
        fi
        mv $tmp/iBEC $tmp/$name.orig
        log "Decrypting iBEC..."
        "$xpwntool" $tmp/$name.orig $tmp/$name.dec -iv $iv -k $key
        log "Patching iBEC..."
        if [[ $device_proc == 4 || -n $device_rd_build || $device_type == "iPad3,1" ]]; then
            "$iBoot32Patcher" $tmp/$name.dec $tmp/$name.patched --rsa --ticket -b "rd=md0 -v amfi=0xff cs_enforcement_disable=1" -c "go" $address
        else
            cp $script_dir/bin/System/Restore/resources/patch/$download_targetfile.patch $tmp/$download_targetfile.patch
            $bspatch $tmp/$name.dec $tmp/$name.patched $tmp/$download_targetfile.patch
        fi
        "$xpwntool" $tmp/$name.patched $tmp/pwnediBEC.dfu -t $tmp/$name.orig
        cp $tmp/pwnediBEC.dfu $saved/patches/pwnedibec/$device_type/pwnediBEC.dfu
        log "Pwned iBEC img3 saved at: $saved/patches/pwnedibec/$device_type/pwnediBEC.dfu"
    else
        if [[ -z $device_type ]]; then
            warning 无法获取设备型号
        else
            cp $saved/patches/pwnedibec/$device_type/pwnediBEC.dfu $tmp/pwnediBEC.dfu
        fi
    fi

}
##################custom ipsw##################

ipsw_select (){
    local ver
    if [[ $1 == target ]]; then
        log 选择目标固件
        ipsw_path="$($zenity --file-selection --multiple --file-filter='IPSW | *.ipsw' --title="Select IPSW file(s)")"
        get_ipsw_info
        if [[ $? -ne 0 ]]; then
            return 1
        fi
        while [[ $ipsw_select_wrong -eq 1 ]]; do
            warning 不是本机的固件,请重新选取
            ipsw_path=
            pause
            return
            if [[ $? -eq 0 ]]; then
                break
            fi
        done
    elif [[ $1 == base ]]; then
        case $device_type in
            "iPod3,1" ) ver=5.1.1 ;;       
            "iPod5,1" ) ver=7.1.x ;;
            * ) error 本设备无法使用powdersn0w降级,可以使用SHSH/强制降级 ; exit 1 ;;
        esac
        log 选择iOS${ver}固件
        ipsw_base_path="$($zenity --file-selection --multiple --file-filter='IPSW | *.ipsw' --title="Select IPSW file(s)")"
        get_ipsw_info "base"
        while [[ $ipsw_base_select_wrong -eq 1 ]]; do
            warning 不是本机的固件,请重新选取
            ipsw_base_path=
            pause
            return
            if [[ $? -eq 0 ]]; then
                break
            fi
        done
        case $device_base_vers in
            7.1.* ) return ;;       
            5.1.1 ) return ;;
            * ) warning 此固件无法使用powdersn0w,请选择ios${ver}固件 ;;
        esac
    elif [[ $1 == justboot ]]; then
        ipsw_justboot_path="$($zenity --file-selection --multiple --file-filter='IPSW | *.ipsw' --title="Select IPSW file(s)")"
    elif [[ $1 == select ]]; then
        ipsw_select_path="$($zenity --file-selection --multiple --file-filter='IPSW | *.ipsw' --title="Select IPSW file(s)")"
    fi
    if [[ $1 != "justboot" && $1 != "select" ]]; then
        if [[ $device_proc != 7 ]]; then
            case $device_target_vers in
                3.* ) ipsw_canjailbreak=0
                    ipsw_prepare_usepowder=0 ;;
                4.1 ) 
                    ipsw_canjailbreak=0
                    ipsw_prepare_usepowder=0 ;; 
                * ) ipsw_canjailbreak=1
                    device_target_other=1
                    ipsw_prepare_usepowder=1 ;;
            esac
            ipsw_openssh=1
        fi
    fi
}

shsh_select (){
    local localshshpath=$lib/shsh
    if [ ! -d "$localshshpath" ]; then
        mkdir -p $localshshpath
    fi
    shsh_path="$($zenity --file-selection --multiple --file-filter='SHSH | *.bshsh2 *.shsh *.shsh2' --title="Select SHSH file(s)")"
    if [[ $no_cp != 1 ]]; then
        cp $shsh_path $localshshpath/$(basename "$shsh_path")
        mv $localshshpath/$(basename "$shsh_path") $localshshpath/$device_ecid-${device_type}-${device_target_vers}.shsh
    fi
}

ipsw_select_old (){
    #ipsw select
    log 选择固件
    ipsw_path="$($zenity --file-selection --multiple --file-filter='IPSW | *.ipsw' --title="Select IPSW file(s)")"
    if [ ! -f "$ipsw_path" ]; then
        echo "错误：文件 $ipsw_path 不存在！"
        return 1
    fi
    
    # 调用获取固件信息函数
    get_ipsw_info "$1"
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # 检查固件选择是否正确
    while [[ $ipsw_select_wrong -eq 1 ]]; do
        warning 不是本机的固件,请重新选取
        ipsw_select "$1"
        if [[ $? -eq 0 ]]; then
            break
        fi
    done
    
    if [[ $1 == powder ]]; then
        local ver
        case $device_type in
            "iPod3,1" ) ver=5.1.1 ;;       
            "iPod5,1" ) ver=7.1.x ;;
            * ) error 本设备无法使用powdersn0w降级,可以使用SHSH/强制降级 ; exit 1 ;;
        esac
        while true; do
            log 选择iOS${ver}固件
            ipsw_base_path="$($zenity --file-selection --multiple --file-filter='IPSW | *.ipsw' --title="Select IPSW file(s)")"
            if [ ! -f "$ipsw_base_path" ]; then
                error "错误：文件 $ipsw_base_path 不存在！"
                continue
            fi
            
            # 调用获取基础固件信息函数
            get_ipsw_info "base"
            if [[ $? -ne 0 ]]; then
                continue
            fi
            
            # 检查基础固件选择是否正确
            while [[ $ipsw_base_select_wrong -eq 1 ]]; do
                warning 不是本机的固件,请重新选取
                ipsw_base_path="$($zenity --file-selection --multiple --file-filter='IPSW | *.ipsw' --title="Select IPSW file(s)")"
                if [ ! -f "$ipsw_base_path" ]; then
                    error "错误：文件 $ipsw_base_path 不存在！"
                    continue
                fi
                get_ipsw_info "base"
            done
            
            case $device_base_vers in
                7.1.* ) break ;;       
                5.1.1 ) break ;;
                * ) warning 此固件无法使用powdersn0w,请选择ios${ver}固件 ;;
            esac
        done
    fi
    
    if [[ $1 != justboot ]]; then
        if [[ $device_proc != 7 ]]; then
            case $device_target_vers in
                3.* ) ipsw_canjailbreak=0
                    ipsw_prepare_usepowder=0 ;;
                4.1 ) 
                    ipsw_canjailbreak=0
                    ipsw_prepare_usepowder=0 ;; 
                * ) ipsw_canjailbreak=1
                    device_target_other=1
                    ipsw_prepare_usepowder=1 ;;
            esac
            ipsw_openssh=1
        fi
        log 本机型号:$device_type
        log 目标版本:$device_target_vers
        log 目标构建版本:$device_target_build
    else
        ipsw_justboot_path=$ipsw_path
    fi
}


shsh_select_old (){
    local localshshpath=$lib/shsh
    if [[ $1 != cp ]]; then
        if [ ! -d "$localshshpath" ]; then
            mkdir -p $localshshpath
        fi
        if [[ $use_powder == 1 ]]; then
            case $device_type in
                "iPod3,1" ) ver=5.1.1 ;;       
                "iPod5,1" ) ver=7.1.x ;;
                * ) error 本设备无法使用powdersn0w降级,可以使用SHSH/强制降级 ; exit 1 ;;
            esac
        else
            local ver=$device_target_vers
        fi
        while true; do
            if [[ $ver != 5.1.1 ]]; then
                log 选择iOS${ver}SHSH
                    shsh_path="$($zenity --file-selection --multiple --file-filter='SHSH | *.bshsh2 *.shsh *.shsh2' --title="Select SHSH file(s)")"
                    if [ ! -f "$shsh_path" ]; then
                        echo "错误：文件 $shsh_path 不存在！"
                        continue
                    else
                        break
                    fi
            else
                shsh_save_tss
                break
            fi   
        done
    else
        if [[ $use_futurerestore != 1 ]] && [[ $flash_mode != tethered ]] && [[ $flash_mode == powder && $device_type != "iPod3,1" ]]; then
            cp $shsh_path $localshshpath/$(basename "$shsh_path")
            mv $localshshpath/$(basename "$shsh_path") $localshshpath/$device_ecid-${device_type}-${device_target_vers}.shsh
        fi
    fi
}

ipsw_prepare() {
    case $device_proc in
        4 )
            if [[ $device_target_tethered == 1 ]]; then
                ipsw_prepare_tethered
                log use ipsw_prepare_tethered
            elif [[ $device_target_other == 1 || $ipsw_gasgauge_patch == 1 ]] ||
                 [[ $device_target_vers == "$device_latest_vers" && $ipsw_jailbreak == 1 ]]; then
                case $device_type in
                    iPhone2,1 ) ipsw_prepare_jailbreak;;
                    iPod2,1 ) ipsw_prepare_custom;;
                    * ) ipsw_prepare_32bit;;
                esac
            elif [[ $device_target_powder == 1 ]] && [[ $device_target_vers == "3"* || $device_target_vers == "4"* ]]; then
                #shsh_save version $device_latest_vers
                case $device_target_vers in
                    "4.3"* ) log use ipsw_prepare_powder ; ipsw_prepare_ios4powder;;
                    * ) ipsw_prepare_ios4multipart;;
                esac
            elif [[ $device_target_powder == 1 ]]; then
                log use ipsw_prepare_powder
                ipsw_prepare_powder
            elif [[ $device_target_vers != "$device_latest_vers" ]]; then
                ipsw_prepare_custom
            fi
            if [[ $ipsw_isbeta == 1 && $ipsw_prepare_ios4multipart_patch != 1 ]] ||
               [[ $device_target_vers == "3.2"* && $ipsw_prepare_ios4multipart_patch != 1 ]] ||
               [[ $ipsw_gasgauge_patch == 1 ]]; then
                ipsw_prepare_multipatch
            fi
        ;;

        [56] )
            # 32-bit devices A5/A6
            if [[ $device_target_tethered == 1 ]]; then
                ipsw_prepare_tethered
            elif [[ $device_target_powder == 1 ]]; then
                ipsw_prepare_powder
            elif [[ $ipsw_jailbreak == 1 && $device_target_other != 1 ]]; then
                ipsw_prepare_jailbreak
            elif [[ $device_target_vers != "$device_latest_vers" || $ipsw_gasgauge_patch == 1 ]]; then
                ipsw_prepare_32bit
            fi
            if [[ $ipsw_fourthree == 1 ]]; then
                ipsw_prepare_fourthree_part2
            elif [[ $ipsw_isbeta == 1 || $ipsw_gasgauge_patch == 1 ]]; then
                case $device_target_vers in
                    [59] ) :;;
                    * ) ipsw_prepare_multipatch;;
                esac
            fi
        ;;
    esac
}

ipsw_prepare_32bit() {
    local ExtraArgs
    local daibutsu
    local JBFiles=()
    # redirect to ipsw_prepare_jailbreak for 4.1 and lower
    case $device_target_vers in
        [23]* | 4.[01]* ) ipsw_prepare_jailbreak $1; return;;
    esac
    local ipsws=$(find "$saved" -type f -name "custom*.ipsw" 2>/dev/null)
    ipsw_prepare_bundle $daibutsu
    if [[ "$device_target_vers" == "4.1" ]]; then
        local ipsw_prepare_usepowder=0
    fi
    ipsw_prepare_usepowder=1
    #if [[ $ipsw_memory == 1 ]]; then
        ExtraArgs+=" -memory"
    #fi
    ExtraArgs+=" -ramdiskgrow 10"
    if [[ $ipsw_jailbreak == 1 ]]; then
        case $device_target_vers in
            9.3.[1234] | 9.3 ) JBFiles+=("untetherhomedepot.tar");;
            9.2* | 9.1 )       JBFiles+=("untetherhomedepot921.tar");;
            9.0* )             JBFiles+=("everuntether.tar");;
            7.1* ) # remove for lyncis
                case $device_type in
                    iPod* ) JBFiles+=("panguaxe-ipod.tar");;
                    *     ) JBFiles+=("panguaxe.tar");;
                esac
            ;;
            7.0* ) # remove for lyncis 7.0.x
                if [[ $device_type == "iPhone5,3" || $device_type == "iPhone5,4" ]] && [[ $device_target_vers == "7.0" ]]; then
                    JBFiles+=("evasi0n7-untether-70.tar")
                else
                    JBFiles+=("evasi0n7-untether.tar")
                fi
            ;;
            6.1.[3456] )   JBFiles+=("p0sixspwn.tar");;
            6* )           JBFiles+=("evasi0n6-untether.tar");;
            5* | 4.[32]* ) JBFiles+=("g1lbertJB/${device_type}_${device_target_build}.tar");;
        esac
        if [[ -n ${JBFiles[0]} ]]; then
            JBFiles[0]=$jelbrek/${JBFiles[0]}
        fi
        case $device_target_vers in
            [98]* ) JBFiles+=("$jelbrek/fstab8.tar");;
            7* ) JBFiles+=("$jelbrek/fstab7.tar");;
            4* ) JBFiles+=("$jelbrek/fstab_old.tar");;
            * )  JBFiles+=("$jelbrek/fstab_rw.tar");;
        esac
        case $device_target_vers in
            4.3* )
                if [[ $device_type == "iPad2"* ]]; then
                    JBFiles[0]=
                fi
            ;;
            4.2.9 | 4.2.10 ) JBFiles[0]=;;
            4.2.1 )
                if [[ $device_type != "iPhone1,2" ]]; then
                    ExtraArgs+=" -punchd"
                    JBFiles[0]=$jelbrek/greenpois0n/${device_type}_${device_target_build}.tar
                fi
            ;;
        esac
        JBFiles+=("$jelbrek/freeze.tar")
        if [[ $device_target_vers == "9.0"* ]]; then
            JBFiles+=("$jelbrek/launchctl.tar")
        elif [[ $device_target_vers == "9"* ]]; then
            JBFiles+=("$jelbrek/daemonloader.tar" "$jelbrek/launchctl.tar")
        elif [[ $device_target_vers == "5"* ]]; then
            JBFiles+=("$jelbrek/cydiasubstrate.tar" "$jelbrek/g1lbertJB.tar")
        fi
        if [[ $ipsw_openssh == 1 ]]; then
            JBFiles+=("$jelbrek/sshdeb.tar")
        fi
        if [[ $device_target_tethered == 1 ]]; then
            case $device_target_vers in
                5* | 4.3* ) JBFiles+=("$jelbrek/g1lbertJB/install.tar");;
            esac
        fi
    fi
    cp -r $tmp/FirmwareBundles $lib/
    log "Preparing custom IPSW: $powdersn0w $ipsw_path $tmp/temp.ipsw $ExtraArgs ${JBFiles[*]}"
    cd $lib
    ./powdersn0w "$ipsw_path" $tmp/temp.ipsw $ExtraArgs ${JBFiles[@]}

    if [[ ! -e $tmp/temp.ipsw ]]; then
        if [[ $platform == "macos" && $platform_arch == "arm64" ]]; then
            warn "Updating to macOS 14.6 or newer is recommended for Apple Silicon Macs to resolve issues."
        fi
        error "Failed to find custom IPSW. Please run the script again" \
        #"* You may try selecting N for memory option"
    fi
    if [[ $device_target_vers == "4"* ]]; then
        ipsw_prepare_ios4patches
        log "Add all to custom IPSW"
        cd $tmp/iOS4Patches
        zip -r0 $tmp/temp.ipsw Firmware/dfu/*
    fi
    #ipsw_custom="${device_type}_${device_target_vers}_${device_target_build}_Custom"
    #if [[ -n $1 ]]; then
    #    ipsw_custom="../$1_Custom"
    #fi
    #if [[ $ipsw_jailbreak == 1 ]]; then
    #    ipsw_custom+="J"
    #else
    #   ipsw_custom+="V"
    #fi
    mv $tmp/temp.ipsw $saved/ipsws/$ipsw_custom.ipsw
}

ipsw_prepare_jailbreak() {
    #debug $ipsw_jailbreak
    #read -p 1
    local ipsws=$(find "$saved" -type f -name "custom*.ipsw" 2>/dev/null)
    if [[ -e "$ipsws" ]]; then
        log "找到之前制作的自制固件,跳过制作"
        return
    fi
    local ExtraArgs=
    local JBFiles=()
    local JBFiles2=()
    local daibutsu=$1

if [[ $ipsw_jailbreak == 1 ]]; then
    JBFiles+=("fstab_rw.tar" "freeze.tar")
    case $device_target_vers in
        6.1.[3456] ) JBFiles+=("p0sixspwn.tar");;
        6* ) JBFiles+=("evasi0n6-untether.tar");;
        4.1 | 4.0* ) JBFiles+=("greenpois0n/${device_type}_${device_target_build}.tar");;
        5* | 4.[32]* ) JBFiles+=("g1lbertJB/${device_type}_${device_target_build}.tar");;
    esac
    case $device_target_vers in
        [43]* ) JBFiles[0]="fstab_old.tar"
    esac
    for i in {0..1}; do
        JBFiles[i]=$jelbrek/${JBFiles[$i]}
    done
    JBFiles[2]=$jelbrek/${JBFiles[2]}
    case $device_target_vers in
        [543]* ) JBFiles+=("$jelbrek/cydiasubstrate.tar");;
    esac
    if [[ $device_target_vers == "5"* ]]; then
        JBFiles+=("$jelbrek/g1lbertJB.tar")
    fi
    if [[ $device_target_tethered == 1 ]]; then
        case $device_target_vers in
            5* | 4.3* ) JBFiles+=("$jelbrek/g1lbertJB/install.tar");;
        esac
    fi

        ExtraArgs+=" -S 30" # system partition add
        if [[ $ipsw_openssh == 1 ]]; then
            JBFiles+=("$jelbrek/sshdeb.tar")
        fi
fi

    ipsw_prepare_bundle $daibutsu

    if [[ $ipsw_memory == 1 ]]; then
        ExtraArgs+=" -memory"
    fi
    ExtraArgs+=" -ramdiskgrow 10"
    #ExtraArgs+=" -bbupdate"
    cp -r $tmp/FirmwareBundles $lib/
    log "Preparing custom IPSW: $ipsw $ipsw_path temp.ipsw $ExtraArgs ${JBFiles[*]}"
    cd $lib 
    ./ipsw "$ipsw_path" $tmp/temp.ipsw $ExtraArgs ${JBFiles[@]}
    #ipsw_custom="${device_type}_${device_target_vers}_${device_target_build}_Custom"
    #if [[ -n $1 ]]; then
    #    ipsw_custom="../$1_Custom"
    #fi
    #if [[ $ipsw_jailbreak == 1 ]]; then
    #    ipsw_custom+="J"
    #else
    #   ipsw_custom+="V"
    #fi
    if [[ ! -e $tmp/temp.ipsw ]]; then
        error "Failed to find custom IPSW. Please run the script again" \
        "* You may try selecting N for memory option"
    fi


    mv $tmp/temp.ipsw $saved/ipsws/$ipsw_custom.ipsw
}

ipsw_prepare_jailbreak() {
    #debug $ipsw_jailbreak
    #read -p 1
    local ipsws=$(find "$customipsws" -type f -name "custom*.ipsw" 2>/dev/null)
    if [[ -e "$ipsws" ]]; then
        log "找到之前制作的自制固件,跳过制作"
        return
    fi
    local ExtraArgs=
    local JBFiles=()
    local JBFiles2=()
    local daibutsu=$1

if [[ $ipsw_jailbreak == 1 ]]; then
    JBFiles+=("fstab_rw.tar" "freeze.tar")
    case $device_target_vers in
        6.1.[3456] ) JBFiles+=("p0sixspwn.tar");;
        6* ) JBFiles+=("evasi0n6-untether.tar");;
        4.1 | 4.0* ) JBFiles+=("greenpois0n/iPod3,1_${device_target_build}.tar");;
        5* | 4.[32]* ) JBFiles+=("g1lbertJB/iPod3,1_${device_target_build}.tar");;
    esac
    case $device_target_vers in
        [43]* ) JBFiles[0]="fstab_old.tar"
    esac
    for i in {0..1}; do
        JBFiles[i]=$jelbrek/${JBFiles[$i]}
    done
    JBFiles[2]=$jelbrek/${JBFiles[2]}
    case $device_target_vers in
        [543]* ) JBFiles+=("$jelbrek/cydiasubstrate.tar");;
    esac
    if [[ $device_target_vers == "5"* ]]; then
        JBFiles+=("$jelbrek/g1lbertJB.tar")
    fi
    if [[ $device_target_tethered == 1 ]]; then
        case $device_target_vers in
            5* | 4.3* ) JBFiles+=("$jelbrek/g1lbertJB/install.tar");;
        esac
    fi

        ExtraArgs+=" -S 30" # system partition add
        if [[ $ipsw_openssh == 1 ]]; then
            JBFiles+=("$jelbrek/sshdeb.tar")
        fi
fi

    ipsw_prepare_bundle $daibutsu

    if [[ $ipsw_memory == 1 ]]; then
        ExtraArgs+=" -memory"
    fi
    ExtraArgs+=" -ramdiskgrow 10"
    #ExtraArgs+=" -bbupdate"
    cp -r $tmp/FirmwareBundles $lib/
    log "Preparing custom IPSW: $ipsw $ipsw_path temp.ipsw $ExtraArgs ${JBFiles[*]}"
    cd $lib 
    ./ipsw "$ipsw_path" $tmp/temp.ipsw $ExtraArgs ${JBFiles[@]}
    if [[ ! -e $tmp/temp.ipsw ]]; then
        error "Failed to find custom IPSW. Please run the script again" \
        "* You may try selecting N for memory option"
    fi


    mv $tmp/temp.ipsw $saved/ipsws/$ipsw_custom.ipsw
}

ipsw_prepare_custom() {
    if [[ -e "$ipsw_custom.ipsw" ]]; then
        log "Found existing Custom IPSW. Skipping IPSW creation."
        return
    elif [[ $device_target_vers == "4.1" && $ipsw_jailbreak != 1 ]]; then
        log "No need to create custom IPSW for non-jailbroken restores on $device_type-$device_target_build"
        return
    fi

    ipsw_prepare_jailbreak old

    mv "$ipsw_custom.ipsw" temp.ipsw
    if [[ $ipsw_24o == 1 ]]; then # old bootrom ipod2,1 3.1.3
        ipsw_prepare_patchcomp LLB
        mv temp.ipsw "$ipsw_custom.ipsw"
        return
    elif [[ $device_type == "iPod2,1" && $device_target_vers == "3.1.3" ]]; then # new bootrom ipod2,1 3.1.3
        mv temp.ipsw "$ipsw_custom.ipsw"
        return
    fi

    case $device_target_vers in
        $device_latest_vers | 4.1 ) :;;
        3.0* )
            ipsw_prepare_patchcomp LLB
            log "Patch Kernelcache"
            unzip -o -j "$ipsw_path.ipsw" kernelcache.release.s5l8920x
            mv kernelcache.release.s5l8920x kernelcache.orig
            $bspatch kernelcache.orig kernelcache.release.s5l8920x ../resources/firmware/FirmwareBundles/Down_iPhone2,1_${device_target_vers}_${device_target_build}.bundle/kernelcache.release.patch
            zip -r0 temp.ipsw kernelcache.release.s5l8920x
        ;;
        * )
            ipsw_prepare_patchcomp LLB
            local bootargs="$device_bootargs_default"
            if [[ $ipsw_verbose == 1 ]]; then
                bootargs="pio-error=0 -v"
            fi
            if [[ $device_target_vers == "3"* ]]; then
                bootargs+=" amfi=0xff cs_enforcement_disable=1"
            fi
            local path="Firmware/all_flash/all_flash.${device_model}ap.production"
            local name="iBoot.${device_model}ap.RELEASE.img3"
            patch_iboot -b "$bootargs"
            mkdir -p $path
            mv $name $path/$name
            zip -r0 temp.ipsw $path/$name
        ;;
    esac
    mv temp.ipsw "$ipsw_custom.ipsw"
}

ipsw_prepare_patchcomp() {
    local path="$all_flash/"
    local name="LLB.${device_model}ap.RELEASE"
    local name41
    local ext="img3"
    local patch
    local iv
    local key

    if [[ $1 == "Kernelcache" ]]; then
        path=
        name="kernelcache.release"
        ext="s5l8900x"
        patch="../resources/patch/$name.$ext.p2"
        log "Patch $1"
        file_extract_from_archive temp.ipsw $name.$ext
        mv $name.$ext kc.orig
        $bspatch kc.orig $name.$ext $patch.patch
        zip -r0 temp.ipsw $name.$ext
        return
    fi

    if [[ $1 == "WTF2" ]]; then
        path="Firmware/dfu/"
        name="WTF.s5l8900xall.RELEASE"
        ext="dfu"
    elif [[ $1 == "iBoot" ]]; then
        name="iBoot.${device_model}ap.RELEASE"
    elif [[ $1 == "iB"* ]]; then
        path="Firmware/dfu/"
        name="$1.${device_model}ap.RELEASE"
        ext="dfu"
    elif [[ $1 == "RestoreRamdisk" ]]; then
        path=
        name="018-6494-014"
        ext="dmg"
        iv=25e713dd5663badebe046d0ffa164fee
        key=7029389c2dadaaa1d1e51bf579493824
        if [[ $device_target_vers == "4"* ]]; then
            name="018-7079-079"
            iv=a0fc6ca4ef7ef305d975e7f881ddcc7f
            key=18eab1ba646ae018b013bc959001fbde
            if [[ $device_target_vers == "4.2.1" ]]; then
                name41="$name"
                name="038-0029-002"
            fi
        fi
    elif [[ $1 == "RestoreDeviceTree" ]]; then
        name="DeviceTree.${device_model}ap"
    elif [[ $1 == "RestoreKernelCache" ]]; then
        path=
        name="kernelcache.release"
        ext="$device_model"
    fi
    patch="../resources/firmware/FirmwareBundles/Down_${device_type}_${device_target_vers}_${device_target_build}.bundle/$name.patch"
    local saved_path="../saved/$device_type/8B117"
    if [[ $1 == "RestoreRamdisk" ]]; then
        local ivkey
        if [[ $device_target_vers == "4"* || $device_type == *"1,1" ]]; then
            ivkey="-iv $iv -k $key"
        fi
        log "Patch $1"
        if [[ $device_target_vers == "4.2.1" ]]; then
            mkdir -p $saved_path 2>/dev/null
            if [[ -s $saved_path/$name41.$ext ]]; then
                cp $saved_path/$name41.$ext $name.$ext
            else
                ipsw_get_url 8B117
                "$pzb" -g $name41.$ext -o $name.$ext "$ipsw_url"
                cp $name.$ext $saved_path/$name41.$ext
            fi
        else
            file_extract_from_archive "$ipsw_path.ipsw" $name.$ext
        fi
        mv $name.$ext rd.orig
        "$xpwntool" rd.orig rd.dec -iv $iv -k $key
        $bspatch rd.dec rd.patched "$patch"
        "$xpwntool" rd.patched $name.$ext -t rd.orig $ivkey
        zip -r0 temp.ipsw $name.$ext
        return
    fi
    log "Patch $1"
    if [[ $device_target_vers == "4.2.1" ]] && [[ $1 == "RestoreDeviceTree" || $1 == "RestoreKernelCache" ]]; then
        mkdir -p $saved_path 2>/dev/null
        if [[ -s $saved_path/$name.$ext ]]; then
            cp $saved_path/$name.$ext $name.$ext
        else
            ipsw_get_url 8B117
            "$pzb" -g ${path}$name.$ext -o $name.$ext "$ipsw_url"
            cp $name.$ext $saved_path/$name.$ext
        fi
        mkdir Downgrade 2>/dev/null
        if [[ $1 == "RestoreKernelCache" ]]; then
            local ivkey="-iv 7238dcea75bf213eff209825a03add51 -k 0295d4ef87b9db687b44f54c8585d2b6"
            "$xpwntool" $name.$ext kernelcache $ivkey
            $bspatch kernelcache kc.patched ../resources/patch/$name.$ext.patch
            "$xpwntool" kc.patched Downgrade/$1 -t $name.$ext $ivkey
        else
            mv $name.$ext Downgrade/$1
        fi
        zip -r0 temp.ipsw Downgrade/$1
        return
    else
        file_extract_from_archive "$ipsw_path.ipsw" ${path}$name.$ext
    fi
    $bspatch $name.$ext $name.patched $patch
    mkdir -p $path
    mv $name.patched ${path}$name.$ext
    zip -r0 temp.ipsw ${path}$name.$ext
}

ipsw_prepare_bundle() {
    device_fw_key_check $1
    local ipsw_path="$ipsw_path"
    local key="$device_fw_key"
    local vers="$device_target_vers"
    local build="$device_target_build"
    local hw="$device_model"
    local base_build="11D257"
    local RootSize
    local daibutsu
    FirmwareBundle="$tmp/FirmwareBundles/"
    if [[ $1 == "daibutsu" ]]; then
        daibutsu=1
    fi
    if [[ "$device_target_vers" == "4.1" ]]; then
        local ipsw_prepare_usepowder=0
    fi
    #debug bundle $ipsw_prepare_usepowder
    #read -p debug
    mkdir $tmp/FirmwareBundles 2>/dev/null
    if [[ $1 == "base" ]]; then
        local ipsw_path="$ipsw_base_path"
        local key="$device_fw_key_base"
        local vers="$device_base_vers"
        local build="$device_base_build"
        FirmwareBundle+="BASE_"
    elif [[ $1 == "target" ]]; then
        if [[ $ipsw_jailbreak == 1 ]]; then
            case $vers in
                [689]* ) ipsw_prepare_config true true;;
                * ) ipsw_prepare_config false true;;
            esac
        else
            ipsw_prepare_config false true
        fi
    elif [[ $ipsw_jailbreak == 1 ]]; then
        ipsw_prepare_config false true
    else
        ipsw_prepare_config false false
    fi
    local FirmwareBundle2="$script_dir/resources/firmware/FirmwareBundles/Down_${device_type}_${vers}_${build}.bundle"
    if [[ $ipsw_prepare_usepowder == 1 ]]; then
        FirmwareBundle2=
    elif [[ -d $FirmwareBundle2 ]]; then
        FirmwareBundle+="Down_"
    fi
    FirmwareBundle+="${device_type}_${vers}_${build}.bundle"
    local NewPlist=$FirmwareBundle/Info.plist
    mkdir -p $FirmwareBundle

    log "Generating firmware bundle for $device_type-$vers ($build) $1..."
    log $ipsw_path
    unzip -o -j "$ipsw_path" $all_flash/manifest -d $FirmwareBundle/
    #mv manifest $FirmwareBundle/
    local ramdisk_name=$(echo "$key" | $jq -j '.keys[] | select(.image == "RestoreRamdisk") | .filename')
    local RamdiskIV=$(echo "$key" | $jq -j '.keys[] | select(.image == "RestoreRamdisk") | .iv')
    local RamdiskKey=$(echo "$key" | $jq -j '.keys[] | select(.image == "RestoreRamdisk") | .key')
    #debug $key
    #debug $ramdisk_name
    #debug $RamdiskIV
    #debug $RamdiskKey
    if [[ -z $ramdisk_name ]]; then
        error "Issue with firmware keys: Failed getting RestoreRamdisk. Check The Apple Wiki or your wikiproxy"
    fi
    unzip -o -j "$ipsw_path" $ramdisk_name -d $tmp/
    #debug 1
    "$xpwntool" $tmp/$ramdisk_name $tmp/Ramdisk.raw -iv $RamdiskIV -k $RamdiskKey
    #debug 2
    "$hfsplus" $tmp/Ramdisk.raw extract usr/local/share/restore/options.$device_model.plist
    mv options.$device_model.plist $tmp/options.$device_model.plist
    #debug 3
    if [[ ! -s $tmp/options.$device_model.plist ]]; then
        rm $tmp/options.$device_model.plist
        "$hfsplus" $tmp/Ramdisk.raw extract usr/local/share/restore/options.plist
        mv options.plist $tmp/options.$device_model.plist 
    fi
    #debug 4
    local ver2="${device_target_vers:0:1}"
    if [[ ! -s $tmp/options.${device_model}.plist ]] && (( ver2 >= 4 )); then
        error "Failed to extract options plist from restore ramdisk. Probably an issue with firmware keys."
    fi
    #read -p debug
    if [[ $device_target_vers == "3.2"* ]]; then
        RootSize=1000
    elif [[ $ver2 == 3 ]]; then
        case $device_type in
            iPhone1,* | iPod1,1 ) RootSize=420;;
            iPod2,1 ) RootSize=450;;
            *       ) RootSize=750;;
        esac
    elif [[ $platform == "macos" ]]; then
        plutil -extract 'SystemPartitionSize' xml1 $tmp/options.${device_model}.plist -o size
        RootSize=$(cat size | sed -ne '/<integer>/,/<\/integer>/p' | sed -e "s/<integer>//" | sed "s/<\/integer>//" | sed '2d')
    else
        RootSize=$(cat $tmp/options.${device_model}.plist | grep -i SystemPartitionSize -A 1 | grep -oPm1 "(?<=<integer>)[^<]+")
    fi
    RootSize=$((RootSize+30))
    local rootfs_name="$(echo "$key" | $jq -j '.keys[] | select(.image == "RootFS") | .filename')"
    local rootfs_key="$(echo "$key" | $jq -j '.keys[] | select(.image == "RootFS") | .key')"
    if [[ -z $rootfs_name ]]; then
        error "Issue with firmware keys: Failed getting RootFS. Check The Apple Wiki or your wikiproxy"
    fi
    echo '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict>' > $NewPlist
    echo "<key>Filename</key><string>$ipsw_path</string>" >> $NewPlist
    echo "<key>RootFilesystem</key><string>$rootfs_name</string>" >> $NewPlist
    echo "<key>RootFilesystemKey</key><string>$rootfs_key</string>" >> $NewPlist
    echo "<key>RootFilesystemSize</key><integer>$RootSize</integer>" >> $NewPlist
    printf "<key>RamdiskOptionsPath</key><string>/usr/local/share/restore/options" >> $NewPlist
    if [[ $device_target_vers != "3"* && $device_target_vers != "4"* ]] ||
       [[ $device_type == "iPad1,1" && $device_target_vers == "4"* ]]; then
        printf ".%s" "$device_model" >> $NewPlist
    fi
    echo ".plist</string>" >> $NewPlist
    if [[ $1 == "base" ]]; then
        device_base_sha1=$($sha1sum "$ipsw_path" | awk '{print $1}')
        echo "<key>SHA1</key><string>$device_base_sha1</string>" >> $NewPlist
    else
        device_target_sha1=$($sha1sum "$ipsw_path" | awk '{print $1}')
        echo "<key>SHA1</key><string>$device_target_sha1</string>" >> $NewPlist
    fi

    if [[ $1 == "base" ]]; then
        case $device_type in
            iPhone5,[12] ) hw="iphone5";;
            iPhone5,[34] ) hw="iphone5b";;
            iPad3,[456] )  hw="ipad3b";;
        esac
        case $device_base_build in
            "11A"* | "11B"* ) base_build="11B554a";;
            "9"* ) base_build="9B206";;
        esac
        echo "<key>RamdiskExploit</key><dict>" >> $NewPlist
        echo "<key>exploit</key><string>src/target/$hw/$base_build/exploit</string>" >> $NewPlist
        echo "<key>inject</key><string>src/target/$hw/$base_build/partition</string></dict>" >> $NewPlist
    elif [[ $1 == "target" ]]; then
        echo "<key>FilesystemPackage</key><dict><key>bootstrap</key><string>freeze.tar</string>" >> $NewPlist
        case $vers in
            8* | 9* ) echo "<key>package</key><string>src/ios9.tar</string>" >> $NewPlist;;
        esac
        printf "</dict><key>RamdiskPackage</key><dict><key>package</key><string>src/bin.tar</string><key>ios</key><string>ios" >> $NewPlist
        case $vers in
            3* ) printf "3" >> $NewPlist;;
            4* ) printf "4" >> $NewPlist;;
            5* ) printf "5" >> $NewPlist;;
            6* ) printf "6" >> $NewPlist;;
            7* ) printf "7" >> $NewPlist;; # remove for lyncis
            #7.0* ) printf "70" >> $NewPlist;; # remove 7.0* and change 7.1* to 7* for lyncis 7.0.x
            #7.1* ) printf "71" >> $NewPlist;;
            8* ) printf "8" >> $NewPlist;;
            9* ) printf "9" >> $NewPlist;;
        esac
        echo "</string></dict>" >> $NewPlist
    elif [[ $ipsw_prepare_usepowder == 1 ]]; then
        echo "<key>FilesystemPackage</key><dict/><key>RamdiskPackage</key><dict/>" >> $NewPlist
    elif [[ $ipsw_isbeta == 1 && $ipsw_prepare_usepowder != 1 ]]; then
        warn "iOS 4.1 beta or older detected. Attempting workarounds"
        cp $FirmwareBundle2/* $FirmwareBundle
        echo "<key>RamdiskPatches</key><dict/>" >> $NewPlist
        echo "<key>FilesystemPatches</key><dict/>" >> $NewPlist
        ipsw_isbeta_needspatch=1
    elif [[ -d $FirmwareBundle2 ]]; then
        cp $FirmwareBundle2/* $FirmwareBundle
        echo "<key>RamdiskPatches</key><dict>" >> $NewPlist
        echo "<key>asr</key><dict>" >> $NewPlist
        echo "<key>File</key><string>usr/sbin/asr</string><key>Patch</key><string>asr.patch</string></dict>" >> $NewPlist
        if [[ -s $FirmwareBundle/restoredexternal.patch ]]; then
            echo "<key>restoredexternal</key><dict>" >> $NewPlist
            echo "<key>File</key><string>usr/local/bin/restored_external</string><key>Patch</key><string>restoredexternal.patch</string></dict>" >> $NewPlist
        fi
        echo "</dict>" >> $NewPlist
        if [[ $ipsw_hacktivate == 1 ]]; then
            echo "<key>FilesystemPatches</key><dict>" >> $NewPlist
            echo "<key>Hacktivation</key><array><dict>" >> $NewPlist
            echo "<key>Action</key><string>Patch</string><key>File</key><string>usr/libexec/lockdownd</string>" >> $NewPlist
            echo "<key>Patch</key><string>lockdownd.patch</string></dict></array></dict>" >> $NewPlist
        else
            echo "<key>FilesystemPatches</key><dict/>" >> $NewPlist # ipsw segfaults if this is missing lol
        fi
    fi

    if [[ $1 == "base" ]]; then
        echo "<key>Firmware</key><dict/>" >> $NewPlist
    elif [[ $1 == "target" && $vers == "4"* ]]; then
        echo "<key>Firmware</key><dict>" >> $NewPlist
        ipsw_prepare_keys iBSS $1
        ipsw_prepare_keys RestoreRamdisk $1
        echo "</dict>" >> $NewPlist
    elif [[ $ipsw_isbeta_needspatch == 1 ]]; then
        echo "<key>FirmwarePatches</key><dict>" >> $NewPlist
        ipsw_prepare_keys RestoreDeviceTree $1
        ipsw_prepare_keys RestoreLogo $1
        ipsw_prepare_keys RestoreKernelCache $1
        ipsw_prepare_keys RestoreRamdisk $1
        echo "</dict>" >> $NewPlist
    elif [[ $device_target_build == "14"* ]]; then
        echo "<key>Firmware</key><dict>" >> $NewPlist
        ipsw_prepare_keys iBSS
        ipsw_prepare_keys iBEC
        ipsw_prepare_keys RestoreRamdisk
    else
        if [[ $ipsw_prepare_usepowder == 1 ]]; then
            echo "<key>Firmware</key><dict>" >> $NewPlist
        else
            echo "<key>FirmwarePatches</key><dict>" >> $NewPlist
        fi
        ipsw_prepare_keys iBSS $1
        # ios 4 and lower do not need ibec patches. the exception is the ipad lineup
        if [[ $vers != "3"* && $vers != "4"* ]] || [[ $device_type == "iPad1,1" || $device_type == "iPad2"* ]]; then
            ipsw_prepare_keys iBEC $1
        fi
        if [[ $device_proc == 1 && $device_target_vers != "4.2.1" ]]; then
            :
        else
            ipsw_prepare_keys RestoreDeviceTree $1
            ipsw_prepare_keys RestoreLogo $1
        fi
        if [[ $1 == "target" ]]; then
            case $vers in
                [457]* ) ipsw_prepare_keys RestoreKernelCache $1;;
                * ) ipsw_prepare_keys KernelCache $1;;
            esac
        elif [[ $device_proc == 1 && $device_target_vers == "4.2.1" ]]; then
            ipsw_prepare_keys RestoreKernelCache $1
        elif [[ $device_proc != 1 && $device_target_vers != "3.0"* ]]; then
            ipsw_prepare_keys RestoreKernelCache $1
        fi
        ipsw_prepare_keys RestoreRamdisk $1
        if [[ $1 == "old" ]]; then
            if [[ $ipsw_24o == 1 ]]; then # old bootrom ipod2,1 3.1.3
                ipsw_prepare_keys iBoot $1
                ipsw_prepare_keys KernelCache $1
            elif [[ $device_type == "iPod2,1" && $device_target_vers == "3.1.3" ]]; then
                : # dont patch iboot/kcache for new bootrom ipod2,1 3.1.3
            elif [[ $device_proc == 1 ]]; then
                ipsw_prepare_keys KernelCache $1
                ipsw_prepare_keys WTF2 $1
            else
                case $device_target_vers in
                    $device_latest_vers | 4.1 ) :;;
                    3.0* ) ipsw_prepare_keys iBoot $1;;
                    * )
                        ipsw_prepare_keys iBoot $1
                        ipsw_prepare_keys KernelCache $1
                    ;;
                esac
            fi
        fi
        echo "</dict>" >> $NewPlist
    fi

    if [[ $1 == "base" ]]; then
        echo "<key>FirmwarePath</key><dict>" >> $NewPlist
        ipsw_prepare_paths AppleLogo $1
        ipsw_prepare_paths BatteryCharging0 $1
        ipsw_prepare_paths BatteryCharging1 $1
        ipsw_prepare_paths BatteryFull $1
        ipsw_prepare_paths BatteryLow0 $1
        ipsw_prepare_paths BatteryLow1 $1
        ipsw_prepare_paths BatteryPlugin $1
        ipsw_prepare_paths RecoveryMode $1
        ipsw_prepare_paths LLB $1
        ipsw_prepare_paths iBoot $1
        echo "</dict>" >> $NewPlist
    elif [[ $1 == "target" ]]; then
        echo "<key>FirmwareReplace</key><dict>" >> $NewPlist
        if [[ $vers == "4"* ]]; then
            ipsw_prepare_paths APTicket $1
        fi
        ipsw_prepare_paths AppleLogo $1
        ipsw_prepare_paths NewAppleLogo $1
        ipsw_prepare_paths BatteryCharging0 $1
        ipsw_prepare_paths BatteryCharging1 $1
        ipsw_prepare_paths BatteryFull $1
        ipsw_prepare_paths BatteryLow0 $1
        ipsw_prepare_paths BatteryLow1 $1
        ipsw_prepare_paths BatteryPlugin $1
        ipsw_prepare_paths RecoveryMode $1
        ipsw_prepare_paths NewRecoveryMode $1
        ipsw_prepare_paths LLB $1
        ipsw_prepare_paths iBoot $1
        ipsw_prepare_paths NewiBoot $1
        ipsw_prepare_paths manifest $1
        echo "</dict>" >> $NewPlist
    fi

    if [[ $daibutsu == 1 ]]; then
        if [[ $ipsw_prepare_usepowder == 1 ]]; then
            echo "<key>RamdiskPackage2</key>" >> $NewPlist
        else
            echo "<key>PackagePath</key><string>./freeze.tar</string>" >> $NewPlist
            echo "<key>RamdiskPackage</key>" >> $NewPlist
        fi
        echo "<string>./bin.tar</string><key>RamdiskReboot</key><string>./reboot.sh</string><key>UntetherPath</key><string>./untether.tar</string>" >> $NewPlist
        local hwmodel="$(tr '[:lower:]' '[:upper:]' <<< ${device_model:0:1})${device_model:1}"
        echo "<key>hwmodel</key><string>$hwmodel</string>" >> $NewPlist
    fi

    echo "</dict></plist>" >> $NewPlist
    cat $NewPlist
}

ipsw_prepare_ios4patches() {
    local device_model=${device_model}ap
    local comps=("iBSS" "iBEC")
    local iv
    local key
    local name
    local path="Firmware/dfu/"
    local tmp=$tmp/iOS4Patches
    log "Applying iOS 4 patches"
    mkdir -p $tmp/$all_flash $tmp/$path
    for getcomp in "${comps[@]}"; do
        iv=$(echo $device_fw_key | $jq -j '.keys[] | select(.image == "'$getcomp'") | .iv')
        key=$(echo $device_fw_key | $jq -j '.keys[] | select(.image == "'$getcomp'") | .key')
        name="$getcomp.$device_model.RELEASE.dfu"
        log "Make $getcomp"
        unzip -o -j "$ipsw_path" $path$name -d $tmp
        mv $tmp/$name $tmp/$getcomp.orig
        "$xpwntool" $tmp/$getcomp.orig $tmp/$getcomp.dec -iv $iv -k $key
        "$iBoot32Patcher" $tmp/$getcomp.dec $tmp/$getcomp.patched --rsa --debug -b "rd=md0 -v amfi=0xff cs_enforcement_disable=1 pio-error=0"
        "$xpwntool" $tmp/$getcomp.patched $tmp/$path$name -t $tmp/$getcomp.orig
    done
}


ipsw_prepare_keys() {
    local comp="$1"
    local getcomp="$1"
    case $comp in
        "RestoreLogo" ) getcomp="AppleLogo";;
        *"KernelCache" ) getcomp="Kernelcache";;
        "RestoreDeviceTree" ) getcomp="DeviceTree";;
    esac
    if [[ "$device_target_vers" == "4.1" ]]; then
        local ipsw_prepare_usepowder=0
    fi
    #debug $device_target_vers
    #debug key $ipsw_prepare_usepowder
    #read -p debug
    local fw_key="$device_fw_key"
    if [[ $2 == "base" ]]; then
        fw_key="$device_fw_key_base"
    fi
    local name=$(echo $fw_key | $jq -j '.keys[] | select(.image == "'$getcomp'") | .filename')
    local iv=$(echo $fw_key | $jq -j '.keys[] | select(.image == "'$getcomp'") | .iv')
    local key=$(echo $fw_key | $jq -j '.keys[] | select(.image == "'$getcomp'") | .key')
    if [[ -z $name && $device_proc != 1 ]]; then
        error "Issue with firmware keys: Failed getting $getcomp. Check The Apple Wiki or your wikiproxy"
    fi

    case $comp in
        "iBSS" | "iBEC" )
            if [[ -z $name ]]; then
                name="$getcomp.${device_model}ap.RELEASE.dfu"
            fi
            echo "<key>$comp</key><dict><key>File</key><string>Firmware/dfu/$name</string><key>IV</key><string>$iv</string><key>Key</key><string>$key</string>" >> $NewPlist
            if [[ $ipsw_prepare_usepowder == 1 ]]; then
                echo "<key>Patch</key><true/>" >> $NewPlist
            elif [[ -s $FirmwareBundle/$comp.${device_model}ap.RELEASE.patch ]]; then
                echo "<key>Patch</key><string>$comp.${device_model}ap.RELEASE.patch</string>" >> $NewPlist
            elif [[ -s $FirmwareBundle/$comp.${device_model}.RELEASE.patch ]]; then
                echo "<key>Patch</key><string>$comp.${device_model}.RELEASE.patch</string>" >> $NewPlist
            fi
        ;;

        "iBoot" )
            echo "<key>$comp</key><dict><key>File</key><string>$all_flash/$name</string><key>IV</key><string>$iv</string><key>Key</key><string>$key</string>" >> $NewPlist
            echo "<key>Patch</key><string>$comp.${device_model}ap.RELEASE.patch</string>" >> $NewPlist
        ;;

        "RestoreRamdisk" )
            echo "<key>Restore Ramdisk</key><dict><key>File</key><string>$name</string><key>IV</key><string>$iv</string><key>Key</key><string>$key</string>" >> $NewPlist
        ;;

        "RestoreDeviceTree" | "RestoreLogo" )
            echo "<key>$comp</key><dict><key>File</key><string>$all_flash/$name</string><key>IV</key><string>$iv</string><key>Key</key><string>$key</string><key>DecryptPath</key><string>Downgrade/$comp</string>" >> $NewPlist
        ;;

        "RestoreKernelCache" )
            echo "<key>$comp</key><dict><key>File</key><string>$name</string><key>IV</key><string>$iv</string><key>Key</key><string>$key</string><key>DecryptPath</key><string>Downgrade/$comp</string>" >> $NewPlist
        ;;

        "KernelCache" )
            echo "<key>$comp</key><dict><key>File</key><string>$name</string><key>IV</key><string>$iv</string><key>Key</key><string>$key</string>" >> $NewPlist
            if [[ $ipsw_prepare_usepowder == 1 ]]; then
                echo "<key>Patch</key><true/>" >> $NewPlist
            elif [[ -e $FirmwareBundle/kernelcache.release.patch ]]; then
                echo "<key>Patch</key><string>kernelcache.release.patch</string>" >> $NewPlist
            fi
        ;;

        "WTF2" )
            echo "<key>WTF 2</key><dict><key>File</key><string>Firmware/dfu/WTF.s5l8900xall.RELEASE.dfu</string><key>Patch</key><string>WTF.s5l8900xall.RELEASE.patch</string>" >> $NewPlist
        ;;
    esac
    if [[ $2 != "old" ]]; then
        echo "<key>Decrypt</key><true/>" >> $NewPlist
    fi
    echo "</dict>" >> $NewPlist
}

ipsw_prepare_paths() {
    local comp="$1"
    local getcomp="$1"
    case $comp in
        "BatteryPlugin" ) getcomp="GlyphPlugin";;
        "NewAppleLogo" | "APTicket" ) getcomp="AppleLogo";;
        "NewRecoveryMode" ) getcomp="RecoveryMode";;
        "NewiBoot" ) getcomp="iBoot";;
    esac
    local fw_key="$device_fw_key"
    if [[ $2 == "base" ]]; then
        fw_key="$device_fw_key_base"
    fi
    local name=$(echo $fw_key | $jq -j '.keys[] | select(.image == "'$getcomp'") | .filename')
    if [[ -z $name && $getcomp != "manifest" ]]; then
        error "Issue with firmware keys: Failed getting $getcomp. Check The Apple Wiki or your wikiproxy"
    fi
    local str="<key>$comp</key><dict><key>File</key><string>$all_flash/"
    local str2
    local logostuff
    if [[ $2 == "target" ]]; then
        case $comp in
            *"AppleLogo" )
                if [[ $device_latest_vers == "5"* ]]; then
                    logostuff=1
                else
                    case $device_target_vers in
                        [789]* ) logostuff=1;;
                    esac
                fi
            ;;
        esac
        case $comp in
            "AppleLogo" ) str2="${name/applelogo/applelogo7}";;
            "APTicket" ) str2="${name/applelogo/applelogoT}";;
            "RecoveryMode" ) str2="${name/recoverymode/recoverymode7}";;
            "NewiBoot" ) str2="${name/iBoot/iBoot2}";;
        esac
        case $comp in
            "AppleLogo" )
                str+="$str2"
                if [[ $logostuff == 1 ]]; then
                    echo "$str2" >> $FirmwareBundle/manifest
                fi
            ;;
            "APTicket" | "RecoveryMode" )
                str+="$str2"
                echo "$str2" >> $FirmwareBundle/manifest
            ;;
            "NewiBoot" )
                if [[ $device_type != "iPad1,1" ]]; then
                    str+="$str2"
                    echo "$str2" >> $FirmwareBundle/manifest
                fi
            ;;
            "manifest" ) str+="manifest";;
            * ) str+="$name";;
        esac
    else
        str+="$name"
    fi
    str+="</string>"

    if [[ $comp == "NewiBoot" ]]; then
        local iv=$(echo $fw_key | $jq -j '.keys[] | select(.image == "'$getcomp'") | .iv')
        local key=$(echo $fw_key | $jq -j '.keys[] | select(.image == "'$getcomp'") | .key')
        str+="<key>IV</key><string>$iv</string><key>Key</key><string>$key</string>"
    elif [[ $comp == "manifest" ]]; then
        str+="<key>manifest</key><string>manifest</string>"
    fi

    echo "$str</dict>" >> $NewPlist
}

ipsw_prepare_config() {
    # usage: ipsw_prepare_config [jailbreak (true/false)] [needpref (true/false)]
    # creates config file to FirmwareBundles/config.plist
    local FirmwareBundles="$tmp/FirmwareBundles"
    local verbose="false"
    if [[ $ipsw_verbose == 1 ]]; then
        verbose="true"
    fi
    log "Preparing config file"
    echo "<plist>
<dict>
    <key>FilesystemJailbreak</key>
    <$1/>
    <key>needPref</key>
    <$2/>
    <key>iBootPatches</key>
    <dict>
        <key>debugEnabled</key>
        <false/>
        <key>bootArgsInjection</key>
        <$verbose/>
        <key>bootArgsString</key>
        <string>-v</string>
    </dict>
</dict>
</plist>" | tee $FirmwareBundles/config.plist
}

ipsw_prepare_tethered() {
    local name
    local iv
    local key
    local options_plist="options.$device_model.plist"
    if [[ $device_type == "iPad1,1" && $device_target_vers == "4"* ]]; then
        :
    elif [[ $device_target_vers == "3"* || $device_target_vers == "4"* ]]; then
        options_plist="options.plist"
    fi

    if [[ -e "$saved/ipsws/$ipsw_custom.ipsw" ]]; then
        log "Found existing Custom IPSW. Skipping IPSW creation."
        return
    fi
   
    ipsw_prepare_32bit
    local tmp1=$tmp/tethered
    if [ ! -d "$tmp1" ]; then
        mkdir -p "$tmp1"
        log "创建文件夹: $tmp1"
    fi
    log "Extract RestoreRamdisk and options.plist"
    device_fw_key_check temp $device_target_build
    name=$(echo $device_fw_key_temp | $jq -j '.keys[] | select(.image == "RestoreRamdisk") | .filename')
    iv=$(echo $device_fw_key_temp | $jq -j '.keys[] | select(.image == "RestoreRamdisk") | .iv')
    key=$(echo $device_fw_key_temp | $jq -j '.keys[] | select(.image == "RestoreRamdisk") | .key')
    mv "$saved/ipsws/$ipsw_custom.ipsw" $tmp1/temp.ipsw
    unzip -o -j $tmp1/temp.ipsw $name -d $tmp1
    mv $tmp1/$name $tmp1/ramdisk.orig
    "$xpwntool" $tmp1/ramdisk.orig $tmp1/ramdisk.dec -iv $iv -k $key
    #debug xpwntool
    "$hfsplus" $tmp1/ramdisk.dec extract usr/local/share/restore/$options_plist
    #debug hfstool

    log "Modify options.plist"
    "$hfsplus" $tmp1/ramdisk.dec rm usr/local/share/restore/$options_plist
    cat $options_plist | sed '$d' | sed '$d' > options2.plist
    printf "<key>FlashNOR</key><false/></dict>\n</plist>\n" >> options2.plist
    cat options2.plist
    "$hfsplus" $tmp1/ramdisk.dec add options2.plist usr/local/share/restore/$options_plist

    log "Repack Restore Ramdisk"
    "$xpwntool" $tmp1/ramdisk.dec $name -t $tmp1/ramdisk.orig
    log "Add Restore Ramdisk to IPSW"
    zip -r0 $tmp1/temp.ipsw $name
    #if [[ $ipsw_jailbreak == 1 ]]; then
    #    ipsw_custom+="J"
    #else
    #   ipsw_custom+="V"
    #fi
    #ipsw_custom+="T"
    mv $tmp1/temp.ipsw "$saved/ipsws/$ipsw_custom.ipsw"
}


device_justboot() {
    if [[ ! -d "$script_dir/justboot" ]]; then
        mkdir -p "$script_dir/tmp/justboot"
    fi
    if [[ -z $device_bootargs ]]; then
        device_bootargs="pio-error=0 -v"
    fi
    if [[ $main_argmode == "device_justboot" ]]; then
        cat "$device_rd_build" > "../saved/$device_type/justboot_${device_ecid}"
    fi
    device_ramdisk justboot
}

device_ramdisk() {
    #only retent justboot part
    local comps=("iBSS" "iBEC" "DeviceTree" "Kernelcache")
    local name
    local iv
    local key
    local path
    local url
    local decrypt
    local ramdisk_path
    local version
    local build_id
    local mode="$1"
    local rec=2
    if [[ -n $device_rd_build ]]; then
        device_target_build=$device_rd_build
        device_rd_build=
    fi
    local tmp2=$script_dir/tmp/justboot
    version=$device_target_vers
    if [ ! -d "$tmp2" ]; then
        mkdir -p "$tmp2"
        log "创建文件夹: $tmp2"
    fi
    ipsw_justboot_path="$ipsw_path"
    build_id=$device_target_build
    device_fw_key_check
    ipsw_get_url $build_id $version
    local ramdisk_path="$tmp2/$device_type/ramdisk_$build_id"
    mkdir -p $ramdisk_path
    for getcomp in "${comps[@]}"; do
        name=$(echo $device_fw_key | $jq -j '.keys[] | select(.image == "'$getcomp'") | .filename')
        iv=$(echo $device_fw_key | $jq -j '.keys[] | select(.image == "'$getcomp'") | .iv')
        key=$(echo $device_fw_key | $jq -j '.keys[] | select(.image == "'$getcomp'") | .key')
        case $getcomp in
            "iBSS" | "iBEC" ) path="Firmware/dfu/";;
            "DeviceTree" )
                path="Firmware/all_flash/"
                case $build_id in
                    14[EFG]* ) :;;
                    * ) path="$all_flash/";;
                esac
            ;;
            * ) path="";;
        esac
        if [[ -z $name ]]; then
            local hwmodel="$device_model"
            case $build_id in
                14[EFG]* )
                    case $device_type in
                        iPhone5,[12] ) hwmodel="iphone5";;
                        iPhone5,[34] ) hwmodel="iphone5b";;
                        iPad3,[456] )  hwmodel="ipad3b";;
                    esac
                ;;
                [789]* | 10* | 11* ) hwmodel+="ap";;
            esac
            case $getcomp in
                "iBSS" | "iBEC" ) name="$getcomp.$hwmodel.RELEASE.dfu";;
                "DeviceTree" )    name="$getcomp.${device_model}ap.img3";;
                "Kernelcache" )   name="kernelcache.release.$hwmodel";;
            esac
        fi

        log "$getcomp"
        if [[ -n $ipsw_justboot_path ]]; then
            unzip -o -j "$ipsw_justboot_path" "${path}$name" -d $tmp2
        elif [[ -s $ramdisk_path/$name ]]; then
            cp $ramdisk_path/$name .
        else
            "$pzb" -g "${path}$name" -o "$name" "$ipsw_url"
        fi
        if [[ ! -s $name ]]; then
            error "Failed to get $name. Please run the script again."
        fi
        if [[ ! -s $ramdisk_path/$name ]]; then
            cp $name $ramdisk_path/
        fi
        mv $tmp2/$name $tmp2/$getcomp.orig
        if [[ $getcomp == "Kernelcache" || $getcomp == "iBSS" ]] && [[ $device_proc == 1 || $device_type == "iPod2,1" ]]; then
            decrypt="-iv $iv -k $key"
            "$xpwntool" $getcomp.orig $getcomp.dec $decrypt
        elif [[ $build_id == "14"* ]]; then
            cp $tmp2/$getcomp.orig $tmp2/$getcomp.dec
        else
            "$xpwntool" $tmp2/$getcomp.orig $tmp2/$getcomp.dec -iv $iv -k $key -decrypt
        fi
    done
    log "Sign iBSS"
    "$xpwntool" $tmp2/iBSS.dec $tmp2/iBSS.raw
    if [[ $device_type == "iPad2,"* || $device_type == "iPhone3,3" ]]; then
        case $build_id in
            8[FGHJKL]* | 8E600 | 8E501 ) device_boot4=1;;
        esac
    fi
    if [[ $device_boot4 == 1 ]]; then
        "$iBoot32Patcher" $tmp2/iBSS.raw $tmp2/iBSS.patched --rsa --debug -b "-v amfi=0xff cs_enforcement_disable=1"
    else
        "$iBoot32Patcher" $tmp2/iBSS.raw $tmp2/iBSS.patched --rsa --debug -b "$device_bootargs"
    fi
    "$xpwntool" $tmp2/iBSS.patched $tmp2/iBSS -t $tmp2/iBSS.dec
    if [[ $build_id == "7"* || $build_id == "8"* ]] && [[ $device_type != "iPad"* ]]; then
        :
    else
        log "Sign iBEC"
        "$xpwntool" $tmp2/iBEC.dec $tmp2/iBEC.raw
        if [[ $1 == "justboot" ]]; then
            "$iBoot32Patcher" $tmp2/iBEC.raw $tmp2/iBEC.patched --rsa --debug -b "$device_bootargs"
        else
            "$iBoot32Patcher" $tmp2/iBEC.raw $tmp2/iBEC.patched --rsa --debug -b "rd=md0 -v amfi=0xff amfi_get_out_of_my_way=1 cs_enforcement_disable=1 pio-error=0"
        fi
        "$xpwntool" $tmp2/iBEC.patched $tmp2/iBEC -t $tmp2/iBEC.dec
    fi
    mv $tmp2/iBSS $tmp2/iBEC $tmp2/DeviceTree.dec $tmp2/Kernelcache.dec $tmp2/Ramdisk.dmg $ramdisk_path 2>/dev/null


    #if [[ $1 == "jailbreak" || $1 == "justboot" ]]; then
    #    device_enter_mode pwnDFU
    #else
    #    device_buttons
    #fi
    $primepwn
    log "Sending iBSS..."
    $irecovery -f $ramdisk_path/iBSS
    sleep 2
    sleep 3
    if [[ $build_id != "7"* && $build_id != "8"* ]]; then
        log "Sending iBEC..."
        $irecovery -f $ramdisk_path/iBEC
    fi
    sleep 3
    if [[ $1 != "justboot" ]]; then
        log "Sending ramdisk..."
        $irecovery -f $ramdisk_path/Ramdisk.dmg
        log "Running ramdisk"
        $irecovery -c "getenv ramdisk-delay"
        $irecovery -c ramdisk
        sleep 2
    fi
    log "Sending DeviceTree..."
    $irecovery -f $ramdisk_path/DeviceTree.dec
    log "Running devicetree"
    $irecovery -c devicetree
    log "Sending KernelCache..."
    $irecovery -f $ramdisk_path/Kernelcache.dec
    $irecovery -c bootx

    if [[ $1 == "justboot" ]]; then
        log "Device should now boot."
        return
    fi
}

local_ramdisk() {
    local options=()
    local selected
    case $device_proc in
        1 ) DFUhelper_legacy ;;
        * ) DFUhelper pwn ;;
    esac
    local  device_type=$($irecovery -q | grep -i "product" | awk -F': ' '{print $2}')
    case $de in
        1 ) 
            device_type=iPod1,1
            rd_build="7E18"
            rd_sha=6e3d9b8539e370bb3adf5b3b6281eb04e73873a6ca17566bf1b6b6cc1bb7db45
            ;;
        2 ) 
            device_type=iPod2,1
            rd_build="8C148"
            rd_sha=2642519439fed3484d9d43a04713834e1947776119bb8bfdc8276bbcca67efe0
            ;;
        3 ) 
            device_type=iPod3,1
            rd_build="9B206"
            rd_sha=4263b275b251444c23faa1fe8bb3bff4b2fcb6ef5b5ae60a3f92f8c82c56a22c
            ;;
        4 ) 
            device_type=iPod4,1
            rd_build="10B500"
            rd_sha=e09f50b27d0d70aa6529d9e78ea008b9832dbafa48d0b7310d4fcd283b7a5ac0
            ;;
        5 ) 
            device_type=iPod5,1
            debug $device_major_ver
            pause
            if [ -z "$device_major_ver" ]; then
                log 选择SSHRD版本
                options+=("10B329(iOS6-8)")
                options+=("13A452(iOS9)")
                select_option "${options[@]}"
                selected="${options[$?]}"
                    case $selected in
                        "10B329(iOS6-8)" ) 
                            rd_build=10B329 
                            rd_sha=061751e68975997567a296819ed6b8a5fc1b1fa4aebb081b1920fc75bc60f69d
                            ;;
                        "13A452(iOS9)" )
                            rd_build=13A452
                            rd_sha=7c0ac61d96618fa8699e0d7c994f4fe5d0b79ca16fa86108acbbd6b691bc98cc
                            ;;
                    esac
            else
                case $device_major_ver in
                    6 )
                        rd_build="10B329"
                        rd_sha=061751e68975997567a296819ed6b8a5fc1b1fa4aebb081b1920fc75bc60f69d
                        ;;
                    * )
                        rd_build=13A452
                        rd_sha=7c0ac61d96618fa8699e0d7c994f4fe5d0b79ca16fa86108acbbd6b691bc98cc
                        ;;
                esac
            fi
            ;;
        * ) 
            rd_build="10B329"
            ;;
    esac
    local ramdisk_name=${device_type}_${rd_build}
    if [[ ! -d "$saved/ramdisk/$ramdisk_name" ]]; then
        log 下载$rd_build ramdisk for $device_type
        lanzou_download --u="https://wwhu.lanzoub.com/b0w99yrda" --pwd="6ruq" --f="${device_type}_${rd_build}.zip" --q
        if [[ ! -f "$tmp/${device_type}_${rd_build}.zip" ]]; then
            error 下载失败
            yesno 是否重试? 1
            if [[ $? == 1 ]]; then
                local_ramdisk
            else
                go_to_menu nopause
            fi
        else
            dl_rd_sha=$(shasum -a 256 "$tmp/${device_type}_${rd_build}.zip" | cut -d ' ' -f1)
            if [ "$dl_rd_sha" = "$rd_sha" ]; then
                log "✅ SHA256 校验通过"
                log 解压ramdisk
                $z7z x $tmp/${device_type}_${rd_build}.zip -o"$tmp/ramdisk"
                cp -R $tmp/ramdisk $saved/ramdisk/${device_type}_${rd_build}
            else
                error 下载失败
                yesno 是否重试? 1
                if [[ $? == 1 ]]; then
                    local_ramdisk
                else
                    go_to_menu nopause
                fi
            fi
        fi
    else
        cp -R $saved/ramdisk/${device_type}_${rd_build} $tmp/ramdisk
    fi
    case $device_type in
        iPod1,1 | iPod2,1 ) local required_files=("iBSS" "Ramdisk.dmg" "DeviceTree.dec" "Kernelcache.dec") ;;
        *) local required_files=("iBSS" "iBEC" "Ramdisk.dmg" "DeviceTree.dec" "Kernelcache.dec") ;;
    esac
    for file in "${required_files[@]}"; do
        if [[ ! -f "$tmp/ramdisk/$file" ]]; then
            missing_files+=("$file")
        fi
    done
    if [[ ${#missing_files[@]} -eq 0 ]]; then
        log "所有必需的Ramdisk文件都存在"
    else
        error 文件缺失,是否重新下载?
        yesno 是否重新下载? 1
        if [[ $? == 1 ]]; then
            rm -rf $tmp/ramdisk
            rm -rf $saved/ramdisk/${device_type}_${rd_build}
            local_ramdisk
        else
            rm -rf $tmp/ramdisk/
            rm -rf $saved/ramdisk/${device_type}_${rd_build}
            go_to_menu nopause
        fi
    fi
    log 启动ramdisk
        rm ~/.ssh/known_hosts
        log 发送iBSS
        $irecovery -f $tmp/ramdisk/iBSS
        sleep 2
        if [[ $device_proc != 1 ]]; then
            log 发送iBEC
            $irecovery -f $tmp/ramdisk/iBEC
            sleep 3
        fi
        checkmode recovery
        log 发送Ramdisk
        $irecovery -f $tmp/ramdisk/Ramdisk.dmg
        sleep 5
        $irecovery -c "getenv ramdisk-delay"
        $irecovery -c "ramdisk"
        sleep 2
        log 发送devicetree
        $irecovery -f $tmp/ramdisk/DeviceTree.dec
        $irecovery -c "devicetree"
        sleep 1
        log 发送Kernelcache
        $irecovery -f $tmp/ramdisk/kernelcache.dec
        $irecovery -c "bootx"
        if [[ $rd_build == "13A452" ]]; then
            local time=15
        else
            local time=10
        fi
        log "等待设备启动(约${time}秒)..."
        sleep $time
        log "设置SSH端口($ssh_port)"
        pkill -9 -f "iproxy.*$ssh_port" 2>/dev/null
        $iproxy $ssh_port 22 -s 127.0.0.1 >/dev/null &
        if [[ $device_proc == 1 || $device_type == "iPod2,1" ]]; then
            log 上传文件
            $ssh -p $ssh_port root@127.0.0.1 "rm -f /bin/mount.sh /usr/bin/date"
            $scp -P $ssh_port $script_dir/bin/SSHRD/files/bin/* root@127.0.0.1:/bin
            $scp -P $ssh_port $script_dir/bin/SSHRD/files/usr/bin/* root@127.0.0.1:/usr/bin
        fi
        if [[ "$1" != "nomenu" ]]; then
            SSHRD_choice
        fi
}
    

ipsw_prepare_ios4multipart() {
    local JBFiles=()
    ipsw_custom_part2="${device_type}_${device_target_vers}_${device_target_build}_CustomNP-${device_ecid}"
    local all_flash2=$tmp/part2
    local iboot

    if [[ -e "../$ipsw_custom_part2.ipsw" && -e "$ipsw_custom.ipsw" ]]; then
        log "Found existing Custom IPSWs. Skipping IPSW creation."
        return
    elif [[ -e "../$ipsw_custom_part2.ipsw" ]]; then
        rm -f "../$ipsw_custom_part2.ipsw"
    fi

    log "Preparing NOR flash IPSW..."
    mkdir -p $tmp/$ipsw_custom_part2/Firmware/dfu $tmp/$ipsw_custom_part2/Downgrade $tmp/$all_flash2

    local comps=("iBSS" "iBEC" "DeviceTree" "Kernelcache" "RestoreRamdisk")
    local name
    local iv
    local key
    local path
    local vers="5.1.1"
    local build="9B206"
    local saved_path="../saved/$device_type/$build"
    ipsw_get_url $build
    local url="$ipsw_url"
    device_fw_key_check temp $build

    mkdir -p $saved_path
    log "Getting $vers restore components"
    for getcomp in "${comps[@]}"; do
        name=$(echo $device_fw_key_temp | $jq -j '.keys[] | select(.image == "'$getcomp'") | .filename')
        iv=$(echo $device_fw_key_temp | $jq -j '.keys[] | select(.image == "'$getcomp'") | .iv')
        key=$(echo $device_fw_key_temp | $jq -j '.keys[] | select(.image == "'$getcomp'") | .key')
        case $getcomp in
            "iBSS" | "iBEC" ) path="Firmware/dfu/";;
            "DeviceTree" ) path="$all_flash/";;
            * ) path="";;
        esac
        log "$getcomp"
        if [[ $vers == "$device_base_vers" ]]; then
            unzip -o -j "$ipsw_base_path" ${path}$name -d $tmp
        elif [[ -e $saved_path/$name ]]; then
            cp $saved_path/$name .
        else
            "$pzb" -g "${path}$name" -o "$name" "$url"
            cp $name $saved_path/
        fi
        case $getcomp in
            "DeviceTree" )
                "$xpwntool" $name $tmp/$ipsw_custom_part2/Downgrade/RestoreDeviceTree -iv $iv -k $key -decrypt
            ;;
            "Kernelcache" )
                "$xpwntool" $name $tmp/$ipsw_custom_part2/Downgrade/RestoreKernelCache -iv $iv -k $key -decrypt
            ;;
            * )
                mv $tmp/$name $tmp/$getcomp.orig
                "$xpwntool" $tmp/$getcomp.orig $tmp/$getcomp.dec -iv $iv -k $key
            ;;
        esac
    done

    log "Patch iBSS"
    "$iBoot32Patcher" $tmp/iBSS.dec $tmp/iBSS.patched --rsa
    "$xpwntool" $tmp/iBSS.patched $tmp/$ipsw_custom_part2/Firmware/dfu/iBSS.${device_model}ap.RELEASE.dfu -t $tmp/iBSS.orig

    log "Patch iBEC"
    "$iBoot32Patcher" $tmp/iBEC.dec $tmp/iBEC.patched --rsa --ticket -b "rd=md0 -v nand-enable-reformat=1 amfi=0xff cs_enforcement_disable=1"
    "$xpwntool" $tmp/iBEC.patched $tmp/$ipsw_custom_part2/Firmware/dfu/iBEC.${device_model}ap.RELEASE.dfu -t $tmp/iBEC.orig

    log "Manifest plist"
    if [[ $vers == "$device_base_vers" ]]; then
        unzip -o -j "$ipsw_base_path" BuildManifest.plist -d $tmp
    elif [[ -e $saved_path/BuildManifest.plist ]]; then
        cp $saved_path/BuildManifest.plist $tmp/
    else
        "$pzb" -g "${path}BuildManifest.plist" -o "BuildManifest.plist" "$url"
        cp BuildManifest.plist $saved_path/
    fi
    $PlistBuddy -c "Set BuildIdentities:0:Manifest:RestoreDeviceTree:Info:Path Downgrade/RestoreDeviceTree" $tmp/BuildManifest.plist
    $PlistBuddy -c "Set BuildIdentities:0:Manifest:RestoreKernelCache:Info:Path Downgrade/RestoreKernelCache" $tmp/BuildManifest.plist
    $PlistBuddy -c "Set BuildIdentities:0:Manifest:RestoreLogo:Info:Path Downgrade/RestoreLogo" $tmp/BuildManifest.plist
    cp $tmp/BuildManifest.plist $tmp/$ipsw_custom_part2/

    log "Restore Ramdisk"
    local ramdisk_name=$(echo $device_fw_key_temp | $jq -j '.keys[] | select(.image == "RestoreRamdisk") | .filename')
    mv RestoreRamdisk.dec ramdisk.dec
    "$hfsplus" ramdisk.dec grow 18000000

    local rootfs_name=$(echo $device_fw_key_temp | $jq -j '.keys[] | select(.image == "RootFS") | .filename')
    touch $tmp/$ipsw_custom_part2/$rootfs_name
    log "Dummy RootFS: $rootfs_name"

    log "Modify options.plist"
    local options_plist="options.$device_model.plist"
    echo '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CreateFilesystemPartitions</key>
    <false/>
    <key>UpdateBaseband</key>
    <false/>
    <key>SystemImage</key>
    <false/>
</dict>
</plist>' | tee $options_plist
    "$hfsplus" ramdisk.dec rm usr/local/share/restore/$options_plist
    "$hfsplus" ramdisk.dec add $options_plist usr/local/share/restore/$options_plist

    log "Patch ASR"
    #cp ../resources/patch/old/$device_type/$vers/* .
    #ipsw_patch_file ramdisk.dec usr/sbin asr asr.patch #低俗
    $hfsplus ramdisk.dec extract usr/sbin/asr
    $hfsplus ramdisk.dec rm usr/sbin/asr
    $bspatch asr asr.patched asr.patch
    $hfsplus ramdisk.dec add asr.patched usr/sbin/asr
    $hfsplus ramdisk.dec chmod 755 usr/sbin/asr
    $hfsplus ramdisk.dec chown 0:0 usr/sbin/asr
    mv ramdisk.dec $tmp

    log "Repack Restore Ramdisk"
    "$xpwntool" $tmp/ramdisk.dec $tmp/$ipsw_custom_part2/$ramdisk_name -t $tmp/RestoreRamdisk.orig

    log "Extract all_flash from $device_base_vers base"
    unzip -o -j "$ipsw_base_path" Firmware/all_flash/\* -d $tmp

    log "Add $device_target_vers DeviceTree to all_flash"
    rm $all_flash2/DeviceTree.${device_model}ap.img3
    unzip -o -j "$ipsw_path.ipsw" $all_flash/DeviceTree.${device_model}ap.img3 -d $all_flash2

    local ExtraArr=("--boot-partition" "--boot-ramdisk" "--logo4")
    case $device_target_vers in
        4.2.9 | 4.2.10 ) :;;
        * ) ExtraArr+=("--433");;
    esac
    local bootargs="$device_bootargs_default"
    if [[ $ipsw_verbose == 1 ]]; then
        bootargs="pio-error=0 -v"
    fi
    ExtraArr+=("-b" "$bootargs")
    patch_iboot "${ExtraArr[@]}"

    log "Add $device_target_vers iBoot to all_flash"
    cp $tmp/iBoot $all_flash2/iBoot2.img3
    echo "iBoot2.img3" >> $all_flash2/manifest

    log "Add APTicket to all_flash"
    cat "$shsh_path" | sed '64,$d' | sed -ne '/<data>/,/<\/data>/p' | sed -e "s/<data>//" | sed "s/<\/data>//" | tr -d '[:space:]' | base64 --decode > $tmp/apticket.der
    "$xpwntool" $tmp/apticket.der $all_flash2/applelogoT.img3 -t $script_dir/resources/firmware/src/scab_template.img3
    echo "applelogoT.img3" >> $all_flash2/manifest

    log "AppleLogo"
    local logo_name="$(echo $device_fw_key | $jq -j '.keys[] | select(.image == "AppleLogo") | .filename')"
    unzip -o -j "$ipsw_path.ipsw" $all_flash/$logo_name -d $tmp
    echo "0000010: 3467" | xxd -r - $tmp/$logo_name
    echo "0000020: 3467" | xxd -r - $tmp/$logo_name
    log "Add AppleLogo to all_flash"
    if [[ $device_latest_vers == "5"* ]]; then
        mv $tmp/$logo_name $all_flash2/applelogo4.img3
        echo "applelogo4.img3" >> $all_flash2/manifest
    else
        sed '/applelogo/d' $all_flash2/manifest > $tmp/manifest
        rm $all_flash2/manifest
        echo "$logo_name" >> $tmp/manifest
        mv $tmp/$logo_name $tmp/manifest $all_flash2/
    fi

    log "Creating $ipsw_custom_part2.ipsw..."
    pushd $tmp/$ipsw_custom_part2 >/dev/null
    zip -r0 $tmp/$ipsw_custom_part2.ipsw *
    popd >/dev/null

    if [[ $ipsw_skip_first == 1 ]]; then
        return
    fi

    # ------ part 2 (nor flash) ends here. start creating part 1 ipsw ------
    ipsw_prepare_32bit $iboot

    ipsw_prepare_ios4multipart_patch=1
    ipsw_prepare_multipatch
}

patch_iboot() {
    device_fw_key_check
    local iboot_name=$(echo $device_fw_key | $jq -j '.keys[] | select(.image == "iBoot") | .filename')
    local iboot_iv=$(echo $device_fw_key | $jq -j '.keys[] | select(.image == "iBoot") | .iv')
    local iboot_key=$(echo $device_fw_key | $jq -j '.keys[] | select(.image == "iBoot") | .key')
    if [[ -z $iboot_name ]]; then
        error "Issue with firmware keys: Failed getting iBoot. Check The Apple Wiki or your wikiproxy"
    fi
    local rsa="--rsa"
    log "Sign iBoot: $*"
    if [[ $1 == "--logo" ]]; then
        iboot_name="${iboot_name/iBoot/iBoot2}"
        rsa=
        unzip -o -j $tmp/temp.ipsw $all_flash/$iboot_name -d $tmp
    else
        unzip -o -j "$ipsw_path" $all_flash/$iboot_name -d $tmp
    fi
    mv $tmp/$iboot_name $tmp/iBoot.orig
    "$xpwntool" $tmp/iBoot.orig $tmp/iBoot.dec -iv $iboot_iv -k $iboot_key
    "$iBoot32Patcher" $tmp/iBoot.dec $tmp/iBoot.pwned $rsa "$@"
    "$xpwntool" $tmp/iBoot.pwned $tmp/iBoot -t $tmp/iBoot.orig
    if [[ $device_type == "iPad1,1" || $device_type == "iPhone5,"* ]]; then
        echo "0000010: 6365" | xxd -r - $tmp/iBoot
        echo "0000020: 6365" | xxd -r - $tmp/iBoot
        return
    elif [[ $device_type != "iPhone2,1" ]]; then
        echo "0000010: 626F" | xxd -r - $tmp/iBoot
        echo "0000020: 626F" | xxd -r - $tmp/iBoot
    fi
    "$xpwntool" $tmp/iBoot.pwned $tmp/$iboot_name -t $tmp/iBoot -iv $iboot_iv -k $iboot_key
}

ipsw_patch_file() {
    # usage: ipsw_patch_file <ramdisk/fs> <location> <filename> <patchfile>
    "$hfsplus" "$1" extract "$2"/"$3"
    "$hfsplus" "$1" rm "$2"/"$3"
    $bspatch "$3" "$3".patched "$4"
    "$hfsplus" "$1" add "$3".patched "$2"/"$3"
    "$hfsplus" "$1" chmod 755 "$2"/"$3"
    "$hfsplus" "$1" chown 0:0 "$2"/"$3"
}

ipsw_prepare_ios4powder() {
    local ExtraArgs="-apticket $shsh"
    local JBFiles=()
    ipsw_prepare_usepowder=1

    if [[ -e "$saved/ipsws/$ipsw_custom.ipsw" ]]; then
        log "Found existing Custom IPSW. Skipping IPSW creation."
        return
    fi

    if [[ $ipsw_jailbreak == 1 ]]; then
        JBFiles=("g1lbertJB/${device_type}_${device_target_build}.tar" "fstab_old.tar" "freeze.tar" "cydiasubstrate.tar")
        for i in {0..3}; do
            JBFiles[i]=$jelbrek/${JBFiles[$i]}
        done
        if [[ $ipsw_openssh == 1 ]]; then
            JBFiles+=("$jelbrek/sshdeb.tar")
        fi
        cp $jelbrek/freeze.tar $lib
    fi

    ipsw_prepare_bundle target
    ipsw_prepare_bundle base
    #ipsw_prepare_logos_convert
    cp -R $script_dir/resources/firmware/src $lib
    rm $lib/src/target/$device_model/$device_base_build/partition
    mv $lib/src/target/$device_model/reboot4 $lib/src/target/$device_model/$device_base_build/partition
    rm $lib/src/bin.tar
    mv $lib/src/bin4.tar $lib/src/bin.tar
    ipsw_prepare_config false true
    if [[ $ipsw_memory == 1 ]]; then
        ExtraArgs+=" -memory"
    fi
    local ExtraArr=("--boot-partition" "--boot-ramdisk" "--logo4")
    case $device_target_vers in
        4.3.[45] ) :;;
        * ) ExtraArr+=("--433");;
    esac
    local bootargs="$device_bootargs_default"
    if [[ $ipsw_verbose == 1 ]]; then
        bootargs="pio-error=0 -v"
    fi
    ExtraArr+=("-b" "$bootargs")
    patch_iboot "${ExtraArr[@]}"
    cp $tmp/iBoot $lib
    cd $lib
    tar -rvf src/bin.tar iBoot
    log "Preparing custom IPSW: $powdersn0w $ipsw_path temp.ipsw -base $ipsw_base_path $ExtraArgs ${JBFiles[*]}"
    ./powdersn0w "$ipsw_path" $tmp/temp.ipsw -base "$ipsw_base_path" $ExtraArgs ${JBFiles[@]}

    if [[ ! -e temp.ipsw ]]; then
        if [[ $platform == "macos" && $platform_arch == "arm64" ]]; then
            warn "Updating to macOS 14.6 or newer is recommended for Apple Silicon Macs to resolve issues."
        fi
        error "Failed to find custom IPSW. Please run the script again" \
        "* You may try selecting N for memory option"
    fi

    ipsw_prepare_ios4patches
    if [[ -n $ipsw_customlogo ]]; then
        ipsw_prepare_logos_add
    else
        log "Patch AppleLogo"
        local applelogo_name=$(echo "$device_fw_key" | $jq -j '.keys[] | select(.image == "AppleLogo") | .filename')
        unzip -o -j temp.ipsw $all_flash/$applelogo_name
        echo "0000010: 3467" | xxd -r - $applelogo_name
        echo "0000020: 3467" | xxd -r - $applelogo_name
        mv $applelogo_name $all_flash/$applelogo_name
    fi

    log "Add all to custom IPSW"
    mv $tmp/$ramdisk_name $tmp/iOS4Patches/$ramdisk_name
    cd $tmp/iOS4Patches
    zip -r0 $tmp/temp.ipsw $all_flash/* Firmware/dfu/* $ramdisk_name

    mv $tmp/temp.ipsw "$saved/ipsws/$ipsw_custom.ipsw"
}

ipsw_prepare_powder() {
if [[ ! -f $tmp/temp.ipsw ]]; then
    local ExtraArgs
    if [[ -f "$saved/ipsws/$ipsw_custom.ipsw" ]]; then
        log "Found existing Custom IPSW. Skipping IPSW creation."
        return
    fi
    ipsw_prepare_usepowder=1
    ipsw_prepare_bundle target
    ipsw_prepare_bundle base
    $ipsw_prepare_logos_convert
    cp -R $resources/firmware/src $lib
    if [[ $ipsw_memory == 1 ]]; then
        ExtraArgs+=" -memory"
    fi
    if [[ $ipsw_jailbreak == 1 ]]; then
        cp $jelbrek/freeze.tar $lib
        case $device_target_vers in
            7.1* ) # remove for lyncis
                ExtraArgs+=" $jelbrek/fstab7.tar"
                case $device_type in
                    iPod* ) ExtraArgs+=" $jelbrek/panguaxe-ipod.tar";;
                    *     ) ExtraArgs+=" $jelbrek/panguaxe.tar";;
                esac
            ;;
            #7.1* ) ExtraArgs+=" $jelbrek/lyncis.tar";; # change to 7* for lyncis 7.0.x and remove below line
            7.0* ) # remove for lyncis 7.0.x
                ExtraArgs+=" $jelbrek/fstab7.tar"
                if [[ $device_type == "iPhone5,3" || $device_type == "iPhone5,4" ]] && [[ $device_target_vers == "7.0" ]]; then
                    ExtraArgs+=" $jelbrek/evasi0n7-untether-70.tar"
                else
                    ExtraArgs+=" $jelbrek/evasi0n7-untether.tar"
                fi
            ;;
            5*   ) ExtraArgs+=" $jelbrek/cydiasubstrate.tar $jelbrek/g1lbertJB.tar $jelbrek/g1lbertJB/${device_type}_${device_target_build}.tar";;
        esac
        case $device_target_vers in
            [689]* ) :;;
            * ) ExtraArgs+="$jelbrek/freeze.tar";;
        esac
        if [[ $ipsw_openssh == 1 ]]; then
            ExtraArgs+=" $jelbrek/sshdeb.tar"
        fi
    fi
    local ExtraArr=("--boot-partition" "--boot-ramdisk")
    local bootargs="$device_bootargs_default"
    if [[ $ipsw_verbose == 1 ]]; then
        bootargs="pio-error=0 -v"
    fi
    case $device_target_vers in
        [789]* ) :;;
        * ) ExtraArr+=("--logo");;
    esac
    tmp=$script_dir/tmp
    log "Preparing custom IPSW: $powdersn0w $ipsw_path.ipsw temp.ipsw -base $ipsw_base_path.ipsw $ExtraArgs"
    cp -r $tmp/FirmwareBundles $lib
    cd $lib
    ./powdersn0w "$ipsw_path" $tmp/temp.ipsw -base "$ipsw_base_path" $ExtraArgs
    if [ -f "$lib/temp.ipsw" ]; then
        mv $lib/temp.ipsw $script_dir/tmp/temp.ipsw
    fi
    if [[ ! -f $tmp/temp.ipsw ]]; then
        error 固件制作失败
    fi
fi
    if [[ $device_type != "iPhone5"* && $device_type != "iPad1,1" ]] || [[ $ipsw_powder_5c70 == 1 ]]; then
        case $device_target_vers in
            [789]* ) :;;
            * )
                all_flash="Firmware/all_flash/all_flash.${device_model}ap.production"
                patch_iboot --logo
                mkdir -p $tmp/iBootPatches/$all_flash
                mv $tmp/iBoot*.img3 $tmp/iBootPatches/$all_flash
                cd $tmp/iBootPatches
                zip -r0 $tmp/temp.ipsw $all_flash/iBoot*.img3
            ;;
        esac
    fi
    #ipsw_prepare_logos_add
    #ipsw_bbreplace
    mv $tmp/temp.ipsw $saved/ipsws/$ipsw_custom.ipsw
}

##################restore#######################

restore_idevicerestore (){
    warning 准备刷入,此操作会删除所有数据!
    shsh_select cp
    if [[ $1 == shsh ]]; then
        cd $lib
        ./idevicerestore -ew $ipsw_path
    elif [[ $1 == tethered ]]; then
        shsh_save_tss
        cd $lib
        ./idevicerestore -ew $ipsw_path
    else
       yesno 是否刷入? 1
        if [[ $? == 1 ]]; then
            if [[ $device_target_tethered == 1 ]]; then
                shsh_save_tss
            fi
            cd $lib
            ./idevicerestore -ew $saved/ipsws/$ipsw_custom.ipsw
        else
            log 不刷入固件
        fi
    fi
    log 恢复完成✅
}

restore_futurerestore (){
    local ExtraArr=()
    if [[ $device_type == iPod5,1 ]]; then
        local futurerestore2=$futurerestore_old
    else
        local futurerestore2="$futurerestore"
    fi
    local port=8888
    local opt
    device_fw_key_check server
    pushd $tmp >/dev/null
    echo "🔍 检测80端口占用情况..."
    PID=$(lsof -t -i :8888)

    if [ -z "$PID" ]; then
        echo "✅ 8888端口未被占用"
    else
        echo "⚠️ 发现占用8888端口的进程(PID): $PID"
        echo "📌 进程详细信息:"
        lsof -i :8888 | awk 'NR==1 || /LISTEN/'
        
        echo "🛑 正在强制终止进程 $PID ..."
        kill -9 $PID 2>/dev/null
        
        # 验证是否成功释放
        if [ -z "$(lsof -t -i :8888)" ]; then
            echo "✅ 8888端口已成功释放"
        else
            echo "❌ 释放失败，请手动检查"
            exit 1
        fi
    fi
    log "Starting local server for firmware keys"
    "$darkhttpd" $tmp/ --port $port &
    httpserver_pid=$!
    log "httpserver PID: $httpserver_pid"
    popd >/dev/null
    log "Waiting for local server"
    until [[ $(curl http://127.0.0.1:$port 2>/dev/null) ]]; do
        sleep 1
    done
    ExtraArr+=("--no-baseband")
    if [[ $device_type == iPod7,1 ]]; then
        if [[ $device_target_vers == "10"* ]]; then
            export FUTURERESTORE_I_SOLEMNLY_SWEAR_THAT_I_AM_UP_TO_NO_GOOD=1 # required since custom-latest-ota is broken
        else
            ExtraArr=("--latest-sep")
            case $device_type in
                iPhone* | iPad5,[24] | iPad6,[48] | iPad6,12 | iPad7,[46] | iPad7,12 ) ExtraArr+=("--latest-baseband");;
                * ) ExtraArr+=("--no-baseband");;
            esac
        fi
        ExtraArr+=("--no-rsep")
    fi
    if [[ -n "$1" ]]; then
        ExtraArr+=("$1")
    fi
    if [[ -n "$2" ]]; then
        ExtraArr+=("$2")
    fi
    ExtraArr+=("-t" "$shsh_path" "$ipsw_path")
    ipsw_extract

    log "Running futurerestore with command: $futurerestore2 ${ExtraArr[*]}"
    $futurerestore2 "${ExtraArr[@]}"
    kill $httpserver_pid
    log 恢复完成✅
}

##################options#######################
function select_option() {
    if [[ $menu_old == 1 ]]; then
        select opt in "$@"; do
            selected=$((REPLY-1))
            break
        done
        return $selected
    fi

    # clear input buffer to prevent error
    if (( bash_ver > 3 )); then
        while read -s -t 0.01 -n 1; do :; done
    else
        local old=$(stty -g)
        stty -icanon -echo min 0 time 1
        dd bs=1 count=1000 if=/dev/tty of=/dev/null 2>/dev/null
        stty "$old"
    fi

    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "   $1  "; }
    print_selected()   { printf " ->$ESC[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    key_input()        { read -s -n3 key 2>/dev/null >&2
                         if [[ $key = $ESC[A ]]; then echo up;    fi
                         if [[ $key = $ESC[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - $#))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done

        # user key control
        case `key_input` in
            enter) break;;
            up)    ((selected--));
                   if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
            down)  ((selected++));
                   if [ $selected -ge $# ]; then selected=0; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected
}

function select_opt {
    select_option "$@" 1>&2
    local result=$?
    echo $result
    return $result
}

function yesno() {
    local msg="是否继续?"
    if [[ -n $1 ]]; then
        msg="$1"
    fi
    if [[ $2 == 1 ]]; then
        msg+=" (Y/n): "
    else
        msg+=" (y/N): "
    fi
    local yesno=("No" "Yes") # default is "no" by default
    if [[ $2 == 1 ]]; then # default is "yes" if $2 is set to 1
        yesno=("Yes" "No")
    fi
    input "$msg"
    select_option "${yesno[@]}"
    local res=$?
    if [[ $2 == 1 ]]; then
        [[ $res == 0 ]] && return 1 || return 0
    fi
    return $res
}

yn() {
    yesno $1 1
    if [[ $? == 1 ]]; then
        $2 #no
    else
        $3 #yes
    fi 
}

for i in "$@"; do
    case "$i" in
        "--old-menu"|"old-menu")
            menu_old=1
            ;;
        "--select-mirror"|"select-mirror")
            oscheck
            if [[ "$platform" == "linux" ]]; then
                select_apt_mirror
                log 请重新运行脚本
                exit
            else
                log macOS无需换源
                exit
            fi
            ;;
        "--restore-mirror"|"restore-mirror")
            oscheck
            if [[ "$platform" == "linux" ]]; then
                restore_default_sources
                log 请重新运行脚本
                exit
            else
                log macOS无需恢复源
                exit
            fi
            ;;
    esac
done

oscheck
set_path
clean_all
mkdir_all
get_local_ver
set_ssh_config
select_device
main_choice
pause
clean_all
