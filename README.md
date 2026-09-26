# Vagrant Network Test Environment

This environment spins up 15 minimal Alpine Linux 3.19 virtual machines (node1 through node15) to test internal network traffic and routing.



## Setup

Install vagrant on your host machine: [Install Vagrant](https://developer.hashicorp.com/vagrant/tutorials/get-started/install)

Install VirtualBox on your host machine: [Install VirtualBox](https://www.virtualbox.org/wiki/Downloads)

## Commands

```bash
cd vagrant-ping-platoon # location of config files
vagrant up # builds all 15 VMs defined in Vagrantfile
vagrant destroy -f # deletes all VMs
```

## Network Testing

To run the automated ping sweep across all 15 nodes (IPs `192.168.56.101` to `192.168.56.115`):

**Linux / macOS / Git Bash:**
```bash
chmod +x ping_test.sh
./ping_test.sh
```

## SSH connection

The environment uses Vagrant's securely generated private keys rather than password authentication. 

```bash
# Recommended: Connect directly using the Vagrant node name
vagrant ssh node1

# Alternative: Connect manually via standard SSH
ssh -i .vagrant/machines/node1/virtualbox/private_key vagrant@192.168.56.101
```
