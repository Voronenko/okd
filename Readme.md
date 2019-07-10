## Do I need this play?

If you want just to give a try to openshift - definitely no. Check below why

Instead, to try

### 1) oc cluster up
This is included in OpenShift Origin 3.3+ and Red Hat OpenShift Container Platform 3.3+, which allows you to create a Red Hat OpenShift Container Platform environment in a containerized environment. It’s actually creating a containerized platform in a container. It has a lot of flexibility and runs on Windows, Linux, and macOS.

```bash
$ oc cluster up --use-existing-config \
               --host-data-dir=/usr/data \
               --metrics=true \
               --image=registry.access.redhat.com/openshift3/ose \
               --version=latest
```

### 2) minishift

Minishift is gaining a lot of traction and popularity within the community. It doesn't matter if you're running on Windows, Linux, or Mac. This tool runs OpenShift locally using a single node OpenShift cluster in a virtual machine using a driver, such as kvm, xhyve, or Hyper-V. Many people find value with Minishift, as it provides parameters for customizing settings such as disk size, CPU, and memory.

```
$ minishift start --cpus=2 --disk-size=20g --memory=2048
```

### or should I ?


If you want to check openshift ansible play https://github.com/openshift/openshift-ansible in "wild zoo" - probably, yes.

BUT, please note, that - 3.11 is latest release for V3. There will be no 3.12 

Openshift V4 will be installed with new concept called `installer`, check  https://github.com/openshift/installer/blob/master/docs/user/overview.md#installer-overview

Thus it will not be in scope of this repo anyway.

Ok, you were warned.


## Expectations

- Host with 16GB+ memory
- Oracle VirtualBox on host
- Vagrant 2+ on host
- Vagrant plugins `vagrant-hostmanager`, `vagrant-vbguest`

```
vagrant plugin  install vagrant-vbguest
vagrant plugin  install vagrant-hostsupdater
```

## OKD

OKD in operation - 3.11

- [OKD v3.11 (default)](https://github.com/openshift/origin/releases/tag/v3.11.0)

previous _might_ work

See Vagrantfile L19

```
OPENSHIFT_RELEASE = "3.11"
OPENSHIFT_ANSIBLE_BRANCH = "release-#{OPENSHIFT_RELEASE}"
```

## vagrant up

Vagrant spins-up 3 VMs in `NETWORK_BASE` subnet.


| VM Node | Private IP | Roles |
| --- | --- | --- |
| master | #{NETWORK_BASE}.101 | node, master, etcd |
| node01 | #{NETWORK_BASE}.102 | node |
| node02 | #{NETWORK_BASE}.103 | node |


```bash
vagrant up
vagrant provision --provision-with master-key,node01-key,node02-key
vagrant ssh master \
      -c 'ansible-playbook /home/vagrant/openshift-ansible/playbooks/prerequisites.yml &&
          ansible-playbook /home/vagrant/openshift-ansible/playbooks/deploy_cluster.yml'
```

alternatively,

```bash
$ ./okd-setup.sh
```

### OpenShift Web Console

should be available at https://master.openshift.local:8443/
The default login account is **admin/password**

(default login is configured in `ansible-hosts` L27)

```
openshift_master_htpasswd_users={'admin': '$apr1$ZZPMRUz8$/uqRbAFgpDjm0cirIS6S11'}
```
