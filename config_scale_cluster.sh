#!/usr/bin/bash

USER_PASSWORD="$1"
CLIENT_NODE_PREFIX="$2"
CLIENT_NODE_COUNT="$3"
CLUSTER_NAME="$4"

# Password-less ssh setup with all other nodes in the cluster
for (( node=1; node<$CLIENT_NODE_COUNT; node++ ))
do
    sshpass -p $USER_PASSWORD ssh-copy-id -i /root/.ssh/id_rsa.pub $CLIENT_NODE_PREFIX$node
done

# Populate host entries
for (( node=0; node<$CLIENT_NODE_COUNT; node++ ))
do
    ipaddr=`sshpass -p $USER_PASSWORD ssh $CLIENT_NODE_PREFIX$node hostname -I`
    printf "$ipaddr   $CLIENT_NODE_PREFIX$node\n" >> /etc/hosts
done

# Prepare client-all.cfg
rm -fr /root/client-all.cfg

for (( node=0; node<$CLIENT_NODE_COUNT; node++ ))
do
    printf "$CLIENT_NODE_PREFIX$node\n" >> /root/client-all.cfg
done

# Use mmaddnode
/usr/lpp/mmfs/bin/mmaddnode -N /root/client-all.cfg
/usr/lpp/mmfs/bin/mmchlicense client --accept -N /root/client-all.cfg

/usr/lpp/mmfs/bin/mmstartup -N /root/client-all.txt
sleep 240

/usr/lpp/mmfs/bin/mmmount all -a
