#!/usr/bin/bash

USER_PASSWORD="$1"
export AZURE_STORAGE_ACCOUNT="$2"
export AZURE_STORAGE_ACCESS_KEY="$3"
AZURE_STORAGE_CONTAINER="$4"

# https://github.com/Azure/WALinuxAgent/issues/178
# yum update -y --exclude=WALinuxAgent
# Avoiding yum update, to skip reboot. Need to remove hardcodings.
yum install -y https://buildlogs.centos.org/c7.1511.u/kernel/20161024152721/3.10.0-327.36.3.el7.x86_64/kernel-headers-3.10.0-327.36.3.el7.x86_64.rpm
yum install -y https://buildlogs.centos.org/c7.1511.u/kernel/20161024152721/3.10.0-327.36.3.el7.x86_64/kernel-devel-3.10.0-327.36.3.el7.x86_64.rpm
yum install -y epel-release
yum install -y gcc gcc-c++ ksh m4 sshpass nodejs npm
npm install -g azure-cli

mkdir -p /root/.ssh
ssh-keygen -f /root/.ssh/id_rsa -t rsa -N '' -q -P ""

echo 'Host *' >> /root/.ssh/config
echo 'StrictHostKeyChecking no' >> /root/.ssh/config

# Enable root login
echo $USER_PASSWORD | passwd --stdin root
hostname=`hostname`
# Enable password less ssh login within the node
sshpass -p $USER_PASSWORD ssh-copy-id -i /root/.ssh/id_rsa.pub $hostname

azure config mode arm
gpfs_rpms=("gpfs.adv-4.2.3-0.x86_64.rpm" "gpfs.base-4.2.3-0.x86_64.rpm" "gpfs.crypto-4.2.3-0.x86_64.rpm" "gpfs.docs-4.2.3-0.noarch.rpm" "gpfs.ext-4.2.3-0.x86_64.rpm" "gpfs.gpl-4.2.3-0.noarch.rpm" "gpfs.gskit-8.0.50-75.x86_64.rpm" "gpfs.license.adv-4.2.3-0.x86_64.rpm" "gpfs.msg.en_US-4.2.3-0.noarch.rpm")

for eachrpm in ${gpfs_rpms[*]}
do
    azure storage blob download -m -q $AZURE_STORAGE_CONTAINER $eachrpm "/root"
done

yum install /root/gpfs* -y
cd /usr/lpp/mmfs/src
make Autoconfig LINUX_DISTRIBUTION=REDHAT_AS_LINUX
make World
make InstallImages
cd /root
