#!/bin/bash

echo -e "\033[1;31mbuild_QY\033[0m"
echo -e "\033[1;32m正在安装软件\033[0m"
apt update -y
apt upgrade -y
apt install bc \
            binutils-dev \
            bison \
            build-essential \
            ca-certificates \
            ccache \
            clang \
            cmake \
            curl \
            file \
            flex \
            git \
            libelf-dev \
            libssl-dev \
            lld \
            make \
            ninja-build \
            python3-dev \
            texinfo \
            u-boot-tools \
            xz-utils \
            zlib1g-dev -y
# 颜色定义
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
RED="\033[1;31m"
RESET="\033[0m"

# 路径定义
GCC_DIR="$(pwd)/gcc"
KERNEL_DIR="$(pwd)/kernel"
CLANG_DIR="$(pwd)/clang"
COMMON_DIR="$(pwd)/common"

# 内核分支与 Clang 版本映射
declare -A BRANCH_MAP=(
    [1]="android12-5.10"
    [2]="android13-5.15"
    [3]="android14-6.1"
    [4]="android15-6.6"
)

declare -A CLANG_MAP=(
    [1]="r416183b"     # Android 12
    [2]="r450784d"     # Android 13
    [3]="r487747c"     # Android 14
    [4]="r510928"      # Android 15
    [5]="r383902"      #clang11.0.1
)

# 显示菜单
echo -e "${BLUE}选择你需要的内核版本:${RESET}"
echo -e "${YELLOW}1. Android 12 (5.10)"
echo -e "2. Android 13 (5.15)"
echo -e "3. Android 14 (6.1)"
echo -e "4. Android 15 (6.6)"
echo -e "5. 从git下载自定义版本${RESET}"

# 读取输入
read -p "请输入选项数字 (1-5): " choice

case $choice in
    1|2|3|4)
        selected_branch=${BRANCH_MAP[$choice]}
        selected_clang=${CLANG_MAP[$choice]}
        clang_branch="${selected_branch%-*}"  # 提取 androidXX
        
        # 下载 kernel
        [ -d "$COMMON_DIR" ] && {
            echo -e "${GREEN}检测到已有 kernel 目录，跳过下载${RESET}"
        } || {
            echo -e "${BLUE}正在下载 $selected_branch 内核...${RESET}"
            git clone --depth=1 \
                https://android.googlesource.com/kernel/common \
                -b "$selected_branch" \
                "$COMMON_DIR" || {
                    echo -e "${RED}内核下载失败! 错误码: $?${RESET}"
                    exit 1
                }
        }

        # 下载 clang
        if [ -d "$CLANG_DIR" ]; then
            echo -e "${GREEN}检测到已有 clang 目录，跳过下载${RESET}"
        else
            echo -e "${BLUE}正在下载 clang-$selected_clang 工具链...${RESET}"
            mkdir -p "$CLANG_DIR"
            wget -qO "$CLANG_DIR/clang-$selected_clang.tar.gz" \
                "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/${clang_branch}-release/clang-$selected_clang.tar.gz" \
                || {
                    echo -e "${RED}工具链下载失败!"
                    echo -e "可尝试以下手动验证:"
                    echo -e "curl -I https://android.googlesource.com/.../clang-$selected_clang.tar.gz"
                    exit 1
                }
            
            # 解压并清理
            tar xzf "$CLANG_DIR/clang-$selected_clang.tar.gz" -C "$CLANG_DIR"
            rm -f "$CLANG_DIR/clang-$selected_clang.tar.gz"
        fi
        ;;

    5)
    	if [ -d $KERNEL_DIR ];then
        	echo "1"
        else
		read -p "请输入自定义 Git 仓库地址: " custom_repo
        	read -p "请输入分支" batch
        	if [ -z "$batch" ];then 
        	git clone --depth=1 "$custom_repo" "$KERNEL_DIR" || exit 1
        	else [ -z "$batch" ]
        	git clone --depth=1 "$custom_repo" -b "$batch" "$KERNEL_DIR" || exit 1
        	fi
        fi
        ;;

    *)
        echo -e "${RED}无效选项! 请输入 1-5 的数字${RESET}"
        exit 1
        ;;
esac

# 验证结果
echo -e "\n${GREEN}完成! 已下载内容:${RESET}"
echo -e "内核存放目录: $COMMON_DIR"
if [ ! -d "$CLANG_DIR" ]; then
    echo "请下载clang"
    echo -e "\033[1;32m1. clang11.0.1\033[0m"
    echo -e "\033[1;32m2. clang12.0.5\033[0m"
    echo -e "\033[1;32m3. r450784d\033[0m"
    echo -e "\033[1;32m4. r487747c\033[0m"
    echo -e "\033[1;32m5. r510928\033[0m"
    echo -e "\033[1;32m6. clang20\033[0m"
    
    mkdir -p "$CLANG_DIR"
    read -p "请输入选项数字: " clang_kernel

    case $clang_kernel in
        1)
            wget -qO "$CLANG_DIR/clang.tar.gz" \
                "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/android12-release/clang-r383902.tar.gz"
            mkdir -p "$GCC_DIR"
            tar xf "$CLANG_DIR/clang.tar.gz" -C "$CLANG_DIR"
            rm -f "$CLANG_DIR/clang.tar.gz"
            git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git "$GCC_DIR/aarch64-linux-android-4.9"
            git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git "$GCC_DIR/arm-linux-androideabi-4.9"
            ;;
        2)
            wget -qO "$CLANG_DIR/clang.tar.gz" \
                "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/android12-release/clang-r416183b.tar.gz"
            tar xf "$CLANG_DIR/clang.tar.gz" -C "$CLANG_DIR"
            rm -f "$CLANG_DIR/clang.tar.gz"
            ;;
        3)
            wget -qO "$CLANG_DIR/clang.tar.gz" \
                "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/android13-release/clang-r450784d.tar.gz"
            tar xf "$CLANG_DIR/clang.tar.gz" -C "$CLANG_DIR"
            rm -f "$CLANG_DIR/clang.tar.gz"
            ;;
        4)
            wget -qO "$CLANG_DIR/clang.tar.gz" \
                "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/android14-release/clang-r487747c.tar.gz"
            tar xf "$CLANG_DIR/clang.tar.gz" -C "$CLANG_DIR"
            rm -f "$CLANG_DIR/clang.tar.gz"
            ;;
        5)
            wget -qO "$CLANG_DIR/clang.tar.gz" \
                "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/android15-release/clang-r510928.tar.gz"
            tar xf "$CLANG_DIR/clang.tar.gz" -C "$CLANG_DIR"
            rm -f "$CLANG_DIR/clang.tar.gz"
            ;;
        6)
            wget -qO "$CLANG_DIR/clang.tar.gz" \
                "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/llvm-r547379-release/clang-r547379.tar.gz"
            mkdir -p "$GCC_DIR"
            tar xf "$CLANG_DIR/clang.tar.gz" -C "$CLANG_DIR"
            rm -f "$CLANG_DIR/clang.tar.gz"
            git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git "$GCC_DIR/aarch64-linux-android-4.9"
            git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git "$GCC_DIR/arm-linux-androideabi-4.9"
            ;;
        *)
            echo "无效选项，跳过Clang下载。"
            ;;
    esac
else
    echo -e "Clang 工具链目录: $CLANG_DIR"
fi
echo -e "\033[1;29m选择编译方式\033[0m"
echo -e "\033[1;32m1.clang编译\033[0m"
echo -e "\033[1;32m2.交叉编译\033[0m"
read build_kernel
if [ $build_kernel == 1 ];then
	if [ -d $KERNEL_DIR ];then
		cd $KERNEL_DIR
	elif [ ! -d $KERNEL_DIR ];then
		cd $COMMON_DIR
	else
	echo "error"
	fi
	export CLANG=$CLANG_DIR/bin
	export PATH=:${CLANG}:$PATH
	export ARCH=arm64
	export LLVM=1
	export LLVM_IAS=1
	export CROSS_COMPILE=aarch64-linux-gnu-
	export CROSS_COMPILE_COMPAT=arm-linux-gnueabi-
	curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU-Next/next-susfs/kernel/setup.sh" | bash -s next-susfs-dev
	git clone https://gitlab.com/simonpunk/susfs4ksu.git -b $selected_branch
	make gki_defconfig O=out
	make -j24 CC=clang O=out
	mkdir $(pwd)/boot
	mv $O/arch/arm64/boot/* $(pwd)/boot
elif [ $build_kernel == 2 ];then
	if [ -d $KERNEL_DIR ];then
		cd $KERNEL_DIR
	elif [ ! -d $KERNEL_DIR ];then
		cd $COMMON_DIR
	else
	echo "error"
	fi
	export CLANG=$CLANG_DIR/bin
	export GCC_A=$GCC_DIR/aarch64-linux-android-4.9/bin
	export GCC_B=$GCC_DIR/arm-linux-androideabi-4.9/bin
	export PATH=:${CLANG}:${GCC_A}:${GCC_A}:$PATH
	export ARCH=arm64
	curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU-Next/next-susfs/kernel/setup.sh" | bash -s next-susfs-dev
	git clone https://gitlab.com/simonpunk/susfs4ksu.git -b $selected_branch
	make O=out
	make -j24 CROSS_COMPILE=aarch64-linux-android- CROSS_COMPILE_COMPAT=arm-linux-androideabi- CC=clang LD=ld.lld O=out
	mkdir $(pwd)/boot
	mv $O/arch/arm64/boot/* $(pwd)/boot
else 
echo "error"
fi
