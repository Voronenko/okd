#!/bin/bash
OPENSHIFT_TIMEZONE=${OPENSHIFT_TIMEZONE:-Europe/Kiev}
OPENSHIFT_RELEASE="$1"
# bash -c 'echo "export TZ='${OPENSHIFT_TIMEZONE}'" > /etc/profile.d/tz.sh'

setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config

yum -y install docker
usermod -aG dockerroot vagrant
cat > /etc/docker/daemon.json <<EOF
{
    "group": "dockerroot"
}
EOF
systemctl enable docker
systemctl start docker

# Sourcing common functions
. /vagrant/scripts/common.sh
# Fix missing packages for openshift origin 3.11.0
# https://lists.openshift.redhat.com/openshift-archives/dev/2018-November/msg00005.html
if [ "$(version ${OPENSHIFT_RELEASE})" -eq "$(version 3.11)" ]; then
    yum install -y centos-release-openshift-origin311
fi
