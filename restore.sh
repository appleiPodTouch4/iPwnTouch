#!/bin/bash
openssh_port="2222"
ssh_port="2222"
device_os_check=1
saved="../saved"
jelbrek=../resources/Jailbreak
ipsw_openssh=1

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

warn() {
    YELLOW='\033[33m'
    RESET='\033[0m'
    echo -e "${YELLOW}[WARNING]${RESET} ${YELLOW}$@${RESET}" > /dev/tty
    eval "$@" >/dev/null 2>&1
}

warning() {
    YELLOW='\033[33m'
    RESET='\033[0m'
    echo -e "${YELLOW}[WARNING]${RESET} ${YELLOW}$@${RESET}" > /dev/tty
    eval "$@" >/dev/null 2>&1
}

debug() {
    if [[ $(whoami) == "mry0000" ]]; then
        local BLUE='\033[38;5;45m'
        RESET='\033[0m'
        echo -e "${BLUE}[DEBUG]${RESET} ${BLUE}$@${RESET}" > /dev/tty
        eval "$@" >/dev/null 2>&1
        pause
    fi
}

print() {
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

exit() {
    rexit=1
    command exit $@
}

oscheck() {
    if [[ -f ../resources/current_platform ]]; then
        local local_platform_message=$(cat ../resources/current_platform 2>/dev/null)
    else
        local local_platform_message=""
    fi
    arch_path=
    if [[ "$device_os_check" == "1" ]]; then
        platform_check=$(uname)
        arch_check=$(uname -m)
        if [[ "$platform_check" == "Darwin" ]]; then
            platform=macos
            if [[ "$arch_check" == "x86_64" ]]; then
                platform_arch=x86_64
            elif [[ "$arch_check" == "arm64" ]]; then
                platform_arch=arm64
            else
                error Unsupport platform,please use support platform
                exit
            fi
        elif [[ "$platform_check" == "Linux" ]]; then
            platform=linux
            if [[ "$arch_check" == "x86_64" ]]; then
                platform_arch=x86_64
            elif [[ "$arch_check" == "arm64" ]]; then
                platform_arch=arm64
            else
                error Unsupport platform,please use support platform
                exit
            fi
        else
            error Unsupport platform,please use support platform
            exit
        fi
        if [[ "$platform" == "macos" ]]; then
            if [[ "$platform_arch" == "arm64" ]]; then
                if [[ "$ship_platform_check" != "1" ]]; then
                    warning "Using M-series chips may cause compatibility issues; please use with caution."
                    pause Press Enter to ignore this issue.  
                fi
                dir="../bin/macos/arm64"
            else
                dir="../bin/macos"
            fi
            macos_ver="${1:-$(sw_vers -productVersion)}"
            macos_major_ver="${macos_ver:0:2}"
            if [[ $macos_major_ver == 10 ]]; then
                macos_minor_ver=${macos_ver:3}
                macos_minor_ver=${macos_minor_ver%.*}
                if (( macos_minor_ver < 11 )); then
                    if [[ "$ship_platform_check" != "1" ]]; then
                        error "Your macOS version is too old. Please upgrade to macOS High Sierra or later."
                        exit
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
                warning "运行在macOS12+可能会出现一些问题,是否继续?"
                yesno continue?
                 if [[ $? == 1 ]]; then
                    :
                else
                    exit
                fi
            fi
            platform_message="macOS ${macos_name}($platform_arch)"
        elif [[ "$platform" == "linux" ]]; then
            warning Linux仍然在适配中,可能会出现一些严重bug,是否继续？
            yesno
            if [[ $? == 1 ]]; then
                :
            else
                exit
            fi
            check_sudo
            linux_part
            arch_path="linux/"
            linux_name=$(grep '^NAME=' /etc/os-release | cut -d'"' -f2)
            platform_message="${linux_name} ($platform_arch)"
            dir="../bin/linux/$platform_arch"
            if [[ $linux_name != Ubuntu ]]; then
                error Support ubuntu only,change your distro to ubuntu
                exit
            fi
        fi
    fi
    if [[ $platform_message != $local_platform_message ]]; then
        install_depends
    fi

}

set_path() {
    if [[ "$script_dir/" =~ [[:space:]] ]]; then
        warning "Directory path contains whitespace characters！" >&2
        warning "Current directory: '$script_dir'" >&2
        pause Press enter to exit
        exit 1
    fi
    if [[ $1 == "ramdisk" ]] && [[ $platform_arch == "arm64" && $platform == "linux" ]]; then
        local dir="../bin/linux/x86_64"
    elif [[ $1 == "ramdisk" ]]; then
        return
    fi
    chmod +x $dir/*
    if [[ "$platform" == "macos" ]]; then
        sshpass=""
        irecovery=""
        iproxy=""
        ipwnder=""
        idevicerestore=""
        futurerestore=""
        futurerestore_old=""
        ideviceinfo=""
        dmg=""
        zenity="$dir/zenity"
        ideviceactivation=""
        ideviceinstaller=""
        primepwn=""
        gaster=""
        iBoot32Patcher=""
        xpwntool=""
        hfsplus=""
        pzb=""
        jq=""
        ticket=""
        validate=""
        img4tool=""
        irecovery2=""
        aria2c=""
        tsschecker=""
        z7z=""
        sha1sum="$(command -v shasum) -a 1"
        bspatch="$(command -v bspatch)"
        PlistBuddy="/usr/libexec/PlistBuddy"
        KPlooshFinder=""
        gtar=""
        img4=""
        kerneldiff=""
        Kernel64Patcher=""
        iBoot64Patcher=""
        kairos=""
        lanzou=""
        sqlite3=""
        idevicediagnostics=""
        pymobiledevice3=""
    elif [[ "$platform" == "linux" ]]; then
        export LD_LIBRARY_PATH="$dir/lib"
        sshpass="sudo "
        irecovery="sudo "
        iproxy="sudo "
        ipwnder="sudo "
        idevicerestore="sudo LD_LIBRARY_PATH=$dir/lib "
        futurerestore="sudo "
        futurerestore_old="sudo "
        ideviceinfo="sudo LD_LIBRARY_PATH=$dir/lib "
        dmg="sudo "
        zenity="sudo GSETTINGS_BACKEND=memory $(command -v zenity)"
        ideviceactivation="sudo LD_LIBRARY_PATH=$dir/lib "
        ideviceinstaller="sudo LD_LIBRARY_PATH=$dir/lib "
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
        afc="sudo "
        bspatch="$dir/bspatch"
        PlistBuddy="$dir/PlistBuddy"
        KPlooshFinder="sudo "
        gtar="sudo "
        img4="sudo "
        kerneldiff="sudo "
        Kernel64Patcher="sudo "
        iBoot64Patcher="sudo "
        kairos="sudo "
        sqlite3="sudo "
        idevicediagnostics="sudo "
        pymobiledevice3="sudo "
    fi
    
    # 原有工具
    sshpass+=$dir/sshpass
    irecovery+="$dir/irecovery"
    iproxy+=$dir/iproxy
    ipwnder+=$dir/ipwnder
    gaster+=$dir/gaster
    idevicerestore+=$dir/idevicerestore
    futurerestore+=$dir/futurerestore
    futurerestore_old+=$dir/futurerestore_old
    ideviceinfo+=$dir/ideviceinfo
    dmg+=$dir/dmg
    ideviceactivation+=$dir/ideviceactivation
    ideviceinstaller+=$dir/ideviceinstaller
    primepwn+=$dir/primepwn
    iBoot32Patcher+=$dir/iBoot32Patcher
    xpwntool+=$dir/xpwntool
    hfsplus+=$dir/hfsplus
    pzb+=$dir/pzb
    jq+=$dir/jq
    ticket+=$dir/ticket
    validate+=$dir/validate
    img4tool+=$dir/img4tool
    irecovery2+=$dir/irecovery2
    aria2c+=$dir/aria2c
    tsschecker+=$dir/tsschecker
    z7z+=$dir/7zz
    afc+=$dir/afc_tool
    KPlooshFinder+=$dir/KPlooshFinder
    gtar+=$dir/gtar
    img4+=$dir/img4
    kerneldiff+=$dir/kerneldiff
    Kernel64Patcher+=$dir/Kernel64Patcher
    iBoot64Patcher+=$dir/iBoot64Patcher
    kairos+=$dir/kairos
    sha1sum="$(command -v shasum) -a 1"
    lanzou+=$dir/lanzou
    sqlite3+=$dir/sqlite3
    idevicediagnostics+=$dir/idevicediagnostics
    pymobiledevice3+=$dir/pymobiledevice3
}

set_ssh_config() {
    if [ -z "$1" ]; then
        cp ../resources/ssh_config .
        if [[ $(ssh -V 2>&1 | grep -c SSH_8.8) == 1 || $(ssh -V 2>&1 | grep -c SSH_8.9) == 1 ||
            $(ssh -V 2>&1 | grep -c SSH_9.) == 1 || $(ssh -V 2>&1 | grep -c SSH_1) == 1 ]]; then
            echo "    PubkeyAcceptedAlgorithms +ssh-rsa" >> ./ssh_config
        elif [[ $(ssh -V 2>&1 | grep -c SSH_6) == 1 ]]; then
            cat ssh_config | sed "s,Add,#Add,g" | sed "s,HostKeyA,#HostKeyA,g" > ssh_config
        fi
    fi
    
    if [ -z "$1" ]; then
        ssh="$dir/sshpass -p alpine ssh -F ./ssh_config"
        scp="$dir/sshpass -p alpine scp -F ./ssh_config"
    fi
    
    if [[ "$1" == "pass" ]]; then
        ssh="$dir/sshpass -p $2 ssh -F ./ssh_config"
        scp="$dir/sshpass -p $2 scp -F ./ssh_config"
    fi
}

checkmode() {
    local mode_cn
    if [[ $1 != all ]]; then
        case $1 in
            "nor" ) mode_cn="正常";;
            "rec" ) mode_cn="恢复";;
            "DFU" | "WTF" ) mode_cn="$device_mode";;
            "DFUall" ) mode_cn="DFU";;
        esac
        log "等待设备进入${mode_cn}模式"
    else
        log 等待设备连接
    fi
    if [[ $platform == macos && $macos_name == Tahoe ]]; then
        checkmode_irec $1
    else
        checkmode_sys $1
    fi
}

checkmode_sys() {
    local target_mode="$1"
    
    if [[ "$platform" == "macos" ]]; then
        case $target_mode in
            WTF)
                while true; do
                    usb_info=$(system_profiler SPUSBDataType 2>/dev/null)
                    if echo "$usb_info" | grep -q ' USB DFU Device'; then
                        device_mode="WTF"
                        break
                    fi
                    sleep 1
                done
                ;;
            DFU)
                while true; do
                    usb_info=$(system_profiler SPUSBDataType 2>/dev/null)
                    if echo "$usb_info" | grep -q ' Apple Mobile Device (DFU Mode)'; then
                        device_mode="DFU"
                        break
                    fi
                    sleep 1
                done
                ;;
            rec)
                while true; do
                    usb_info=$(system_profiler SPUSBDataType 2>/dev/null)
                    if echo "$usb_info" | grep -q 'Apple Mobile Device (Recovery Mode)'; then
                        device_mode="Recovery"
                        break
                    fi
                    sleep 1
                done
                ;;
            nor)
                while true; do
                    usb_info=$(system_profiler SPUSBDataType 2>/dev/null)
                    if echo "$usb_info" | grep -q ' iPod'; then
                        device_mode="Normal"
                        break
                    fi
                    if echo "$usb_info" | grep -q ' iPhone'; then
                        device_mode="Normal"
                        break
                    fi
                    sleep 1
                done
                ;;
            DFUall)
                while true; do
                    usb_info=$(system_profiler SPUSBDataType 2>/dev/null)
                    if echo "$usb_info" | grep -q ' Apple Mobile Device (DFU Mode)'; then
                        device_mode="DFU"
                        break
                    fi
                    if echo "$usb_info" | grep -q ' USB DFU Device'; then
                        device_mode="WTF"
                        break
                    fi
                    sleep 1
                done
                ;;
            all)
                while true; do
                    usb_info=$(system_profiler SPUSBDataType 2>/dev/null)
                    if echo "$usb_info" | grep -q ' Apple Mobile Device (DFU Mode)'; then
                        device_mode="DFU"
                        break
                    fi
                    if echo "$usb_info" | grep -q ' USB DFU Device'; then
                        device_mode="WTF"
                        break
                    fi
                    if echo "$usb_info" | grep -q ' iPod'; then
                        device_mode="Normal"
                        break
                    fi
                    if echo "$usb_info" | grep -q ' iPhone'; then
                        device_mode="Normal"
                        break
                    fi
                    if echo "$usb_info" | grep -q 'Apple Mobile Device (Recovery Mode)'; then
                        device_mode="Recovery"
                        break
                    fi
                    sleep 1
                done
                ;;
        esac
    elif [[ "$platform" == "linux" ]]; then
        if [[ -z $(command -v lsusb) ]]; then
            checkmode_irec "$target_mode"
            return
        fi
        
        case $target_mode in
            WTF)
                while true; do
                    usb_info=$(lsusb 2>/dev/null)
                    if echo "$usb_info" | grep -q ' USB DFU Device'; then
                        device_mode="WTF"
                        break
                    fi
                    sleep 1
                done
                ;;
            DFU)
                while true; do
                    usb_info=$(lsusb 2>/dev/null)
                    if echo "$usb_info" | grep -q ' Apple, Inc. Mobile Device (DFU Mode)'; then
                        device_mode="DFU"
                        break
                    fi
                    sleep 1
                done
                ;;
            rec)
                while true; do
                    usb_info=$(lsusb 2>/dev/null)
                    if echo "$usb_info" | grep -q '.*Recovery Mode.*'; then
                        device_mode="Recovery"
                        break
                    fi
                    sleep 1
                done
                ;;
            nor)
                while true; do
                    usb_info=$(lsusb 2>/dev/null)
                    if echo "$usb_info" | grep -q ' iPod'; then
                        device_mode="Normal"
                        break
                    fi
                    if echo "$usb_info" | grep -q ' iPhone'; then
                        device_mode="Normal"
                        break
                    fi
                    sleep 1
                done
                ;;
            DFUall)
                while true; do
                    usb_info=$(lsusb 2>/dev/null)
                    if echo "$usb_info" | grep -q ' Apple, Inc. Mobile Device (DFU Mode)'; then
                        device_mode="DFU"
                        break
                    fi
                    if echo "$usb_info" | grep -q ' USB DFU Device'; then
                        device_mode="WTF"
                        break
                    fi
                    sleep 1
                done
                ;;
            all)
                while true; do
                    usb_info=$(lsusb 2>/dev/null)
                    if echo "$usb_info" | grep -q ' Apple, Inc. Mobile Device (DFU Mode)'; then
                        device_mode="DFU"
                        break
                    fi
                    if echo "$usb_info" | grep -q ' USB DFU Device'; then
                        device_mode="WTF"
                        break
                    fi
                    if echo "$usb_info" | grep -q ' iPod'; then
                        device_mode="Normal"
                        break
                    fi
                    if echo "$usb_info" | grep -q ' iPhone'; then
                        device_mode="Normal"
                        break
                    fi
                    if echo "$usb_info" | grep -q '.*Recovery Mode.*'; then
                        device_mode="Recovery"
                        break
                    fi
                    sleep 1
                done
                ;;
        esac
    fi
}

checkmode_irec() {
    local mode
    case $1 in
        nor )
        while true; do
            device_vers=$($ideviceinfo -s 2>/dev/null | grep "ProductVersion:" | cut -d' ' -f2)
            if [[ $device_vers =~ ^[0-9]+\.[0-9]+(\.[0-9]+)*$ ]]; then
                device_mode="Normal"
                device_build=$($ideviceinfo -s 2>/dev/null | grep "BuildVersion:" | cut -d' ' -f2)
                break
            else
                device_mode=""
            fi
            sleep 1
        done
        ;;
        rec | DFU | DFUall )
        while true; do
            device_mode="$($irecovery -q 2>/dev/null | grep -w "MODE" | cut -c 7-)"
            if [[ $device_mode == "$mode" ]]; then
                break
            elif [[ $device_mode == "WTF" ]]; then
                break
            else
                device_mode=""
            fi
            sleep 1
        done
        ;;
        all )
        while true; do
            device_vers=$($ideviceinfo -s 2>/dev/null | grep "ProductVersion:" | cut -d' ' -f2)
            device_mode="$($irecovery -q 2>/dev/null | grep -w "MODE" | cut -c 7-)"
            if [[ $device_mode == "Recovery" || $device_mode == "DFU" || $device_mode == "WTF" ]]; then
                break
            fi
            if [[ $device_vers =~ ^[0-9]+\.[0-9]+(\.[0-9]+)*$ ]]; then
                device_mode="Normal"
                break
            fi
            sleep 1
        done
        ;;
    esac
}

device_info() {
    clear
    checkmode all
    case $device_mode in
        "Normal" ) mode_cn="正常";;
        "Recovery" ) mode_cn="恢复";;
        "DFU" | "WTF" ) mode_cn="$device_mode";;
    esac
    if [[ -n $device_type && $device_type =~ ^(iPhone|iPad|iPod)[1-9]*,[0-9]+$ ]]; then
        device_get_info
        return
    fi
    if [[ -z $device_type ]]; then
        case $device_mode in
            "WTF" | "DFU" | "Recovery" ) device_type=$($irecovery -q | grep "PRODUCT" | cut -c 10-);;
            "Normal" ) 
                device_type=$($ideviceinfo -s -k ProductType 2>/dev/null)
                [[ -z $device_type ]] && device_type=$($ideviceinfo -k ProductType 2>/dev/null)
                if [[ $device_type == "iPhone3,1" ]] || [[ $device_type == "iPhone3,1" ]]; then
                    device_type="iPod4,1"
                fi
                ;;
        esac
    fi
    if [[ $device_type =~ ^(iPhone|iPad|iPod)[1-9]*,[0-9]+$ ]]; then
        :
    else
        local try1=0
        while true; do
            warning 设备名称格式错误,请手动输入
            read $device_type
            if [[ $device_type =~ ^(iPhone|iPad|iPod)[1-9]*,[0-9]+$ ]]; then
                break
            elif [[ $try1 == 10 ]];then
                error "无法识别设备"
                exit
            fi
            ((try1++))
        done
    fi
    case $device_type in
        iPhone* | iPad* ) 
        warning "本设备不在本工具支持范围内,是否继续"
        yesno
        if [[ $? != 1 ]]; then
            exit
        else
            device_unsupport=1
        fi
        ;;
        * ) :;;
    esac
    if [ ! -d "$saved/$device_type" ]; then
        mkdir $saved/$device_type
    fi
    device_get_info
    log "获取设备信息"
    case $device_mode in
        Normal )
            device_ecid=$($ideviceinfo -s -k UniqueChipID)
            device_vers=$($ideviceinfo -s 2>/dev/null | grep "ProductVersion:" | cut -d' ' -f2)
            device_build=$($ideviceinfo -s 2>/dev/null | grep "BuildVersion:" | cut -d' ' -f2)
            device_serial="$($ideviceinfo -k SerialNumber | cut -c 3- | cut -c -3)"
            if [[ $device_type == "iPod2,1" ]]; then
                device_newbr="$($ideviceinfo -k ModelNumber | grep -c 'C')"
            fi
            device_uuid=$($ideviceinfo -s -k UniqueDeviceID)
            device_color=$($ideviceinfo -s -k DeviceColor)
            #removed,because it stucks too long and it's only used for a5 bypass
            #device_region=$($pymobiledevice3 lockdown info | grep '"RegionInfo"' | awk -F': ' '{print $2}' | tr -d '",')
            #device_model_number=$($pymobiledevice3 lockdown info | grep '"ModelNumber"' | awk -F': ' '{print $2}' | tr -d '",')
            ;;
        DFU | WTF | Recovery )
            device_ecid=$($idevicerestore -l 2>/dev/null | grep -i "ECID" | awk '{print $3}')
            device_serial="$($irecovery -q | grep "SRNM" | cut -c 7- | cut -c 3- | cut -c -3)"
            device_cpid=$($irecovery -q | grep CPID | sed 's/CPID: //')
            if [[ $device_mode == "DFU" ]]; then
                device_pwnd="$($irecovery -q | grep "PWND" | cut -c 7-)"
                if [[ -n $device_pwnd ]]; then
                    device_have_pwnd=1
                fi
                device_serial="$($irecovery -q | grep "SRNM" | cut -c 7- | cut -c 3- | cut -c -3)"   
            elif [[ $device_mode == "Recovery" ]]; then
                device_iboot_vers=$(echo "/exit" | $irecovery -s | grep -a "iBoot-")
            fi
            if [[ $device_type == "iPod2,1" && $device_newbr != 2 ]]; then
                device_newbr="$($irecovery -q | grep -c '240.5.1')"
            fi
            ;;
    esac
    all_flash="Firmware/all_flash/all_flash.${device_model}ap.production"
}

device_get_info() {
    if [[ $device_type == iPhone1,1 ]]; then
        device_type="iPod1,1"
    elif [[ $device_type == "iPhone3,1" ]] || [[ $device_type == "iPhone3,3" ]]; then
        device_type="iPod4,1"
    fi
    case $device_type in
        iPod1,1 )
            device_proc=1;; # S5L8900
        iPod[234],1 )
            device_proc=4;; # A4/S5L8720/8920/8922
        iPod5,1 )
            device_proc=5;; # A5
        iPod7,1 )
            device_proc=8;; # A8
        iPod9,1 )
            device_proc=10;; # A10
    esac
    case $device_proc in
        "1"|"4"|"5" ) device_64bit=0;;
        * ) device_64bit=1;;
    esac
    case $device_type in
        iPod1,1 ) 
            de=1
            device_latest_vers="3.1.3"
            device_use_build="7E18"
            device_model="n45";;
        iPod2,1 ) 
            de=2
            device_latest_vers="4.2.1"
            device_use_build="8C148"
            device_model="n72";;
        iPod3,1 ) 
            de=3
            device_latest_vers="5.1.1"
             device_use_build="9B206"
            device_model="n18";;
        iPod4,1 ) 
            de=4
            device_latest_vers="6.1.6"
            device_use_build="10B500"
            device_model="n81";;
        iPod5,1 ) 
            de=5
            device_latest_vers="9.3.5"
            device_use_build="13G36"
            device_model="n78";;
        iPod7,1 ) 
            de=6
            device_latest_vers="12.5.8"
            device_latest_build="16H88"
            device_model="n102";;
        iPod9,1 ) 
            de=7
            device_latest_vers="15.8.6"
            device_latest_build="19H402"
            device_model="n112";;
    esac
    case $device_type in
        iPod[35],1 ) device_canpowder=1;;
    esac
    case $device_latest_vers in
        10* ) ipsw_gasgauge_patch=;;
        [76543]* ) ipsw_canjailbreak=1;;
    esac
}

device_info2() {
    clear
    if [[ -n $device_type && $device_type =~ ^(iPhone|iPod)[1-9]*,[1]+$ ]]; then
        case $device_type in
            iPod[1234579],1 ) device_get_info ;return ;;
            * ) device_type="" ;;
        esac
    fi
    input 请选择设备
    options=("iPod touch1" "iPod touch2" "iPod touch3" "iPod touch4" "iPod touch5" "iPod touch6" "iPod touch7" "退出")
    select_option "${options[@]}"
    selected="${options[$?]}"
    case $selected in
        "iPod touch1" ) device_type=iPod1,1 ;;
        "iPod touch2" ) device_type=iPod2,1 ;;
        "iPod touch3" ) device_type=iPod3,1 ;;
        "iPod touch4" ) device_type=iPod4,1 ;;
        "iPod touch5" ) device_type=iPod5,1 ;;
        "iPod touch6" ) device_type=iPod7,1 ;;
        "iPod touch7" ) device_type=iPod9,1 ;;
        "退出" ) exit;;
    esac
    device_get_info
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
        return
    else
        local target_version="${1:-3.0.3}"
        local plist_file="${2:-/Applications/i4tools.app/Contents/Info.plist}"
        local version=$($PlistBuddy -c "Print CFBundleShortVersionString" "$plist_file" 2>/dev/null)
        if [ -n "$version" ]; then
            log "爱思版本:$version"
            case $version in
                1.* | 2.* | 3.0.[1234] | 9.* ) ok=1;;
            esac
            if [ "$ok" = "1" ]; then
                return
            else
                warning "检测到此版本的爱思助手无法破解DFU,请关闭爱思助手或使用老版本(若忽略按回车继续,否则关闭爱思后继续)"
                exit 1
            fi
        fi
    fi
}

checkpwn() {
    device_pwnd="$($irecovery -q | grep "PWND" | cut -c 7-)"
    if [[ -n $device_pwnd ]]; then
        log 设备已进入破解DFU✅
    else
        if [[ "$1" != "noerror" ]]; then
            error 破解DFU失败.确保关闭爱思助手后重试
            main_menu
            return
        fi
    fi
}

device_pwn() {
    local a5
    log 正在破解DFU
    local device_pwnd="$($irecovery -q | grep "PWND" | cut -c 7-)"
    if [[ -z $device_pwnd ]]; then
        case $device_proc in
            1 ) device_s5l8900xall ;;
            4 ) 
            case $device_type in
                iPod[24],1 )
                if [[ $platform == linux ]]; then
                    log Pwn:primepwn
                    $ipwnder -p
                else
                    log Pwn:primepwn
                    $primepwn
                fi
                ;;
                * )
                log Pwn:ipwnder
                if [[ $platform == macos ]]; then
                    $ipwnder
                else
                    $ipwnder -p
                fi
                ;;
            esac
             ;;
            5 ) a5=1 ;;
            6 )
            log Pwn:ipwnder
            if [[ $platform == macos ]]; then
                $ipwnder
            else
                $ipwnder -p
            fi
            ;;
            8 | 10 )
            log "Pwn:gaster"
            $gaster pwn
            ;;
        esac
    fi
    if [[ $device_proc == 5 ]]; then
        if [[ $ship_send_pwnibss != 1 ]]; then 
            while true; do
                local device_pwnd2="$($irecovery -q | grep "PWND" | cut -c 7-)"
                if [ "$device_pwnd2" != "checkm8" ]; then
                    print "pwn a5 device needs Arduino+USB Host Shield or Pi Pico"
                    yesno "如果你已经发送了Pwn ibss,请选择YES"
                    if [[ $? == 1 ]]; then
                        return
                    fi
                else
                    break
                fi
            done
            device_send_unpacked_ibss
        else
            warning make sure you have been sent pwnibss
            pause press enter to continue
        fi
    fi
    device_pwnd1="$($irecovery -q | grep "PWND" | cut -c 7-)"
    if [[ $device_proc != 1 ]]; then
        if [[ $device_proc != 5 && $device_proc != 6 ]]; then
            if [[ -n $device_pwnd1 ]]; then
                log 破解DFU成功✅
                device_have_pwnd=1
            else
                error "无法破解DFU❎(请关闭爱思助手后再次尝试)"
                exit 1
            fi
        else
            log 破解DFU成功✅
            log 若发送iBEC或者其他文件时卡住,则为破解失败,请重试
        fi
    fi
}

device_s5l8900xall() {
    local wtf_sha="cb96954185a91712c47f20adb519db45a318c30f"
    local wtf_saved="../saved/patches/WTF.s5l8900xall.RELEASE.dfu"
    local wtf_patched="$wtf_saved.patched"
    local wtf_patch="../resources/patch/WTF.s5l8900xall.RELEASE.patch"
    local wtf_sha_local="$($sha1sum "$wtf_saved" 2>/dev/null | awk '{print $1}')"
    mkdir ../saved 2>/dev/null
    mkdir ../saved/patches 2>/dev/null
    if [[ $wtf_sha_local != "$wtf_sha" ]]; then
        log "Downloading WTF.s5l8900xall"
        "$dir/pzb" -g "Firmware/dfu/WTF.s5l8900xall.RELEASE.dfu" -o WTF.s5l8900xall.RELEASE.dfu "http://appldnld.apple.com/iPhone/061-7481.20100202.4orot/iPhone1,1_3.1.3_7E18_Restore.ipsw"
        rm -f "$wtf_saved"
        mv WTF.s5l8900xall.RELEASE.dfu $wtf_saved
    fi
    wtf_sha_local="$($sha1sum "$wtf_saved" | awk '{print $1}')"
    if [[ $wtf_sha_local != "$wtf_sha" ]]; then
        error "SHA1sum mismatch. Expected $wtf_sha, got $wtf_sha_local. Please run the script again"
    fi
    rm -f "$wtf_patched"
    log "Patching WTF.s5l8900xall"
    $bspatch $wtf_saved $wtf_patched $wtf_patch
    log "Sending patched WTF.s5l8900xall (Pwnage 2.0)"
    $irecovery -f "$wtf_patched"
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
}

patch_ibss() {
    # creates file pwnediBSS to be sent to device
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
    log "Decrypting iBSS..."
    "$dir/xpwntool" iBSS iBSS.dec -iv $iv -k $key
    log "Patching iBSS..."
    "$dir/iBoot32Patcher" iBSS.dec pwnediBSS --rsa
    "$dir/xpwntool" pwnediBSS pwnediBSS.dfu -t iBSS
    cp pwnediBSS pwnediBSS.dfu ../saved/$device_type/
    log "Pwned iBSS saved at: saved/$device_type/pwnediBSS"
    log "Pwned iBSS img3 saved at: saved/$device_type/pwnediBSS.dfu"
}

patch_ibec() {
    # creates file pwnediBEC to be sent to device for blob dumping
    local build_id
    if [[ ! -f ../saved/$device_type/pwnediBEC.dfu ]]; then
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
        mv iBEC $name.orig
        log "Decrypting iBEC..."
        "$dir/xpwntool" $name.orig $name.dec -iv $iv -k $key
        log "Patching iBEC..."
        if [[ $device_proc == 4 || -n $device_rd_build || $device_type == "iPad3,1" ]]; then
            "$dir/iBoot32Patcher" $name.dec $name.patched --rsa --ticket -b "rd=md0 -v amfi=0xff cs_enforcement_disable=1" -c "go" $address
        else
            $bspatch $name.dec $name.patched "../resources/patch/$download_targetfile.patch"
        fi
        "$dir/xpwntool" $name.patched pwnediBEC.dfu -t $name.orig
        rm $name.dec $name.orig $name.patched
        cp pwnediBEC.dfu ../saved/$device_type/
        log "Pwned iBEC img3 saved at: saved/$device_type/pwnediBEC.dfu"
    else
        log Found exist Pwned iBEC
        cp ../saved/$device_type/pwnediBEC.dfu .
    fi
}

device_send_unpacked_ibss() {
    local pwnrec="pwned iBSS"
    device_rd_build=
    patch_ibss
    log "发送破解pwn iBSS"
    $primepwn pwnediBSS
    local tool_pwned=$?
    if [[ $tool_pwned != 0 ]]; then
        error "发送pwn iBSS失败"
    fi
    sleep 1
    log "Checking for device"
    local irec="$($irecovery -q 2>&1)"
    device_pwnd="$(echo "$irec" | grep "PWND" | cut -c 7-)"
    if [[ -z $device_pwnd && $irec != "ERROR"* ]]; then
        log "设备处于 $pwnrec 模式"
        log 破解DFU成功✅
    else
        error "设备进入${pwnrec}模式失败"
        error "无法破解DFU❎(请关闭爱思助手后再次尝试)"
        exit 1
    fi
}

download_comp() {
    # usage: download_comp [build_id] [comp]
    local build_id="$1"
    local comp="$2"
    ipsw_get_url $build_id
    download_targetfile="$comp.$device_model"
    if [[ $build_id != "12"* ]]; then
        download_targetfile+="ap"
    fi
    download_targetfile+=".RELEASE"

    if [[ -e "../saved/$device_type/${comp}_$build_id.dfu" ]]; then
        cp "../saved/$device_type/${comp}_$build_id.dfu" ${comp}
    else
        log "Downloading ${comp}..."
        "$dir/pzb" -g "Firmware/dfu/$download_targetfile.dfu" -o ${comp} "$ipsw_url"
        cp ${comp} "../saved/$device_type/${comp}_$build_id.dfu"
    fi
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

cut_os_build() {
    local num
    num=$(echo "$1" | cut -c1-2)
    case $num in
        3 ) major_ver="1" ;minor_ver="0";;
        4 ) major_ver="1" ;minor_ver="1";;
        5 ) major_ver="2";;
        7 ) major_ver="3";;
        8 ) major_ver="4";;
        9 ) major_ver="5";;
        10 ) major_ver="6";;
        11 ) major_ver="7";;
        12 ) major_ver="8";;
        13 ) major_ver="9";;
        14 ) major_ver="10";;
        15 ) major_ver="11";;
        16 ) major_ver="12";;
        17 ) major_ver="13";;
        18 ) major_ver="14";;
        19 ) major_ver="15";;
    esac
}

device_power() {
    case $1 in
        "reboot" ) $idevicediagnostics restart;;
        "shutdown" )$idevicediagnostics shutdown;;
    esac
}

#######ramdisk###########

#use sshrd32_script

ramdisk() {
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
    local local_build_id
    local files
    local rec=2
    all_flash="Firmware/all_flash/all_flash.${device_model}ap.production"
    if [[ no_ramdisk == 1 ]]; then
        return
    fi
    if [[ $1 == "setnvram" ]]; then
        rec=$2
    fi
    if [[ $1 != "justboot" ]]; then
        comps+=("RestoreRamdisk")
    fi
    case $device_type in
        iPhone1,[12] | iPod1,1 ) device_target_build="7E18"; device_target_vers="3.1.3";;
        iPod2,1 ) device_target_build="8C148";;
        iPod3,1 | iPad1,1 ) device_target_build="9B206";;
        iPhone2,1 | iPod4,1 ) device_target_build="10B500";;
        iPhone5,[34] ) device_target_build="11D257";;
        * ) device_target_build="10B329";;
    esac
    if [[ $just_useipsw == 1 ]] && [[ $1 == "justboot" ]]; then
        if [[ -n $device_rd_ver ]]; then
            ipsw_menu justboot target_ver=$device_rd_ver
        elif [[ -n $device_rd_build ]]; then
            ipsw_menu justboot target_ver=$device_rd_build
        else
            ipsw_menu justboot
        fi
    elif [[ $just_useipsw == 1 ]]; then
        if [[ -n $device_rd_ver ]]; then
            ipsw_menu ramdisk target_ver=$device_rd_ver
        elif [[ -n $device_rd_build ]]; then
            ipsw_menu ramdisk target_build=$device_rd_build
        else
            ipsw_menu ramdisk target_build=$device_target_build
        fi
        get_ipsw_info ipsw $ipsw_path.ipsw
    fi

    if [[ -n $device_rd_build_custom ]]; then
        if [[ -n $ipsw_path && $device_ipsw_build != $device_rd_build ]]; then
            error You have seleted $device_ipsw_build iPSW,but you want use $device_rd_build ssh ramdisk,please seleted right ipsw or cancal choose specified version
            exit 1
        fi
        print "*Use custom version:$device_rd_build*"
    elif [[ -n $ipsw_path ]]; then
        device_rd_build=$device_ipsw_build
    fi
    if [[ -n $device_rd_build ]]; then
        device_target_build=$device_rd_build
        device_rd_build=
    fi

    version=$device_target_vers
    build_id=$device_target_build
    device_fw_key_check
    if [[ -z $ipsw_path ]]; then
        ipsw_get_url $build_id $version
    fi
    if [[ $arg_l != 1 ]]; then
        ramdisk_path="../saved/$device_type/ramdisk_$build_id"
    else
        ramdisk_path="../current_ramdisk"
        if [[ -f ../current_ramdisk/build_id ]]; then
            local_build_id=$(cat ../current_ramdisk/build_id)
            if [[ $local_build_id != $build_id ]]; then
                log Clean old ramdsk
                rm -f ../current_ramdisk
            fi
        fi
    fi
    if [[ -d $ramdisk_path ]]; then
        local ramdisk_files=("Ramdisk.dmg" "DeviceTree.dec" "Kernelcache.dec")
        for files in $ramdisk_files; do
            if [[ ! -f $ramdisk_path/$files ]]; then
                warning "$files missed,redownload"
                pause
                rm -rf $ramdisk_path
                break
            fi
        done
    fi
    mkdir $ramdisk_path 2>/dev/null
    if [[ $arg_l == 1 ]]; then
        touch ../current_ramdisk/build_id
        echo "$build_id" > "../current_ramdisk/build_id"
    fi
    if [[ $just_boot != 1 ]]; then
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
                    [12345789]* | 10* | 11* ) hwmodel+="ap";;
                esac
                case $getcomp in
                    "iBSS" | "iBEC" ) name="$getcomp.$hwmodel.RELEASE.dfu";;
                    "DeviceTree" )    
                        if [[ $plist_legacy == 1 && $device_ipsw_build == 3* ]]; then
                            name="$getcomp.${device_model}ap.img2"
                        else
                            name="$getcomp.${device_model}ap.img3"
                        fi
                        ;;
                    "Kernelcache" ) 
                        if [[ $plist_legacy == 1 && $device_ipsw_build == 3* ]]; then
                            name="kernelcache.release.*"
                        else  
                            name="kernelcache.release.$hwmodel"
                        fi
                        ;;
                esac
            fi

            log "$getcomp"
            if [[ -n $ipsw_justboot_path ]]; then
                file_extract_from_archive "$ipsw_justboot_path.ipsw" "${path}$name"
            elif [[ -s $ramdisk_path/$name ]]; then
                cp $ramdisk_path/$name .
            elif [[ -n $ipsw_path ]]; then
                unzip -p $ipsw_path.ipsw "${path}$name" > $name
            else
                "$dir/pzb" -g "${path}$name" -o "$name" "$ipsw_url"
            fi
            if [[ ! -s $name ]]; then
                error "Failed to get $name. Please run the script again."
            fi
            if [[ ! -s $ramdisk_path/$name ]]; then
                cp $name $ramdisk_path/
            fi
            mv $name $getcomp.orig
            if [[ $getcomp == "Kernelcache" || $getcomp == "iBSS" ]] && [[ $device_proc == 1 || $device_type == "iPod2,1" ]]; then
                decrypt="-iv $iv -k $key"
                "$dir/xpwntool" $getcomp.orig $getcomp.dec $decrypt
                pause
            elif [[ $build_id == "14"* ]]; then
                cp $getcomp.orig $getcomp.dec
            else
                "$dir/xpwntool" $getcomp.orig $getcomp.dec -iv $iv -k $key -decrypt
            fi
        done

        if [[ $1 != "justboot" ]]; then
            log "Make RestoreRamdisk"
            "$dir/xpwntool" RestoreRamdisk.dec Ramdisk.raw
            if [[ $device_proc != 1 ]]; then
                "$dir/hfsplus" Ramdisk.raw grow 30000000
                "$dir/hfsplus" Ramdisk.raw untar ../resources/ramdisk32/sbplist.tar
            fi
        fi

        if [[ $device_proc == 1 ]]; then
            $bspatch Ramdisk.raw Ramdisk.patched ../resources/patch/018-6494-014.patch
            "$dir/xpwntool" Ramdisk.patched Ramdisk.dmg -t RestoreRamdisk.dec
            log "Make iBSS"
            $bspatch iBSS.orig iBSS ../resources/patch/iBSS.${device_model}ap.RELEASE.patch
            log "Make Kernelcache"
            mv Kernelcache.dec Kernelcache0.dec
            $bspatch Kernelcache0.dec Kernelcache.patched ../resources/patch/kernelcache.release.s5l8900x.patch
            "$dir/xpwntool" Kernelcache.patched Kernelcache.dec -t Kernelcache.orig $decrypt
            rm DeviceTree.dec
            mv DeviceTree.orig DeviceTree.dec
        elif [[ $device_type == "iPod2,1" ]]; then
            "$dir/hfsplus" Ramdisk.raw untar ../resources/ramdisk32/ssh_old.tar
            "$dir/xpwntool" Ramdisk.raw Ramdisk.dmg -t RestoreRamdisk.dec
            log "Make iBSS"
            $bspatch iBSS.dec iBSS.patched ../resources/patch/iBSS.${device_model}ap.RELEASE.patch
            "$dir/xpwntool" iBSS.patched iBSS -t iBSS.orig
            log "Make Kernelcache"
            mv Kernelcache.dec Kernelcache0.dec
            $bspatch Kernelcache0.dec Kernelcache.patched ../resources/patch/kernelcache.release.${device_model}.patch
            "$dir/xpwntool" Kernelcache.patched Kernelcache.dec -t Kernelcache.orig $decrypt
            rm DeviceTree.dec
            mv DeviceTree.orig DeviceTree.dec
        else
            if [[ $1 != "justboot" ]]; then
                "$dir/hfsplus" Ramdisk.raw untar ../resources/ramdisk32/ssh.tar
                if [[ $1 == "jailbreak" && $device_vers == "8"* ]]; then
                    "$dir/hfsplus" Ramdisk.raw untar ../resources/jailbreak/daibutsu/bin.tar
                fi
                "$dir/hfsplus" Ramdisk.raw mv sbin/reboot sbin/reboot_bak
                "$dir/hfsplus" Ramdisk.raw mv sbin/halt sbin/halt_bak
                case $build_id in
                        "12"* | "13"* | "14"* )
                        echo '#!/bin/bash' > restored_external
                        echo "/sbin/sshd; exec /usr/local/bin/restored_external_o" >> restored_external
                        "$dir/hfsplus" Ramdisk.raw mv usr/local/bin/restored_external usr/local/bin/restored_external_o
                        "$dir/hfsplus" Ramdisk.raw add restored_external usr/local/bin/restored_external
                        "$dir/hfsplus" Ramdisk.raw chmod 755 usr/local/bin/restored_external
                        "$dir/hfsplus" Ramdisk.raw chown 0:0 usr/local/bin/restored_external
                    ;;
                esac
                if [[ $just_password == 1 ]]; then
                    if [[ $just_password_legacy != 1 ]]; then
                        case $build_id in
                                "12"* | "13"* | "14"* )
                                "$dir/hfsplus" Ramdisk.raw mv usr/local/bin/restored_external usr/local/bin/restored_external.real
                                cp ../resources/bruteforce/setup.sh ./restored_external
                                "$dir/hfsplus" Ramdisk.raw add restored_external usr/local/bin/restored_external
                                "$dir/hfsplus" Ramdisk.raw chmod 755 usr/local/bin/restored_external
                                "$dir/hfsplus" Ramdisk.raw chown 0:0 usr/local/bin/restored_external
                            ;;
                        esac
                        "$dir/hfsplus" Ramdisk.raw rm usr/local/bin/restored_external.real
                        cp ../resources/bruteforce/restored_external ./restored_external.sshrd
                        "$dir/hfsplus" Ramdisk.raw add restored_external.sshrd usr/local/bin/restored_external.sshrd
                        "$dir/hfsplus" Ramdisk.raw chmod 755 usr/local/bin/restored_external.sshrd
                        cp ../resources/bruteforce/bruteforce .
                        "$dir/hfsplus" Ramdisk.raw add bruteforce usr/bin/bruteforce
                        "$dir/hfsplus" Ramdisk.raw chmod 755 usr/bin/bruteforce
                        cp ../resources/bruteforce/setup.sh ./restored_external
                        "$dir/hfsplus" Ramdisk.raw add restored_external usr/local/bin/restored_external
                        "$dir/hfsplus" Ramdisk.raw chmod 755 usr/local/bin/restored_external
                        "$dir/hfsplus" Ramdisk.raw chown 0:0 usr/local/bin/restored_external
                    fi
                fi
                "$dir/xpwntool" Ramdisk.raw Ramdisk.dmg -t RestoreRamdisk.dec
            fi
            log "Make iBSS"
            "$dir/xpwntool" iBSS.dec iBSS.raw
            if [[ $device_type == "iPad2,"* || $device_type == "iPhone3,3" ]]; then
                case $build_id in
                    8[FGHJKL]* | 8E600 | 8E501 ) device_boot4=1;;
                esac
            fi
            if [[ $device_boot4 == 1 ]]; then
                "$dir/iBoot32Patcher" iBSS.raw iBSS.patched --rsa --debug -b "-v amfi=0xff cs_enforcement_disable=1"
            else
                "$dir/iBoot32Patcher" iBSS.raw iBSS.patched --rsa --debug -b "$device_bootargs"
            fi
            "$dir/xpwntool" iBSS.patched iBSS -t iBSS.dec
            if [[ $build_id == "7"* || $build_id == "8"* ]] && [[ $device_type != "iPad"* ]]; then
                :
            else
                log "Make iBEC"
                "$dir/xpwntool" iBEC.dec iBEC.raw
                if [[ $1 == "justboot" ]]; then
                    "$dir/iBoot32Patcher" iBEC.raw iBEC.patched --rsa --debug -b "$device_bootargs"
                else
                    local bootarg="rd=md0 -v amfi=0xff amfi_get_out_of_my_way=1 cs_enforcement_disable=1 pio-error=0"
                    "$dir/iBoot32Patcher" iBEC.raw iBEC.patched --rsa --debug -b "$bootarg"
                fi
                "$dir/xpwntool" iBEC.patched iBEC -t iBEC.dec
            fi
        fi

        if [[ $device_boot4 == 1 ]]; then
            log "Make Kernelcache"
            mv Kernelcache.dec Kernelcache0.dec
            "$dir/xpwntool" Kernelcache0.dec Kernelcache.raw
            $bspatch Kernelcache.raw Kernelcache.patched ../resources/patch/kernelcache.release.${device_model}.${build_id}.patch
            "$dir/xpwntool" Kernelcache.patched Kernelcache.dec -t Kernelcache0.dec
        fi

        mv iBSS iBEC DeviceTree.dec Kernelcache.dec Ramdisk.dmg $ramdisk_path 2>/dev/null

        if [[ $device_argmode == "none" ]]; then
            log "Done creating SSH ramdisk files: saved/$device_type/ramdisk_$build_id"
            return
        fi
    fi
    if [[ $ship_boot != 1 ]]; then
        device_pwn
        if [[ $device_type == "iPad1,1" && $build_id != "9"* ]]; then
            patch_ibss
            log "Sending iBSS..."
            $irecovery -f pwnediBSS.dfu
            sleep 2
            log "Sending iBEC..."
            $irecovery -f $ramdisk_path/iBEC
        elif (( device_proc < 5 )) && [[ $device_pwnrec != 1 ]]; then
            log "Sending iBSS..."
            $irecovery -f $ramdisk_path/iBSS
        fi
        sleep 2
        #if [[ $build_id != "7"* && $build_id != "8"* ]]; then #someting wrong here
        if [[ $device_proc != 1 ]]; then
            log "Sending iBEC..."
            $irecovery -f $ramdisk_path/iBEC
            if [[ $device_pwnrec == 1 ]]; then
                $irecovery -c "go"
            fi
        fi
        sleep 3
        checkmode rec
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
        log "Booting, please wait..."
        sleep 6
    fi
    if [[ $just_boot == 1 ]]; then
        log "Done,use ./restore.sh ssh or ./restore.sh --menu to connect device"
        return
    else
        if [[ -n $1 ]]; then
            device_iproxy
        else
            device_iproxy no-logging
        fi
        local found
        log "Waiting for device..."
        print "* You may need to unplug and replug your device."
        local try=0
        while [[ $found != 1 ]]; do
            found=$($ssh -p $ssh_port root@127.0.0.1 "echo 1" 2>/dev/null)
            try=$((try + 1))
            if [[ $try == 10 ]]; then
                error "Unable to connect SSH, please try boot again"
                return 1
            fi
            sleep 2
        done
        if [[ $device_proc == 1 || $device_type == "iPod2,1" ]]; then
            log "Transferring some files"
            tar -xvf ../resources/ramdisk32/ssh.tar ./bin/chmod ./bin/chown ./bin/cp ./bin/dd ./bin/mount.sh ./bin/tar ./usr/bin/date ./usr/bin/df ./usr/bin/du
            $ssh -p $ssh_port root@127.0.0.1 "rm -f /bin/mount.sh /usr/bin/date"
            $scp -P $ssh_port bin/* root@127.0.0.1:/bin
            $scp -P $ssh_port usr/bin/* root@127.0.0.1:/usr/bin
        fi
        
        if [[ $no_menu != "1" ]]; then
            ssh_menu
        fi
        if [[ $just_jailbreak == 1 ]]; then
            jailbreak_sshrd
        elif [[ $just_get_ios_ver == 1 ]]; then
            check_iosvers
        elif [[ $just_hacktivate == 1 ]]; then
            device_hacktivate
        elif [[ $just_part2 == 1 ]]; then
            device_hacktivate_part2
        elif [[ $just_password == 1 ]]; then
            if [[ $just_password_legacy != 1 ]]; then
                log "Device should show text on screen now."
            else
                device_bruteforce
            fi
        elif [[ $just_unblock_lock == 1 ]]; then
            device_unblock_lock
        fi
    fi
}

ramdisk_64() {
    local version=$1
    local build
    local key
    local iv
    local kbag
    local kernelcache_ivkey
    local devicetree_ivkey
    local restoreramdisk_ivkey
    local deviceid=$device_type
    local replace=$device_model
    local KPlooshFinder="${KPlooshFinder}_new"
    set_path ramdisk
    if [[ -n $device_cpid ]]; then
        local check=$device_cpid
    else
        local check=$($irecovery -q | grep CPID | sed 's/CPID: //')
    fi
    if [[ -z $version ]]; then
        if [[ $device_type == "iPod7,1" ]]; then
            version="12.0"
        else
            version="12.4"
        fi
    fi
    if [[ $version =~ ^[0-9]+\.[0-9]+(\.[0-9]+)*$ ]]; then
        get_firmware_info ver $version
        build=$buildid
        cut_os_vers $version
    else
        get_firmware_info build $version
        version=$versionid
        build=$buildid
        cut_os_vers
    fi
    if [[ -d ../saved/$device_type/ramdisk_$build ]]; then
        local saved="../saved/$device_type/ramdisk_$build"
        if [[ ! -f $saved/iBSS.img4 ]] || [[ ! -f $saved/iBEC.img4 ]] || [[ ! -f $saved/kernelcache.img4 ]] || [[ ! -f $saved/devicetree.img4 ]] || [[ ! -f $saved/ramdisk.img4 ]]; then
            rm -rf  ../saved/$device_type/ramdisk_$build
        else
            local rd_have_made=1
        fi
    fi
    if [[ $rd_have_made != 1 ]]; then
        mkdir saved
        if [[ -z $url ]]; then
            error "无法获取固件链接"
            return
            pause
        else
            local ipswurl=$url
        fi
        local major=$major_ver
        local minor=$minor_ver
        $img4tool -e -s ../resources/ramdisk64/shsh/"${check}".shsh -m IM4M
        $pzb -g BuildManifest.plist "$ipswurl"
        $pzb -g "$(awk "/""${replace}""/{x=1}x&&/iBSS[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"
        $pzb -g "$(awk "/""${replace}""/{x=1}x&&/iBEC[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"
        $pzb -g "$(awk "/""${replace}""/{x=1}x&&/DeviceTree[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"
        $pzb -g "$(awk "/""${replace}""/{x=1}x&&/kernelcache.release/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"

        if [[ $platform == "macos" ]]; then
            if (( $major <= 12 )); then
                $pzb -g Firmware/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".trustcache "$ipswurl"
            fi
            $pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$ipswurl"
        else
            if (( $major <= 12 )); then
                $pzb -g Firmware/"$($PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')".trustcache "$ipswurl"
            fi
            $pzb -g "$($PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')" "$ipswurl"
        fi

        
        $gaster decrypt "$(awk "/""${replace}""/{x=1}x&&/iBSS[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]dfu[/]//')" iBSS.dec
        $gaster decrypt "$(awk "/""${replace}""/{x=1}x&&/iBEC[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]dfu[/]//')" iBEC.dec
        if (( (major == 10 && minor < 3) || major < 10 )); then
            $kairos ./iBSS.dec ./iBSS.patched
            $img4 -i iBSS.patched -o saved/iBSS.img4 -M IM4M -A -T ibss
            $kairos ./iBEC.dec ./iBEC.patched -b "rd=md0 debug=0x2014e -v wdt=-1 `if [ -z "$2" ]; then :; else echo "$2=$3"; fi` `if [ "$check" = '0x8960' ] || [ "$check" = '0x7000' ] || [ "$check" = '0x7001' ]; then echo "nand-enable-reformat=1 -restore"; fi` `if [ "$major" -lt 10 ]; then echo "amfi=0xff cs_enforcement_disable=1"; fi`" -n
            $img4 -i iBEC.patched -o saved/iBEC.img4 -M IM4M -A -T ibec   
        else
            $iBoot64Patcher iBSS.dec iBSS.patched
            $img4 -i ./iBSS.patched -o saved/iBSS.img4 -M IM4M -A -T ibss
            $iBoot64Patcher iBEC.dec iBEC.patched -b "rd=md0 debug=0x2014e -v wdt=-1 `if [ -z "$2" ]; then :; else echo "$2=$3"; fi` `if [ "$check" = '0x8960' ] || [ "$check" = '0x7000' ] || [ "$check" = '0x7001' ]; then echo "nand-enable-reformat=1 -restore"; fi`" -n
            $img4 -i iBEC.patched -o saved/iBEC.img4 -M IM4M -A -T ibec
        fi
        if (( major < 10 )); then
            kbag=$($img4 -i "$(awk "/""${replace}""/{x=1}x&&/kernelcache.release/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" -b | head -n 1)
            iv=$($gaster decrypt_kbag "$kbag" | tail -n 1 | cut -d ',' -f 1 | cut -d ' ' -f 2)
            key=$($gaster decrypt_kbag "$kbag" | tail -n 1 | cut -d ' ' -f 4)
            kernelcache_ivkey="$iv$key"
            $img4 -i "$(awk "/""${replace}""/{x=1}x&&/kernelcache.release/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" -o kernelcache.im4p -k "$kernelcache_ivkey" -D
            $img4 -i kernelcache.im4p -o saved/kernelcache.img4 -M IM4M -T rkrn
        else
            $img4 -i "$(awk "/""${replace}""/{x=1}x&&/kernelcache.release/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" -o kcache.raw
            $KPlooshFinder kcache.raw kcache.patched
            $kerneldiff kcache.raw kcache.patched kc.bpatch
            $img4 -i "$(awk "/""${replace}""/{x=1}x&&/kernelcache.release/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" -o saved/kernelcache.img4 -M IM4M -T rkrn -P kc.bpatch `if [ "$platform" = 'linux' ]; then echo "-J"; fi`
        fi
        if [[ $major == "10" ]] && (( minor < 3 )); then
            $img4 -i "$(awk "/""${replace}""/{x=1}x&&/DeviceTree[.]/{print;exit}" BuildManifest.plist | grep '<string>' | cut -d\> -f2 | cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]all_flash[.].*[.]production[/]//')" -o saved/devicetree.img4 -M IM4M -T rdtr
        elif (( major < 10 )); then
            kbag=$($img4 -i "$(awk "/""${replace}""/{x=1}x&&/DeviceTree[.]/{print;exit}" BuildManifest.plist | grep '<string>' | cut -d\> -f2 | cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]all_flash[.].*[.]production[/]//')" -b | head -n 1)
            iv=$($gaster decrypt_kbag "$kbag" | tail -n 1 | cut -d ',' -f 1 | cut -d ' ' -f 2)
            key=$($gaster decrypt_kbag "$kbag" | tail -n 1 | cut -d ' ' -f 4)
            devicetree_ivkey="$iv$key"
            $img4 -i "$(awk "/""${replace}""/{x=1}x&&/DeviceTree[.]/{print;exit}" BuildManifest.plist | grep '<string>' | cut -d\> -f2 | cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]all_flash[.].*[.]production[/]//')" -o dtree.raw -k "$devicetree_ivkey"
            $img4 -i dtree.raw -o saved/devicetree.img4 -A -M IM4M -T rdtr
        else
            $img4 -i "$(awk "/""${replace}""/{x=1}x&&/DeviceTree[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]//')" -o saved/devicetree.img4 -M IM4M -T rdtr
        fi
        if [[ $platform == "macos" ]]; then
            if (( $major >= 12 )); then
                $img4 -i "$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".trustcache -o saved/trustcache.img4 -M IM4M -T rtsc
            fi
            if (( $major < 10 )); then
                kbag=$($img4 -i "$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" -b | head -n 1)
                iv=$($gaster decrypt_kbag "$kbag" | tail -n 1 | cut -d ',' -f 1 | cut -d ' ' -f 2)
                key=$($gaster decrypt_kbag "$kbag" | tail -n 1 | cut -d ' ' -f 4)
                restoreramdisk_ivkey="$iv$key"
                $img4 -i "$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" -o ramdisk.dmg -k "$restoreramdisk_ivkey"
            else
                $img4 -i "$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" -o ramdisk.dmg
            fi
        else
            if (( $major >= 12 )); then
                $img4 -i "$($PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')".trustcache -o saved/trustcache.img4 -M IM4M -T rtsc
            fi
            if (( $major < 10 )); then
                kbag=$($img4 -i "$($PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')" -b | head -n 1)
                iv=$($gaster decrypt_kbag "$kbag" | tail -n 1 | cut -d ',' -f 1 | cut -d ' ' -f 2)
                key=$($gaster decrypt_kbag "$kbag" | tail -n 1 | cut -d ' ' -f 4)
                restoreramdisk_ivkey="$iv$key"
                $img4 -i "$($PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')" -o ramdisk.dmg -k "$restoreramdisk_ivkey"
            else
                $img4 -i "$($PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')" -o ramdisk.dmg
            fi
        fi
        #try to use hfsplus
        if (( (major == 11 && minor < 3) || major == 10 || major == 9 )); then
            $hfsplus ramdisk.dmg grow 110000000 > /dev/null
        elif (( major == 7 || major == 8 )); then
            $hfsplus ramdisk.dmg grow 50000000 > /dev/null
        else
            $hfsplus ramdisk.dmg grow 210000000 > /dev/null
        fi
        if (( major < 12 )); then
            mkdir 12rd
            get_firmware_info ver 12.0
            if [[ -z $url ]]; then
                error "无法获取链接1"
                return
                pause
            else
                ipswurl12=$url
            fi
            cd 12rd
            ../$pzb -g BuildManifest.plist "$ipswurl12"
            ../$pzb -g "$($PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')" "$ipswurl12"
            ../$img4 -i "$($PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')" -o ramdisk.dmg
            ../$hfsplus ramdisk.dmg extract usr/lib/libcharset.1.dylib libcharset.1.dylib
            ../$hfsplus ramdisk.dmg extract usr/lib/libiconv.2.dylib libiconv.2.dylib
            ../$hfsplus ../ramdisk.dmg add libiconv.2.dylib usr/lib/libiconv.2.dylib
            ../$hfsplus ../ramdisk.dmg add libcharset.1.dylib usr/lib/libcharset.1.dylib
            cd ../
            rm -rf 12rd
        fi
        cp ../resources/ramdisk64/ssh.tar.gz .
        cp ../resources/ramdisk64/iram.tar.gz .
        gzip -d -k ssh.tar.gz
        gzip -d -k iram.tar.gz
        if (( major == 7 )) || (( major == 8 )); then
            $hfsplus ramdisk.dmg untar iram.tar > /dev/null
            touch saved/device_port_44
        else
            $hfsplus ramdisk.dmg untar ssh.tar > /dev/null
        fi
        $hfsplus ramdisk.dmg untar ../resources/ramdisk64/sbplist.tar > /dev/null
        $img4 -i ramdisk.dmg -o saved/ramdisk.img4 -M IM4M -A -T rdsk
        $img4 -i ../resources/ramdisk64/bootlogo.im4p -o saved/logo.img4 -M IM4M -A -T rlgo
        if [[ ! -f saved/iBSS.img4 ]] || [[ ! -f saved/iBEC.img4 ]] || [[ ! -f saved/kernelcache.img4 ]] || [[ ! -f saved/devicetree.img4 ]] || [[ ! -f saved/ramdisk.img4 ]]; then
            error "SSH Ramdisk制作失败"
            return
        else
            echo $version > saved/version.txt
            cp -R saved/ ../saved/$device_type/ramdisk_$build
            log "Ramdisk已保存至../saved/$device_type/ramdisk_$build"
            if [[ $device_argmode == "none" ]]; then
                return
            fi
        fi
        sleep 3
    else
        log "找到已制作过的Ramdisk,跳过制作"
        cp -R ../saved/$device_type/ramdisk_$build saved/
    fi

    log "[*] gaster reset"
    $gaster reset
    log "[*] Sending iBSS.img4"
    $irecovery -f saved/iBSS.img4
    sleep 5
    log "[*] Sending iBEC.img4"
    $irecovery -f saved/iBEC.img4
    sleep 5
    checkmode rec
    log "[*] Sending logo.img4"
    $irecovery -f saved/logo.img4
    $irecovery -c "setpicture 0x1"
    log "[*] Sending ramdisk.img4"
    $irecovery -f saved/ramdisk.img4
    $irecovery -c ramdisk
    log "[*] Sending devicetree.img4"
    $irecovery -f saved/devicetree.img4
    $irecovery -c devicetree
    if (( $major >= 12 )); then
        log "[*] Sending trustcache.img4"
        $irecovery -f saved/trustcache.img4
        $irecovery -c firmware
    fi
    log "[*] Sending kernelcache.img4"
    $irecovery -f saved/kernelcache.img4
    $irecovery -c bootx
    log "[*] Device should be boot now"
    pause
    device_iproxy
    log "Waiting for device..."
    print "* You may need to unplug and replug your device."
    local try=0
    while [[ $found != 1 ]]; do
        found=$($ssh -p $ssh_port root@127.0.0.1 "echo 1" 2>/dev/null)
        try=$((try + 1))
        if [[ $try == 10 ]]; then
            error "Unable to connect SSH, please try boot again"
            return 1
        fi
        sleep 2
    done
    ssh_menu
    pause
}

device_send_rdtar() {
    local target="/mnt1"
    if [[ $2 == "data" ]]; then
        target+="/private/var"
    fi
    log "Sending $1"
    $scp -P $ssh_port $jelbrek/$1 root@127.0.0.1:$target
    log "Extracting $1"
    $ssh -p $ssh_port root@127.0.0.1 "tar -xvf $target/$1 -C /mnt1; rm $target/$1"
}

device_iproxy() {
    local port=22
    log "Running iproxy for SSH..."
    if [[ -n $2 ]]; then
        port=$2
    fi
    if [[ $1 == "no-logging" && $debug_mode != 1 ]]; then
        "$dir/iproxy" $ssh_port $port -s 127.0.0.1 >/dev/null &
        iproxy_pid=$!
    else
        "$dir/iproxy" $ssh_port $port -s 127.0.0.1 &
        iproxy_pid=$!
    fi
    log "iproxy PID: $iproxy_pid"
    sleep 1
}

device_hacktivate() {
    local ver
    local build
    local 
    log Get iOS version
    check_iosvers
    cut_os_vers $device_vers
    log $device_rd_build_custom
    log Mount Filesystem
    $ssh -p $ssh_port root@127.0.0.1 "mount.sh"
    if (( major_ver > 9 )); then
        local message=$($ssh -p $ssh_port root@127.0.0.1 "ls /mnt2")
        if [[ $message == "" ]]; then
            warning "This version of ramdisk cannot mount /mnt2,please use “./restore.sh --version=9.0.2 --bypass” and try again"
            pause
            return
        fi
    fi
    case $device_vers in
        [56]* )
            if [[ -n $($ssh -p $ssh_port root@127.0.0.1 "ls /mnt1/bin/bash 2>/dev/null") ]]; then
                log Great,this device has been jailbroken,continue
            else
                yesno "Since jailbreaking is required for hacktivate-activation in iOS 5-6, do you want jailbreak? (y > jailbreak) (n > go to ssh menu)"
                if [[ $? == 1 ]]; then
                    jailbreak_sshrd noreboot
                    if [[ -n $($ssh -p $ssh_port root@127.0.0.1 "ls /mnt1/bin/bash 2>/dev/null") ]]; then
                        log Great,this device has been jailbroken,continue
                    else
                        error "This device also hasn't jailbroken,press enter to go to ssh menu"
                        ssh_menu
                        return
                    fi
                else
                    ssh_menu
                    return
                fi
            fi
            log Rename orgin file
            $ssh -p $ssh_port root@127.0.0.1 "mv /mnt1/usr/libexec/lockdownd /mnt1/usr/libexec/lockdownd.bak"
            log Upload new file
            $scp -P $ssh_port ../resources/lockdownd root@127.0.0.1:/mnt1/usr/libexec
            log Set permissions
            $ssh -p $ssh_port root@127.0.0.1 "chmod 755 /mnt1/usr/libexec/lockdownd"
            yesno Do you want to rename Setup.app?
            if [[ $? == 1 ]]; then
                $ssh -p $ssh_port root@127.0.0.1 "mv /mnt1/Applications/Setup.app /mnt1/Applications/Setup.app.bak"
            fi
            log Rebooting
            $ssh -p $ssh_port root@127.0.0.1 "reboot_bak"
            exit=1
            ;;
        [78]* | 9.[012]* )
            log "Download files"
            $scp -P $ssh_port root@127.0.0.1:/mnt2/mobile/Library/Caches/com.apple.MobileGestalt.plist .
            if [[ ! -f "com.apple.MobileGestalt.plist" ]]; then
                error Download files failed
                pause
                return
            else
                log "Add key to files"
                $afc activation com.apple.MobileGestalt.plist
                if [[ ! -f "com.apple.MobileGestalt.plist.backup" ]]; then
                    error "Add key failed"
                    pause
                    return
                fi
                cp com.apple.MobileGestalt.plist.backup ../saved/$device_type
                mv ../saved/$device_type/com.apple.MobileGestalt.plist.backup ../saved/$device_type/com.apple.MobileGestalt.plist.$(date '+%Y-%m-%d-%H-%M-%S').backup

            fi
            log Replace original files
            $ssh -p $ssh_port root@127.0.0.1 "mv /mnt2/mobile/Library/Caches/com.apple.MobileGestalt.plist /mnt2/mobile/Library/Caches/com.apple.MobileGestalt.plist.bak"
            log Upload files
            $scp -P $ssh_port com.apple.MobileGestalt.plist root@127.0.0.1:/mnt2/mobile/Library/Caches
            log Rename Setup.app
            $ssh -p $ssh_port root@127.0.0.1 "mv /mnt1/Applications/Setup.app /mnt1/Applications/Setup.app.bak"
            log Rebooting
            $ssh -p $ssh_port root@127.0.0.1 "reboot_bak"
            log Done
            exit=1
            ;;
        9.3* | 10* )
            warning "本脚本暂时不支持iOS9.3-10的绕激活,请使用https://github.com/appleiPodTouch4/SSHRD_Script_32Bit"
            exit
            ;;
        * )
            warning This iOS version is unsupport
            pause Press enter to enter ssh menu
            ssh_menu
            ;;
    esac
}


device_bruteforce() {
    log Mount Filesystem
    $ssh -p $ssh_port root@127.0.0.1 "mount.sh"
    log Upload files
    $scp -P $ssh_port ../resources/bruteforce/bruteforce root@127.0.0.1:/var/root
    $ssh -p $ssh_port root@127.0.0.1 "chmod +x bruteforce"
    $ssh -p $ssh_port root@127.0.0.1 "./bruteforce -u"
    log When it finished, the last one is the password.
    pause
    ssh_menu
}

device_unblock_lock() {
    log Mount Filesystem
    $ssh -p $ssh_port root@127.0.0.1 "mount.sh"
    log Del some files
    $ssh -p $ssh_port root@127.0.0.1 "rm -rf /mnt2/mobile/Library/Preferences/com.apple.springboard.plist"
    $ssh -p $ssh_port root@127.0.0.1 "rm -rf /mnt2/mobile/Library/SpringBoard/LockoutStateJournal.plist"
    log Rebooting
    $ssh -p $ssh_port root@127.0.0.1 "cat /dev/rdisk1" | dd of=dump.raw bs=256 count=$((0x4000))
    exit=1
}

device_shsh_dump_64() {
    local ver=$($ssh -p $ssh_port root@127.0.0.1 "sw_vers -productVersion")
    local device=rdisk1
    $ssh -p $ssh_port root@127.0.0.1 "cat /dev/$device" | dd of=dump.raw bs=256 count=$((0x4000))
    $img4tool --convert -s dumped.shsh2 dump.raw
    if [[ ! -d ../saved/shsh ]]; then
        mkdir -p ../saved/shsh
    fi
    mv dumped.shsh2 ../saved/shsh/${device_ecid}_${ver}_${device_type}.shsh2
    log "SHSH已保存至../saved/shsh/${device_ecid}_${ver}_${device_type}.shsh2"
}

ssh_message() {
    if [[ $device_64bit != 1 ]]; then
        print "* For accessing data, note the following:"
        print "* Host: sftp://127.0.0.1 | User: root | Password: alpine | Port: $ssh_port"
        echo
        print "* Other Useful SSH Ramdisk commands:"
        print "* Clear NVRAM with this command:"
        print "    nvram -c"
        print "* Erase All Content and Settings with this command (iOS 9+ only):"
        print "    nvram oblit-inprogress=5"
        print "* To reboot, use this command:"
        print "    reboot_bak"
        print "* Remove Setup.app:"
        print "    rm -rf /mnt1/Applications/Setup.app"
        echo
    else
        print "[*] For accessing data, note the following:"
        print "    Host: sftp://127.0.0.1   User: root   Password: alpine   Port: 2222"
        print "[*] Mount filesystems (make sure ramdisk version is correct):"
        print "10.3 and above: /usr/bin/mount_filesystems"
        print "10.0-10.2.1: mount_hfs /dev/disk0s1s1 /mnt1 && /usr/libexec/seputil --load /mnt1/usr/standalone/firmware/sep-firmware.img4 && mount_hfs /dev/disk0s1s2 /mnt2"
        print "7.0-9.3.5: mount_hfs /dev/disk0s1s1 /mnt1 && mount_hfs /dev/disk0s1s2 /mnt2"
        print "[*] Rename system snapshot (when first time modifying /mnt1 on 11.3+):"
        print '    /usr/bin/snaputil -n "$(/usr/bin/snaputil -l /mnt1)" orig-fs /mnt1'
        print "[*] Erase device without updating (9.0+):"
        print "    /usr/sbin/nvram oblit-inprogress=5"
        print "[*] Reboot:"
        print "    /sbin/reboot"
        print "[*] Remove Setup.app (up to 13.2.3 or 12.4.4; on 10.0+ the device must be erased afterwards, on 11.3+ also rename system snapshot):"
        print "    rm -rf /mnt1/Applications/Setup.app"
    fi
}

###sshrd#functions###

check_iosvers() {
    local options
    local selected
    device_datetime_cmd nopause
    if [[ $device_64bit == 1 ]]; then
        local mount_command="mount_filesystems"
    else
        local mount_command="mount.sh root"
    fi
    device_vers=
    device_build=
    log "Mounting root filesystem"
    $ssh -p $ssh_port root@127.0.0.1 "$mount_command"
    sleep 1
    log "Getting iOS version"
    $scp -P $ssh_port root@127.0.0.1:/mnt1/System/Library/CoreServices/SystemVersion.plist .
    rm -f BuildVer Version
    if [[ $platform == "macos" ]]; then
        plutil -extract 'ProductVersion' xml1 SystemVersion.plist -o Version
        device_vers=$(cat Version | sed -ne '/<string>/,/<\/string>/p' | sed -e "s/<string>//" | sed "s/<\/string>//" | sed '2d')
        plutil -extract 'ProductBuildVersion' xml1 SystemVersion.plist -o BuildVer
        device_build=$(cat BuildVer | sed -ne '/<string>/,/<\/string>/p' | sed -e "s/<string>//" | sed "s/<\/string>//" | sed '2d')
    else
        device_vers=$(cat SystemVersion.plist | grep -i ProductVersion -A 1 | grep -oPm1 "(?<=<string>)[^<]+")
        device_build=$(cat SystemVersion.plist | grep -i ProductBuildVersion -A 1 | grep -oPm1 "(?<=<string>)[^<]+")
    fi
    if [[ -n $device_vers ]]; then
        log "Get iOS Version successfully"
        print "* iOS Version: $device_vers ($device_build)"
        if [[ $1 != nopause ]]; then
            pause
            return
        fi
    else
        error "Unable get iOS Version"
        if [[ $1 != nopause ]]; then
            pause
            return
        fi
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

jailbreak_sshrd() {
    local vers
    local build
    local untether
    jelbrek=../resources/Jailbreak
    device_jailbreak=1
    check_iosvers nopause
    vers=$device_vers
    build=$device_build

    if [[ -z $device_vers ]]; then
        error Unable get iOS version,please try again
        pause
        return
    fi

    if [[ -n $($ssh -p $ssh_port root@127.0.0.1 "ls /mnt1/bin/bash 2>/dev/null") ]]; then
        warning "Your device seems to be already jailbroken. Cannot continue."
        if [[ $just_jailbreak == 1 ]]; then
            $ssh -p $ssh_port root@127.0.0.1 "reboot_bak"
        else
            pause
            return
        fi
    fi

    case $vers in
        9.3.[4231] | 9.3 ) untether="untetherhomedepot.tar";;
        9.2* | 9.1 )       untether="untetherhomedepot921.tar";;
        9.0* )             untether="everuntether.tar";;
        8* )               untether="daibutsu/untether.tar";;
        7.1* )
            case $device_type in
                iPod* ) untether="panguaxe-ipod.tar";;
                * ) untether="panguaxe.tar";;
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
            if [[ $just_jailbreak == 1 ]]; then
                $ssh -p $ssh_port root@127.0.0.1 "reboot_bak"
            else
                pause
                return
            fi
        ;;
    esac

    if [[ -z $untether ]]; then
        warning "iOS $vers is not supported for jailbreaking with SSHRD."
        if [[ $just_jailbreak == 1 ]]; then
            $ssh -p $ssh_port root@127.0.0.1 "reboot_bak"
        else
            pause
            return
        fi
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

    log "Jailbreak successfully✅"
    exit=1
}


#######custom#ipsw########

get_ipsw_info() {
    local ipsw_file
    local manifest_file="BuildManifest.plist"
    local device_type_ipsw_temp=""
    local device_vers=""
    local device_build=""
    local device_type_ipsw=""
    # 确定要处理的IPSW文件
    if [[ $1 == "base" ]]; then
        ipsw_file="$2"
    else
        ipsw_file="$2"
    fi    
    if [ -z "$ipsw_file" ]; then
        warning 无法获取固件路径
        pause
        return
    fi
    unzip -p "$ipsw_file" "BuildManifest.plist" > "$manifest_file" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "错误：无法从 IPSW 提取 BuildManifest.plist！"
        return 1
    fi
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
    if [[ $1 == "base" ]]; then
        device_type_ipswbase="$device_type_ipsw"
        device_base_vers="$device_vers"
        device_base_build="$device_build"
        if [[ "$device_type" != "$device_type_ipswbase" ]]; then
            ipsw_base_select_wrong=1
            return 1
        else
            ipsw_base_select_wrong=0
        fi
    elif [[ $1 == ipsw ]]; then
        device_type_ipsw="$device_type_ipsw"
        device_ipsw_vers="$device_vers"
        device_ipsw_build="$device_build"
        if [[ "$device_type" != "$device_type_ipsw" ]]; then
            ipsw_select_wrong=1
            ipsw_path=""
        else
            ipsw_select_wrong=0
        fi
    else
        device_target_vers="$device_vers"
        device_target_build="$device_build"
        if [[ $device_target_t4os7 == 1 || $device_target_t4os72 == 1 ]]; then
            if [[ "$device_type_ipsw" == "iPhone3,1" || "$device_type_ipsw" == "iPhone3,3" ]] && [[ $device_vers == "7.1.2" ]]; then
                ipsw_select_wrong=0
            else
                ipsw_select_wrong=1
                return 1
            fi
        else
            if [[ "$device_type" != "$device_type_ipsw" ]]; then
                ipsw_select_wrong=1
                return 1
            else
                ipsw_select_wrong=0
            fi
        fi
    fi
    if [[ $ipsw_select_wrong != 1 ]]; then
        log 获取固件shasum1值
        if [[ $1 == base ]]; then
            device_base_sha1=$(shasum -a 1 $ipsw_base_path1 | cut -d ' ' -f1)
        else
            if [[ -n $ipsw_justboot_path1 ]]; then
                get_firmware_info build $device_build
                rm -f "$manifest_file"
                return
            else
                device_target_sha1=$(shasum -a 1 $ipsw_path1 | cut -d ' ' -f1)
            fi
        fi
        get_firmware_info build $device_build
        if [[ -z $sha1 ]]; then
            warning 无法校验固件,按回车跳过校验
            pause
        else
            if [[ $1 == base ]]; then
                if [[ $sha1 != $device_base_sha1 ]]; then
                    warning 你的固件似乎不完整,请重新下载
                    ipsw_select_wrong=1
                    device_base_sha1=""
                fi
            else
                if [[ $sha1 != $device_target_sha1 ]]; then
                    log $sha1
                    log $device_target_sha1
                    warning 你的固件似乎不完整,请重新下载
                    ipsw_select_wrong=1
                    device_target_sha1=""
                fi
            fi
        fi
    fi
    rm -f "$manifest_file"
    return 0
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
    url=
    versionid=
    releasedate=
    uploaddate=
    if [[ $device_type == "iPod1,1" ||  $device_type == "iPod2,1" ]]; then
        if [[ ! -f $saved/invoxiplaygames.html ]]; then
            file_download https://invoxiplaygames.uk/ipsw/ temp.html
            if [[ -f temp.html ]]; then
                mv temp.html $saved/invoxiplaygames.html
            fi
        fi
        cp $saved/invoxiplaygames.html temp.html
        local links=$(grep -o 'https://invoxiplaygames.uk/ipsw/[^"]*\.ipsw' temp.html)
        if [[ $device_type == "iPod1,1" ]]; then
            local t1_links=$(echo "$links" | grep 'iPod1,1')
            url=$(echo "$t1_links" | grep $2)
        else
            local t2_links=$(echo "$links" | grep 'iPod1,1')
            url=$(echo "$t2_links" | grep $2)
        fi
        if [[ -n $url ]]; then
            return  
        fi
    fi

    curl -s -L "https://api.ipsw.me/v4/device/$device_type?type=ipsw" -o tmp.json
    JSON_FILE=tmp.json
    if [[ ! -f "tmp.json" ]]; then
        error Unable to get json,please check internat connection
        exit
    fi
    if [[ $1 == "ver" ]]; then
        version=$2
        if [[ "$device_type" == "iPod4,1" && "$version" == "4.1" ]]; then
            log Select version
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
        versionid=$version
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
        versionid=$($jq -r ".firmwares[] | select(.buildid == \"$build\") | .version" "$JSON_FILE")
        filesize=$($jq -r ".firmwares[] | select(.buildid == \"$build\") | .filesize" "$JSON_FILE")
        url=$($jq -r ".firmwares[] | select(.buildid == \"$build\") | .url" "$JSON_FILE")
        sha1=$($jq -r ".firmwares[] | select(.buildid == \"$build\") | .sha1sum" "$JSON_FILE")
        sha256=$($jq -r ".firmwares[] | select(.buildid == \"$build\") | .sha256sum" "$JSON_FILE")
        md5=$($jq -r ".firmwares[] | select(.buildid == \"$build\") | .md5sum" "$JSON_FILE")
        signed=$($jq -r ".firmwares[] | select(.buildid == \"$build\") | .signed" "$JSON_FILE")
        releasedate=$($jq -r ".firmwares[] | select(.buildid == \"$build\") | .releasedate" "$JSON_FILE")
        uploaddate=$($jq -r ".firmwares[] | select(.buildid == \"$build\") | .uploaddate" "$JSON_FILE")
    fi
    ipsw_url="$url"
}

ipsw_get_url() {
    local device_fw_dir="../saved/${device_type}/urls"
    mkdir $device_fw_dir 2>/dev/null
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
    if [[ $device_type == "iPod1,1" ]] && [[ $build_id == "5"* || $build_id == "7"* ]]; then
        url="https://invoxiplaygames.uk/ipsw/${device_type}_${version}_${build_id}_Restore.ipsw"
    elif [[ $device_type == "iPod2,1" && $build_id == "7"* ]]; then
        url="https://invoxiplaygames.uk/ipsw/${device_type}_${version}_${build_id}_Restore.ipsw"
    fi
    if [[ -z $url ]]; then
        log "Getting URL for $device_type-$build_id"
        local phone="OS" # iOS
        case $build_id in
            [23][0123456789]* | 7B405 | 7B500 ) :;;
            1[AC]* | [2345]* ) phone="Phone%20Software";; # iPhone Software
            7* ) phone="Phone%20OS";; # iPhone OS
        esac
        if [[ $device_type == "iPad"* ]]; then
            case $build_id in
                1[789]* | [23]* ) phone="PadOS";; # iPadOS
            esac
        fi
        rm -f tmp.json
        $aria2c "https://raw.githubusercontent.com/littlebyteorg/appledb/refs/heads/gh-pages/ios/i${phone};$build_id.json" -o tmp.json
        [[ $? != 0 ]] && $curl -L "https://raw.githubusercontent.com/littlebyteorg/appledb/refs/heads/gh-pages/ios/i${phone};$build_id.json" -o tmp.json
        #github may be banned,add this way
        if [[ ! -f tmp.json ]]; then
            get_firmware_info build $build_id
        else
            url="$(cat tmp.json | $jq -r ".sources[] | select(.type == \"ipsw\" and any(.deviceMap[]; . == \"$device_type\")) | .links[0].url")"
        fi
        local url2="$(echo "$url" | tr '[:upper:]' '[:lower:]')"
        local build_id2="$(echo "$build_id" | tr '[:upper:]' '[:lower:]')"
        if [[ $(echo "$url" | grep -c '<') != 0 || $url2 != *"$build_id2"* ]]; then
            if [[ -n $url_local ]]; then
                url="$url_local"
                log "Using saved URL for this IPSW: $url"
                echo "$url" > $device_fw_dir/$build_id/url
                ipsw_url="$url"
                return
            fi
            if [[ $ipsw_isbeta != 1 ]]; then
                error "Unable to get URL for $device_type-$build_id"
            fi
        fi
        mkdir -p $device_fw_dir/$build_id 2>/dev/null
        echo "$url" > $device_fw_dir/$build_id/url
    fi
    ipsw_url="$url"
}

device_fw_key_check() {
    # check and download keys for device_target_build, then set the variable device_fw_key (or device_fw_key_base)
    #remove download part,replace use unzip
    local key
    local build="$device_target_build"
    if [[ $1 == "base" ]]; then
        build="$device_base_build"
    elif [[ $1 == "temp" ]]; then
        build="$2"
    fi
    device_fw_dir=../saved/$device_type/$build
    local keys_path="."

    log "Checking firmware keys"
    if [[ $(cat "$keys_path/index.html" 2>/dev/null | grep -c "$build") != 1 ]]; then
        rm -f "$keys_path/index.html"
    fi
    if [[ ! -e "$keys_path/index.html" ]]; then
        cp ../resources/keys.zip .
        unzip -p keys.zip "Legacy-iOS-Kit-Keys-master/$device_type/$build/index.html" > index.html
    fi
    if [[ ! -f index.html ]]; then
        local try=("https://raw.githubusercontent.com/LukeZGD/Legacy-iOS-Kit-Keys/master/$device_type/$build/index.html"
                   "http://127.0.0.1:8888/firmware/$device_type/$build"
                   "https://api.m1sta.xyz/wikiproxy/$device_type/$build")
        for i in "${try[@]}"; do
            log "Getting firmware keys for $device_type-$build: $i"
            $aria2c "$i" -o index.html
            [[ $? != 0 ]] && $curl -L "$i" -o index.html
            if [[ $(cat index.html | grep -c "$build") == 1 ]]; then
                break
            fi
            rm -f index.html
        done
    fi
    if [[ $1 == "base" ]]; then
        device_fw_key_base="$(cat index.html)"
    elif [[ $1 == "temp" ]]; then
        device_fw_key_temp="$(cat index.html)"
    else
        device_fw_key="$(cat index.html)"
    fi
}

file_extract() {
    local archive="$1"
    local dest="$2"
    local arr=()
    if [[ $platform == "macos" ]]; then
        arr+=("-xzvf" "$archive")
        [[ -n $dest ]] && arr+=("-C" "$dest")
        tar "${arr[@]}"
        return
    fi
    arr+=("-o" "$archive")
    [[ -n $dest ]] && arr+=("-d" "$dest")
    unzip "${arr[@]}"
}

file_extract_from_archive() {
    local archive="$1"
    local file="$2"
    local dest="$3"
    [[ -z $dest ]] && dest=.
    local arr=()
    if [[ $platform == "macos" && $file != *"/"* ]]; then
        arr+=("-xzvOf" "$archive")
        arr+=("$file")
        tar "${arr[@]}" > "$dest/$file"
        return
    fi
    arr+=("-o" "-j" "$archive" "$file")
    [[ -n $dest ]] && arr+=("-d" "$dest")
    unzip "${arr[@]}"
}

ipsw_prepare() {
    case $device_proc in
        1 )
            if [[ $ipsw_jailbreak == 1 ]]; then
                ipsw_prepare_s5l8900
            elif [[ $device_target_vers == "$device_latest_vers" ]]; then
                return
            fi
        ;;

        4 )
            if [[ $device_target_tethered == 1 ]]; then
                ipsw_prepare_tethered
            elif [[ $device_target_other == 1 || $ipsw_gasgauge_patch == 1 ]] ||
                 [[ $device_target_vers == "$device_latest_vers" && $ipsw_jailbreak == 1 ]]; then
                case $device_type in
                    iPod2,1 ) ipsw_prepare_custom;;
                    * ) ipsw_prepare_32bit;;
                esac
            elif [[ $device_target_t4os7 == 1 ]]; then
                ipsw_prepare_ios7touch4
            elif [[ $device_target_t3os6 ]]; then
                ipsw_prepare_ios6touch3
            elif [[ $device_target_powder == 1 ]] && [[ $device_target_vers == "3"* || $device_target_vers == "4"* ]]; then
                #shsh_save version $device_latest_vers
                case $device_target_vers in
                    "4.3"* ) ipsw_prepare_ios4powder;;
                    * ) ipsw_prepare_ios4multipart;;
                esac
            elif [[ $device_target_powder == 1 ]]; then
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
        5 )
            # 32-bit devices A5/A6
            if [[ $device_target_tethered == 1 ]]; then
                ipsw_prepare_tethered
            elif [[ $device_target_powder == 1 ]]; then
                ipsw_prepare_powder
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
        8 | 10 )
        return
        ;;
    esac
}

ipsw_prepare_keys() {
    local comp="$1"
    local getcomp="$1"
    case $comp in
        "RestoreLogo" ) getcomp="AppleLogo";;
        *"KernelCache" ) getcomp="Kernelcache";;
        "RestoreDeviceTree" ) getcomp="DeviceTree";;
    esac
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
</plist>" | tee FirmwareBundles/config.plist
}

ipsw_prepare_systemversion() {
    local sysplist="SystemVersion.plist"
    log "Beta iOS detected, preparing modified $sysplist"
    echo '<plist><dict>' > $sysplist
    echo "<key>ProductBuildVersion</key><string>$device_target_build</string>" >> $sysplist
    local copyright="<key>ProductCopyright</key><string>1983-201"
    case $device_target_vers in
        3* ) copyright+="0";;
        4* ) copyright+="1";;
        5* ) copyright+="2";;
        6* ) copyright+="3";;
        7* ) copyright+="4";;
        8* ) copyright+="5";;
        9* ) copyright+="6";;
    esac
    copyright+=" Apple Inc.</string>"
    echo "$copyright" >> $sysplist # idk if the copyright key is actually needed but whatever
    echo "<key>ProductName</key><string>iPhone OS</string>" >> $sysplist
    echo "<key>ProductVersion</key><string>$device_target_vers</string>" >> $sysplist
    echo "</dict></plist>" >> $sysplist
    cat $sysplist
    mkdir -p System/Library/CoreServices
    mv SystemVersion.plist System/Library/CoreServices
    tar -cvf systemversion.tar System
}

ipsw_prepare_bundle() {
    device_fw_key_check $1
    local ipsw_p="$ipsw_path"
    local key="$device_fw_key"
    local vers="$device_target_vers"
    local build="$device_target_build"
    local hw="$device_model"
    local base_build="11D257"
    local RootSize
    local daibutsu
    FirmwareBundle="FirmwareBundles/"
    if [[ $1 == "daibutsu" ]]; then
        daibutsu=1
    fi

    mkdir FirmwareBundles 2>/dev/null
    if [[ $1 == "base" ]]; then
        ipsw_p="$ipsw_base_path"
        key="$device_fw_key_base"
        vers="$device_base_vers"
        build="$device_base_build"
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
    local FirmwareBundle2="../resources/firmware/FirmwareBundles/Down_${device_type}_${vers}_${build}.bundle"
    if [[ $ipsw_prepare_usepowder == 1 ]]; then
        FirmwareBundle2=
    elif [[ -d $FirmwareBundle2 ]]; then
        FirmwareBundle+="Down_"
    fi
    FirmwareBundle+="${device_type}_${vers}_${build}.bundle"
    local NewPlist=$FirmwareBundle/Info.plist
    mkdir -p $FirmwareBundle

    log "Generating firmware bundle for $device_type-$vers ($build) $1..."
    file_extract_from_archive "$ipsw_p.ipsw" $all_flash/manifest
    mv manifest $FirmwareBundle/
    local ramdisk_name=$(echo "$key" | $jq -j '.keys[] | select(.image == "RestoreRamdisk") | .filename')
    local RamdiskIV=$(echo "$key" | $jq -j '.keys[] | select(.image == "RestoreRamdisk") | .iv')
    local RamdiskKey=$(echo "$key" | $jq -j '.keys[] | select(.image == "RestoreRamdisk") | .key')
    if [[ -z $ramdisk_name ]]; then
        error "Issue with firmware keys: Failed getting RestoreRamdisk. Check The Apple Wiki or your wikiproxy"
    fi
    file_extract_from_archive "$ipsw_p.ipsw" $ramdisk_name
    "$dir/xpwntool" $ramdisk_name Ramdisk.raw -iv $RamdiskIV -k $RamdiskKey
    "$dir/hfsplus" Ramdisk.raw extract usr/local/share/restore/options.$device_model.plist
    if [[ ! -s options.$device_model.plist ]]; then
        rm options.$device_model.plist
        "$dir/hfsplus" Ramdisk.raw extract usr/local/share/restore/options.plist
        mv options.plist options.$device_model.plist
    fi
    local ver2="${device_target_vers:0:1}"
    if [[ ! -s options.$device_model.plist ]] && (( ver2 >= 4 )); then
        error "Failed to extract options plist from restore ramdisk. Probably an issue with firmware keys."
    fi
    if [[ $device_target_vers == "3.2"* ]]; then
        RootSize=1000
    elif [[ $ver2 == 3 ]]; then
        case $device_type in
            iPhone1,* | iPod1,1 ) RootSize=420;;
            iPod2,1 ) RootSize=450;;
            *       ) RootSize=750;;
        esac
    elif [[ $platform == "macos" ]]; then
        plutil -extract 'SystemPartitionSize' xml1 options.$device_model.plist -o size
        RootSize=$(cat size | sed -ne '/<integer>/,/<\/integer>/p' | sed -e "s/<integer>//" | sed "s/<\/integer>//" | sed '2d')
    else
        RootSize=$(cat options.$device_model.plist | grep -i SystemPartitionSize -A 1 | grep -oPm1 "(?<=<integer>)[^<]+")
    fi
    RootSize=$((RootSize+30))
    local rootfs_name="$(echo "$key" | $jq -j '.keys[] | select(.image == "RootFS") | .filename')"
    local rootfs_key="$(echo "$key" | $jq -j '.keys[] | select(.image == "RootFS") | .key')"
    if [[ -z $rootfs_name ]]; then
        error "Issue with firmware keys: Failed getting RootFS. Check The Apple Wiki or your wikiproxy"
    fi
    echo '<plist><dict>' > $NewPlist
    echo "<key>Filename</key><string>$ipsw_p.ipsw</string>" >> $NewPlist
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
        echo "<key>SHA1</key><string>$device_base_sha1</string>" >> $NewPlist
    else
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
ipsw_prepare_rebootsh() {
    log "Generating reboot.sh"
    echo '#!/bin/bash' | tee reboot.sh
    echo "mount_hfs /dev/disk0s1s1 /mnt1; mount_hfs /dev/disk0s1s2 /mnt2" | tee -a reboot.sh
    echo "nvram -d boot-partition; nvram -d boot-ramdisk" | tee -a reboot.sh
    if [[ $1 == "lyncis" ]]; then
        echo "mv /mnt1/System/Library/LaunchDaemons/com.apple.mDNSResponder.plist_ /mnt1/Library/LaunchDaemons/com.apple.mDNSResponder.plist" | tee -a reboot.sh
        echo "mv -v /mnt1/usr/libexec/CrashHousekeeping /mnt1/usr/libexec/CrashHousekeeping.backup; ln -s /lyncis /mnt1/usr/libexec/CrashHousekeeping" | tee -a reboot.sh
        echo "rm /mnt1/install.sh; /sbin/reboot_" | tee -a reboot.sh
    else
        echo "/usr/bin/haxx_overwrite --${device_type}_${device_target_build}" | tee -a reboot.sh
    fi
}

ipsw_prepare_32bit() {
    local ExtraArgs
    local daibutsu
    local JBFiles=()
    # redirect to ipsw_prepare_jailbreak for 4.1 and lower
    case $device_target_vers in
        [23]* | 4.[01]* ) ipsw_prepare_jailbreak $1; return;;
    esac
    # use everuntether+jsc_untether instead of everuntether+dsc haxx for a5(x) 8.0-8.2
    if [[ $device_proc == 5 && $ipsw_jailbreak == 1 ]]; then
        case $device_target_vers in
            8.[012]* )
                ipsw_everuntether=1
                JBFiles+=("everuntether.tar")
            ;;
        esac
    fi
    if [[ -s "$ipsw_custom.ipsw" ]]; then
        log "Found existing Custom IPSW. Skipping IPSW creation."
        return
    elif [[ $ipsw_jailbreak == 1 && $ipsw_everuntether != 1 ]]; then
        if [[ $device_target_vers == "8"* ]]; then
            daibutsu="daibutsu"
            ExtraArgs+=" -daibutsu"
            cp $jelbrek/daibutsu/bin.tar $jelbrek/daibutsu/untether.tar .
            ipsw_prepare_rebootsh
        : ' # remove for lyncis (uncomment)
        elif [[ $device_target_vers == "7.1"* ]]; then # change to "7"* for lyncis 7.0.x
            daibutsu="daibutsu"
            ExtraArgs+=" -daibutsu"
            cp $jelbrek/daibutsu/bin.tar .
            cp $jelbrek/lyncis.tar untether.tar
            ipsw_prepare_rebootsh lyncis
        '
        fi
    elif [[ $ipsw_nskip == 1 ]]; then
        :
    elif [[ $ipsw_jailbreak != 1 && $device_target_build != "9A406" && # 9a406 needs custom ipsw
            $device_proc != 4 && $device_actrec != 1 && $device_target_tethered != 1 && $ipsw_isbeta != 1 ]]; then
        log "No need to create custom IPSW for non-jailbroken restores on $device_type-$device_target_build"
        return
    fi
    ipsw_prepare_usepowder=1

    ipsw_prepare_bundle $daibutsu

    if [[ $ipsw_memory == 1 ]]; then
        ExtraArgs+=" -memory"
    fi
    ExtraArgs+=" -ramdiskgrow 10"

    if [[ $ipsw_jailbreak == 1 ]]; then
        case $device_target_vers in
            9.3.[56] ) :;;
            9* )            JBFiles+=("everuntether.tar");;
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
            4.3* ) [[ $device_type == "iPad2"* ]] && JBFiles[0]=;;
            4.2.9 | 4.2.10 ) JBFiles[0]=;;
            4.2.[8761] )
                ExtraArgs+=" -punchd"
                JBFiles[0]=$jelbrek/greenpois0n/${device_type}_${device_target_build}.tar
            ;;
        esac
        JBFiles+=("freeze.tar")
        if [[ $device_target_vers == "9"* ]]; then
            JBFiles+=("$jelbrek/launchctl.tar")
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
        case $device_target_vers in
            [43]* ) :;;
            * ) JBFiles+=("$jelbrek/LukeZGD.tar");;
        esac
        cp $jelbrek/freeze.tar.gz .
        gzip -d freeze.tar.gz
    fi

    if [[ $ipsw_isbeta == 1 ]]; then
        ipsw_prepare_systemversion
        ExtraArgs+=" systemversion.tar"
    fi
    if [[ $1 == "iboot" ]]; then
        ExtraArgs+=" iBoot.tar"
    fi
    if [[ $device_type == "$device_disable_bbupdate" && $device_deadbb != 1 ]]; then
        ExtraArgs+=" ../saved/$device_type/baseband-$device_ecid.tar"
    fi
    if [[ $device_actrec == 1 ]]; then
        ExtraArgs+=" ../saved/$device_type/activation-$device_ecid.tar"
    fi

    log "Preparing custom IPSW: $dir/powdersn0w $ipsw_path.ipsw temp.ipsw $ExtraArgs ${JBFiles[*]}"
    "$dir/powdersn0w" "$ipsw_path.ipsw" temp.ipsw $ExtraArgs ${JBFiles[@]}

    if [[ ! -e temp.ipsw ]]; then
        if [[ $platform == "macos" && $platform_arch == "arm64" ]]; then
            warn "Updating to macOS 14.6 or newer is recommended for Apple Silicon Macs to resolve issues."
        fi
        error "Failed to find custom IPSW. Please run the script again" \
        "* You may try selecting N for memory option"
    fi

    if [[ $device_target_vers == "4"* ]]; then
        ipsw_prepare_ios4patches
        log "Add all to custom IPSW"
        zip -r0 temp.ipsw Firmware/dfu/*
    fi

    mv temp.ipsw "$ipsw_custom.ipsw"
}

ipsw_bbdigest() {
    local loc="BuildIdentities:0:"
    if [[ $2 != "UniqueBuildID" ]]; then
        loc+="Manifest:BasebandFirmware:"
    fi
    loc+="$2"
    local out="$1"
    log "Replacing $2"
    if [[ $platform == "macos" ]]; then
        echo $out | base64 --decode > t
        $PlistBuddy -c "Import $loc t" BuildManifest.plist
        rm t
        return
    fi
    in=$($PlistBuddy -c "Print $loc" BuildManifest.plist | tr -d "<>" | xxd -r -p | base64)
    in="${in}<"
    in="$(echo "$in" | sed -e 's,AAAAAAAAAAAAAAAAAAAAAAA<,==,' \
                           -e 's,AAAAAAAAAAAAA<,=,' \
                           -e 's,AAAAAAAAA<,=,')"
    case $2 in
        *"PartialDigest" )
            in="${in%????????????}"
            in=$(grep -m1 "$in" BuildManifest.plist)
            sed "s,$in,replace," BuildManifest.plist | \
            awk 'f{f=0; next} /replace/{f=1} 1' | \
            awk '/replace$/{printf "%s", $0; next} 1' > tmp.plist
            in="replace"
        ;;
        * ) mv BuildManifest.plist tmp.plist;;
    esac
    sed "s,$in,$out," tmp.plist > BuildManifest.plist
    rm tmp.plist
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
    log "Ma'ke iBoot: $*"
    if [[ $1 == "--logo" ]]; then
        iboot_name="${iboot_name/iBoot/iBoot2}"
        rsa=
        file_extract_from_archive temp.ipsw $all_flash/$iboot_name
    else
        file_extract_from_archive "$ipsw_path.ipsw" $all_flash/$iboot_name
    fi
    mv $iboot_name iBoot.orig
    "$dir/xpwntool" iBoot.orig iBoot.dec -iv $iboot_iv -k $iboot_key
    "$dir/iBoot32Patcher" iBoot.dec iBoot.pwned $rsa "$@"
    "$dir/xpwntool" iBoot.pwned iBoot -t iBoot.orig
    if [[ $device_type == "iPad1,1" || $device_type == "iPhone5,"* ]]; then
        echo "0000010: 6365" | xxd -r - iBoot
        echo "0000020: 6365" | xxd -r - iBoot
        return
    elif [[ $device_type != "iPhone2,1" ]]; then
        echo "0000010: 626F" | xxd -r - iBoot
        echo "0000020: 626F" | xxd -r - iBoot
    fi
    "$dir/xpwntool" iBoot.pwned $iboot_name -t iBoot -iv $iboot_iv -k $iboot_key
}

ipsw_patch_file() {
    # usage: ipsw_patch_file <ramdisk/fs> <location> <filename> <patchfile>
    "$dir/hfsplus" "$1" extract "$2"/"$3"
    "$dir/hfsplus" "$1" rm "$2"/"$3"
    $bspatch "$3" "$3".patched "$4"
    "$dir/hfsplus" "$1" add "$3".patched "$2"/"$3"
    "$dir/hfsplus" "$1" chmod 755 "$2"/"$3"
    "$dir/hfsplus" "$1" chown 0:0 "$2"/"$3"
}

ipsw_prepare_ios4multipart() {
    local JBFiles=()
    ipsw_custom_part2="${device_type}_${device_target_vers}_${device_target_build}_CustomNP-${device_ecid}"
    local all_flash2="$ipsw_custom_part2/$all_flash"
    local iboot

    if [[ -e "$saved/$device_type/$ipsw_custom_part2.ipsw" && -e "$ipsw_custom.ipsw" ]]; then
        log "Found existing Custom IPSWs. Skipping IPSW creation."
        return
    elif [[ -e "../$ipsw_custom_part2.ipsw" ]]; then
        rm -f "../$ipsw_custom_part2.ipsw"
    fi

    log "Preparing NOR flash IPSW..."
    mkdir -p $ipsw_custom_part2/Firmware/dfu $ipsw_custom_part2/Downgrade $all_flash2

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
            file_extract_from_archive "$ipsw_base_path.ipsw" ${path}$name
        elif [[ -e $saved_path/$name ]]; then
            cp $saved_path/$name .
        else
            "$dir/pzb" -g "${path}$name" -o "$name" "$url"
            cp $name $saved_path/
        fi
        case $getcomp in
            "DeviceTree" )
                "$dir/xpwntool" $name $ipsw_custom_part2/Downgrade/RestoreDeviceTree -iv $iv -k $key -decrypt
            ;;
            "Kernelcache" )
                "$dir/xpwntool" $name $ipsw_custom_part2/Downgrade/RestoreKernelCache -iv $iv -k $key -decrypt
            ;;
            * )
                mv $name $getcomp.orig
                "$dir/xpwntool" $getcomp.orig $getcomp.dec -iv $iv -k $key
            ;;
        esac
    done

    log "Make iBSS"
    "$dir/iBoot32Patcher" iBSS.dec iBSS.patched --rsa
    "$dir/xpwntool" iBSS.patched $ipsw_custom_part2/Firmware/dfu/iBSS.${device_model}ap.RELEASE.dfu -t iBSS.orig

    log "Make iBEC"
    "$dir/iBoot32Patcher" iBEC.dec iBEC.patched --rsa --ticket -b "rd=md0 -v nand-enable-reformat=1 amfi=0xff cs_enforcement_disable=1"
    "$dir/xpwntool" iBEC.patched $ipsw_custom_part2/Firmware/dfu/iBEC.${device_model}ap.RELEASE.dfu -t iBEC.orig

    log "Manifest plist"
    if [[ $vers == "$device_base_vers" ]]; then
        file_extract_from_archive "$ipsw_base_path.ipsw" BuildManifest.plist
    elif [[ -e $saved_path/BuildManifest.plist ]]; then
        cp $saved_path/BuildManifest.plist .
    else
        "$dir/pzb" -g "${path}BuildManifest.plist" -o "BuildManifest.plist" "$url"
        cp BuildManifest.plist $saved_path/
    fi
    $PlistBuddy -c "Set BuildIdentities:0:Manifest:RestoreDeviceTree:Info:Path Downgrade/RestoreDeviceTree" BuildManifest.plist
    $PlistBuddy -c "Set BuildIdentities:0:Manifest:RestoreKernelCache:Info:Path Downgrade/RestoreKernelCache" BuildManifest.plist
    $PlistBuddy -c "Set BuildIdentities:0:Manifest:RestoreLogo:Info:Path Downgrade/RestoreLogo" BuildManifest.plist
    cp BuildManifest.plist $ipsw_custom_part2/

    log "Restore Ramdisk"
    local ramdisk_name=$(echo $device_fw_key_temp | $jq -j '.keys[] | select(.image == "RestoreRamdisk") | .filename')
    mv RestoreRamdisk.dec ramdisk.dec
    "$dir/hfsplus" ramdisk.dec grow 18000000

    local rootfs_name=$(echo $device_fw_key_temp | $jq -j '.keys[] | select(.image == "RootFS") | .filename')
    touch $ipsw_custom_part2/$rootfs_name
    log "Dummy RootFS: $rootfs_name"

    log "Modify options.plist"
    local options_plist="options.$device_model.plist"
    echo '<plist>
<dict>
    <key>CreateFilesystemPartitions</key>
    <false/>
    <key>UpdateBaseband</key>
    <false/>
    <key>SystemImage</key>
    <false/>
</dict>
</plist>' | tee $options_plist
    "$dir/hfsplus" ramdisk.dec rm usr/local/share/restore/$options_plist
    "$dir/hfsplus" ramdisk.dec add $options_plist usr/local/share/restore/$options_plist

    log "Make ASR"
    cp ../resources/patch/old/$device_type/$vers/* .
    ipsw_patch_file ramdisk.dec usr/sbin asr asr.patch

    log "Repack Restore Ramdisk"
    "$dir/xpwntool" ramdisk.dec $ipsw_custom_part2/$ramdisk_name -t RestoreRamdisk.orig

    log "Extract all_flash from $device_base_vers base"
    file_extract_from_archive "$ipsw_base_path.ipsw" Firmware/all_flash/\* $all_flash2

    log "Add $device_target_vers DeviceTree to all_flash"
    rm -f $all_flash2/DeviceTree.${device_model}ap.img3
    file_extract_from_archive "$ipsw_path.ipsw" $all_flash/DeviceTree.${device_model}ap.img3 $all_flash2

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

    if [[ $device_type == "iPad1,1" && $device_target_vers == "3"* ]]; then
        cp iBoot ../saved/iPad1,1/iBoot3_$device_ecid
    elif [[ $device_type == "iPad1,1" ]]; then
        cp iBoot iBEC
        tar -cvf iBoot.tar iBEC
        iboot="iboot"
    else
        log "Add $device_target_vers iBoot to all_flash"
        cp iBoot $all_flash2/iBoot2.img3
        echo "iBoot2.img3" >> $all_flash2/manifest
    fi

    log "Add APTicket to all_flash"
    cat "$shsh_path" | sed '64,$d' | sed -ne '/<data>/,/<\/data>/p' | sed -e "s/<data>//" | sed "s/<\/data>//" | tr -d '[:space:]' | base64 --decode > apticket.der
    "$dir/xpwntool" apticket.der $all_flash2/applelogoT.img3 -t ../resources/firmware/src/scab_template.img3
    echo "applelogoT.img3" >> $all_flash2/manifest

    log "AppleLogo"
    local logo_name="$(echo $device_fw_key | $jq -j '.keys[] | select(.image == "AppleLogo") | .filename')"
    if [[ -n $ipsw_customlogo ]]; then
        ipsw_prepare_logos_convert
        mv $all_flash/$logoname $logo_name
    else
        file_extract_from_archive "$ipsw_path.ipsw" $all_flash/$logo_name
        echo "0000010: 3467" | xxd -r - $logo_name
        echo "0000020: 3467" | xxd -r - $logo_name
    fi
    log "Add AppleLogo to all_flash"
    if [[ $device_latest_vers == "5"* ]]; then
        mv $logo_name $all_flash2/applelogo4.img3
        echo "applelogo4.img3" >> $all_flash2/manifest
    else
        sed '/applelogo/d' $all_flash2/manifest > manifest
        rm $all_flash2/manifest
        echo "$logo_name" >> manifest
        mv $logo_name manifest $all_flash2/
    fi

    log "Creating $ipsw_custom_part2.ipsw..."
    pushd $ipsw_custom_part2 >/dev/null
    zip -r0 ../../$ipsw_custom_part2.ipsw *
    popd >/dev/null

    if [[ $ipsw_skip_first == 1 ]]; then
        return
    fi

    # ------ part 2 (nor flash) ends here. start creating part 1 ipsw ------
    ipsw_prepare_32bit $iboot

    ipsw_prepare_ios4multipart_patch=1
    ipsw_prepare_multipatch
}

ipsw_prepare_multipatch() {
    local vers
    local build
    local options_plist
    local saved_path
    local url
    local ramdisk_name
    local name
    local iv
    local key
    local comps=("iBSS" "iBEC" "DeviceTree" "Kernelcache" "RestoreRamdisk")
    local use_ticket=1

    log "Starting multipatch"
    mv "$ipsw_custom.ipsw" temp.ipsw
    rm asr* iBSS* iBEC* ramdisk* *.dmg 2>/dev/null
    options_plist="options.$device_model.plist"
    if [[ $device_type == "iPad1,1" && $device_target_vers == "4"* ]]; then
        use_ticket=
    elif [[ $device_target_vers == "3"* || $device_target_vers == "4"* ]]; then
        options_plist="options.plist"
        use_ticket=
    fi

    vers="4.2.1"
    build="8C148"
    if [[ $ipsw_isbeta == 1 ]]; then
        :
    elif [[ $device_type == "iPad1,1" || $device_type == "iPhone3,3" ]] ||
         [[ $device_type == "iPod3,1" && $device_target_vers == "3"* ]]; then
        vers="$device_target_vers"
        build="$device_target_build"
    fi
    case $device_target_vers in
        4.3* ) vers="4.3.5"; build="8L1";;
        5* ) vers="5.1.1"; build="9B206";;
        6* ) vers="6.1.3"; build="10B329";;
    esac
    if [[ $ipsw_gasgauge_patch == 1 ]]; then
        vers="6.1.3"
        build="10B329"
    else
        case $device_target_vers in
            7* ) vers="7.1.2"; build="11D257";;
            8* ) vers="8.4.1"; build="12H321";;
            9* ) vers="9.3.5"; build="13G36";;
        esac
    fi
    saved_path="../saved/$device_type/$build"
    ipsw_get_url $build
    url="$ipsw_url"
    device_fw_key_check
    ramdisk_name=$(echo $device_fw_key | $jq -j '.keys[] | select(.image == "RestoreRamdisk") | .filename')
    rootfs_name=$(echo $device_fw_key | $jq -j '.keys[] | select(.image == "RootFS") | .filename')
    if [[ -z $ramdisk_name ]]; then
        error "Issue with firmware keys: Failed getting RestoreRamdisk. Check The Apple Wiki or your wikiproxy"
    fi

    mkdir -p $saved_path Downgrade Firmware/dfu 2>/dev/null
    device_fw_key_check temp $build
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
        if [[ $vers == "$device_target_vers" ]]; then
            file_extract_from_archive "$ipsw_path.ipsw" ${path}$name
        elif [[ -e $saved_path/$name ]]; then
            cp $saved_path/$name .
        else
            "$dir/pzb" -g "${path}$name" -o "$name" "$url"
            cp $name $saved_path/
        fi
        case $getcomp in
            "DeviceTree" )
                "$dir/xpwntool" $name Downgrade/RestoreDeviceTree -iv $iv -k $key -decrypt
                zip -r0 temp.ipsw Downgrade/RestoreDeviceTree
            ;;
            "Kernelcache" )
                "$dir/xpwntool" $name Downgrade/RestoreKernelCache -iv $iv -k $key -decrypt
                zip -r0 temp.ipsw Downgrade/RestoreKernelCache
            ;;
            * )
                mv $name $getcomp.orig
                "$dir/xpwntool" $getcomp.orig $getcomp.dec -iv $iv -k $key
            ;;
        esac
        if [[ $getcomp == "iB"* ]]; then
            local ticket=
            if [[ $getcomp == "iBEC" && $use_ticket == 1 ]]; then
                ticket="--ticket"
            fi
            log "Make $getcomp"
            "$dir/iBoot32Patcher" $getcomp.dec $getcomp.patched --rsa --debug $ticket -b "rd=md0 -v nand-enable-reformat=1 amfi=0xff amfi_get_out_of_my_way=1 cs_enforcement_disable=1 pio-error=0"
            "$dir/xpwntool" $getcomp.patched ${path}$name -t $getcomp.orig
            cp ${path}$name ${path}$getcomp.$device_model.RELEASE.dfu 2>/dev/null
            zip -r0 temp.ipsw ${path}$name ${path}$getcomp.$device_model.RELEASE.dfu
        fi
    done

    log "Extracting ramdisk from IPSW"
    file_extract_from_archive temp.ipsw $ramdisk_name
    mv $ramdisk_name ramdisk2.orig
    "$dir/xpwntool" ramdisk2.orig ramdisk2.dec

    log "Checking multipatch"
    "$dir/hfsplus" ramdisk2.dec extract multipatched
    if [[ -s multipatched ]]; then
        log "Already multipatched"
        mv temp.ipsw "$ipsw_custom.ipsw"
        return
    fi

    log "Grow ramdisk"
    "$dir/hfsplus" RestoreRamdisk.dec grow 30000000

    log "Make ASR"
    local asrpatch="../resources/firmware/FirmwareBundles/Down_${device_type}_${vers}_${build}.bundle/asr.patch"
    if [[ -s "$asrpatch" ]]; then
        cp "$asrpatch" .
        ipsw_patch_file RestoreRamdisk.dec usr/sbin asr asr.patch
    elif [[ $ipsw_gasgauge_patch == 1 ]]; then
        "$dir/hfsplus" RestoreRamdisk.dec rm usr/sbin/asr
        "$dir/hfsplus" RestoreRamdisk.dec add ../resources/patch/asr usr/sbin/asr
        "$dir/hfsplus" RestoreRamdisk.dec chmod 755 usr/sbin/asr
        log "Make restored_external"
        "$dir/hfsplus" RestoreRamdisk.dec rm usr/local/bin/restored_external
        "$dir/hfsplus" RestoreRamdisk.dec add ../resources/patch/re usr/local/bin/restored_external
        "$dir/hfsplus" RestoreRamdisk.dec chmod 755 usr/local/bin/restored_external
    else
        "$dir/hfsplus" ramdisk2.dec extract usr/sbin/asr
        "$dir/hfsplus" RestoreRamdisk.dec add asr usr/sbin/asr
        "$dir/hfsplus" RestoreRamdisk.dec chmod 755 usr/sbin/asr
    fi

    if [[ $device_target_vers == "3.2"* ]]; then
        log "3.2 options.plist"
        cp ../resources/firmware/src/target/k48/options.plist $options_plist
    else
        log "Extract options.plist from $device_target_vers IPSW"
        "$dir/hfsplus" ramdisk2.dec extract usr/local/share/restore/$options_plist
    fi

    log "Modify options.plist"
    "$dir/hfsplus" RestoreRamdisk.dec rm usr/local/share/restore/$options_plist
    if [[ $ipsw_prepare_ios4multipart_patch == 1 || $device_target_tethered == 1 ]]; then
        cat $options_plist | sed '$d' | sed '$d' > options2.plist
        printf "<key>FlashNOR</key><false/></dict>\n</plist>\n" >> options2.plist
        cat options2.plist
        "$dir/hfsplus" RestoreRamdisk.dec add options2.plist usr/local/share/restore/$options_plist
    else
        "$dir/hfsplus" RestoreRamdisk.dec add $options_plist usr/local/share/restore/$options_plist
    fi
    if [[ $device_target_vers == "3"* ]]; then
        :
    elif [[ $device_target_powder == 1 && $device_target_vers == "4"* ]]; then
        log "Adding exploit and partition stuff"
        cp -R ../resources/firmware/src .
        "$dir/hfsplus" RestoreRamdisk.dec untar src/bin4.tar
        "$dir/hfsplus" RestoreRamdisk.dec mv sbin/reboot sbin/reboot_
        "$dir/hfsplus" RestoreRamdisk.dec add src/target/$device_model/reboot4 sbin/reboot
        "$dir/hfsplus" RestoreRamdisk.dec chmod 755 sbin/reboot
        "$dir/hfsplus" RestoreRamdisk.dec chown 0:0 sbin/reboot
    elif [[ $device_target_powder == 1 ]]; then
        local hw="$device_model"
        local base_build="11D257"
        case $device_type in
            iPhone5,[12] ) hw="iphone5";;
            iPhone5,[34] ) hw="iphone5b";;
            iPad3,[456] )  hw="ipad3b";;
        esac
        case $device_base_build in
            "11A"* | "11B"* ) base_build="11B554a";;
            "9"* ) base_build="9B206";;
        esac
        local exploit="src/target/$hw/$base_build/exploit"
        local partition="src/target/$hw/$base_build/partition"
        log "Adding exploit and partition stuff"
        "$dir/hfsplus" RestoreRamdisk.dec untar src/bin.tar
        "$dir/hfsplus" RestoreRamdisk.dec mv sbin/reboot sbin/reboot_
        "$dir/hfsplus" RestoreRamdisk.dec add $partition sbin/reboot
        "$dir/hfsplus" RestoreRamdisk.dec chmod 755 sbin/reboot
        "$dir/hfsplus" RestoreRamdisk.dec chown 0:0 sbin/reboot
        "$dir/hfsplus" RestoreRamdisk.dec add $exploit exploit
    elif [[ $ipsw_jailbreak == 1 && $device_target_vers == "8"* && $ipsw_everuntether != 1 ]]; then
        # daibutsu haxx overwrite
        "$dir/hfsplus" RestoreRamdisk.dec untar bin.tar
        "$dir/hfsplus" RestoreRamdisk.dec mv sbin/reboot sbin/reboot_
        "$dir/hfsplus" RestoreRamdisk.dec add reboot.sh sbin/reboot
        "$dir/hfsplus" RestoreRamdisk.dec chmod 755 sbin/reboot
        "$dir/hfsplus" RestoreRamdisk.dec chown 0:0 sbin/reboot
    fi

    echo "multipatched" > multipatched
    "$dir/hfsplus" RestoreRamdisk.dec add multipatched multipatched

    log "Repack Restore Ramdisk"
    "$dir/xpwntool" RestoreRamdisk.dec $ramdisk_name -t RestoreRamdisk.orig
    log "Add Restore Ramdisk to IPSW"
    zip -r0 temp.ipsw $ramdisk_name

    # 3.2.x ipad/4.2.x cdma fs workaround
    case $device_target_vers in
    4.2.10 | 4.2.9 | 4.2.[876] | 3.2* | 3.1.3 )
        local ipsw_name="../${device_type}_${device_target_vers}_${device_target_build}_FS"
        local type="iPad1.1"
        [[ $device_type == "iPhone3,3" ]] && type="iPhone3.3"
        [[ $device_type == "iPod3,1" ]] && type="iPod3.1"
        local build="$device_target_build"
        local vers="$device_target_vers"
        local rootfs_name_fs="$rootfs_name"
        case $device_target_vers in
        4.2.10 | 4.2.9 )
            build="8E401"
            vers="4.2.8"
            device_fw_key_check temp $build
            rootfs_name_fs=$(echo $device_fw_key_temp | $jq -j '.keys[] | select(.image == "RootFS") | .filename')
        esac
        local ipsw_url="https://github.com/LukeZGD/Legacy-iOS-Kit-Keys/releases/download/jailbreak/${type}_${vers}_${build}_FS2.ipsw"
        local sha1E="f4660666ce9d7bd9312d761c850fa3a1615899e9" # 3.2.2
        local sha1L="none"
        case $vers in
            4.2.10 | 4.2.[98] ) sha1E="b78fc4aba52bbf652c71cc633eccfba6d659698f";;
            4.2.7 ) sha1E="d07c841bbedae42f9ff98fa9160fc1298e6fffb2";;
            4.2.6 ) sha1E="671cbbb3964e5e5c38078577f5c2844bbe16699c";;
            3.2.1 ) sha1E="896c0344435615aee7f52fc75739241022e38fe7";;
            3.2   ) sha1E="47fdfe04ad9b65da009c834902eda3f141feac28";;
            3.1.3 ) sha1E="5500f63ff36ddf3379c66fcff26f0a6837ad522d";;
        esac
        if [[ -s "$ipsw_name.ipsw" ]]; then
            log "Verifying FS IPSW..."
            sha1L=$($sha1sum "$ipsw_name.ipsw" | awk '{print $1}')
            if [[ $sha1L != "$sha1E" ]]; then
                log "Verifying IPSW failed. Expected $sha1E, got $sha1L"
                log "Deleting existing custom IPSW"
                rm "$ipsw_name.ipsw"
            fi
        fi
        if [[ ! -s "$ipsw_name.ipsw" ]]; then
            log "Downloading FS IPSW..."
            $aria2c -c -s 16 -x 16 -k 1M -j 1 "$ipsw_url" -o temp2.ipsw
            log "Getting SHA1 hash for FS IPSW..."
            sha1L=$($sha1sum temp2.ipsw | awk '{print $1}')
            if [[ $sha1L != "$sha1E" ]]; then
                error "Verifying IPSW failed. The IPSW may be corrupted or incomplete. Please run the script again" \
                "* SHA1sum mismatch. Expected $sha1E, got $sha1L"
            fi
            mv temp2.ipsw "$ipsw_name.ipsw"
        fi
        log "Extract RootFS from FS IPSW"
        file_extract_from_archive "$ipsw_name.ipsw" $rootfs_name_fs
        [[ $rootfs_name_fs != "$rootfs_name" ]] && mv $rootfs_name_fs $rootfs_name
        log "Add RootFS to IPSW"
        zip -r0 temp.ipsw $rootfs_name
    ;;
    esac

    mv temp.ipsw "$ipsw_custom.ipsw"
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

    if [[ -s "$ipsw_custom.ipsw" ]]; then
        log "Found existing Custom IPSW. Skipping IPSW creation."
        return
    fi

    ipsw_prepare_32bit

    log "Extract RestoreRamdisk and options.plist"
    device_fw_key_check temp $device_target_build
    name=$(echo $device_fw_key_temp | $jq -j '.keys[] | select(.image == "RestoreRamdisk") | .filename')
    iv=$(echo $device_fw_key_temp | $jq -j '.keys[] | select(.image == "RestoreRamdisk") | .iv')
    key=$(echo $device_fw_key_temp | $jq -j '.keys[] | select(.image == "RestoreRamdisk") | .key')
    mv "$ipsw_custom.ipsw" temp.ipsw
    file_extract_from_archive temp.ipsw $name
    mv $name ramdisk.orig
    "$dir/xpwntool" ramdisk.orig ramdisk.dec -iv $iv -k $key
    "$dir/hfsplus" ramdisk.dec extract usr/local/share/restore/$options_plist

    log "Modify options.plist"
    "$dir/hfsplus" ramdisk.dec rm usr/local/share/restore/$options_plist
    cat $options_plist | sed '$d' | sed '$d' > options2.plist
    printf "<key>FlashNOR</key><false/></dict>\n</plist>\n" >> options2.plist
    cat options2.plist
    "$dir/hfsplus" ramdisk.dec add options2.plist usr/local/share/restore/$options_plist

    log "Repack Restore Ramdisk"
    "$dir/xpwntool" ramdisk.dec $name -t ramdisk.orig
    log "Add Restore Ramdisk to IPSW"
    zip -r0 temp.ipsw $name
    mv temp.ipsw "$ipsw_custom.ipsw"
}

ipsw_prepare_ios4patches() {
    local comps=("iBSS" "iBEC")
    local iv
    local key
    local name
    local path="Firmware/dfu/"
    log "Applying iOS 4 patches"
    mkdir -p $all_flash $path
    for getcomp in "${comps[@]}"; do
        iv=$(echo $device_fw_key | $jq -j '.keys[] | select(.image == "'$getcomp'") | .iv')
        key=$(echo $device_fw_key | $jq -j '.keys[] | select(.image == "'$getcomp'") | .key')
        name="$getcomp.${device_model}ap.RELEASE.dfu"
        log "Make $getcomp"
        file_extract_from_archive "$ipsw_path.ipsw" ${path}$name
        mv $name $getcomp.orig
        "$dir/xpwntool" $getcomp.orig $getcomp.dec -iv $iv -k $key
        "$dir/iBoot32Patcher" $getcomp.dec $getcomp.patched --rsa --debug -b "rd=md0 -v amfi=0xff cs_enforcement_disable=1 pio-error=0"
        "$dir/xpwntool" $getcomp.patched ${path}$name -t $getcomp.orig
    done
}

ipsw_prepare_logos_convert() {
    local fourcc="logo"
    if [[ -n $ipsw_customlogo ]]; then
        log "Converting custom logo"
        logoname=$(echo "$device_fw_key" | $jq -j '.keys[] | select(.image == "AppleLogo") | .filename')
        if [[ $device_target_powder == 1 ]]; then
            fourcc="logb"
            case $target_det in
                [34] ) fourcc="log4";;
            esac
        fi
        "$dir/ibootim" "$ipsw_customlogo" logo.raw
        "$dir/img3maker" -t $fourcc -f logo.raw -o logo.img3
        if [[ ! -s logo.img3 ]]; then
            error "Converting custom logo failed. Check your image"
        fi
        mkdir -p $all_flash 2>/dev/null
        mv logo.img3 $all_flash/$logoname
    fi
    if [[ -n $ipsw_customrecovery ]]; then
        log "Converting custom recovery"
        recmname=$(echo "$device_fw_key" | $jq -j '.keys[] | select(.image == "RecoveryMode") | .filename')
        "$dir/ibootim" "$ipsw_customlogo" recovery.raw
        "$dir/img3maker" -t recm -f recovery.raw -o recovery.img3
        if [[ ! -s recovery.img3 ]]; then
            error "Converting custom recovery failed. Check your image"
        fi
        mkdir -p $all_flash 2>/dev/null
        mv recovery.img3 $all_flash/$recmname
    fi
}

ipsw_prepare_logos_add() {
    if [[ -n $ipsw_customlogo ]]; then
        log "Adding custom logo to IPSW"
        zip -r0 temp.ipsw $all_flash/$logoname
    fi
    if [[ -n $ipsw_customrecovery ]]; then
        log "Adding custom recovery to IPSW"
        zip -r0 temp.ipsw $all_flash/$recmname
    fi
}

ipsw_prepare_ios4powder() {
    local ExtraArgs="-apticket $shsh_path"
    local JBFiles=()
    ipsw_prepare_usepowder=1

    if [[ -s "$ipsw_custom.ipsw" ]]; then
        log "Found existing Custom IPSW. Skipping IPSW creation."
        return
    fi

    if [[ $ipsw_jailbreak == 1 ]]; then
        JBFiles=("g1lbertJB/${device_type}_${device_target_build}.tar" "fstab_old.tar" "cydiasubstrate.tar" "freeze.tar")
        for i in {0..2}; do
            JBFiles[i]=$jelbrek/${JBFiles[$i]}
        done
        if [[ $ipsw_openssh == 1 ]]; then
            JBFiles+=("$jelbrek/sshdeb.tar")
        fi
        cp $jelbrek/freeze.tar.gz .
        gzip -d freeze.tar.gz
    fi

    ipsw_prepare_bundle target
    ipsw_prepare_bundle base
    ipsw_prepare_logos_convert
    cp -R ../resources/firmware/src .
    rm src/target/$device_model/$device_base_build/partition
    mv src/target/$device_model/reboot4 src/target/$device_model/$device_base_build/partition
    rm src/bin.tar
    mv src/bin4.tar src/bin.tar
    ipsw_prepare_config false true
    if [[ $ipsw_memory == 1 ]]; then
        ExtraArgs+=" -memory"
    fi
    if [[ $device_actrec == 1 ]]; then
        ExtraArgs+=" ../saved/$device_type/activation-$device_ecid.tar"
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

    tar -rvf src/bin.tar iBoot
    if [[ $device_type == "iPad1,1" ]]; then
        cp iBoot iBEC
        tar -cvf iBoot.tar iBEC
        ExtraArgs+=" iBoot.tar"
    fi
    if [[ $ipsw_isbeta == 1 ]]; then
        ipsw_prepare_systemversion
        ExtraArgs+=" systemversion.tar"
    fi

    log "Preparing custom IPSW: $dir/powdersn0w $ipsw_path.ipsw temp.ipsw -base $ipsw_base_path.ipsw $ExtraArgs ${JBFiles[*]}"
    "$dir/powdersn0w" "$ipsw_path.ipsw" temp.ipsw -base "$ipsw_base_path.ipsw" $ExtraArgs ${JBFiles[@]}

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
        log "Make AppleLogo"
        local applelogo_name=$(echo "$device_fw_key" | $jq -j '.keys[] | select(.image == "AppleLogo") | .filename')
        file_extract_from_archive temp.ipsw $all_flash/$applelogo_name
        echo "0000010: 3467" | xxd -r - $applelogo_name
        echo "0000020: 3467" | xxd -r - $applelogo_name
        mv $applelogo_name $all_flash/$applelogo_name
    fi

    log "Add all to custom IPSW"
    if [[ $device_type != "iPad1,1" ]]; then
        cp iBoot $all_flash/iBoot2.${device_model}ap.RELEASE.img3
    fi
    zip -r0 temp.ipsw $all_flash/* Firmware/dfu/* $ramdisk_name

    mv temp.ipsw "$ipsw_custom.ipsw"
}

ipsw_prepare_powder() {
    local ExtraArgs
    if [[ -s "$ipsw_custom.ipsw" ]]; then
        log "Found existing Custom IPSW. Skipping IPSW creation."
        return
    fi
    ipsw_prepare_usepowder=1

    ipsw_prepare_bundle target
    ipsw_prepare_bundle base
    ipsw_prepare_logos_convert
    cp -R ../resources/firmware/src .
    if [[ $ipsw_memory == 1 ]]; then
        ExtraArgs+=" -memory"
    fi
    if [[ $device_use_bb != 0 && $device_type != "$device_disable_bbupdate" ]]; then
        ExtraArgs+=" -bbupdate"
    fi

    if [[ $ipsw_jailbreak == 1 ]]; then
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
            * ) ExtraArgs+=" freeze.tar";;
        esac
        if [[ $ipsw_openssh == 1 ]]; then
            ExtraArgs+=" $jelbrek/sshdeb.tar"
        fi
        ExtraArgs+=" $jelbrek/LukeZGD.tar"
        cp $jelbrek/freeze.tar.gz .
        gzip -d freeze.tar.gz
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
    if [[ $device_type == "iPhone5,3" || $device_type == "iPhone5,4" ]] && [[ $device_base_vers == "7.0"* ]]; then
        ipsw_powder_5c70=1
    fi
    if [[ $device_type == "iPhone5"* && $ipsw_powder_5c70 != 1 ]]; then
        # do this stuff because these use ramdiskH (jump to /boot/iBEC) instead of ramdiskI (jump ibot to ibob)
        if [[ $device_target_vers == "9"* ]]; then
            ExtraArr[0]+="9"
        fi
        if [[ $ipsw_jailbreak == 1 && $device_target_vers != "7"* ]]; then
            bootargs+=" cs_enforcement_disable=1 amfi_get_out_of_my_way=1 amfi=0xff"
        fi
        ExtraArr+=("-b" "$bootargs")
        patch_iboot "${ExtraArr[@]}"
        tar -cvf iBoot.tar iBoot
        ExtraArgs+=" iBoot.tar"
    elif [[ $device_type == "iPad1,1" ]]; then
        # ipad 1 ramdiskH jumps to /iBEC instead
        ExtraArr+=("-b" "$bootargs")
        patch_iboot "${ExtraArr[@]}"
        mv iBoot iBEC
        tar -cvf iBoot.tar iBEC
        ExtraArgs+=" iBoot.tar"
    fi

    if [[ $ipsw_isbeta == 1 ]]; then
        ipsw_prepare_systemversion
        ExtraArgs+=" systemversion.tar"
    fi
    if [[ $device_type == "$device_disable_bbupdate" && $device_deadbb != 1 ]]; then
        ExtraArgs+=" ../saved/$device_type/baseband-$device_ecid.tar"
    fi
    if [[ $device_actrec == 1 ]]; then
        ExtraArgs+=" ../saved/$device_type/activation-$device_ecid.tar"
    fi

    log "Preparing custom IPSW: $dir/powdersn0w $ipsw_path.ipsw temp.ipsw -base $ipsw_base_path.ipsw $ExtraArgs"
    "$dir/powdersn0w" "$ipsw_path.ipsw" temp.ipsw -base "$ipsw_base_path.ipsw" $ExtraArgs

    if [[ ! -e temp.ipsw ]]; then
        if [[ $platform == "macos" && $platform_arch == "arm64" ]]; then
            warn "Updating to macOS 14.6 or newer is recommended for Apple Silicon Macs to resolve issues."
        fi
        error "Failed to find custom IPSW. Please run the script again" \
        "* You may try selecting N for memory option"
    fi

    if [[ $device_type != "iPhone5"* && $device_type != "iPad1,1" ]] || [[ $ipsw_powder_5c70 == 1 ]]; then
        case $device_target_vers in
            [789]* ) :;;
            * )
                patch_iboot --logo
                mkdir -p $all_flash
                mv iBoot*.img3 $all_flash
                zip -r0 temp.ipsw $all_flash/iBoot*.img3
            ;;
        esac
    fi
    ipsw_prepare_logos_add

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
        log "Make $1"
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
        log "Make $1"
        if [[ $device_target_vers == "4.2.1" ]]; then
            mkdir -p $saved_path 2>/dev/null
            if [[ -s $saved_path/$name41.$ext ]]; then
                cp $saved_path/$name41.$ext $name.$ext
            else
                ipsw_get_url 8B117
                "$dir/pzb" -g $name41.$ext -o $name.$ext "$ipsw_url"
                cp $name.$ext $saved_path/$name41.$ext
            fi
        else
            file_extract_from_archive "$ipsw_path.ipsw" $name.$ext
        fi
        mv $name.$ext rd.orig
        "$dir/xpwntool" rd.orig rd.dec -iv $iv -k $key
        $bspatch rd.dec rd.patched "$patch"
        "$dir/xpwntool" rd.patched $name.$ext -t rd.orig $ivkey
        zip -r0 temp.ipsw $name.$ext
        return
    fi
    log "Make $1"
    if [[ $device_target_vers == "4.2.1" ]] && [[ $1 == "RestoreDeviceTree" || $1 == "RestoreKernelCache" ]]; then
        mkdir -p $saved_path 2>/dev/null
        if [[ -s $saved_path/$name.$ext ]]; then
            cp $saved_path/$name.$ext $name.$ext
        else
            ipsw_get_url 8B117
            "$dir/pzb" -g ${path}$name.$ext -o $name.$ext "$ipsw_url"
            cp $name.$ext $saved_path/$name.$ext
        fi
        mkdir Downgrade 2>/dev/null
        if [[ $1 == "RestoreKernelCache" ]]; then
            local ivkey="-iv 7238dcea75bf213eff209825a03add51 -k 0295d4ef87b9db687b44f54c8585d2b6"
            "$dir/xpwntool" $name.$ext kernelcache $ivkey
            $bspatch kernelcache kc.patched ../resources/patch/$name.$ext.patch
            "$dir/xpwntool" kc.patched Downgrade/$1 -t $name.$ext $ivkey
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

ipsw_prepare_s5l8900() {
    local rname="018-6494-014.dmg"
    local sha1E="4f6539d2032a1c7e1a068c667e393e62d8912700"
    local sha1L="none"
    ipsw_url="https://github.com/LukeZGD/Legacy-iOS-Kit-Keys/releases/download/jailbreak/"
    if [[ $device_target_vers == "4.1" ]]; then
        rname="018-7079-079.dmg"
        sha1E="9a64eea9949b720f1033d41adc85254e6dbf9525"
    elif [[ $device_target_vers == "4.2.1" ]]; then
        rname="038-0029-002.dmg"
        sha1E="9a64eea9949b720f1033d41adc85254e6dbf9525"
    elif [[ $device_type == "iPhone1,1" && $ipsw_hacktivate == 1 ]]; then
        ipsw_url+="iPhone1.1_3.1.3_7E18_CustomHJ.ipsw"
        sha1E="8140ed162c6712a6e8d1608d3a36257998253d82"
    elif [[ $device_type == "iPhone1,1" ]]; then
        ipsw_url+="iPhone1.1_3.1.3_7E18_CustomJ.ipsw"
        sha1E="4aa139672835d95bebdd2945f713321dcc4965b5"
    elif [[ $device_type == "iPod1,1" ]]; then
        ipsw_url+="iPod1.1_3.1.3_7E18_CustomJ.ipsw"
        sha1E="39d0e16536c281c3f98db91923e3d53b6fad6c6c"
    fi

    if [[ $device_type == "iPhone1,2" && -e "$ipsw_custom.ipsw" ]]; then
        log "Checking RestoreRamdisk hash of custom IPSW"
        file_extract_from_archive "$ipsw_custom.ipsw" $rname
        sha1L="$($sha1sum $rname | awk '{print $1}')"
    elif [[ -e "$ipsw_custom2.ipsw" ]]; then
        log "Getting SHA1 hash for $ipsw_custom2.ipsw..."
        sha1L=$($sha1sum "$ipsw_custom2.ipsw" | awk '{print $1}')
    fi
    if [[ $sha1L == "$sha1E" && $ipsw_customlogo2 == 1 ]]; then
        log "Verified existing Custom IPSW. Preparing custom logo images and IPSW"
        rm -f "$ipsw_custom.ipsw"
        cp $saved/$device_type/"$ipsw_custom2.ipsw" temp.ipsw
        device_fw_key_check
        ipsw_prepare_logos_convert
        ipsw_prepare_logos_add
        mv temp.ipsw "$ipsw_custom.ipsw"
        return
    elif [[ $sha1L == "$sha1E" ]]; then
        log "Verified existing Custom IPSW. Skipping IPSW creation."
        return
    else
        log "Verifying IPSW failed. Expected $sha1E, got $sha1L"
    fi

    if [[ -s "$ipsw_custom.ipsw" ]]; then
        log "Deleting existing custom IPSW"
        rm "$ipsw_custom.ipsw"
    fi

    if [[ $device_type != "iPhone1,2" ]]; then
        log "Downloading IPSW: $ipsw_url"
        $aria2c -c -s 16 -x 16 -k 1M -j 1 "$ipsw_url" -o temp.ipsw
        log "Getting SHA1 hash for IPSW..."
        sha1L=$($sha1sum temp.ipsw | awk '{print $1}')
        if [[ $sha1L != "$sha1E" ]]; then
            error "Verifying IPSW failed. The IPSW may be corrupted or incomplete. Please run the script again" \
            "* SHA1sum mismatch. Expected $sha1E, got $sha1L"
        fi
        if [[ $ipsw_customlogo2 == 1 ]]; then
            cp temp.ipsw "$ipsw_custom2.ipsw"
            device_fw_key_check
            ipsw_prepare_logos_convert
            ipsw_prepare_logos_add
        fi
        mv temp.ipsw "$ipsw_custom.ipsw"
        return
    fi

    ipsw_prepare_jailbreak old

    mv "$ipsw_custom.ipsw" temp.ipsw
    ipsw_prepare_patchcomp LLB
    ipsw_prepare_patchcomp iBoot
    ipsw_prepare_patchcomp RestoreRamdisk
    if [[ $device_target_vers == "4"* ]]; then
        ipsw_prepare_patchcomp WTF2
        ipsw_prepare_patchcomp iBEC
    fi
    if [[ $device_target_vers == "4.2.1" ]]; then
        ipsw_prepare_patchcomp iBSS
        ipsw_prepare_patchcomp RestoreDeviceTree
        ipsw_prepare_patchcomp RestoreKernelCache
    elif [[ $device_target_vers == "3.1.3" ]]; then
        ipsw_prepare_patchcomp Kernelcache
    fi
    mv temp.ipsw "$ipsw_custom.ipsw"
}

ipsw_prepare_custom() {
    if [[ -s "$ipsw_custom.ipsw" ]]; then
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
            log "Make Kernelcache"
            file_extract_from_archive "$ipsw_path.ipsw" kernelcache.release.s5l8920x
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

ipsw_prepare_jailbreak() {
    if [[ -s "$ipsw_custom.ipsw" ]]; then
        log "Found existing Custom IPSW. Skipping IPSW creation."
        return
    fi
    local ExtraArgs=
    local JBFiles=()
    local JBFiles2=()
    local daibutsu=$1

    if [[ $ipsw_jailbreak == 1 ]]; then
        JBFiles+=("fstab_rw.tar")
        case $device_target_vers in
            6.1.[3456] ) JBFiles+=("p0sixspwn.tar");;
            6* ) JBFiles+=("evasi0n6-untether.tar");;
            4.[10]* | 3.2* | 3.1.3 ) JBFiles+=("greenpois0n/${device_type}_${device_target_build}.tar");;
            5* | 4.[32]* ) JBFiles+=("g1lbertJB/${device_type}_${device_target_build}.tar");;
        esac
        case $device_target_vers in
            [43]* ) JBFiles[0]="fstab_old.tar"
        esac
        for i in {0..1}; do
            JBFiles[i]=$jelbrek/${JBFiles[$i]}
        done
        JBFiles+=("freeze.tar")
        case $device_target_vers in
            4.3* ) [[ $device_type == "iPad2"* ]] && JBFiles[1]=;;
            4.2.[8761] )
                if [[ $device_type == "iPhone1,2" ]]; then
                    JBFiles[1]=
                else
                    ExtraArgs+=" -punchd"
                    JBFiles[1]=$jelbrek/greenpois0n/${device_type}_${device_target_build}.tar
                fi
            ;;
            3.1* )
                if [[ $device_type == "iPhone1,2" || $device_type == "iPhone2,1" || $ipsw_24o == 1 ]]; then
                    JBFiles[1]=
                fi
            ;;
            3.0* | 4.2* ) JBFiles[1]=;;
        esac
        case $device_target_vers in
            [543]* ) JBFiles+=("$jelbrek/cydiasubstrate.tar");;
        esac
        if [[ $device_target_vers == "3"* ]]; then
            JBFiles+=("$jelbrek/cydiahttpatch.tar")
        elif [[ $device_target_vers == "5"* ]]; then
            JBFiles+=("$jelbrek/g1lbertJB.tar")
        fi
        if [[ $device_target_tethered == 1 && $device_type != "iPad2"* ]]; then
            case $device_target_vers in
                5* | 4.3* ) JBFiles+=("$jelbrek/g1lbertJB/install.tar");;
            esac
        fi
        ExtraArgs+=" -S 30" # system partition add
        if [[ $ipsw_openssh == 1 ]]; then
            JBFiles+=("$jelbrek/sshdeb.tar")
        fi
        case $device_target_vers in
            [43]* ) :;;
            * ) JBFiles+=("$jelbrek/LukeZGD.tar");;
        esac
        cp $jelbrek/freeze.tar.gz .
        gzip -d freeze.tar.gz
    fi

    ipsw_prepare_bundle $daibutsu
    ipsw_prepare_logos_convert

    if [[ $ipsw_memory == 1 ]]; then
        ExtraArgs+=" -memory"
    fi
    ExtraArgs+=" -ramdiskgrow 10"

    if [[ $device_actrec == 1 ]]; then
        ExtraArgs+=" ../saved/$device_type/activation-$device_ecid.tar"
    fi
    if [[ $1 == "iboot" ]]; then
        ExtraArgs+=" iBoot.tar"
    fi
    if [[ $ipsw_isbeta == 1 ]]; then
        ipsw_prepare_systemversion
        ExtraArgs+=" systemversion.tar"
    fi

    log "Preparing custom IPSW: $dir/ipsw $ipsw_path.ipsw temp.ipsw $ExtraArgs ${JBFiles[*]}"
    "$dir/ipsw" "$ipsw_path.ipsw" temp.ipsw $ExtraArgs ${JBFiles[@]}

    if [[ ! -e temp.ipsw ]]; then
        error "Failed to find custom IPSW. Please run the script again" 
    fi

    ipsw_prepare_logos_add

    mv temp.ipsw "$ipsw_custom.ipsw"
}

ipsw_prepare_ios7touch4() {
    local all_flash2="$ipsw_custom/$all_flash"
    local patches="../resources/patch/touch4-ios7"
    local saves="../saved/$device_type/touch4-ios7"
    if [[ -e "$ipsw_custom.ipsw" ]]; then
        log "Found existing Custom IPSW. Skipping IPSW creation."
        return
    fi
    all_flash_special="Firmware/all_flash/all_flash.${device_model_special}ap.production"

    log "Preparing custom IPSW..."
    mkdir -p $ipsw_custom/Firmware/dfu $ipsw_custom/Downgrade $all_flash2 $saves/$device_target_build 2>/dev/null

    local comps=("iBSS" "iBEC" "DeviceTree" "Kernelcache" "RestoreRamdisk"
        "AppleLogo" "BatteryCharging0" "BatteryCharging1" "BatteryFull" "BatteryLow0" "BatteryLow1"
        "GlyphCharging" "GlyphPlugin" "iBoot" "LLB" "RecoveryMode")
    local name
    local iv
    local key
    local path
    device_fw_key_check base

    log "Getting base ($device_base_vers) restore components"
    for getcomp in "${comps[@]}"; do
        name=$(echo $device_fw_key_base | $jq -j '.keys[] | select(.image == "'$getcomp'") | .filename')
        iv=$(echo $device_fw_key_base | $jq -j '.keys[] | select(.image == "'$getcomp'") | .iv')
        key=$(echo $device_fw_key_base | $jq -j '.keys[] | select(.image == "'$getcomp'") | .key')
        case $getcomp in
            "iBSS" | "iBEC" ) path="Firmware/dfu/";;
            "Kernelcache" | "RestoreRamdisk" ) path="";;
            * ) path="$all_flash/";;
        esac
        log "$getcomp"
        file_extract_from_archive "$ipsw_base_path.ipsw" ${path}$name
        case $getcomp in
            "DeviceTree" )
                cp $name $all_flash2/
                "$dir/xpwntool" $name $ipsw_custom/Downgrade/RestoreDeviceTree -iv $iv -k $key -decrypt
            ;;
            "Kernelcache" )
                "$dir/xpwntool" $name $ipsw_custom/Downgrade/RestoreKernelCache -iv $iv -k $key -decrypt
            ;;
            "AppleLogo" )
                cp $name $all_flash2/
                "$dir/xpwntool" $name $ipsw_custom/Downgrade/RestoreLogo -iv $iv -k $key -decrypt
            ;;
            "iBSS" | "iBEC" | "RestoreRamdisk" )
                mv $name $getcomp.orig
                "$dir/xpwntool" $getcomp.orig $getcomp.dec -iv $iv -k $key
            ;;
            * ) mv $name $all_flash2/;;
        esac
    done

    log "Make iBSS"
    "$dir/iBoot32Patcher" iBSS.dec iBSS.patched --rsa
    "$dir/xpwntool" iBSS.patched $ipsw_custom/Firmware/dfu/iBSS.${device_model}ap.RELEASE.dfu -t iBSS.orig

    log "Make iBEC"
    $bspatch iBEC.dec iBEC.patched $patches/iBEC.${device_model}ap.RELEASE.patch
    "$dir/xpwntool" iBEC.patched $ipsw_custom/Firmware/dfu/iBEC.${device_model}ap.RELEASE.dfu -t iBEC.orig
    "$dir/iBoot32Patcher" iBEC.dec iBEC.patched --rsa --debug --ticket -b "-v amfi=0xff cs_enforcement_disable=1"
    "$dir/xpwntool" iBEC.patched $saves/pwnediBEC.dfu -t iBEC.orig

    log "Base manifest plist"
    file_extract_from_archive "$ipsw_base_path.ipsw" BuildManifest.plist
    $PlistBuddy -c "Set BuildIdentities:0:Manifest:RestoreDeviceTree:Info:Path Downgrade/RestoreDeviceTree" BuildManifest.plist
    $PlistBuddy -c "Set BuildIdentities:0:Manifest:RestoreKernelCache:Info:Path Downgrade/RestoreKernelCache" BuildManifest.plist
    $PlistBuddy -c "Set BuildIdentities:0:Manifest:RestoreLogo:Info:Path Downgrade/RestoreLogo" BuildManifest.plist
    cp BuildManifest.plist $ipsw_custom/

    local ramdisk_name=$(echo $device_fw_key_base | $jq -j '.keys[] | select(.image == "RestoreRamdisk") | .filename')
    log "Restore Ramdisk: $ramdisk_name"
    mv RestoreRamdisk.dec ramdisk.dec
    "$dir/hfsplus" ramdisk.dec grow 11000000

    log "Make ASR"
    ipsw_patch_file ramdisk.dec usr/sbin asr $patches/asr.patch

    log "Modify options.plist"
    "$dir/hfsplus" ramdisk.dec rm usr/local/share/restore/options.n81.plist
    "$dir/hfsplus" ramdisk.dec add $patches/options.n81.plist usr/local/share/restore/options.n81.plist

    log "Repack Restore Ramdisk"
    "$dir/xpwntool" ramdisk.dec $ipsw_custom/$ramdisk_name -t RestoreRamdisk.orig

    local rootfs_name=$(echo $device_fw_key_base | $jq -j '.keys[] | select(.image == "RootFS") | .filename')
    log "Base RootFS: $rootfs_name"

    log "Target manifest plist"
    rm BuildManifest.plist
    file_extract_from_archive "$ipsw_path.ipsw" BuildManifest.plist
    local rootfs_target_name=$($PlistBuddy -c "Print BuildIdentities:0:Manifest:OS:Info:Path" BuildManifest.plist | tr -d '"')
    local rootfs_target_key
    local kc_iv
    local kc_key
    local dt_iv
    local dt_key
    case $device_type_special in
        iPhone3,1 )
            rootfs_target_key="38d0320d099b9dd34ffb3308c53d397f14955b347d6a433fe173acc2ced1ae78756b3684"
            kc_iv="a1aee41423e11a44135233dd345433ce"
            kc_key="9b05ef79c63c59e71f253219ffaa952f25f6810d3863aac2b49628e64f9f0869"
            dt_iv="d2f224a2d7e04461ec12ac81f91d657a"
            dt_key="b93c3a564dc36e184871e246fa8df725ecebafb38c042b6302b333c39e7d1787"
        ;;
        iPhone3,3 )
            rootfs_target_key="423b3503689b7058d1398d1b5d56a7b1ccf4d79e1c3e6ba853122b4f86820a9e3bc911f6"
            kc_iv="b84212f017d5ffd962db0bbe050581dc"
            kc_key="92e5720cadf724cdf428d44119b634ab3346aef1ab4e3e20abc8ecb73f7f8642"
            dt_iv="8662383170bb93fffe2dbdd181a620da"
            dt_key="8473b8932e1957c1e650f15cb3b6f49f497e241ebacfaa7d0b1eca3b15fc633c"
        ;;
    esac
    log $device_type_special
    pause
    local rootfs_target_size=$((1589*1024*1024))

    log "Target kernelcache"
    file_extract_from_archive "$ipsw_path.ipsw" kernelcache.release.$device_model_special
    mv kernelcache.release.$device_model_special kc
    "$dir/xpwntool" kc kc.dec -iv $kc_iv -k $kc_key
    $bspatch kc.dec kc.patched $patches/$device_target_build/kc$ipsw_jailbreak.$device_model_special.patch # kc for non-jb, kc1 for jb
    "$dir/xpwntool" kc.patched kc.new -t kc -iv $kc_iv -k $kc_key
    "$dir/xpwntool" kc.new $saves/$device_target_build/kernelcache$ipsw_jailbreak -iv $kc_iv -k $kc_key -decrypt
    cp kc.new $ipsw_custom/kernelcache.release.$device_model # wont be used, but needed for restore
    pause
    log "Target devicetree"
    file_extract_from_archive "$ipsw_path.ipsw" $all_flash_special/DeviceTree.${device_model_special}ap.img3
    mv DeviceTree.${device_model_special}ap.img3 dt
    "$dir/xpwntool" dt dt.dec -iv $dt_iv -k $dt_key -decrypt
    echo "0000006d: 38 31" | xxd -r - dt.dec
    cp dt.dec $saves/$device_target_build/devicetree

    log "Target RootFS: extracting dmg from ipsw"
    file_extract_from_archive "$ipsw_path.ipsw" $rootfs_target_name
    log "Target RootFS: extracting dmg with key $rootfs_target_key"
    "$dir/dmg" extract $rootfs_target_name rootfs.dec -k $rootfs_target_key
    if [[ $? != 0 || ! -s rootfs.dec ]]; then
        error "Failed to extract dmg. Please run the script again"
    fi
    log "Target RootFS: growing $rootfs_target_size"
    "$dir/hfsplus" rootfs.dec grow $rootfs_target_size
    log "Target RootFS: untar wifi firmware"
    "$dir/hfsplus" rootfs.dec untar $patches/wifi.tar
    "$dir/hfsplus" rootfs.dec untar $patches/beauty.tar

    if [[ $ipsw_jailbreak == 1 ]]; then
        log "Target RootFS: untar jailbreak bootstrap"
        cp $jelbrek/freeze.tar.gz .
        gzip -d freeze.tar.gz
        "$dir/hfsplus" rootfs.dec untar freeze.tar
        "$dir/hfsplus" rootfs.dec untar $jelbrek/fstab_rw.tar
        "$dir/hfsplus" rootfs.dec untar $jelbrek/LukeZGD.tar
        if [[ $ipsw_openssh == 1 ]]; then
            "$dir/hfsplus" rootfs.dec untar $jelbrek/sshdeb.tar
        fi
        touch .cydia_no_stash
        "$dir/hfsplus" rootfs.dec add .cydia_no_stash .cydia_no_stash
    fi

    echo '<plist><dict><key>com.apple.mobile.lockdown_cache-ActivationState</key><string>FactoryActivated</string></dict></plist>' > data_ark.plist
    log "Target RootFS: activation stuff"
    "$dir/hfsplus" rootfs.dec add data_ark.plist /var/root/Library/Lockdown/data_ark.plist
    "$dir/hfsplus" rootfs.dec mv Applications/Setup.app Setup.app
    "$dir/hfsplus" rootfs.dec mv Applications/MobilePhone.app MobilePhone.app

    log "Target RootFS: building dmg as $rootfs_name"
    "$dir/dmg" build rootfs.dec $ipsw_custom/$rootfs_name
    if [[ $? != 0 || ! -s $ipsw_custom/$rootfs_name ]]; then
        error "Failed to build dmg. Please run the script again"
    fi
    echo "device_target_build=$device_target_build
    ipsw_jailbreak=$ipsw_jailbreak" > $saves/$device_ecid
    log "Creating $ipsw_custom.ipsw..."
    pushd $ipsw_custom >/dev/null
    zip -r0 ../$(basename $ipsw_custom.ipsw) *
    popd >/dev/null
    if [[ ! -f $ipsw_custom.ipsw ]]; then
        error 制作固件失败
        pause
        exit 1
    else
        cp $ipsw_custom.ipsw ../saved/$device_type/
        log "固件保存至../saved/$device_type/$ipsw_custom.ipsw"
        pause
    fi

}

ipsw_prepare_ios7touch4_2() {
    local rootfs_target_size=$((1589*1024*1024))
    local patches="../resources/patch/touch4-ios7"
    local rootfs_target_name="058-4110-009.dmg"
    local rootfs_target_key="423b3503689b7058d1398d1b5d56a7b1ccf4d79e1c3e6ba853122b4f86820a9e3bc911f6"
    log "Target RootFS: extracting dmg from ipsw"
    file_extract_from_archive "$ipsw_path.ipsw" $rootfs_target_name
    log "Extract RootFS"
    $dmg extract $rootfs_name decrypted.dmg -k $rootfs_target_key
    log "Target RootFS: building dmg as temp.dmg"
    $dmg build decrypted.dmg temp.dmg
    if [[ $? != 0 || ! -f temp.dmg ]]; then
        error "Failed to build dmg. Please run the script again"
    else
        cp temp.dmg $saved/$device_type/UDZO.dmg
    fi
    pause
}

ipsw_prepare_ios6touch3() {
    local sundance="../saved/SundanceInH2A_$platform"
    local ipsw_path2="${device_type_special}_${device_target_vers}_${device_target_build}_Restore"
    local ipsw_base_path2="${device_type}_${device_base_vers}_${device_base_build}_Restore"
    local ipsw_custom2="${device_type}_${device_target_vers}_${device_target_build}_Custom"
    local jb
    local kc="$sundance/artifacts/kernelcache.n18ap.bin"
    local kc_sha1="56baaebd7c260f3d41679fee686426ef2578bbd3"
    local kc_url="https://gist.githubusercontent.com/NyanSatan/1cf6921821484a2f8f788e567b654999/raw/7fa62c2cb54855d72b2a91c2aa3d57cab7318246/magic-A63970m.b64"
    if [[ $ipsw_jailbreak == 1 ]]; then
        jb="-j"
        kc="$sundance/artifacts/kernelcache.jailbroken.n18ap.bin"
        kc_sha1="2c42a07b82d14dab69417f750d0e4ca118bf225c"
        kc_url="https://gist.githubusercontent.com/NyanSatan/1cf6921821484a2f8f788e567b654999/raw/095022a2e8635ec3f3ee3400feb87280fd2c9f17/magic-A63970m-jb.b64"
    fi

    if [[ -e "$ipsw_custom.ipsw" ]]; then
        log "Found existing Custom IPSW. Skipping IPSW creation."
        return
    fi

    log "Preparing SundanceInH2A"
    if [[ -s $sundance/Sundancer ]]; then
        pushd $sundance >/dev/null
        git reset --hard
        git pull
        popd >/dev/null
    else
        local repo
        rm -rf $sundance
        case $platform in
            "macos" ) repo="https://github.com/NyanSatan/SundanceInH2A";;
            "linux" ) repo="https://github.com/LukeZGD/SundanceInH2A";;
        esac
        log "git clone: $repo"
        git clone $repo $sundance
    fi

    if [[ -s $kc ]]; then
        if [[ $($sha1sum $kc 2>/dev/null | awk '{print $1}') != "$kc_sha1" ]]; then
            rm $kc
        fi
    fi

    if [[ ! -s $kc ]]; then
        log "Downloading kernelcache: $(basename $kc)"
        download_from_url "$kc_url" kc.b64
        base64 --decode kc.b64 | gunzip > $kc
    fi

    if [[ $($sha1sum $kc 2>/dev/null | awk '{print $1}') != "$kc_sha1" ]]; then
        rm $kc
        error "Downloading/verifying kernelcache failed. Please run the script again"
    fi

    log "Copying IPSWs..."
    cp "$ipsw_path.ipsw" "$sundance/$ipsw_path2.ipsw"
    cp "$ipsw_base_path.ipsw" "$sundance/$ipsw_base_path2.ipsw"
    log "Preparing custom IPSW..."
    pushd $sundance >/dev/null
    rm -rf "$ipsw_custom2"
    ./Sundancer $jb "$ipsw_base_path2.ipsw" "$ipsw_path2.ipsw" "$ipsw_custom2"
    rm "$ipsw_path2.ipsw" "$ipsw_base_path2.ipsw"
    if [[ ! -d "$ipsw_custom2" ]]; then
        error "Custom IPSW creation seems to have failed. Please run the script again" \
        "* If you do not have Python 3 installed, install it since SundanceInH2A requires it."
    fi
    pushd "$ipsw_custom2"
    zip -r0 ../../$ipsw_custom.ipsw *
    popd >/dev/null
    rm -rf "$ipsw_custom2"
    popd >/dev/null
}

ipsw_custom_set() {
    if [[ $device_64bit == 1 ]]; then
        return
    fi

    ipsw_custom="../saved/${device_type}/${device_type}_${device_target_vers}_${device_target_build}_Custom"
    if [[ -n $1 ]]; then
        ipsw_custom="../$1_Custom"
    fi

    if [[ $device_actrec == 1 ]]; then
        ipsw_custom+="A"
    fi
    if [[ $device_deadbb == 1 ]]; then
        ipsw_custom+="D"
    elif [[ $device_type == "$device_disable_bbupdate" ]]; then
        ipsw_custom+="B"
    fi
    if [[ $ipsw_gasgauge_patch == 1 ]]; then
        ipsw_custom+="G"
    fi
    if [[ $ipsw_hacktivate == 1 ]]; then
        ipsw_custom+="H"
    fi
    if [[ $ipsw_jailbreak == 1 ]]; then
        ipsw_custom+="J"
    fi
    if [[ $device_proc == 1 && $device_type != "iPhone1,2" ]]; then
        ipsw_custom2="$ipsw_custom"
    fi
    if [[ -n $ipsw_customlogo || -n $ipsw_customrecovery ]]; then
        ipsw_custom+="L"
        if [[ $device_proc == 1 && $device_type != "iPhone1,2" ]]; then
            ipsw_customlogo2=1
        fi
    fi
    if [[ $ipsw_24o == 1 ]]; then
        ipsw_custom+="O"
    fi
    if [[ $device_target_powder == 1 ]]; then
        ipsw_custom+="P"
        if [[ $device_base_vers == "7.0"* ]]; then
            ipsw_custom+="0"
        fi
    fi
    if [[ $device_target_tethered == 1 ]]; then
        ipsw_custom+="T"
    fi
    if [[ $device_target_t4os7 == 1 || $device_target_t4os72 == 1 || $device_target_t3os6 == 1 ]]; then
        ipsw_custom+="S"
        if [[ $device_target_t4os72 ]]; then
            ipsw_custom+="2"
        fi
    fi
    if [[ $ipsw_verbose == 1 ]]; then
        ipsw_custom+="V"
    fi
    if [[ $device_target_powder == 1 && $device_target_vers == "4.3"* ]] || [[ $device_actrec == 1 ]] ||
       [[ $device_type == "$device_disable_bbupdate" && $device_deadbb != 1 ]]; then
        ipsw_custom+="-$device_ecid"
    fi
}

ipsw_extract() {
    if [[ $1 == "custom" ]]; then
        local ipsw=$ipsw_custom
    else
        local ipsw=$ipsw_path
    fi
    if [[ ! -d "$ipsw" ]]; then
        mkdir "$ipsw"
        log "Extracting IPSW: $ipsw.ipsw"
        file_extract "$ipsw.ipsw" "$ipsw/"
    fi
}
###########justboot##########

device_justboot() {
    if [[ -z $device_bootargs ]]; then
        device_bootargs="pio-error=0 -v"
    fi
    if [[ $main_argmode == "device_justboot" ]]; then
        cat "$device_rd_build" > "../saved/$device_type/justboot_${device_ecid}"
    fi
    ramdisk justboot
}

device_justboot_ios7touch4() {
    local patches="../resources/patch/touch4-ios7"
    local saves="../saved/$device_type/touch4-ios7"
    device_type_special="iPhone3,3"
    device_model_special="n92"
    if [[ ! -s $saves/$device_ecid ]]; then
        error "Cannot find device file for $device_ecid in saved. Need to restore to iOS 7.1.2 first."
    fi

    source $saves/$device_ecid
    [[ -z $device_target_build ]] && device_target_build="11D257"
    log "device_target_build=$device_target_build"
    log "ipsw_jailbreak=$ipsw_jailbreak"
    if [[ -d "$saves/$device_type_special" ]]; then
        # migrate from old location to new
        local old="$saves/$device_type_special"
        local new="$saves/$device_target_build"
        mkdir -p "$new"
        if [[ -s "$old/pwnediBEC.dfu" ]]; then
            mv "$old/pwnediBEC.dfu" "$saves/"
        fi
        for f in devicetree "kernelcache$ipsw_jailbreak"; do
            [[ -s "$old/$f" ]] && mv "$old/$f" "$new/"
        done
        rm -r "$old"
    fi

    device_enter_mode pwnDFU
    device_rd_build=
    patch_ibss
    log "Sending iBSS..."
    $irecovery -f pwnediBSS.dfu
    sleep 1
    log "Sending iBEC..."
    $irecovery -f $saves/pwnediBEC.dfu
    checkmode rec
    log "devicetree"
    $irecovery -f $saves/$device_target_build/devicetree
    $irecovery -c devicetree
    log "kernelcache"
    $irecovery -f $saves/$device_target_build/kernelcache$ipsw_jailbreak
    $irecovery -c bootx
    log "Device should now boot."

}

device_justboot_tm() {
    local ver
    log "复制文件"
    if [[ $platform == "macos" ]]; then
        if [[ $platform_arch == "arm64" ]]; then
            cp -R ../bin/macos/turdus_m3rula .
        else
            cp -R $dir/turdus_m3rula .
        fi
    else
        cp -R $dir/turdus_m3rula .
    fi
    if [[ -f ./turdus_m3rula/bin/turdus_merula ]] && [[ -f ./turdus_m3rula/bin/turdusra1n ]]; then
        :
    else
        error "文件不完整,请重新下载本脚本"
        exit 1
    fi
    input "输入要引导的版本"
    read ver
    log "引导设备"
    local saved="../saved/$device_type/justboot/image4_${ver}_${device_ecid}"
    if [[ ! -d $saved ]]; then
        error "似乎本设备并未储存过此版本的引导文件,请先进行无SHSH刷机后再试"
    else
        if [[ -f $saved/$device_ecid-$device_type-$ver-iBoot.img4 && -f $saved/$device_ecid-$device_type-$ver-SEP.im4p && -f $saved/$device_ecid-$device_type-signed-SEP.img4 ]]; then
            ./turdus_m3rula/bin/turdusra1n -t $saved/$device_ecid-$device_type-$ver-iBoot.img4 -i $saved/$device_ecid-$device_type-signed-SEP.img4 -p $saved/$device_ecid-$device_type-$ver-SEP.im4p
            log "引导完成"
        else
            error "引导文件不完整"
        fi
    fi
}   

###########restore###########

dfu_helper() {
    local butten
    if [[ $device_mode != "DFU" ]] && [[ $1 == "?" ]]; then
        yesno 是否使用DFUhelper进入DFU? 1
        if [[ $? == 1 ]]; then
            use_dfuhelper=1
        fi
    fi
    if [[ $device_mode == "DFU" || $device_mode == "WTF" ]]; then
        return
    fi
    if [[ $use_dfuhelper == 1 ]]; then
        if [[ $device_type != "iPod9,1" ]]; then
            butten="home"
        else
            butten="音量下"
        fi
        warning 准备开始操作
        for i in {3..1}; do
        echo "$i..."
        sleep 1
        done
        log 同时按住${butten}键和电源键
        for i in {8..1}; do
        echo "$i..."
        sleep 1
        done
        log 松开电源键只按住${butten}键
        for i in {8..1}; do
        echo "$i..."
        sleep 1
        done
        checkmode DFUall
    else
        checkmode DFUall
    fi
}



restore_idevicerestore() {
    local ExtraArgs="-ew"
    local idevicerestore2="$idevicerestore"
    ipsw_extract custom
    log "Running idevicerestore with command: $idevicerestore2 $ExtraArgs \"$ipsw_custom.ipsw\""
    $idevicerestore2 $ExtraArgs "$ipsw_custom.ipsw"
    log "Restoring done! Read the message below if any error has occurred:"
}

restore_futurerestore() {
    local ExtraArr=()
    local port=8888
    local build=$device_target_build
    case $device_proc in
        "4" | "5" ) local futurerestore2=$futurerestore_old ;;
        "8" | "10" ) local futurerestore2="${futurerestore}_${platform}" ;;
        * ) error 本设备不支持futurestore
    esac
    log 创建本地服务器
    device_fw_key_check
    mkdir -p firmware/$device_type/$device_target_build
    mv index.html firmware/$device_type/$device_target_build
    pushd ../saved >/dev/null
    log "Starting local server for firmware keys"
    "$dir/darkhttpd" ./ --port $port &
    httpserver_pid=$!
    log "httpserver PID: $httpserver_pid"
    popd >/dev/null
    log "等待本地服务器"
    until [[ $(curl http://127.0.0.1:$port 2>/dev/null) ]]; do
        sleep 1
    done
    if [[ ! -s ../saved/firmwares.json ]]; then
        file_download https://api.ipsw.me/v2.1/firmwares.json/condensed firmwares.json
        mv firmwares.json ../saved
    fi
    rm -f /tmp/firmwares.json
    cp ../saved/firmwares.json /tmp
    if [[ $device_proc == 8 || $device_proc == 10 ]]; then
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
    ExtraArr+=("--use-pwndfu")
    if [[ -n "$1" ]]; then
        ExtraArr+=("$1")
    fi
    if [[ -n "$2" ]]; then
        ExtraArr+=("$2")
    fi
    ExtraArr+=("-t" "$shsh_path" "$ipsw_path.ipsw")
    ipsw_extract
    log "Running futurerestore with command: $futurerestore2 ${ExtraArr[*]}"
    $futurerestore2 "${ExtraArr[@]}"
    kill $httpserver_pid
    log 恢复完成✅
}

restore_turdus_merula() {
    local ExtraArr=()
    log "复制文件"
    if [[ $platform == "macos" ]]; then
        if [[ $platform_arch == "arm64" ]]; then
            cp -R ../bin/macos/turdus_m3rula .
        else
            cp -R $dir/turdus_m3rula .
        fi
    else
        cp -R $dir/turdus_m3rula .
    fi
    if [[ -f ./turdus_m3rula/bin/turdus_merula ]] && [[ -f ./turdus_m3rula/bin/turdusra1n ]]; then
        :
    else
        error "文件不完整,请重新下载本脚本"
        exit 1
    fi
    if [[ $device_target_shsh == 1 ]] && [[ $device_target_other == 1 ]]; then
        log "破解DFU并固定G值"
        ./turdus_m3rula/bin/turdusra1n -Db $shsh_generator
        sleep 3
        log "开始恢复"
        ./turdus_m3rula/bin/turdus_merula -w --load-shsh $shsh_path $ipsw_path.ipsw
        log "恢复完成✅"
    elif [[ $device_target_tethered == 1 ]]; then
        local saved="../saved/$device_type/justboot/image4_${device_target_vers}_${device_ecid}"
        if [[ -d $saved ]]; then
            rm -rf $saved
        fi
        log "破解DFU"
        ./turdus_m3rula/bin/turdusra1n -D
        sleep 3
        log "开始恢复"
        ./turdus_m3rula/bin/turdus_merula -o $ipsw_path.ipsw
        if [[ ! -d ../saved/$device_type/justboot ]]; then
            mkdir ../saved/$device_type/justboot
        fi
        mv ./image4 ../saved/$device_type/justboot/image4_${device_target_vers}_${device_ecid}
        if [[ -f $saved/$device_ecid-$device_type-$ver-iBoot.img4 && -f $saved/$device_ecid-$device_type-$ver-SEP.im4p && -f $saved/$device_ecid-$device_type-signed-SEP.img4 ]]; then
            log "恢复完成✅"
        else
            error "恢复失败"
        fi
    fi

}

restore_latest() {
    local idevicerestore2="$idevicerestore"
    local ExtraArgs="-e"
    local noextract
    [[ $1 == "update" ]] && ExtraArgs=
    if [[ $device_latest_vers == "12"* || $device_latest_vers == "15"* || $device_latest_vers == "16"* || $device_checkm8ipad == 1 ]]; then
        idevicerestore2+="2"
        ExtraArgs+=" -y"
        noextract=1
    fi
    if [[ $1 == "custom" ]]; then
        ExtraArgs+=" -c"
        ipsw_path="$ipsw_custom"
        ipsw_extract custom
    else
        ipsw_extract
    fi
    if [[ $device_type == "iPhone1,2" && $device_target_vers == "4"* ]]; then
        if [[ $1 == "custom" ]]; then
            log "Sending s5l8900xall..."
            $irecovery -f "$ipsw_custom/Firmware/dfu/WTF.s5l8900xall.RELEASE.dfu"
            checkmode DFUall
            log "Sending iBSS..."
            $irecovery -f "$ipsw_custom/Firmware/dfu/iBSS.${device_model}ap.RELEASE.dfu"
            checkmode rec
        fi
    elif [[ $device_proc == 1 && $device_target_vers == "3.1.3" && $mode == "customipsw" ]]; then
        log "Sending iBSS..."
        $irecovery -f "$ipsw_custom/Firmware/dfu/iBSS.${device_model}ap.RELEASE.dfu"
        checkmode rec
    fi
    if [[ $debug_mode == 1 ]]; then
        ExtraArgs+=" -d"
    fi
    log "Running idevicerestore with command: $idevicerestore2 $ExtraArgs \"$ipsw_path.ipsw\""
    $idevicerestore2 $ExtraArgs "$ipsw_path.ipsw"

    log "Done"
}

############shsh##############

shsh_save() {
    if [[ $1 == "4.1" ]]; then
        local device_latest_vers="4.1"
    fi
    if [[ ! -d ../saved/shsh ]]; then
        mkdir ../saved/shsh 2>/dev/null
    fi
    if [[ ! -d ../saved/manifest ]]; then
        mkdir ../saved/manifest 2>/dev/null
    fi
    if [[ -f ../saved/shsh/$device_ecid-$device_type-$device_latest_vers.shsh ]]; then
        return
    fi
    local buildmanifest="../saved/manifest/BuildManifest_${device_type}_${device_latest_vers}.plist"
    log Save SHSH
    if [[ -f $buildmanifest ]]; then
        cp $buildmanifest manfests.plist
    else
        log "Download BuildManifest from $device_latest_vers IPSW..."
        get_firmware_info ver $device_latest_vers
        "$pzb" -g BuildManifest.plist -o manfests.plist "$ipsw_url"
        cp manfests.plist $buildmanifest
    fi
    mkdir tss 2>/dev/null
    $tsschecker -d $device_type -e $device_ecid -i ${device_latest_vers} -s -m manfests.plist --save-path tss/
    local tss_shsh=$(find tss/ -type f -name "*.shsh2" 2>/dev/null)
    if [[ -f $tss_shsh ]]; then
        mv $tss_shsh ../saved/shsh/$device_ecid-$device_type-$device_latest_vers.shsh
    else
        error Unable get SHSH
        exit 1
    fi
}

shsh_save_cydia() {
    rm -f tmp.json
    $aria2c "https://api.ipsw.me/v4/device/${device_type}?type=ipsw" -o tmp.json
    [[ $? != 0 ]] && $curl -L "https://api.ipsw.me/v4/device/${device_type}?type=ipsw" -o tmp.json
    local json=$(cat tmp.json)
    local len=$(echo "$json" | $jq -r ".firmwares | length")
    local builds=()
    local i=0
    while (( i < len )); do
        builds+=($(echo "$json" | $jq -r ".firmwares[$i].buildid"))
        ((i++))
    done
    for build in ${builds[@]}; do
        if [[ $build == "10"* && $build != "10B329" && $build != "10B350" ]]; then
            continue
        fi
        printf "\n%s " "$build"
        $tsschecker -d $device_type -e $device_ecid --server-url "http://cydia.saurik.com/TSS/controller?action=2/" -s -g 0x1111111111111111 --buildid $build >/dev/null
        if [[ $(ls *$build* 2>/dev/null) ]]; then
            printf "saved"
            mv $(ls *$build*) ../saved/shsh/$device_ecid-$device_type-$build.shsh
        else
            printf "failed"
        fi
    done
}

device_shsh_save() {
    local shsh
    local raw
    if [[ $1 == "raw" ]]; then
        local arg="dump"
        local text="Raw"
    else
        local text="SHSH"
    fi
    log "开始保存设备$text"
    device_save_shsh=1
    ipsw_menu
    dfu_helper ?
    device_pwn
    device_raw_dump $arg
    if [[ $1 == raw ]]; then
        raw=“../saved/raws/rawdump_${device_ecid}-${device_type}-${device_target_vers}-${device_target_build}_$(date +%Y-%m-%d-%H%M).raw”
        if [[ ! -f $raw ]]; then
            error "保存Raw失败"
            exit 1
        else
            log "Raw文件已保存至$raw"
        fi
    else
        shsh="../saved/shsh/${device_ecid}-${device_type}-${device_target_vers}-${device_target_build}.shsh"
        if [[ ! -f $shsh ]]; then
            error "保存SHSH失败"
            exit 1
        else
            log "SHSH文件已保存至$shsh"
        fi
    fi
}

device_raw_dump() {
    if [[ $device_proc == 4 && $device_pwnrec != 1 ]]; then
        patch_ibss
        log "Sending iBSS..."
        $irecovery -f pwnediBSS.dfu
    fi
    sleep 2
    patch_ibec
    log "Sending iBEC..."
    $irecovery -f pwnediBEC.dfu
    if [[ $device_pwnrec == 1 ]]; then
        $irecovery -c "go"
    fi
    sleep 3
    checkmode rec
    log "Dumping raw dump now"
    (echo -e "/send ../resources/payload\ngo blobs\n/exit") | $irecovery2 -s
    $irecovery2 -g dump.raw
    log "Rebooting device"
    $irecovery -n
    local raw
    local err
    device_shsh_dump $1
    err=$?
    mkdir ../saved/raws 2>/dev/null
    raw="../saved/raws/rawdump_${device_ecid}-${device_type}-${device_target_vers}-${device_target_build}_$(date +%Y-%m-%d-%H%M).raw"
    if [[ $1 == "dump" ]] || [[ $err != 0 && -s dump.raw ]]; then
        mv dump.raw $raw
        return
    fi
}

device_shsh_dump() {
    mkdir ../saved/shsh 2>/dev/null
    shsh="../saved/shsh/${device_ecid}-${device_type}-${device_target_vers}-${device_target_build}.shsh"
    # remove ibob for powdersn0w/dra downgraded devices. fixes unknown magic 69626f62
    local blob=$(xxd -p dump.raw | tr -d '\n')
    local bobi="626f6269"
    local blli="626c6c69"
    if [[ $blob == *"$bobi"* ]]; then
        log "Detected \"ibob\". Fixing... (This happens on DRA/powdersn0w downgraded devices)"
        rm -f dump.raw
        printf "%s" "${blob%"$bobi"*}${blli}${blob##*"$blli"}" | xxd -r -p > dump.raw
    fi
    shsh_onboard_iboot="$(cat dump.raw | strings | grep iBoot | head -1)"
    log "Raw dump iBoot version: $shsh_onboard_iboot"
    if [[ $1 == "dump" ]]; then
        return
    fi
    log "Converting raw dump to SHSH blob"
    "$dir/ticket" dump.raw dump.shsh "$ipsw_path.ipsw" -z
    if [[ ! -s dump.shsh ]]; then
        warning "Converting onboard SHSH blobs failed."
        return 1
    fi
    mv dump.shsh $shsh
    log "Successfully saved $device_target_vers blobs: $shsh"
}

############others###########

ipsw_downloader() {
    local version=$1
    if [[ -z $version ]]; then
        log "获取链接"
        input "输入版本号(iOS版本号和构件号均可)"
        read version
    fi
    case $version in
        [0-9]*.[0-9]* ) get_firmware_info ver $version;;
        [1][0-9]*.[0-9]* ) get_firmware_info ver $version;;
        [0-9]*[A-Za-z][0-9]* ) get_firmware_info build $version;;
        * ) 
        warning "未知版本,请重新输入"
        ipsw_downloader
        return
        ;;
    esac
    if [[ -z $url ]]; then
        error "无法获取链接,请检查网络连接"
        exit
    else
        log "URL:$url"
    fi
    log "开始下载"
    local ipsw_name=$(basename $url)
    file_download $url $ipsw_name
    if [[ -f $ipsw_name ]]; then
        cp $ipsw_name ../saved/$device_type/$ipsw_name
        log "iPSW下载完成,保存至../saved/$device_type/$ipsw_name"
        exit 1
    else
        error "iPSW下载失败"
        exit
    fi
}

device_t4os72_step1() {
    local found
    local size
    local data
    local block
    local df
    if [[ $device_mode != "Normal" ]]; then
        checkmode nor
    fi
    log "尝试链接设备SSH"
    device_iproxy
    local try=0
    while [[ $found != 1 ]]; do
        found=$($ssh -p $ssh_port root@127.0.0.1 "echo 1" 2>/dev/null)
        try=$((try + 1))
        if [[ $try == 10 ]]; then
            error "确保设备已越狱并安装OpenSSH"
            return 1
        fi
        sleep 2
    done
    $ssh -p $openssh_port root@127.0.0.1 "mkdir /mnt1"
    $ssh -p $openssh_port root@127.0.0.1 "mkdir /mnt2"
    df=$($ssh -p $ssh_port root@127.0.0.1 "df -B1")
    echo "$df" > block.txt
    block=$(sed -n '/^\/dev\/disk0s1s2/s/.* \([0-9]\{1,\}\) .*/\1/p' ./block.txt)
    data=$(($block/1073741824))
    log "本机空间为${data}GB"
    if (( $data <= 8 )); then
        yesno "8GB版本内存太小,不建议安装,是否继续?"
        if [[ $? != 1 ]]; then
            exit
        fi
    fi
    until [[ -n $size ]] && [ "$size" -eq "$size" ]; do
        read -p "$(input '输入你想给iOS7分配多少GB的存储空间:')" size
    done
    log "将给iOS7分配${size}GB的空间"
    size=$((size*1073741824))
    block1=$(($block-$size))
    if [[ -f ../block_$device_ecid.txt ]]; then
        rm -rf ../block_$device_ecid.txt
    fi
    echo $block1 > ../block_$device_ecid.txt
    pause
    log "上传工具"
    $scp -P $ssh_port $jelbrek/dualbootstuff.tar root@127.0.0.1:/tmp
    log "安装依赖"
    $ssh -p $ssh_port root@127.0.0.1 "tar -xvf /tmp/dualbootstuff.tar -C /; dpkg -i /tmp/dualbootstuff/*.deb"
    sleep 3
    log "开始分区"
    $ssh -p $openssh_port root@127.0.0.1 "hfs_resize /private/var $block1"
    log "分区完成,准备写入分区表"
    sleep 3
    device_t4os72_step2
    sleep 3
    device_t4os72_step3
}

device_t4os72_step2() {
    log "尝试链接设备SSH"
    device_iproxy
    local try=0
    while [[ $found != 1 ]]; do
        found=$($ssh -p $ssh_port root@127.0.0.1 "echo 1" 2>/dev/null)
        try=$((try + 1))
        if [[ $try == 10 ]]; then
            error "确保设备已越狱并安装OpenSSH"
            return 1
        fi
        sleep 2
    done
    log "写入分区表"
    local SSH_CMD="$ssh -p $ssh_port root@127.0.0.1"
    local DEVICE="/dev/rdisk0s1"
    local UDZO_PATH="../saved/$device_type/UDZO.dmg"
    local BLOCK_FILE="../block_${device_ecid}.txt"
    
    if [[ ! -f "$BLOCK_FILE" ]]; then
        error "找不到 block 文件: $BLOCK_FILE"
        return 1
    fi
    
    if [[ ! -f "$UDZO_PATH" ]]; then
        error "找不到 UDZO 文件: $UDZO_PATH"
        return 1
    fi
    
    log "获取磁盘信息..."

    local disk_info
    disk_info=$($SSH_CMD "echo -e 'p\nq' | gptfdisk $DEVICE 2>&1")

    local part1_end=169367

    log "获取分区2信息..."
    local guid_flags_info
    guid_flags_info=$($SSH_CMD "echo -e 'i\n2\nq' | gptfdisk $DEVICE 2>&1")
    
    local guid=$(echo "$guid_flags_info" | grep -i "unique guid" | awk '{print $NF}')
    local flags=$(echo "$guid_flags_info" | grep -i "attribute flags" | awk '{print $NF}')
    debug $guid
    debug $flags

    log "分区信息:"
    log "  GUID: $guid"
    log "  Flags: $flags"

    local diskused
    diskused=$(cat "$BLOCK_FILE")
    
    if [[ -z "$diskused" ]] || ! [[ "$diskused" =~ ^[0-9]+$ ]]; then
        error "block 文件内容无效: $diskused"
        return 1
    fi
    
    log "diskused (hfs_resize计算值): $diskused 字节 ($(echo "scale=2; $diskused/1073741824" | bc)GB)"
    
    local FILE_SIZE
    FILE_SIZE=$(stat -f%z "$UDZO_PATH")
    log "UDZO 文件大小: $FILE_SIZE 字节 ($(echo "scale=2; $FILE_SIZE/1073741824" | bc)GB)"
    local last_sector=3903491
    local default_first_sector_data=$((part1_end + 1))
    local data_end_sector
    data_end_sector=$(echo "scale=0; $diskused / 8192 + $default_first_sector_data" | bc)
    local default_first_sector_system=$((data_end_sector + 1))
    local system_end_sector
    system_end_sector=$(echo "scale=0; $FILE_SIZE / 4096 + $default_first_sector_system" | bc)
    local data2_end_sector=$((last_sector - 5))
    if (( data_end_sector <= default_first_sector_data )); then
        error "Data 分区太小"
        return 1
    fi
    
    if (( system_end_sector <= data_end_sector )); then
        error "iOS7SYSTEM 必须在 Data 分区之后"
        return 1
    fi
    
    if (( data2_end_sector <= system_end_sector )); then
        error "iOS7DATA 必须在 iOS7SYSTEM 之后"
        return 1
    fi
    
    if (( data2_end_sector > last_sector )); then
        error "iOS7DATA 超出磁盘范围"
        return 1
    fi
    
    local data_sectors=$((data_end_sector - default_first_sector_data + 1))
    local system_sectors=$((system_end_sector - default_first_sector_system + 1))
    local data2_sectors=$((data2_end_sector - (system_end_sector + 1) + 1))
    
    local sector_size=8192
    local data_size_bytes=$((data_sectors * sector_size))
    local system_size_bytes=$((system_sectors * sector_size))
    local data2_size_bytes=$((data2_sectors * sector_size))
    
    log "分区大小:"
    log "  Data 分区: $data_sectors 扇区 ($(echo "scale=2; $data_size_bytes/1073741824" | bc)GB)"
    log "  iOS7SYSTEM: $system_sectors 扇区 ($(echo "scale=2; $system_size_bytes/1073741824" | bc)GB)"
    log "  iOS7DATA: $data2_sectors 扇区 ($(echo "scale=2; $data2_size_bytes/1073741824" | bc)GB)"
    
    if (( system_size_bytes < FILE_SIZE )); then
        warning "iOS7SYSTEM 分区大小 ($(echo "scale=2; $system_size_bytes/1073741824" | bc)GB) 小于 UDZO 文件 ($(echo "scale=2; $FILE_SIZE/1073741824" | bc)GB)"
        warning "可能无法正确恢复系统"
    else
        log "✓ iOS7SYSTEM 分区足够大"
    fi
    
    # 构建 gptfdisk 命令
    log "构建分区命令..."
    
    # 创建命令文件
    local cmd_file="gptfdisk_cmds.txt"
    cat > "$cmd_file" << EOF
d
2
n

$data_end_sector

c
2
Data
x
a
2
EOF
    
    if [[ "$flags" == "0003000000000000" ]]; then
        echo "48" >> "$cmd_file"
        echo "49" >> "$cmd_file"
    elif [[ "$flags" == "0001000000000000" ]]; then
        echo "48" >> "$cmd_file"
        echo "" >> "$cmd_file"
    else
        debug 1
    fi
    
    cat >> "$cmd_file" << EOF
c
2
$guid
s
4
m
n
3

$system_end_sector

c
3
iOS7System
n
4

$data2_end_sector

c
4
iOS7Data
p
w
y

EOF
    

    echo "=========================================="
    log "分区规划:"
    log "1. 分区1: 扇区 4-169367 (原有系统分区)"
    log "2. Data 分区: 扇区 $default_first_sector_data-$data_end_sector"
    log "3. iOS7SYSTEM: 扇区 $default_first_sector_system-$system_end_sector"
    log "4. iOS7DATA: 扇区 $((system_end_sector + 1))-$data2_end_sector"
    log ""
    log "使用公式:"
    log "  Data结束 = diskused/8192 + 169368"
    log "  iOS7SYSTEM结束 = UDZO大小/4096 + (Data结束+1)"
    log "  iOS7DATA结束 = 最后扇区 - 5"
    echo "=========================================="
    
    # 显示命令前几行
    log "分区命令 (前20行):"
    cat "$cmd_file"
    
    # 确认执行
    read -p "确认执行分区操作？(y/N): " confirm
    if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
        log "已取消"
        return 1
    fi

    log "执行分区操作..."
    local result
    result=$($SSH_CMD "cat > gpt_cmds.txt && gptfdisk $DEVICE < gpt_cmds.txt" < "$cmd_file")
    
    echo "分区结果:"
    echo "$result"

    log "验证分区表..."
    local final_info
    final_info=$($SSH_CMD "echo -e 'p\nq' | gptfdisk $DEVICE")
    
    echo "最终分区表:"
    echo "$final_info"

    $SSH_CMD "rm -f gpt_cmds.txt"
    
    log "分区操作完成"
    pause
    log "正在重启"
    $ssh -p $ssh_port root@127.0.0.1 "reboot"
    pause 重启后回车
    return
}

device_t4os72_step3() {
    log "尝试链接设备SSH"
    device_iproxy
    local try=0
    while [[ $found != 1 ]]; do
        found=$($ssh -p $ssh_port root@127.0.0.1 "echo 1" 2>/dev/null)
        try=$((try + 1))
        if [[ $try == 10 ]]; then
            error "确保设备已越狱并安装OpenSSH"
            return 1
        fi
        sleep 2
    done
    log "安装系统"
    local uzdo="../saved/$device_type/UDZO.dmg"
    local patches="../resources/patch/touch4-ios7/du"
    local jb="$patches/jb"
    cp ../saved/$device_type/UDZO.dmg UDZO.dmg
    $ssh -p $openssh_port root@127.0.0.1 "/sbin/newfs_hfs -s -v System -J -b 8192 -n a=8192,c=8192,e=8192 /dev/disk0s1s3"
    $ssh -p $openssh_port root@127.0.0.1 "/sbin/newfs_hfs -s -v Data -J -b 8192 -n a=8192,c=8192,e=8192 /dev/disk0s1s4"
    $ssh -p $openssh_port root@127.0.0.1 "mount_hfs /dev/disk0s1s4 /mnt2"
    $scp -v -P $openssh_port UDZO.dmg root@127.0.0.1:/mnt2
    $ssh -p $openssh_port root@127.0.0.1 "echo 'y' | asr restore --source /mnt2/UDZO.dmg --target /dev/disk0s1s3 --erase"
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
    $scp -v -P $openssh_port $patches/fstab root@127.0.0.1:/mnt1/private/etc
    $ssh -p $openssh_port root@127.0.0.1 "rm -rf /mnt1/usr/share/firmware/wifi"
    $scp -v -r -P $openssh_port $patches/wifi root@127.0.0.1:/mnt1/usr/share/firmware
    $scp -v -P $openssh_port $patches/applelogo root@127.0.0.1:/mnt1
    $scp -v -P $openssh_port $patches/devicetree root@127.0.0.1:/mnt1
    $scp -v -P $openssh_port $patches/kernelcache root@127.0.0.1:/mnt1
    $scp -v -P $openssh_port $patches/ramdisk root@127.0.0.1:/mnt1
    $scp -v -P $openssh_port $patches/iBSS root@127.0.0.1:/
    $scp -v -P $openssh_port $patches/iBEC7 root@127.0.0.1:/
    log "工厂激活"
    $ssh -p $openssh_port root@127.0.0.1 "mount_hfs /dev/disk0s1s4 /mnt2"
    $scp -v -r -P $openssh_port $patches/Lockdown root@127.0.0.1:/mnt2/root/Library
    $ssh -p $openssh_port root@127.0.0.1 "rm -rf /mnt2/root/Library/Lockdown/data_ark.plist"
    $scp -v -P $openssh_port $patches/data_ark.plist root@127.0.0.1:/mnt2/root/Library/Lockdown/
    log "越狱"
    $ssh -p $openssh_port root@127.0.0.1 "umount /mnt1"
    $ssh -p $openssh_port root@127.0.0.1 "mount_hfs /dev/disk0s1s3 /mnt1"
    $ssh -p $openssh_port root@127.0.0.1 "mount_hfs /dev/disk0s1s4 /mnt1/private/var"
    $ssh -p $openssh_port root@127.0.0.1 "rm -rf /mnt1/kernelcache"
    $scp -v -P $openssh_port $jb/kernelcache root@127.0.0.1:/mnt1
    $scp -v -P $openssh_port $jb/cydia.tar.lzma root@127.0.0.1:/mnt1
    $scp -v -P $openssh_port $jb/jbloader.tar.lzma root@127.0.0.1:/mnt1
    $ssh -p $openssh_port root@127.0.0.1 "cd /mnt1; tar --lzma -xvf cydia.tar.lzma"
    $ssh -p $openssh_port root@127.0.0.1 "cd /mnt1; tar --lzma -xvf jbloader.tar.lzma"
    log "美化"
    $ssh -p $openssh_port root@127.0.0.1 "umount /mnt1"
    $ssh -p $openssh_port root@127.0.0.1 "mount_hfs /dev/disk0s1s3 /mnt1"
    $scp -v -P $openssh_port ../resources/patches/touch4-ios7/beauty.tar root@127.0.0.1:/mnt1
    $ssh -p $openssh_port root@127.0.0.1 "cd /mnt1; tar -xvf beauty.tar"
    log "Done"
    pause
}

device_ideviceactivation() {
    if [[ $($ideviceactivation state) == *"ActivationState: Activated"* ]]; then
        log "设备已激活"
        3s
    elif [[ $($ideviceactivation state) == *"ActivationState: Unactivated"* ]]; then
        log "设备未激活"
        log 开始激活
        case $os in
            1.* | 2.* | 3.* ) $ideviceactivation itunes ;;
            * ) $ideviceactivation activate ;;
        esac
        sleep 2
        if [[ $($ideviceactivation state) == *"ActivationState: Activated"* ]]; then
            log "设备已激活"
            sleep 3
        elif [[ $($ideviceactivation state) == *"ActivationState: Unactivated"* ]]; then
            log 设备若未激活请重新尝试,或者使用SSHRD选项-激活设备来伪激活设备
            sleep 3
        fi
    fi
}

device_hacktivate_a5() {
    clear
    local device_region=$($pymobiledevice3 lockdown info | grep '"RegionInfo"' | awk -F': ' '{print $2}' | tr -d '",')
    local device_model_number=$($pymobiledevice3 lockdown info | grep '"ModelNumber"' | awk -F': ' '{print $2}' | tr -d '",')
    local patches="../resources/bypass_a5"
    if [[ $device_mode != "Normal" ]]; then
        checkmode nor
        device_info
    fi
    local device_model=$($ideviceinfo -s -k HardwareModel)
    local device_region2=$(echo "$device_region" | cut -d'/' -f1)
    print "*设备信息*"
    print "*当前iOS版本:$device_vers($device_build)*"
    cut_os_vers device $device_vers
    print "*销售型号:${device_region}($device_model_number)($device_region2)*"
    print "*设备颜色:$device_color*"
    if [[ $($ideviceactivation state) == *"ActivationState: Activated"* ]]; then
        print "*是否激活:是*"
        device_have_actived=1
    elif [[ $($ideviceactivation state) == *"ActivationState: Unactivated"* ]]; then
        print "*是否激活:否*"
    fi
    pause
    cp $patches/downloads.28.sqlitedb downloads.28.sqlitedb
    local try=("api.mry0000.top" "api.20090126.xyz")
    local check
    log "检查服务器是否可用"
    #for i in "${try[@]}"; do
    #    ping -c1 $i >/dev/null
    #    check=$?
    #    if [[ $check == 0 ]]; then
    #        local url="${i}/a5/server.php"
    #        break
    #    fi
    #done
    #url="http://api.mry0000.top/a5/server.php"
    #check=1
    #if [[ $check != 0 ]]; then
        yesno "无可用服务器,是否尝试本地部署?"
        if [[ $? == 1 ]]; then
            local local_server=1
            local ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | grep '^192\.168\.')
            local port=5408
            if [[ $ip != 192.168.* ]]; then
                error "似乎不是正常的ip地址?"
                pause
                exit 1
            fi
            local url="http://${ip}:${port}/server.php"
        else
            exit 1
        fi
    #fi
    debug $url
    log "制作数据库文件"
    $sqlite3 downloads.28.sqlitedb "UPDATE asset SET url = REPLACE(url, 'http://a5bypassoss.atwebpages.com/server.php', '$url') WHERE url LIKE '%a5bypassoss.atwebpages.com/server.php%';"
    pause
    if [[ $local_server == 1 ]]; then
        log "制作plist"
        cp $patches/server.php .
        cp $patches/origin.plist .
        mkdir -p plists/$device_type/$device_build
        $PlistBuddy -c "Set :CacheExtra:mumHZHMLEfAuTkkd28fHlQ '$device_color'" origin.plist
        $PlistBuddy -c "Set :CacheExtra:JhEU414EIaDvAz8ki5DSqw '$device_color'" origin.plist
        $PlistBuddy -c "Set :CacheExtra:D0cJ8r7U5zve6uA6QbOiLA '$device_model_number'" origin.plist
        $PlistBuddy -c "Set :CacheExtra:zHeENZu+wbg7PUprwNwBWg '$device_region'" origin.plist
        $PlistBuddy -c "Set :CacheExtra:h63QSdBCiT/z0WU6rdQv6Q '$device_region2'" origin.plist
    fi
    mv origin.plist patched.plist
    mv patched.plist plists/$device_type/$device_build/patched.plist
    pause
    if [[ $local_server == 1 ]]; then
        local patches="../resources/bypass_a5"
        log "检查端口占用"
        PID=$(lsof -t -i :$port)
        if [ -z "$PID" ]; then
            log "✅ ${port}端口未被占用"
        else
            log "⚠️ 发现占用${port}端口的进程(PID): $PID"
            #echo "📌 进程详细信息:"
            #lsof -i :${port} | awk 'NR==1 || /LISTEN/'
            
            log "🛑 正在强制终止进程 $PID ..."
            kill -9 $PID 2>/dev/null
            if [ -z "$(lsof -t -i :${port})" ]; then
                log "✅ ${port}端口已成功释放"
            else
                error "❌ 释放失败"
                exit 1
            fi
        fi
        log "启动本地服务器"
        nohup php -S 0.0.0.0:$port -t "./" > /dev/null 2>&1 &
        php_pid=$!
        echo $php_pid > "php_server.pid"
        log "等待服务器启动"
        while true; do
            local message=$(curl -s "$url" && echo "")
            if [[ $message == "Forbidden" ]]; then
                break
            fi
            sleep 1
        done
        log "done"
    fi
    log "上传数据库文件到设备"
    $afc upload downloads.28.sqlitedb /Downloads
    log "重启设备"
    device_power reboot
    sleep 20
    checkmode nor
    pause
}

############menus#############

display_message() {
    case $1 in
        main_menu )
            print hello
            ;;
        ipsw_menu )
            if [[ $device_target_t3os6 == 1 ]]; then
                print "*目标固件选择iOS6.0的固件,其他版本无法制作*"
            elif [[ $device_target_t4os7 == 1 || $device_target_t4os72 == 1 ]]; then
                print "*目标固件选择iPhone3,3的iOS7.1.2固件*"
            elif [[ $device_target_powder == 1 ]]; then
                if [[ $device_type == "iPod5,1" ]]; then
                    print "*选择iOS7.1.X的SHSH和固件*"
                fi
            fi
            if [[ -n $ipsw_path && -n $device_target_build && -n $device_target_vers ]]; then
                if [[ $device_target_vers == 3.* ]]; then
                    local i="iPhone"
                else
                    local i="i"
                fi
                print "*目标固件:$ipsw_path.ipsw(${i}OS${device_target_vers}($device_target_build))*"
            else
                if [[ -n $ipsw_justboot_path ]]; then
                    print "*目标固件:$ipsw_justboot_path.ipsw(${i}OS${device_target_vers}($device_target_build))*"
                fi
            fi
            if [[ -n $ipsw_base_path && -n $device_base_build && -n $device_base_vers ]]; then
                print "*基础固件:$ipsw_base_path.ipsw(iOS${device_base_vers}($device_base_build))*"
            fi
            if [[ -n $shsh_path ]]; then
                if [[ -n "$shsh_generator" ]] && [[ $shsh_generator =~ ^0x[0-9a-fA-F]{16}$ ]]; then
                    print "*SHSH:$(basename $shsh_path)(G值:$shsh_generator)*"
                else
                    print "*SHSH:$(basename $shsh_path)*"
                fi
            fi
            ;;
        ramdisk_menu )
            local ramdisk_ver
            local ramdisk_build
            case $device_type in
                iPod1,1 ) ramdisk_build="7E18"; ramdisk_ver="3.1.3";;
                iPod2,1 ) ramdisk_build="8C148"; ramdisk_ver="4.2.1";;
                iPod3,1 ) ramdisk_build="9B206"; ramdisk_ver="5.1.1";;
                iPod4,1 ) ramdisk_build="10B500"; ramdisk_ver="6.1.6";;
                iPod5,1 ) ramdisk_build="10B329"; ramdisk_ver="6.1.3";;
                iPod7,1 ) ramdisk_ver="12.0"; ramdisk_build="16A366";;
                iPod9,1 ) ramdisk_ver="12.4"; ramdisk_build="16G77";;
            esac
            print "*默认Ramdisk版本:$ramdisk_ver($ramdisk_build)*"
            if [[ -n $device_rd_build_custom ]]; then
                print "*自定义Ramdisk版本:$device_rd_ver($device_rd_build)*"
            fi
            ;;
    esac
}

file_download() {
    # usage: file_download {link} {target location} {sha1}
    local filename="$(basename $2)"
    log "Downloading $filename..."
    $aria2c "$1" -o $2
    [[ $? != 0 ]] && $curl -L "$1" -o $2
    if [[ ! -s $2 ]]; then
        error "Downloading $2 failed. Please run the script again"
    fi
    if [[ -z $3 ]]; then
        return
    fi
    local sha1=$($sha1sum $2 | awk '{print $1}')
    if [[ $sha1 != "$3" ]]; then
        error "Verifying $filename failed. The downloaded file may be corrupted or incomplete. Please run the script again" \
        "* SHA1sum mismatch. Expected $3, got $sha1"
    fi
}

main() {
    clear
    print  "*** iPwnTouch Tools ***"
    print  "- Script by MrY0000 -"
    print  "- Thanks XiaoWZ Setup.app -"
    print  "- $platform_message -"
    if [[ $device_no_message == 1 || $device_no_check == 1 ]]; then
        print "当前设备:$device_type"
        display_message ${FUNCNAME[1]}
        return
    fi
    print "*当前模式:$mode_cn*"
    print "*当前设备:$device_type*"
    if [[ -n $device_ecid ]]; then
        print "*ECID:$device_ecid*"
    fi
    if [[ -n $device_cpid ]]; then
        print "*CPID:$device_cpid*"
    fi
    case $device_mode in
        DFU )
        if [[ $device_have_pwnd == 1 ]]; then
            if [[ -n $device_pwnd ]]; then
                print "*是否破解DFU:是($device_pwnd)*"
            else
                print "*是否破解DFU:是*"
            fi
        else
            print "*是否破解DFU:否*"
        fi
        ;;
        Normal )
        if [[ -n $device_vers && "$device_vers" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            print "*当前iOS版本:$device_vers($device_build)*"
            cut_os_vers device $device_vers
        fi
        if [[ -n $device_region ]]; then
            print "*销售型号:${device_region}($device_model_number)*"
        fi
        if [[ -n $device_color ]]; then
            print "*设备颜色:$device_color*"
        fi
        if [[ $device_type != "iPod1,1" ]]; then
            if [[ $($ideviceactivation state) == *"ActivationState: Activated"* ]]; then
                print "*是否激活:是*"
                device_have_actived=1
            elif [[ $($ideviceactivation state) == *"ActivationState: Unactivated"* ]]; then
                print "*是否激活:否*"
            fi
        fi
        ;;
        Recovery )
        if [[ -n $device_iboot_vers ]]; then
            print "*iBoot版本:$device_iboot_vers*"
        fi
        ;;
    esac
    if [[ -n $device_newbr ]]; then
        case $device_newbr in
            0 ) print "*是否为旧Bootrom:是*";;
            1 ) print "*是否为旧Bootrom:否*";;
            2 ) print "*是否为旧Bootrom:无法获取*";;
        esac
    fi
    display_message ${FUNCNAME[1]}
    device_entered_menu=1
}

main_menu() {
    local options=()
    local selected
    main
    options+=("恢复/降级" "越狱" "提取SHSH")
    case $device_mode in
        "Normal" )
        if [[ $device_have_actived != 1 ]]; then
            options+=("激活设备(ideviceactivation)")
            if (( $device_major_ver > 4 )); then
                options+=("激活设备(伪激活)")
            fi
        fi
        ;;
    esac
    if [[ $device_mode == "Recovery" || $device_mode == "DFU" ]] && [[ $device_type != "iPod7,1" ]]; then
        options+=("引导启动")
    fi
    options+=("SSH Ramdisk")
    if [[ $script_test == 1 ]]; then
        options+=("TEST")
    fi
    options+=("其他选项")
    options+=("退出")
    select_option "${options[@]}"
    selected="${options[$?]}"
    case $selected in
        "恢复/降级" ) restore_menu;;
        "越狱" ) Jailbreak_choice;;
        "更新" ) update;;
        "提取SHSH" ) device_shsh_save ;;
        "引导启动" ) justboot_menu;;
        "SSH Ramdisk") ramdisk_menu;;
        "TEST") TEST_FUN;;
        "其他选项" ) others_menu;;
        "激活设备(ideviceactivation)" ) device_ideviceactivation ;;
        "退出" ) exit;;
    esac
}

restore_menu() {
    local options=()
    local selected
    local options1=()
    local selected1
    local arg=""
    device_target_shsh=""
    device_target_other=""
    device_target_tethered=""
    device_target_powder=""
    device_target_os3=""
    device_target_t3os6=""
    device_target_t4os7=""
    device_target_t4os72=""
    device_target_latest=""
    main
    if [[ $1 != make ]]; then
        if [[ $device_type != "iPod7,1" ]]; then
            if [[ $device_proc != 1 ]]; then
                options+=("降级(SHSH)")
                options+=("降级(无SHSH)")
            else
                options+=("iOS3.0+")
            fi
        fi
        if [[ $device_64bit == 1 ]]; then
            options+=("降级(Futurerestore)")
        fi
        if [[ $device_canpowder == 1 ]]; then
            options+=("降级(powdersn0w)")
        fi
        if [[ $de == 3 ]]; then
            options+=("6.0/6.1.3/6.1.6")
        elif [[ $de == 4 ]]; then
            options+=("7.1.2")
            options+=("7.1.2双系统")
        fi
        if [[ $device_type == "iPod2,1" || $device_type == "iPod3,1" ]]; then
            options+=("4.1")
        elif [[ $device_type == "iPod5,1" ]]; then
            options+=("8.4.1")
        fi
    else
        arg+="make"
        if [[ $device_type != "iPod7,1" ]]; then
            if [[ $device_proc == 1 ]]; then
                options+=("3.0+")
            elif [[ $device_type == "iPod2,1" || $device_type == "iPod3,1" ]]; then
                options+=("4.1")
            elif [[ $device_type == "iPod5,1" ]]; then
                options+=("8.4.1")
            else
                options+=("制作降级固件(SHSH)")
                options+=("制作降级固件(无SHSH)")
            fi
        fi
        if [[ $device_canpowder == 1 ]]; then
            options+=("制作降级固件(powdersn0w)")
        fi
        if [[ $de == 3 ]]; then
            options+=("制作固件(iOS6.0)")
        elif [[ $de == 4 ]]; then
            options+=("制作固件(iOS7.1.2)")
        fi
    fi
    options+=("$device_latest_vers")
    options+=("iPSW下载")
    options+=("返回主页")
    select_option "${options[@]}"
    selected="${options[$?]}"
    case $selected in
        "降级(SHSH)" | "制作降级固件(SHSH)" ) 
            device_target_other=1
            device_target_shsh=1
            if [[ $device_type == "iPod9,1" ]]; then
                device_use_tm=1
            fi
            ;;
        "降级(无SHSH)" | "制作降级固件(无SHSH)" ) 
            device_target_tethered=1
            if [[ $device_type == "iPod9,1" ]]; then
                device_use_tm=1
            fi
            ;;
        "降级(powdersn0w)" ) 
            device_target_powder=1
            if [[ $device_type == "iPod5,1" ]]; then
                device_target_shsh=1
            fi
            ;;
        "降级(Futurerestore)" ) 
            device_use_futurerestore=1
            device_target_shsh=1
            ;;
        "3.0+" ) device_target_os3=1;;
        "6.0/6.1.3/6.1.6" ) device_target_t3os6=1;;
        "7.1.2" ) device_target_t4os7=1;;
        "7.1.2双系统" )
            main
            device_target_t4os72=1
            options1+=("制作固件")
            if [[ -f $saved/$device_type/UDZO.dmg ]]; then
                options1+=("开始安装") 
            fi
            select_option "${options1[@]}"
            selected1="${options1[$?]}"
            case $selected1 in
               "制作固件" ) : ;;
               "开始安装" ) 
                if [[ $device_vers != "6.1.6" ]]; then
                    warning "此版本iOS无法安装iOS7双系统,请升级到iOS6.1.6后再试"
                    return
                fi
               device_t4os72_step1
               return
               ;;
            esac
            ;;
        "8.4.1" ) arg+="target_ver=8.4.1" ;;
        "4.1" ) arg+="target_ver=4.1";;
        "$device_latest_vers" ) device_target_latest=1 ;;
        "iPSW下载") ipsw_downloader;;
        "返回主页" ) main_menu;;
    esac
    debug $arg
    ipsw_menu $arg
    ipsw_set $1
    if [[ $device_target_t4os72 == 1 ]]; then
        ipsw_prepare_ios7touch4_2
        return
    fi
    if [[ $1 != "make" ]]; then
        if [[ $device_mode == "DFU" || $device_mode == "WTF" ]]; then
            :
        else
            dfu_helper ?
        fi
        if [[ $device_use_futurerestore == 1 ]] || [[ $device_target_vers == "$device_latest_vers" && $ipsw_canjailbreak == 1 ]] || [[ $ipsw_canjailbreak == 1 ]]; then
            device_pwn
        fi
    fi
    ipsw_custom_set
    ipsw_prepare
    if [[ $1 != "make" ]]; then
        restore_set
    fi
    pause
}

restore_set() {
    if [[ $device_use_futurerestore == 1 ]]; then
        restore_futurerestore
    elif [[ $device_use_tm == 1 ]]; then
        restore_turdus_merula
    else
        mkdir shsh 2>/dev/null
        if [[ $device_target_tethered == 1 ]] || [[ $device_type == "iPod3,1" && $device_target_powder == 1 ]] || [[ $device_target_t4os7 == 1 ]] || [[ $device_target_vers == $device_latest_vers ]]; then
            if [[ ! -f ../saved/shsh/$device_ecid-$device_type-$device_latest_vers.shsh ]]; then
                shsh_save
            elif [[ $device_type == "iPod2,1" || $device_type == "iPod3,1" ]] && [[ $device_target_vers == "4.1" ]]; then
                shsh_save 4.1
            fi
            if [[ $device_target_t4os7 == 1 ]]; then
                cp ../saved/shsh/$device_ecid-$device_type-$device_latest_vers.shsh shsh/$device_ecid-$device_type-6.1.6.shsh
            elif [[ $device_type == "iPod2,1" || $device_type == "iPod3,1" ]] && [[ $device_target_vers == "4.1" ]]; then
                cp ../saved/shsh/$device_ecid-$device_type-4.1.shsh shsh/$device_ecid-$device_type-4.1.shsh
            else
                cp ../saved/shsh/$device_ecid-$device_type-$device_latest_vers.shsh shsh/$device_ecid-$device_type-$device_target_vers.shsh
            fi
        else
            shsh_name=$(basename "$shsh_path")
            cp $shsh_path .
            mv $shsh_name shsh/"$device_ecid-$device_type-$device_target_vers.shsh"
        fi
        if [[ $ipsw_jailbreak != 1 ]] && [[ $device_target_vers == $device_latest_vers ]]; then
            restore_latest
        else
            restore_idevicerestore
        fi
    fi
}

ipsw_menu() {
    local options=()
    local selected
    local ver
    local arg
    clear
    main
    for arg in $@; do
        case $arg in
            text=* )
            local text="${arg#text=}"
            ;;
            shsh )
            local use_shsh=1
            ;;
            base )
            local use_base=1
            ;;
            ramdisk )
            local use_ramdisk=1
            ;;
            justboot )
            local use_jsb=1
            ;;
        esac
    done

    for arg1 in $@; do
        case $arg1 in
            target_ver=* )
            if [[ $use_shsh == 1 ]]; then
                local target_ver="${arg#target_ver=}"
            elif [[ $use_base == 1 ]]; then
                local target_ver_base="${arg#target_ver=}"
            fi
            ;;
            target_build=* )
            if [[ $use_shsh == 1 ]]; then
                local target_build="${arg#target_build=}"
            elif [[ $use_base == 1 ]]; then
                local target_build_base="${arg#target_build=}"
            fi
            ;;
        esac
    done
    for ism in $@; do
        if [[ $ism == make ]]; then 
            local text="开始制作"
        fi
    done
    if [[ -z $text ]]; then
        if [[ $use_jsb == 1 ]]; then
            print "*选择需要引导的版本的固件*"
            local text="开始引导启动"
        elif [[ $use_ramdisk == 1 ]]; then
            local text="开始制作Ramdisk"
        elif [[ $device_save_shsh == 1 ]]; then
            local text="开始提取SHSH"
        elif [[ $device_save_raw == 1 ]]; then
            local text="开始提取Raw"
        else
            local text="开始恢复"
        fi
    fi

    options+=("选择固件(目标固件)")
    if [[ $device_target_shsh == 1 ]] || [[ $use_shsh == 1 ]]; then
        options+=("选择SHSH")
    fi
    if [[ $device_target_powder == 1 ]]; then
        case $de in
            3 ) ver="5.1.1";;
            5 ) ver="7.1.X"
        esac
        options+=("选择固件(iOS$ver)")
    fi
    if [[ $use_base == 1 ]]; then
        options+=("选择基础固件")
    fi
    if [[ $device_target_t3os6 == 1 ]]; then
        options+=("选择固件(iOS5.1.1)")
        device_type_special="iPhone2,1"
        device_model_special="n88"
    fi
    if [[ $device_target_t4os7 == 1 ]]; then
        options+=("选择固件(iOS6.1.6)")
        device_type_special="iPhone3,3"
        device_model_special="n92"
    fi
    if [[ $device_target_shsh == 1 ]]; then
        if [[ $device_target_powder == 1 ]]; then
            if [[ -n $ipsw_path && -n $ipsw_base_path && -n $shsh_path ]]; then
                options+=("$text")
            fi
        else
            if [[ -n $ipsw_path && -n $shsh_path ]]; then
                options+=("$text")
            fi
        fi
    else
        if [[ $device_target_powder == 1 ]] || [[ $device_target_t3os6 == 1 || $device_target_t4os7 == 1 ]]; then
            if [[ -n $ipsw_path && -n $ipsw_base_path ]]; then
                options+=("$text")
            fi
        else
            if [[ -n $ipsw_path ]]; then
                options+=("$text")
            fi
        fi
        #if [[ $1 == "justboot" ]]; then
            if [[ -n $ipsw_justboot_path ]]; then
                options+=("$text")
            fi
        #fi
    fi
    if [[ -n $device_target_vers ]]; then
        case $device_target_vers in
            [456]* ) ipsw_cancustomlogo2=1;;
            * ) ipsw_cancustomlogo2=0
        esac
    fi
    if [[ $device_type == "iPod2,1" && $device_newbr == 0 && $device_target_vers == "3.1.3" ]]; then
        ipsw_cancustomlogo=1
        if [[ $ipsw_jailbreak == 1 ]]; then
            ipsw_24o=1
        fi
    fi
    select_option "${options[@]}"
    selected="${options[$?]}"
    case $selected in
        "选择固件(目标固件)") 
            if [[ $1 == "justboot" ]]; then
                ipsw_justboot_path1="$($zenity --file-selection --multiple --file-filter='IPSW | *.ipsw' --title="Select IPSW file(s)")"
                get_ipsw_info target $ipsw_justboot_path1
            else
                ipsw_path1="$($zenity --file-selection --multiple --file-filter='IPSW | *.ipsw' --title="Select IPSW file(s)")"
                get_ipsw_info target $ipsw_path1
            fi
            if [[ $ipsw_select_wrong == 1 ]]; then
                error 固件选择错误,请选择正确的固件
                sleep 3
                ipsw_path=""
            else
                if [[ $use_jsb != 1 ]]; then
                    if [[ -n $target_ver ]]; then
                        if [[ $versionid != $target_ver ]]; then
                            error 固件版本选择错误,请选择正确的固件
                            sleep 3
                            ipsw_path=""
                        else
                            cp $ipsw_path1 .
                            ipsw_path2="${ipsw_path1%.ipsw}"
                            ipsw_path=$(basename $ipsw_path2)
                        fi
                    elif [[ -n $target_build ]]; then
                        if [[ $buildid != $target_build ]]; then
                            error 固件版本选择错误,请选择正确的固件
                            sleep 3
                            ipsw_path=""
                        else
                            cp $ipsw_path1 .
                            ipsw_path2="${ipsw_path1%.ipsw}"
                            ipsw_path=$(basename $ipsw_path2)
                        fi
                    else
                        cp $ipsw_path1 .
                        ipsw_path2="${ipsw_path1%.ipsw}"
                        ipsw_path=$(basename $ipsw_path2)
                    fi
                else
                    if [[ -n $target_ver ]]; then
                        if [[ $versionid != $target_ver ]]; then
                            error 固件版本选择错误,请选择正确的固件
                            sleep 3
                            ipsw_justboot_path=""
                        else
                            cp $ipsw_justboot_path1 .
                            ipsw_justboot_path2="${ipsw_justboot_path1%.ipsw}"
                            ipsw_justboot_path=$(basename $ipsw_justboot_path2)
                        fi
                    elif [[ -n $target_build ]]; then
                        if [[ $buildid != $target_build ]]; then
                            error 固件版本选择错误,请选择正确的固件
                            sleep 3
                            ipsw_justboot_path=""
                        else
                            cp $ipsw_justboot_path1 .
                            ipsw_justboot_path2="${ipsw_justboot_path1%.ipsw}"
                            ipsw_justboot_path=$(basename $ipsw_justboot_path2)
                        fi
                    else
                        cp $ipsw_justboot_path1 .
                        ipsw_justboot_path2="${ipsw_justboot_path1%.ipsw}"
                        ipsw_justboot_path=$(basename $ipsw_justboot_path2)
                    fi

                fi
            fi
            ;;
        "选择SHSH") 
            shsh_path="$($zenity --file-selection --multiple --file-filter='SHSH | *.bshsh2 *.shsh *.shsh2' --title="Select SHSH file(s)")"
            if [[ $device_64bit == 1 ]]; then
                log "获取G值"
                if [[ $platform == "macos" ]]; then
                    shsh_generator=$(plutil -extract generator raw -o - "$shsh_path")
                else
                    shsh_generator=$(cat $shsh_path | grep -A 1 "generator")
                fi
                if [[ $shsh_generator =~ ^0x[0-9a-fA-F]{16}$ ]]; then
                    :
                else
                    warning "此SHSH疑似损坏或者无G值,可能无法降级,回车跳过检测"
                    pause
                fi
            fi
            ;;
        "选择固件(iOS$ver)" | "选择固件(iOS5.1.1)" | "选择固件(iOS6.1.6)" | "选择基础固件" ) 
            ipsw_base_path1="$($zenity --file-selection --multiple --file-filter='IPSW | *.ipsw' --title="Select IPSW file(s)")"
            get_ipsw_info base $ipsw_base_path1
            if [[ $ipsw_select_wrong == 1 ]]; then
                error 固件选择错误,请选择正确的固件
                sleep 3
                ipsw_base_path=""
            else
                if [[ -n $target_ver_base ]]; then
                    if [[ $versionid != $target_ver_base ]]; then
                        error 固件版本选择错误,请选择正确的固件
                        sleep 3
                        ipsw_base_path=""
                    else
                        cp $ipsw_base_path1 .
                        ipsw_base_path2="${ipsw_base_path1%.ipsw}"
                        ipsw_base_path=$(basename $ipsw_path2)
                    fi
                elif [[ -n $target_build_base ]]; then
                    if [[ $buildid != $target_build_base ]]; then
                        warning 固件版本选择错误,请选择正确的固件
                        sleep 3
                        ipsw_base_path=""
                    else
                        cp $ipsw_base_path1 .
                        ipsw_base_path2="${ipsw_base_path1%.ipsw}"
                        ipsw_base_path=$(basename $ipsw_base_path2)
                    fi
                else
                    cp $ipsw_base_path1 .
                    ipsw_base_path2="${ipsw_base_path1%.ipsw}"
                    ipsw_base_path=$(basename $ipsw_base_path2)
                fi
                cp $ipsw_base_path1 .
                ipsw_base_path2="${ipsw_base_path1%.ipsw}"
                ipsw_base_path=$(basename $ipsw_base_path2)
            fi
            ;;
        "$text" ) return;;
    esac
    ipsw_menu
}

ipsw_set() {
    if (( device_proc >= 7 )) || [[ $device_target_vers == "$device_latest_vers" && $ipsw_canjailbreak != 1 && $ipsw_gasgauge_patch != 1 ]]; then
        return
    fi
    yesno 是否越狱? 1
    if [[ $? == 1 ]]; then
        ipsw_jailbreak=1
    fi
}

others_menu() {
    local options=()
    local selected
    main
    options+=("DFU helper")
    options+=("进入破解DFU")
    if [[ $device_64bit != 1 ]] && [[ $device_proc != 1 ]]; then
        options+=("制作自制固件")
    fi
    options+=("返回主页")
    select_option "${options[@]}"
    selected="${options[$?]}"
        case $selected in
            "DFU helper" )
            use_dfuhelper=1
            dfuhelper
            log "现在设备应处于DFU模式"
            return
            ;;
            "进入破解DFU" )
            dfu_helper ?
            device_pwn
            log "现在设备应处于破解DFU模式"
            return
            ;;
            "制作自制固件" )
            restore_menu make
            ;;
            "返回主页" )
            main_menu
            ;;
        esac

}

justboot_menu() {
    main
    local options=()
    local selected
    if [[ $device_type != "DFU" ]]; then
        dfu_helper ?
        if [[ $device_type != "iPod9,1" ]]; then
            device_pwn
        fi
    fi
    if [[ $device_type != "iPod4,1" ]]; then
        if [[ $device_type != "iPod9,1" && $device_type != "iPod7,1" ]]; then
            just_useipsw=1
            device_target_justboot=1
            device_justboot
            return
        else
            device_justboot_tm
            return
        fi
    else
        options+=("引导启动")
        options+=("引导启动(iOS7)")
    fi
    select_option "${options[@]}"
    selected="${options[$?]}"
        case $selected in
            "引导启动" ) ramdisk_menu justboot; return;;
            "引导启动(iOS7)" ) device_justboot_ios7touch4; return;;
        esac
}

ramdisk_menu() {
    local options=()
    local selected
    local ver
    dfu_helper ?
    if [[ $1 == "make" ]]; then
        device_argmode="none"
    fi
    main
    if [[ $1 == "justboot" ]]; then
        if [[ $device_type == "iPod9,1" ]]; then
            device_justboot_tm
            return
        else
            device_target_justboot=1
            local text="引导启动"
            local text1="引导启动"
        fi
    else
        local text="制作Ramdisk"
        local text1="Ramdisk"
    fi
    options+=("使用在线下载$text")
    if [[ $device_64bit != 1 ]]; then
        options+=("使用本地固件$text")
    fi
    options+=("自定义${text1}版本")
    select_option "${options[@]}"
    selected="${options[$?]}"
        case $selected in
            "使用在线下载$text" ) 
                if [[ $device_64bit == 1 ]]; then
                    if [[ -n $$device_rd_ver ]]; then
                        ramdisk_64 $device_rd_ver
                    else
                        ramdisk_64
                    fi
                else
                    if [[ $1 == "justboot" ]]; then
                        if [[ -z $device_rd_build ]]; then
                            warning "未定义引导启动版本,请先定义启动版本"
                            sleep 3
                            ramdisk_menu $@
                            return
                        fi
                        ramdisk $1 
                    else
                        ramdisk
                    fi
                fi
                return
            ;;
            "使用本地固件$text" )
                just_useipsw=1
                ramdisk $1
                return
            ;;
            "自定义${text1}版本" )
            input "输入自定义版本"
            read device_rd_build_custom
            log "检查此版本是否可用"
            if [[ "$device_rd_build_custom" =~ ^[0-9]+[A-Za-z][0-9]+[a-z]?$ ]]; then
                get_firmware_info build $device_rd_build_custom
                if [[ -z "$url" ]]; then
                    warning "此版本号无效,请重新输入"
                    device_rd_build_custom=""
                    sleep 3
                else
                    device_rd_build=$device_rd_build_custom
                    device_rd_ver=$versionid
                fi
            else
                get_firmware_info ver $device_rd_build_custom
                if [[ -z "$url" ]]; then
                    warning "此版本号无效,请重新输入"
                    device_rd_build_custom=""
                    sleep 3
                else
                    device_rd_build=$buildid
                    device_rd_ver=$device_rd_build_custom
                fi
            fi
            ;;
        esac
    ramdisk_menu $@
}

ssh_menu() {
    local options=()
    local selected
    if [[ "$ship_boot" == "1" ]]; then
        device_iproxy
        ship_boot=
    fi
    device_no_message=1
    clear
    main
    options+=("SSH Connection")
    #if [[ -n $device_type ]]; then
        #if [[ $device_64bit != 1 ]]; then
            options+=("Jailbreak")
            options+=("Check iOS Version")
            options+=("Bypass(iOS5-iOS10)")
            options+=("Brute-force password cracking(iOS7 below)")
            options+=("Fix Disable")
            options+=("Clear NVRAM")
       #else
            options+=("Dump SHSH")
       #fi
    options+=("Reboot")
    options+=("Exit")
    select_option "${options[@]}"
    selected="${options[$?]}"
        case $selected in
            "SSH Connection")
                ssh_message ; $ssh -p $ssh_port root@127.0.0.1;;
            "Activate Device")
                activition; pause;;
            "Jailbreak")
                jailbreak_sshrd;;
            "Backup Activation Files")
                activition_backup; pause;;
            "Check iOS Version")
                check_iosvers ;;
            "Brute-force password cracking(iOS7 below)")
                device_bruteforce; pause;;
            "Fix Disable")
                device_unblock_lock
                ;;
            "Bypass(iOS5-iOS10)")
                device_hacktivate;;
            "Clear NVRAM")
                log Clear NVRAM
                $ssh -p $ssh_port root@127.0.0.1 "nvram -c" ; pause;;
            "Dump SHSH" ) device_shsh_dump_64; pause;;
            "Reboot")
                log Rebooting
                $ssh -p $ssh_port root@127.0.0.1 "reboot_bak;/sbin/reboot"
                exit=1
                ;;
            "Exit" )
                exit=1
                ;;
        esac
    if [[ "$exit" != "1" ]]; then
        ssh_menu
    fi
}


function select_option() {
    input "选择选项:"
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


clean() {
    kill $httpserver_pid $iproxy_pid $anisette_pid $sshfs_pid 2>/dev/null
    popd &>/dev/null
    rm -rf "$(dirname "$0")/tmp$$/"* "$(dirname "$0")/iP"*/ "$(dirname "$0")/tmp$$/" 2>/dev/null
    rm -rf $(dirname "$0")/tmp*
    if [[ $platform == "macos" && $(ls "$(dirname "$0")" | grep -v tmp$$ | grep -c tmp) == 0 &&
          $no_finder != 1 ]]; then
        killall -CONT AMPDevicesAgent AMPDeviceDiscoveryAgent MobileDeviceUpdater
    fi
}

TEST_FUN() {
    device_hacktivate_a5
}

trap clean EXIT
trap "exit" INT TERM
mkdir "$(dirname "$0")/tmp$$"
pushd "$(dirname "$0")/tmp$$" >/dev/null
mkdir ../saved 2>/dev/null
oscheck
set_ssh_config
set_path
for i in $@; do
    case $i in
        --d | --debug ) debug_mode=1;;
        --device=* ) device_type="${i#--device=}" ; device_no_check=1 ;;
        --nc | --no_check ) device_no_check=1 ;;
        --ssh-menu ) 
        device_iproxy
        ssh_menu
        exit
            ;;
        test ) script_test=1;;
        --device=* )
           device_type="${i#--device=}"
        ;;
        * )
            warning 未知后缀
            exit
            ;;
    esac
done
if [[ "$debug_mode" == "1" ]]; then
    menu_old=1
    set -x
fi
if [[ $device_no_check != 1 ]]; then
    device_info
else
    device_info2
fi
main_menu
print "*iPwnTouch Tools*"
print "*$platform_message*"
print "*如果遇到问题请前往https://github.com/appleiPodTouch4/iPwnTouch/issues提交issue*"
popd >/dev/null