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
end
