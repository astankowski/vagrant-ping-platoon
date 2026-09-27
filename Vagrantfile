Vagrant.configure("2") do |config|
  # Use the community-built Alpine box which natively supports Vagrant networking
  config.vm.box = "generic/alpine319"
  
  # Explicitly tell Vagrant to use its Alpine Linux internal scripts
  config.vm.guest = :alpine 

  # Disable the default synced folder. 
  config.vm.synced_folder ".", "/vagrant", disabled: true

  (1..15).each do |i|
    vm_name = "node#{i}"
    vm_ip = "192.168.56.#{100 + i}"

    config.vm.define vm_name do |node|
      node.vm.hostname = vm_name
      node.vm.network "private_network", ip: vm_ip

      node.vm.provider "virtualbox" do |vb|
        vb.name = "ping_test_#{vm_name}"
        # 128MB is perfect for Alpine! 15 nodes will use less than 2GB total.
        vb.memory = 128
        vb.cpus = 1
        vb.gui = false
        
        # Ensure the virtual network cable registers as connected
        vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
      end
    end
  end

  # ==========================================
  # Monitoring Node with ntopng Dashboard
  # ==========================================
  config.vm.define "monitor" do |node|
    node.vm.hostname = "monitor"
    node.vm.network "private_network", ip: "192.168.56.200"
    node.vm.network "forwarded_port", guest: 3000, host: 3000

    node.vm.provider "virtualbox" do |vb|
      vb.name = "ping_test_monitor"
      vb.memory = 1024
      vb.cpus = 1
      vb.gui = false

      # Put private network (adapter 2) into promiscuous mode to capture all node-to-node packets
      vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
      vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
    end

    # Provision Docker, Redis, and ntopng on Alpine base image
    node.vm.provision "shell", inline: <<-SHELL
      echo "=== Installing Docker & Monitoring Stack ==="
      apk update
      apk add docker
      rc-service docker start
      rc-update add docker boot

      # Wait for Docker daemon socket to be ready
      echo "Waiting for Docker daemon..."
      while ! docker info >/dev/null 2>&1; do
        sleep 1
      done

      # Clean up any existing instances on re-provision
      docker rm -f redis ntopng >/dev/null 2>&1 || true

      # Start Redis (required as ntopng state backend)
      docker run -d --name redis --restart always --network host redis:alpine

      # Start ntopng listening on eth1 (private network adapter)
      docker run -d --name ntopng --restart always --network host \
        ntop/ntopng:latest \
        -i eth1 \
        -w 3000 \
        -r 127.0.0.1:6379 \
        -m "192.168.56.0/24" \
        --community
      echo "=== ntopng is ready on port 3000 ==="
    SHELL
  end
end

