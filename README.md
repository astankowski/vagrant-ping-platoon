# Vagrant Network Test Environment

This environment spins up 15 minimal Alpine Linux 3.19 virtual machines (node1 through node15) to test internal network traffic and routing.

<img width="2296" height="1112" alt="Zrzut ekranu 2026-09-26 131017" src="https://github.com/user-attachments/assets/3795867c-42b9-49c7-a336-358d8350213d" />


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

## Network Visualization (ntopng Dashboard)

A dedicated `monitor` VM (`192.168.56.200`) is configured with promiscuous mode to passively capture all packet exchanges across `192.168.56.0/24`.

1. **Start the monitor node:**
   ```bash
   vagrant up monitor
   ```
2. **Access the Dashboard:**
   Open [http://localhost:3000](http://localhost:3000) in your browser.
   - Default login: `admin` / `admin` (prompts for new password on first login).
3. **View Visuals:**
   - **Maps $\rightarrow$ Hosts Matrix / Chord Diagram:** Interactive visual graph of all 15 nodes and their communication links.
   - **Flows $\rightarrow$ Live Flows:** Real-time stream of all transactions, packet counts, protocols, and latency.

## Fault Injection & Disruption Testing

Simulate network outages, packet drops, and active DoS attacks on any node using disrupt.sh.

### Syntax

```bash
chmod +x disrupt.sh
./disrupt.sh <target_node> <duration_seconds> [method] [source_node]
```

### Disruption Methods

| Method | Description | Target Behavior | Recovery |
| :--- | :--- | :--- | :--- |
| `drop` *(default)* | Mutes ICMP responses via kernel `sysctl` (`net.ipv4.icmp_echo_ignore_all=1`). | Node stays online; SSH works, but pings fail. | Automatically re-enables pings after timer expires. |
| `cable` | Disconnects the virtual network cable on adapter 2 (private network) via VirtualBox. | Complete network isolation from the `192.168.56.0/24` subnet. | Automatically reconnects the virtual cable after timer expires. |
| `flood` | Launches a high-rate ICMP flood (`ping -f -s 1400`) from `source_node` to `target_node`. | Saturates the target's link, inducing latency and packet drop. | Automatically terminates the flood when duration ends. |

### Examples

```bash
# 1. Silent Ping Drop: node3 ignores pings for 20 seconds
./disrupt.sh node3 20

# 2. Virtual Cable Disconnect: node5 unplugged for 30 seconds
./disrupt.sh node5 30 cable

# 3. Active DoS Flood: node1 floods node4 for 15 seconds
./disrupt.sh node4 15 flood node1
```

### Observing Attacks in ntopng

1. Start your test nodes and monitor:
   ```bash
   vagrant up
   ```
2. Open the **ntopng dashboard** at [http://localhost:3000](http://localhost:3000).
3. In a separate terminal, trigger a flood attack:
   ```bash
   ./disrupt.sh node4 20 flood node1
   ```
4. In ntopng:
   - Navigate to **Flows $\rightarrow$ Live Flows** to see the high-throughput ICMP stream.
   - Navigate to **Maps $\rightarrow$ Hosts Matrix / Chord Diagram** to see the active visual connection arc between `node1` and `node4`.
5. Run `./ping_test.sh` concurrently to verify packet loss and latency impact.

> [!NOTE]
> `disrupt.sh` includes automatic binary discovery for `vagrant.exe` and `VBoxManage.exe`, ensuring full compatibility across **Git Bash**, **WSL**, **macOS**, and **Linux**.



