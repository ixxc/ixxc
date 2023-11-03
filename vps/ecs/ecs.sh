#!/usr/bin/env bash
# by spiritlhl
# from https://github.com/spiritLHLS/ecs，对融合怪脚本进行精简，仅保留硬件和系统信息查看代码

# =============== 默认输入设置 ===============
_red() { echo -e "\033[31m\033[01m$@\033[0m"; }
_green() { echo -e "\033[32m\033[01m$@\033[0m"; }
_yellow() { echo -e "\033[33m\033[01m$@\033[0m"; }
_blue() { echo -e "\033[36m\033[01m$@\033[0m"; }
en_status=false

# =============== 基础信息设置 ===============
REGEX=("debian|astra" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "fedora" "arch" "freebsd" "alpine" "openbsd" "opencloudos")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Fedora" "Arch" "FreeBSD" "Alpine" "OpenBSD" "OpenCloudOS")

_exists() {
    # 查询对应变量或组件是否存在
    local cmd="$1"
    if eval type type >/dev/null 2>&1; then
        eval type "$cmd" >/dev/null 2>&1
    elif command >/dev/null 2>&1; then
        command -v "$cmd" >/dev/null 2>&1
    else
        which "$cmd" >/dev/null 2>&1
    fi
    local rt=$?
    return ${rt}
}

sysctl_path=$(which sysctl)

# =============== 基础系统信息 部分 ===============
systemInfo_get_os_release() {
    local regex_size=${#REGEX[@]}
    for ((i = 0; i < regex_size; i++)); do
        local pattern="${REGEX[i]}"
        if [ -f "/etc/debian_version" ] && [[ "$pattern" == "debian|astra" ]]; then
            Var_OSRelease="debian"
            break
        elif [ -f "/etc/lsb-release" ] && [[ "$pattern" == "ubuntu" ]]; then
            Var_OSRelease="ubuntu"
            break
        elif [ -f "/etc/redhat-release" ] && [[ "$pattern" == "centos|red hat|kernel|oracle linux|alma|rocky" ]]; then
            Var_OSRelease="centos"
            break
        elif [ -f "/etc/amazon-linux-release" ] && [[ "$pattern" == "'amazon linux'" ]]; then
            Var_OSRelease="centos"
            break
        elif [ -f "/etc/fedora-release" ] && [[ "$pattern" == "fedora" ]]; then
            Var_OSRelease="fedora"
            break
        elif [ -f "/etc/arch-release" ] && [[ "$pattern" == "arch" ]]; then
            Var_OSRelease="arch"
            break
        elif [ -f "/etc/freebsd-update.conf" ] && [[ "$pattern" == "freebsd" ]]; then
            Var_OSRelease="freebsd"
            break
        elif [ -f "/etc/alpine-release" ] && [[ "$pattern" == "alpine" ]]; then
            Var_OSRelease="alpinelinux"
            break
        elif [ -f "/etc/openbsd.conf" ] && [[ "$pattern" == "openbsd" ]]; then
            Var_OSRelease="openbsd"
            break
        elif [ -f "/etc/opencloudos-release" ] && [[ "$pattern" == "opencloudos" ]]; then
            Var_OSRelease="opencloudos"
            break
        fi
    done
    if [ -z "$Var_OSRelease" ]; then
        Var_OSRelease="unknown"
    fi
    if [ -f /etc/os-release ]; then
        DISTRO=$(grep 'PRETTY_NAME' /etc/os-release | cut -d '"' -f 2)
    fi
}

get_system_bit() {
    local sysarch="$(uname -m)"
    if [ "${sysarch}" = "unknown" ] || [ "${sysarch}" = "" ]; then
        local sysarch="$(arch)"
    fi
    # 根据架构信息设置系统位数并下载文件,其余 * 包括了 x86_64
    case "${sysarch}" in
    "i386" | "i686")
        LBench_Result_SystemBit_Short="32"
        LBench_Result_SystemBit_Full="i386"
        GOSTUN_FILE=gostun-linux-386
        # BESTTRACE_FILE=besttracemac
        CommonMediaTests_FILE=CommonMediaTests-linux-386
        SecurityCheck_FILE=securityCheck-linux-386
        PortChecker_FILE=portchecker-linux-386
        BACKTRACE_FILE=backtrace-linux-386
        NEXTTRACE_FILE=nexttrace_darwin_amd64
        ;;
    "armv7l" | "armv8" | "armv8l" | "aarch64" | "arm64")
        LBench_Result_SystemBit_Short="arm"
        LBench_Result_SystemBit_Full="arm"
        GOSTUN_FILE=gostun-linux-arm64
        # BESTTRACE_FILE=besttracearm
        CommonMediaTests_FILE=CommonMediaTests-linux-arm64
        SecurityCheck_FILE=securityCheck-linux-arm64
        PortChecker_FILE=portchecker-linux-arm64
        BACKTRACE_FILE=backtrace-linux-arm64
        NEXTTRACE_FILE=nexttrace_linux_arm64
        ;;
    *)
        LBench_Result_SystemBit_Short="64"
        LBench_Result_SystemBit_Full="amd64"
        GOSTUN_FILE=gostun-linux-amd64
        # BESTTRACE_FILE=besttrace
        CommonMediaTests_FILE=CommonMediaTests-linux-amd64
        SecurityCheck_FILE=securityCheck-linux-amd64
        PortChecker_FILE=portchecker-linux-amd64
        BACKTRACE_FILE=backtrace-linux-amd64
        NEXTTRACE_FILE=nexttrace_linux_amd64
        ;;
    esac
}

# https://github.com/LemonBench/LemonBench/blob/main/LemonBench.sh
# ===========================================================================
# -> 系统信息模块 (Entrypoint) -> 执行
function BenchFunc_Systeminfo_GetSysteminfo() {
    BenchAPI_Systeminfo_GetCPUinfo
    BenchAPI_Systeminfo_GetVMMinfo
    BenchAPI_Systeminfo_GetMemoryinfo
    BenchAPI_Systeminfo_GetDiskinfo
    BenchAPI_Systeminfo_GetOSReleaseinfo
    # BenchAPI_Systeminfo_GetLinuxKernelinfo
}
#
# -> 系统信息模块 (Collector) -> 获取CPU信息
function BenchAPI_Systeminfo_GetCPUinfo() {
    # CPU 基础信息检测
    local r_modelname && r_modelname="$(lscpu -B 2>/dev/null | grep -oP -m1 "(?<=Model name:).*(?=)" | sed -e 's/^[ ]*//g')"
    local r_cachesize_l1d_b && r_cachesize_l1d_b="$(lscpu -B 2>/dev/null | grep -oP "(?<=L1d cache:).*(?=)" | sed -e 's/^[ ]*//g')"
    local r_cachesize_l1i_b && r_cachesize_l1i_b="$(lscpu -B 2>/dev/null | grep -oP "(?<=L1i cache:).*(?=)" | sed -e 's/^[ ]*//g')"
    local r_cachesize_l1_b && r_cachesize_l1_b="$(echo "$r_cachesize_l1d_b" "$r_cachesize_l1i_b" | awk '{printf "%d\n",$1+$2}')"
    local r_cachesize_l1_k && r_cachesize_l1_k="$(echo "$r_cachesize_l1_b" | awk '{printf "%.2f\n",$1/1024}')"
    local t_cachesize_l1_k && t_cachesize_l1_k="$(echo "$r_cachesize_l1_b" | awk '{printf "%d\n",$1/1024}')"
    if [ "$t_cachesize_l1_k" -ge "1024" ]; then
        local r_cachesize_l1_m && r_cachesize_l1_m="$(echo "$r_cachesize_l1_k" | awk '{printf "%.2f\n",$1/1024}')"
        local r_cachesize_l1="$r_cachesize_l1_m MB"
    else
        local r_cachesize_l1="$r_cachesize_l1_k KB"
    fi
    local r_cachesize_l2_b && r_cachesize_l2_b="$(lscpu -B 2>/dev/null | grep -oP "(?<=L2 cache:).*(?=)" | sed -e 's/^[ ]*//g')"
    local r_cachesize_l2_k && r_cachesize_l2_k="$(echo "$r_cachesize_l2_b" | awk '{printf "%.2f\n",$1/1024}')"
    local t_cachesize_l2_k && t_cachesize_l2_k="$(echo "$r_cachesize_l2_b" | awk '{printf "%d\n",$1/1024}')"
    if [ "$t_cachesize_l2_k" -ge "1024" ]; then
        local r_cachesize_l2_m && r_cachesize_l2_m="$(echo "$r_cachesize_l2_k" | awk '{printf "%.2f\n",$1/1024}')"
        local r_cachesize_l2="$r_cachesize_l2_m MB"
    else
        local r_cachesize_l2="$r_cachesize_l2_k KB"
    fi
    local r_cachesize_l3_b && r_cachesize_l3_b="$(lscpu -B 2>/dev/null | grep -oP "(?<=L3 cache:).*(?=)" | sed -e 's/^[ ]*//g')"
    local r_cachesize_l3_k && r_cachesize_l3_k="$(echo "$r_cachesize_l3_b" | awk '{printf "%.2f\n",$1/1024}')"
    local t_cachesize_l3_k && t_cachesize_l3_k="$(echo "$r_cachesize_l3_b" | awk '{printf "%d\n",$1/1024}')"
    if [ "$t_cachesize_l3_k" -ge "1024" ]; then
        local r_cachesize_l3_m && r_cachesize_l3_m="$(echo "$r_cachesize_l3_k" | awk '{printf "%.2f\n",$1/1024}')"
        local r_cachesize_l3="$r_cachesize_l3_m MB"
    else
        local r_cachesize_l3="$r_cachesize_l3_k KB"
    fi
    local r_sockets && r_sockets="$(lscpu -B 2>/dev/null | grep -oP "(?<=Socket\(s\):).*(?=)" | sed -e 's/^[ ]*//g')"
    if [ "$r_sockets" -ge "2" ]; then
        local r_cores && r_cores="$(lscpu -B 2>/dev/null | grep -oP "(?<=Core\(s\) per socket:).*(?=)" | sed -e 's/^[ ]*//g')"
        r_cores="$(echo "$r_sockets" "$r_cores" | awk '{printf "%d\n",$1*$2}')"
        local r_threadpercore && r_threadpercore="$(lscpu -B 2>/dev/null | grep -oP "(?<=Thread\(s\) per core:).*(?=)" | sed -e 's/^[ ]*//g')"
        local r_threads && r_threads="$(echo "$r_cores" "$r_threadpercore" | awk '{printf "%d\n",$1*$2}')"
        r_threads="$(echo "$r_threadpercore" "$r_cores" | awk '{printf "%d\n",$1*$2}')"
    else
        local r_cores && r_cores="$(lscpu -B 2>/dev/null | grep -oP "(?<=Core\(s\) per socket:).*(?=)" | sed -e 's/^[ ]*//g')"
        local r_threadpercore && r_threadpercore="$(lscpu -B 2>/dev/null | grep -oP "(?<=Thread\(s\) per core:).*(?=)" | sed -e 's/^[ ]*//g')"
        local r_threads && r_threads="$(echo "$r_cores" "$r_threadpercore" | awk '{printf "%d\n",$1*$2}')"
    fi
    # CPU AES能力检测
    # local t_aes && t_aes="$(awk -F ': ' '/flags/{print $2}' /proc/cpuinfo 2>/dev/null | grep -oE "\baes\b" | sort -u)"
    # [[ "${t_aes}" = "aes" ]] && Result_Systeminfo_CPUAES="1" || Result_Systeminfo_CPUAES="0"
    # CPU AVX能力检测
    # local t_avx && t_avx="$(awk -F ': ' '/flags/{print $2}' /proc/cpuinfo 2>/dev/null | grep -oE "\bavx\b" | sort -u)"
    # [[ "${t_avx}" = "avx" ]] && Result_Systeminfo_CPUAVX="1" || Result_Systeminfo_CPUAVX="0"
    # CPU AVX512能力检测
    # local t_avx512 && t_avx512="$(awk -F ': ' '/flags/{print $2}' /proc/cpuinfo 2>/dev/null | grep -oE "\bavx512\b" | sort -u)"
    # [[ "${t_avx512}" = "avx" ]] && Result_Systeminfo_CPUAVX512="1" || Result_Systeminfo_CPUAVX512="0"
    # CPU 虚拟化能力检测
    local t_vmx_vtx && t_vmx_vtx="$(awk -F ': ' '/flags/{print $2}' /proc/cpuinfo 2>/dev/null | grep -oE "\bvmx\b" | sort -u)"
    local t_vmx_svm && t_vmx_svm="$(awk -F ': ' '/flags/{print $2}' /proc/cpuinfo 2>/dev/null | grep -oE "\bsvm\b" | sort -u)"
    if [ "$t_vmx_vtx" = "vmx" ]; then
        Result_Systeminfo_VirtReady="1"
        Result_Systeminfo_CPUVMX="Intel VT-x"
    elif [ "$t_vmx_svm" = "svm" ]; then
        Result_Systeminfo_VirtReady="1"
        Result_Systeminfo_CPUVMX="AMD-V"
    else
        if [ -c "/dev/kvm" ]; then
            Result_Systeminfo_VirtReady="1"
            Result_Systeminfo_CPUVMX="unknown"
        else
            Result_Systeminfo_VirtReady="0"
            Result_Systeminfo_CPUVMX="unknown"
        fi
    fi
    # 输出结果
    Result_Systeminfo_CPUModelName="$r_modelname"
    Result_Systeminfo_CPUSockets="$r_sockets"
    Result_Systeminfo_CPUCores="$r_cores"
    Result_Systeminfo_CPUThreads="$r_threads"
    Result_Systeminfo_CPUCacheSizeL1="$r_cachesize_l1"
    Result_Systeminfo_CPUCacheSizeL2="$r_cachesize_l2"
    Result_Systeminfo_CPUCacheSizeL3="$r_cachesize_l3"
}
#
# -> 系统信息模块 (Collector) -> 获取内存及Swap信息
function BenchAPI_Systeminfo_GetMemoryinfo() {
    # 内存信息
    local r_memtotal_kib && r_memtotal_kib="$(awk '/MemTotal/{print $2}' /proc/meminfo | head -n1)"
    local r_memtotal_mib && r_memtotal_mib="$(echo "$r_memtotal_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_memtotal_gib && r_memtotal_gib="$(echo "$r_memtotal_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_meminfo_memfree_kib && r_meminfo_memfree_kib="$(awk '/MemFree/{print $2}' /proc/meminfo | head -n1)"
    local r_meminfo_buffers_kib && r_meminfo_buffers_kib="$(awk '/Buffers/{print $2}' /proc/meminfo | head -n1)"
    local r_meminfo_cached_kib && r_meminfo_cached_kib="$(awk '/Cached/{print $2}' /proc/meminfo | head -n1)"
    local r_memfree_kib && r_memfree_kib="$(echo "$r_meminfo_memfree_kib" "$r_meminfo_buffers_kib" "$r_meminfo_cached_kib" | awk '{printf $1+$2+$3}')"
    local r_memfree_mib && r_memfree_mib="$(echo "$r_memfree_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_memfree_gib && r_memfree_gib="$(echo "$r_memfree_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_memused_kib && r_memused_kib="$(echo "$r_memtotal_kib" "$r_memfree_kib" | awk '{printf $1-$2}')"
    local r_memused_mib && r_memused_mib="$(echo "$r_memused_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_memused_gib && r_memused_gib="$(echo "$r_memused_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    # 交换信息
    local r_swaptotal_kib && r_swaptotal_kib="$(awk '/SwapTotal/{print $2}' /proc/meminfo | head -n1)"
    local r_swaptotal_mib && r_swaptotal_mib="$(echo "$r_swaptotal_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_swaptotal_gib && r_swaptotal_gib="$(echo "$r_swaptotal_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_swapfree_kib && r_swapfree_kib="$(awk '/SwapFree/{print $2}' /proc/meminfo | head -n1)"
    local r_swapfree_mib && r_swapfree_mib="$(echo "$r_swapfree_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_swapfree_gib && r_swapfree_gib="$(echo "$r_swapfree_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_swapused_kib && r_swapused_kib="$(echo "$r_swaptotal_kib" "${r_swapfree_kib}" | awk '{printf $1-$2}')"
    local r_swapused_mib && r_swapused_mib="$(echo "$r_swapused_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_swapused_gib && r_swapused_gib="$(echo "$r_swapused_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    # 数据加工
    if [ "$r_memused_kib" -lt "1024" ] && [ "$r_memtotal_kib" -lt "1048576" ]; then
        Result_Systeminfo_Memoryinfo="$r_memused_kib KiB / $r_memtotal_mib MiB"
    elif [ "$r_memused_kib" -lt "1048576" ] && [ "$r_memtotal_kib" -lt "1048576" ]; then
        Result_Systeminfo_Memoryinfo="$r_memused_mib MiB / $r_memtotal_mib MiB"
    elif [ "$r_memused_kib" -lt "1048576" ] && [ "$r_memtotal_kib" -lt "1073741824" ]; then
        Result_Systeminfo_Memoryinfo="$r_memused_mib MiB / $r_memtotal_gib GiB"
    else
        Result_Systeminfo_Memoryinfo="$r_memused_gib GiB / $r_memtotal_gib GiB"
    fi
    if [ "$r_swaptotal_kib" -eq "0" ]; then
        Result_Systeminfo_Swapinfo="[ no swap partition or swap file detected ]"
    elif [ "$r_swapused_kib" -lt "1024" ] && [ "$r_swaptotal_kib" -lt "1048576" ]; then
        Result_Systeminfo_Swapinfo="$r_swapused_kib KiB / $r_swaptotal_mib MiB"
    elif [ "$r_swapused_kib" -lt "1024" ] && [ "$r_swaptotal_kib" -lt "1073741824" ]; then
        Result_Systeminfo_Swapinfo="$r_swapused_kib KiB / $r_swaptotal_gib GiB"
    elif [ "$r_swapused_kib" -lt "1048576" ] && [ "$r_swaptotal_kib" -lt "1048576" ]; then
        Result_Systeminfo_Swapinfo="$r_swapused_mib MiB / $r_swaptotal_mib MiB"
    elif [ "$r_swapused_kib" -lt "1048576" ] && [ "$r_swaptotal_kib" -lt "1073741824" ]; then
        Result_Systeminfo_Swapinfo="$r_swapused_mib MiB / $r_swaptotal_gib GiB"
    else
        Result_Systeminfo_Swapinfo="$r_swapused_gib GiB / $r_swaptotal_gib GiB"
    fi
}
#
# -> 系统信息模块 (Collector) -> 获取磁盘信息
function BenchAPI_Systeminfo_GetDiskinfo() {
    # 磁盘信息
    local r_diskpath_root && r_diskpath_root="$(df -x tmpfs / | awk "NR>1" | sed ":a;N;s/\\n//g;ta" | awk '{print $1}')"
    local r_disktotal_kib && r_disktotal_kib="$(df -x tmpfs / | grep -oE "[0-9]{4,}" | awk 'NR==1 {print $1}')"
    local r_disktotal_mib && r_disktotal_mib="$(echo "$r_disktotal_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_disktotal_gib && r_disktotal_gib="$(echo "$r_disktotal_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_disktotal_tib && r_disktotal_tib="$(echo "$r_disktotal_kib" | awk '{printf "%.2f\n",$1/1073741824}')"
    local r_diskused_kib && r_diskused_kib="$(df -x tmpfs / | grep -oE "[0-9]{4,}" | awk 'NR==2 {print $1}')"
    local r_diskused_mib && r_diskused_mib="$(echo "$r_diskused_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_diskused_gib && r_diskused_gib="$(echo "$r_diskused_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_diskused_tib && r_diskused_tib="$(echo "$r_diskused_kib" | awk '{printf "%.2f\n",$1/1073741824}')"
    local r_diskfree_kib && r_diskfree_kib="$(df -x tmpfs / | grep -oE "[0-9]{4,}" | awk 'NR==3 {print $1}')"
    local r_diskfree_mib && r_diskfree_mib="$(echo "$r_diskfree_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_diskfree_gib && r_diskfree_gib="$(echo "$r_diskfree_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_diskfree_tib && r_diskfree_tib="$(echo "$r_diskfree_kib" | awk '{printf "%.2f\n",$1/1073741824}')"
    # 数据加工
    Result_Systeminfo_DiskRootPath="$r_diskpath_root"
    if [ "$r_diskused_kib" -lt "1048576" ]; then
        Result_Systeminfo_Diskinfo="$r_diskused_mib MiB / $r_disktotal_mib MiB"
    elif [ "$r_diskused_kib" -lt "1048576" ] && [ "$r_disktotal_kib" -lt "1073741824" ]; then
        Result_Systeminfo_Diskinfo="$r_diskused_mib MiB / $r_disktotal_gib GiB"
    elif [ "$r_diskused_kib" -lt "1073741824" ] && [ "$r_disktotal_kib" -lt "1073741824" ]; then
        Result_Systeminfo_Diskinfo="$r_diskused_gib GiB / $r_disktotal_gib GiB"
    elif [ "$r_diskused_kib" -lt "1073741824" ] && [ "$r_disktotal_kib" -ge "1073741824" ]; then
        Result_Systeminfo_Diskinfo="$r_diskused_gib GiB / $r_disktotal_tib TiB"
    else
        Result_Systeminfo_Diskinfo="$r_diskused_tib TiB / $r_disktotal_tib TiB"
    fi
}
#
# -> 系统信息模块 (Collector) -> 获取虚拟化信息
function BenchAPI_Systeminfo_GetVMMinfo() {
    if [ -f "/usr/bin/systemd-detect-virt" ]; then
        local r_vmmtype && r_vmmtype="$(/usr/bin/systemd-detect-virt 2>/dev/null)"
        case "${r_vmmtype}" in
        kvm)
            Result_Systeminfo_VMMType="KVM"
            Result_Systeminfo_VMMTypeShort="kvm"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        xen)
            Result_Systeminfo_VMMType="Xen Hypervisor"
            Result_Systeminfo_VMMTypeShort="xen"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        microsoft)
            Result_Systeminfo_VMMType="Microsoft Hyper-V"
            Result_Systeminfo_VMMTypeShort="microsoft"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        vmware)
            Result_Systeminfo_VMMType="VMware"
            Result_Systeminfo_VMMTypeShort="vmware"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        oracle)
            Result_Systeminfo_VMMType="Oracle VirtualBox"
            Result_Systeminfo_VMMTypeShort="oracle"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        parallels)
            Result_Systeminfo_VMMType="Parallels"
            Result_Systeminfo_VMMTypeShort="parallels"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        qemu)
            Result_Systeminfo_VMMType="QEMU"
            Result_Systeminfo_VMMTypeShort="qemu"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        amazon)
            Result_Systeminfo_VMMType="Amazon Virtualization"
            Result_Systeminfo_VMMTypeShort="amazon"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        docker)
            Result_Systeminfo_VMMType="Docker"
            Result_Systeminfo_VMMTypeShort="docker"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        openvz)
            Result_Systeminfo_VMMType="OpenVZ (Virutozzo)"
            Result_Systeminfo_VMMTypeShort="openvz"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        lxc)
            Result_Systeminfo_VMMTypeShort="lxc"
            Result_Systeminfo_VMMType="LXC"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        lxc-libvirt)
            Result_Systeminfo_VMMType="LXC (Based on libvirt)"
            Result_Systeminfo_VMMTypeShort="lxc-libvirt"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        uml)
            Result_Systeminfo_VMMType="User-mode Linux"
            Result_Systeminfo_VMMTypeShort="uml"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        systemd-nspawn)
            Result_Systeminfo_VMMType="Systemd nspawn"
            Result_Systeminfo_VMMTypeShort="systemd-nspawn"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        bochs)
            Result_Systeminfo_VMMType="BOCHS"
            Result_Systeminfo_VMMTypeShort="bochs"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        rkt)
            Result_Systeminfo_VMMType="RKT"
            Result_Systeminfo_VMMTypeShort="rkt"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        zvm)
            Result_Systeminfo_VMMType="S390 Z/VM"
            Result_Systeminfo_VMMTypeShort="zvm"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        none)
            Result_Systeminfo_VMMType="Dedicated"
            Result_Systeminfo_VMMTypeShort="none"
            Result_Systeminfo_isPhysical="1"
            if test -f "/sys/class/iommu/dmar0/uevent"; then
                Result_Systeminfo_IOMMU="1"
            else
                Result_Systeminfo_IOMMU="0"
            fi
            return 0
            ;;
        *)
            echo -e "${Msg_Error} BenchAPI_Systeminfo_GetVirtinfo(): invalid result (${r_vmmtype}), please check parameter!"
            ;;
        esac
    fi
    if [ -f "/.dockerenv" ]; then
        Result_Systeminfo_VMMType="Docker"
        Result_Systeminfo_VMMTypeShort="docker"
        Result_Systeminfo_isPhysical="0"
        return 0
    elif [ -c "/dev/lxss" ]; then
        Result_Systeminfo_VMMType="Windows Subsystem for Linux"
        Result_Systeminfo_VMMTypeShort="wsl"
        Result_Systeminfo_isPhysical="0"
        return 0
    else
        if [ -f "/proc/1/cgroup" ] && grep -q "docker" /proc/1/cgroup 2>/dev/null; then
            Result_Systeminfo_VMMType="Docker"
            Result_Systeminfo_VMMTypeShort="docker"
            Result_Systeminfo_isPhysical="0"
            return 0
        fi
        Result_Systeminfo_VMMType="Dedicated"
        Result_Systeminfo_VMMTypeShort="none"
        if test -f "/sys/class/iommu/dmar0/uevent"; then
            Result_Systeminfo_IOMMU="1"
        else
            Result_Systeminfo_IOMMU="0"
        fi
        return 0
    fi
}
#
# -> 系统信息模块 (Collector) -> 获取Linux发行版信息
function BenchAPI_Systeminfo_GetOSReleaseinfo() {
    local r_arch && r_arch="$(arch)"
    Result_Systeminfo_OSArch="$r_arch"
    # CentOS/Red Hat 判断
    if [ -f "/etc/centos-release" ] || [ -f "/etc/redhat-release" ]; then
        Result_Systeminfo_OSReleaseNameShort="centos"
        local r_prettyname && r_prettyname="$(grep -oP '(?<=\bPRETTY_NAME=").*(?=")' /etc/os-release)"
        local r_elrepo_version && r_elrepo_version="$(rpm -qa | grep -oP "el[0-9]+" | sort -ur | head -n1)"
        case "$r_elrepo_version" in
        9 | el9)
            Result_Systeminfo_OSReleaseVersionShort="9"
            Result_Systeminfo_OSReleaseNameFull="$r_prettyname ($r_arch)"
            return 0
            ;;
        8 | el8)
            Result_Systeminfo_OSReleaseVersionShort="8"
            Result_Systeminfo_OSReleaseNameFull="$r_prettyname ($r_arch)"
            return 0
            ;;
        7 | el7)
            Result_Systeminfo_OSReleaseVersionShort="7"
            Result_Systeminfo_OSReleaseNameFull="$r_prettyname ($r_arch)"
            return 0
            ;;
        6 | el6)
            Result_Systeminfo_OSReleaseVersionShort="6"
            Result_Systeminfo_OSReleaseNameFull="$r_prettyname ($r_arch)"
            return 0
            ;;
        *)
            echo -e "${Msg_Error} BenchAPI_Systeminfo_GetOSReleaseinfo(): invalid result (CentOS/Redhat-$r_prettyname ($r_arch)), please check parameter!"
            exit 1
            ;;
        esac
    elif [ -f "/etc/lsb-release" ]; then # Ubuntu
        Result_Systeminfo_OSReleaseNameShort="ubuntu"
        local r_prettyname && r_prettyname="$(grep -oP '(?<=\bPRETTY_NAME=").*(?=")' /etc/os-release)"
        Result_Systeminfo_OSReleaseVersion="$(grep -oP '(?<=\bVERSION=").*(?=")' /etc/os-release)"
        Result_Systeminfo_OSReleaseVersionShort="$(grep -oP '(?<=\bVERSION_ID=").*(?=")' /etc/os-release)"
        Result_Systeminfo_OSReleaseNameFull="$r_prettyname ($r_arch)"
        return 0
    elif [ -f "/etc/debian_version" ]; then # Debian
        Result_Systeminfo_OSReleaseNameShort="debian"
        local r_prettyname && r_prettyname="$(grep -oP '(?<=\bPRETTY_NAME=").*(?=")' /etc/os-release)"
        Result_Systeminfo_OSReleaseVersion="$(grep -oP '(?<=\bVERSION=").*(?=")' /etc/os-release)"
        Result_Systeminfo_OSReleaseVersionShort="$(grep -oP '(?<=\bVERSION_ID=").*(?=")' /etc/os-release)"
        Result_Systeminfo_OSReleaseNameFull="$r_prettyname ($r_arch)"
        return 0
    else
        echo -e "${Msg_Error} BenchAPI_Systeminfo_GetOSReleaseinfo(): invalid result ($r_prettyname ($r_arch)), please check parameter!"
    fi
}

calc_disk() {
    local total_size=0
    local array=$@
    for size in ${array[@]}; do
        [ "${size}" == "0" ] && size_t=0 || size_t=$(echo ${size:0:${#size}-1})
        [ "$(echo ${size:(-1)})" == "K" ] && size=0
        [ "$(echo ${size:(-1)})" == "M" ] && size=$(awk 'BEGIN{printf "%.1f", '$size_t' / 1024}')
        [ "$(echo ${size:(-1)})" == "T" ] && size=$(awk 'BEGIN{printf "%.1f", '$size_t' * 1024}')
        [ "$(echo ${size:(-1)})" == "G" ] && size=${size_t}
        [ "$(echo ${size:(-1)})" == "E" ] && size=$(awk 'BEGIN{printf "%.1f", '$size_t' * 1024 * 1024}')
        total_size=$(awk 'BEGIN{printf "%.1f", '$total_size' + '$size'}')
    done
    echo ${total_size}
}

get_system_info() {
    arch=$(uname -m)
    if [ -n "$Result_Systeminfo_Diskinfo" ]; then
        :
    else
        disk_size1=($(LC_ALL=C df -hPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem|udev|docker|snapd' | awk '{print $2}'))
        disk_size2=($(LC_ALL=C df -hPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem|udev|docker|snapd' | awk '{print $3}'))
        disk_total_size=$(calc_disk "${disk_size1[@]}")
        disk_used_size=$(calc_disk "${disk_size2[@]}")
    fi
    if [ -f "/proc/cpuinfo" ]; then
        cname=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
        cores=$(awk -F: '/processor/ {core++} END {print core}' /proc/cpuinfo)
        freq=$(awk -F'[ :]' '/cpu MHz/ {print $4;exit}' /proc/cpuinfo)
        ccache=$(awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
        CPU_AES=$(cat /proc/cpuinfo | grep aes)
        CPU_VIRT=$(cat /proc/cpuinfo | grep 'vmx\|svm')
        up=$(awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days, %d hour %d min\n",a,b,c)}' /proc/uptime)
        if _exists "w"; then
            load=$(
                LANG=C
                w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//'
            )
        elif _exists "uptime"; then
            load=$(
                LANG=C
                uptime | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//'
            )
        fi
    elif [ "${Var_OSRelease}" == "freebsd" ]; then
        cname=$($sysctl_path -n hw.model)
        cores=$($sysctl_path -n hw.ncpu)
        freq=$($sysctl_path -n dev.cpu.0.freq 2>/dev/null || echo "")
        ccache=$($sysctl_path -n hw.cacheconfig 2>/dev/null | awk -F: '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' || echo "")
        CPU_AES=$($sysctl_path -a | grep -E 'crypto.aesni' | awk '{print $2}')
        CPU_VIRT=$($sysctl_path -a | grep -E 'hw.vmx|hw.svm' | awk '{print $2}')
        up=$($sysctl_path -n kern.boottime | perl -MPOSIX -nE 'if (/sec = (\d+), usec = (\d+)/) { $boottime = $1; $uptime = time() - $boottime; $days = int($uptime / 86400); $hours = int(($uptime % 86400) / 3600); $minutes = int(($uptime % 3600) / 60); say "$days days, $hours hours, $minutes minutes" }')
        if _exists "w"; then
            load=$(w | awk '{print $(NF-2), $(NF-1), $NF}' | head -n 1)
        elif _exists "uptime"; then
            load=$(uptime | awk '{print $(NF-2), $(NF-1), $NF}')
        fi
    fi
    if [ -z "$cname" ] || [ ! -e /proc/cpuinfo ]; then
        cname=$(lscpu | grep "Model name" | sed 's/Model name: *//g')
        if [ $? -ne 0 ]; then
            ${PACKAGE_INSTALL[int]} util-linux
            cname=$(lscpu | grep "Model name" | sed 's/Model name: *//g')
        fi
        if [ -z "$cname" ]; then
            cname=$(cat /proc/device-tree/model)
        fi
    fi
    cname=$(echo -n "$cname" | tr '\n' ' ' | sed -E 's/ +/ /g')
    if command -v free >/dev/null 2>&1; then
        if free -m | grep -q '内存'; then # 如果输出中包含 "内存" 关键词
            tram=$(free -m | awk '/内存/{print $2}')
            uram=$(free -m | awk '/内存/{print $3}')
            swap=$(free -m | awk '/交换/{print $2}')
            uswap=$(free -m | awk '/交换/{print $3}')
        else # 否则，假定输出是英文的
            tram=$(
                LANG=C
                free -m | awk '/Mem/ {print $2}'
            )
            uram=$(
                LANG=C
                free -m | awk '/Mem/ {print $3}'
            )
            swap=$(
                LANG=C
                free -m | awk '/Swap/ {print $2}'
            )
            uswap=$(
                LANG=C
                free -m | awk '/Swap/ {print $3}'
            )
        fi
    else
        tram=$($sysctl_path -n hw.physmem | awk '{printf "%.0f", $1/1024/1024}')
        uram=$($sysctl_path -n vm.stats.vm.v_active_count | awk '{printf "%.0f", $1/1024}')
        swap=$(swapinfo -k | awk 'NR>1{sum+=$2} END{printf "%.0f", sum/1024}')
        uswap=$(swapinfo -k | awk 'NR>1{sum+=$4} END{printf "%.0f", sum/1024}')
    fi
    if _exists "getconf"; then
        lbit=$(getconf LONG_BIT)
    else
        echo ${arch} | grep -q "64" && lbit="64" || lbit="32"
    fi
    kern=$(uname -r)
    if [ -z "$sysctl_path" ]; then
        tcpctrl="None"
    fi
    tcpctrl=$($sysctl_path -n net.ipv4.tcp_congestion_control 2>/dev/null)
}

print_system_info() {
    if [ "$en_status" = true ]; then
            echo "$en_status"
    else
        if [ -n "$cname" ] >/dev/null 2>&1; then
            echo " CPU 型号          : $(_blue "$cname")"
        elif [ -n "$Result_Systeminfo_CPUModelName" ] >/dev/null 2>&1; then
            echo " CPU 型号          : $(_blue "$Result_Systeminfo_CPUModelName")"
        else
            echo " CPU 型号          : $(_blue "无法检测到CPU型号")"
        fi
        if [[ -n "$Result_Systeminfo_isPhysical" && "$Result_Systeminfo_isPhysical" = "1" ]] >/dev/null 2>&1; then
            if [ -n "$Result_Systeminfo_CPUSockets" ] && [ "$Result_Systeminfo_CPUSockets" -ne 0 ] &&
                [ -n "$Result_Systeminfo_CPUCores" ] && [ "$Result_Systeminfo_CPUCores" -ne 0 ] &&
                [ -n "$Result_Systeminfo_CPUThreads" ] && [ "$Result_Systeminfo_CPUThreads" -ne 0 ] >/dev/null 2>&1; then
                echo " CPU 核心数        : $(_blue "${Result_Systeminfo_CPUSockets} 物理核心, ${Result_Systeminfo_CPUCores} 总核心, ${Result_Systeminfo_CPUThreads} 总线程数")"
            elif [ -n "$cores" ]; then
                echo " CPU 核心数        : $(_blue "$cores")"
            else
                echo " CPU 核心数        : $(_blue "无法检测到CPU核心数量")"
            fi
        elif [[ -n "$Result_Systeminfo_isPhysical" && "$Result_Systeminfo_isPhysical" = "0" ]] >/dev/null 2>&1; then
            if [[ -n "$Result_Systeminfo_CPUThreads" && "$Result_Systeminfo_CPUThreads" -ne 0 ]] >/dev/null 2>&1; then
                echo " CPU 核心数        : $(_blue "${Result_Systeminfo_CPUThreads}")"
            elif [ -n "$cores" ] >/dev/null 2>&1; then
                echo " CPU 核心数        : $(_blue "$cores")"
            else
                echo " CPU 核心数        : $(_blue "无法检测到CPU核心数量")"
            fi
        else
            echo " CPU 核心数        : $(_blue "$cores")"
        fi
        if [ -n "$freq" ] >/dev/null 2>&1; then
            echo " CPU 频率          : $(_blue "$freq MHz")"
        fi
        if [ -n "$Result_Systeminfo_CPUCacheSizeL1" ] && [ -n "$Result_Systeminfo_CPUCacheSizeL2" ] && [ -n "$Result_Systeminfo_CPUCacheSizeL3" ] >/dev/null 2>&1; then
            echo " CPU 缓存          : $(_blue "L1: ${Result_Systeminfo_CPUCacheSizeL1} / L2: ${Result_Systeminfo_CPUCacheSizeL2} / L3: ${Result_Systeminfo_CPUCacheSizeL3}")"
        elif [ -n "$ccache" ] >/dev/null 2>&1; then
            echo " CPU 缓存          : $(_blue "$ccache")"
        fi
        [[ -z "$CPU_AES" ]] && CPU_AES="\xE2\x9D\x8C Disabled" || CPU_AES="\xE2\x9C\x94 Enabled"
        echo " AES-NI指令集      : $(_blue "$CPU_AES")"
        [[ -z "$CPU_VIRT" ]] && CPU_VIRT="\xE2\x9D\x8C Disabled" || CPU_VIRT="\xE2\x9C\x94 Enabled"
        echo " VM-x/AMD-V支持    : $(_blue "$CPU_VIRT")"
        if [ -n "$Result_Systeminfo_Memoryinfo" ] >/dev/null 2>&1; then
            echo " 内存              : $(_blue "$Result_Systeminfo_Memoryinfo")"
        elif [ -n "$tram" ] && [ -n "$uram" ] >/dev/null 2>&1; then
            echo " 内存              : $(_yellow "$tram MB") $(_blue "($uram MB 已用)")"
        fi
        if [ -n "$Result_Systeminfo_Swapinfo" ] >/dev/null 2>&1; then
            echo " Swap              : $(_blue "$Result_Systeminfo_Swapinfo")"
        elif [ -n "$swap" ] && [ -n "$uswap" ] >/dev/null 2>&1; then
            echo " Swap              : $(_blue "$swap MB ($uswap MB 已用)")"
        fi
        if [ -n "$Result_Systeminfo_Diskinfo" ] >/dev/null 2>&1; then
            echo " 硬盘空间          : $(_blue "$Result_Systeminfo_Diskinfo")"
        else
            echo " 硬盘空间          : $(_yellow "$disk_total_size GB") $(_blue "($disk_used_size GB 已用)")"
        fi
        if [ -n "$Result_Systeminfo_DiskRootPath" ] >/dev/null 2>&1; then
            echo " 启动盘路径        : $(_blue "$Result_Systeminfo_DiskRootPath")"
        fi
        echo " 系统在线时间      : $(_blue "$up")"
        echo " 负载              : $(_blue "$load")"
        if [ -n "$Result_Systeminfo_OSReleaseNameFull" ] >/dev/null 2>&1; then
            echo " 系统              : $(_blue "$Result_Systeminfo_OSReleaseNameFull")"
        elif [ -n "$DISTRO" ] >/dev/null 2>&1; then
            echo " 系统              : $(_blue "$DISTRO")"
        fi
        echo " 架构              : $(_blue "$arch ($lbit Bit)")"
        echo " 内核              : $(_blue "$kern")"
        echo " TCP加速方式       : $(_yellow "$tcpctrl")"
        echo " 虚拟化架构        : $(_blue "$Result_Systeminfo_VMMType")"
    fi
}

BenchFunc_Systeminfo_GetSysteminfo
get_system_info
print_system_info
