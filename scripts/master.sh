#!/bin/bash
OPENSHIFT_RELEASE="$1"
OPENSHIFT_ANSIBLE_BRANCH="$2"
NETWORK_BASE="$3"

yum -y install git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct

# Sourcing common functions
. /vagrant/scripts/common.sh

if type ansible 2>/dev/null; then
        echo "ansible already exists"
else
  if [[ "$(version ${OPENSHIFT_RELEASE})" -gt "$(version 3.7)" ]]; then
      yum -y install https://releases.ansible.com/ansible/rpm/release/epel-7-x86_64/ansible-2.6.6-1.el7.ans.noarch.rpm || true
  else
      yum -y install https://releases.ansible.com/ansible/rpm/release/epel-7-x86_64/ansible-2.5.9-1.el7.ans.noarch.rpm || true
  fi
fi

echo "Cloning https://github.com/openshift/openshift-ansible.git"

if [[ ! -d /home/vagrant/openshift-ansible ]]; then
git clone -b ${OPENSHIFT_ANSIBLE_BRANCH} https://github.com/openshift/openshift-ansible.git /home/vagrant/openshift-ansible
fi

echo "Getting /etc/ansible/hosts"
if [[ -f /etc/ansible/hosts ]]; then
    mv /etc/ansible/hosts /etc/ansible/hosts.bak
fi

# Pre-define all possible openshift node groups
HTPASSWORD_FILENAME=", 'filename': '/etc/origin/master/htpasswd'"

# Prevent error "provider HTPasswdPasswordIdentityProvider contains unknown keys filename"
# when openshift version is 3.10 or above.
if [[ "$(version ${OPENSHIFT_RELEASE})" -ge "$(version 3.10)" ]]; then
    NODE_GROUP_MASTER="openshift_node_group_name='node-config-master'"
    NODE_GROUP_INFRA="openshift_node_group_name='node-config-infra'"
    NODE_GROUP_COMPUTE="openshift_node_group_name='node-config-compute'"
    NODE_GROUP_MASTER_INFRA="openshift_node_group_name='node-config-master-infra'"
    NODE_GROUP_ALLINONE="openshift_node_group_name='node-config-all-in-one'"
    unset HTPASSWORD_FILENAME
else
    NODE_GROUP_MASTER="openshift_node_labels=\"{'node-role.kubernetes.io/master': true}\""
    NODE_GROUP_INFRA="openshift_node_labels=\"{'node-role.kubernetes.io/infra': true}\""
    NODE_GROUP_COMPUTE="openshift_node_labels=\"{'node-role.kubernetes.io/compute': true}\""
    NODE_GROUP_MASTER_INFRA="openshift_node_labels=\"{'node-role.kubernetes.io/infra': true, 'node-role.kubernetes.io/master': true}\""
    NODE_GROUP_ALLINONE="openshift_node_labels=\"{'node-role.kubernetes.io/infra': true, 'node-role.kubernetes.io/master': true, 'node-role.kubernetes.io/compute': true}\""
fi

cat /vagrant/ansible-hosts \
    | sed "s~{{OPENSHIFT_RELEASE}}~${OPENSHIFT_RELEASE}~g" \
    | sed "s~{{NETWORK_BASE}}~${NETWORK_BASE}~g" \
    | sed "s~{{NODE_GROUP_MASTER}}~${NODE_GROUP_MASTER}~g" \
    | sed "s~{{NODE_GROUP_INFRA}}~${NODE_GROUP_INFRA}~g" \
    | sed "s~{{NODE_GROUP_COMPUTE}}~${NODE_GROUP_COMPUTE}~g" \
    | sed "s~{{NODE_GROUP_MASTER_INFRA}}~${NODE_GROUP_MASTER_INFRA}~g" \
    | sed "s~{{NODE_GROUP_ALLINONE}}~${NODE_GROUP_ALLINONE}~g" \
    | sed "s~{{HTPASSWORD_FILENAME}}~${HTPASSWORD_FILENAME}~g" \
    > /etc/ansible/hosts

mkdir -p /home/vagrant/.ssh
bash -c 'echo "Host *" >> /home/vagrant/.ssh/config'
bash -c 'echo "StrictHostKeyChecking no" >> /home/vagrant/.ssh/config'
chmod 600 /home/vagrant/.ssh/config
chown -R vagrant:vagrant /home/vagrant
