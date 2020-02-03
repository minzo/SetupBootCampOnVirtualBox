#!/bin/sh

# -----------------------------------------------------------------------------
# BootCampのディスクのidentifier
DISK_IDENTIFIER=/dev/disk0s3
# VirtualBox のディレクトリ
VBOX_DIR="~/VirtualBox VMs"
# VM の名前
VM_NAME="Windows"

# 引数チェック
if [ $# -ne 6 ]; then
    echo "Usage: $0 [--disk <diskidentifier>] [--vmdir <dir>] [--vmname <vmname>]";
    exit 1
fi

# -----------------------------------------------------------------------------
DISK_IDENTIFIER=$2
VBOX_DIR=$4
VM_NAME=$6

# 区切り文字を改行に
IFS=$'\n'

# Disk Identifier から Disk と Partitions 情報を抜き出す
RAW_DISK=${DISK_IDENTIFIER%s*}
DISK_PARTITION=${DISK_IDENTIFIER##*s}

# rawdisk name
VMDK_NAME=${VM_NAME}"_raw.vmdk"

# disk identifier がなければ終了
if [ ! -e ${DISK_IDENTIFIER} ]; then
    echo $0: ${DISK_IDENTIFIER}": No such file or directory"
    exit 1
fi

# 指定のディレクトリがなければ作る
if [ ! -e ${VBOX_DIR} ]; then
    mkdir ${VBOX_DIR}
fi

# 指定ディレクトリに移動
cd ${VBOX_DIR}

# 権限変更
sudo chmod 666 ${DISK_IDENTIFIER}

# アンマウント
sudo umount ${DISK_IDENTIFIER}

# VMDK 作成
sudo VBoxManage internalcommands createrawvmdk -rawdisk ${RAW_DISK} -filename ${VMDK_NAME} -partitions ${DISK_PARTITION}

# VMDK のユーザー変更
sudo chown `logname` *.vmdk
sudo chmod 666 *.vmdk

# VM を作成
VBoxManage createvm --name ${VM_NAME} \
 --ostype Windows7_64 \
 --basefolder ${VBOX_DIR} \
 --register

# VMのディレクトリの権限をユーザーに
sudo chown `logname` ${VBOX_DIR}/${VM_NAME}
sudo chmod 777 ${VBOX_DIR}/${VM_NAME}

# VMの設定を編集
VBoxManage modifyvm ${VM_NAME}\
 --memory 4096 \
 --vram 64 \
 --cpus 2 \
 --rtcuseutc on \
 --firmware bios \
 --audio coreaudio \
 --clipboard-mode bidirectional \
 --draganddrop hosttoguest \
 --usbehci on

# コントローラを追加
VBoxManage storagectl ${VM_NAME} \
 --name "SATA Controller" \
 --add sata \
 --portcount 2 \
 --hostiocache on \
 --bootable on

# コントローラにストレージとDVDドライブを追加
VBoxManage storageattach ${VM_NAME} \
 --storagectl "SATA Controller" \
 --port 0 \
 --type hdd \
 --medium ${VBOX_DIR}/${VMDK_NAME}

VBoxManage storageattach ${VM_NAME} \
 --storagectl "SATA Controller" \
 --port 1 \
 --type dvddrive \
 --medium emptydrive