#!/bin/bash

SCRIPT_PATH="$0"
RETCODE=0

while [ -h "$SCRIPT_PATH" ]; do
    ls=`ls -ld "$SCRIPT_PATH"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
        SCRIPT_PATH="$link"
    else
        SCRIPT_PATH=`dirname "$SCRIPT_PATH"`/"$link"
    fi
done

OKD_DIR=`dirname "$SCRIPT_PATH"`

readonly openshift_release=`cat Vagrantfile | grep '^OPENSHIFT_RELEASE' | awk -F'=' '{print $2}' | sed 's/^[[:blank:]\"]*//;s/[[:blank:]\"]*$//'`

. "$OKD_DIR/scripts/common.sh"

vagrant up
vagrant provision --provision-with master-key,node01-key,node02-key

if [ "$(version $openshift_release)" -gt "$(version 3.7)" ]; then
    vagrant ssh master \
        -c 'ansible-playbook /home/vagrant/openshift-ansible/playbooks/prerequisites.yml &&
            ansible-playbook /home/vagrant/openshift-ansible/playbooks/deploy_cluster.yml'
else
    vagrant ssh master \
        -c 'ansible-playbook /home/vagrant/openshift-ansible/playbooks/byo/config.yml'
fi
