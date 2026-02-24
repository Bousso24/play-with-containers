Vagrant.configure("2") do |config|
config.vm.synced_folder ".", "/vagrant", type: "rsync"

config.vm.box = "generic/ubuntu2004"

require 'dotenv'
Dotenv.load('.env')

config.vm.provider "libvirt" do |lv|
    lv.memory = "2048"
    lv.cpus = 2
    end

# ============================================================================
  # VM 1 : API GATEWAY
  # ============================================================================
  config.vm.define "api-gateway" do |gateway|
    gateway.vm.hostname = "api-gateway"

    #configure network
    gateway.vm.network "forwarded_port", guest: 8080, host: 8080 # API Gateway Port

    #resource allocation
    gateway.vm.provider "libvirt" do |lv|
      lv.memory = "2048"
      lv.cpus = 2
      lv.storage :file, size: "20G"

    end

    #provisioning script
    gateway.vm.provision "shell", path: "scripts/provision.sh", args: ["gateway"]
  end

   # ============================================================================
  # VM 2 : INVENTORY APP
  # ============================================================================
    config.vm.define "inventory-app" do |inventory|
    inventory.vm.hostname = "inventory-app"

    #configure network
    inventory.vm.network "forwarded_port", guest: 5001, host: 5001 # Inventory App Port
    inventory.vm.network "forwarded_port", guest: 5432, host: 5432 # MongoDB Port

    #resource allocation, Configuration libvirt spécifique pour cette VM
    inventory.vm.provider "libvirt" do |lv|
      lv.memory = "1024"
      lv.cpus = 1
    end

    #provisioning script
    inventory.vm.provision "shell", path: "scripts/provision.sh", args: ["inventory"]
  end

  # ============================================================================
  # VM 3 : BILLING APP
  # ============================================================================
    config.vm.define "billing-app" do |billing|
    billing.vm.hostname = "billing-app"

    #configure network
    # billing.vm.network "forwarded_port", guest: 5002, host: 5002 # Billing App Port
    billing.vm.network "forwarded_port", guest: 5432, host: 5432 # MongoDB Port
    billing.vm.network "forwarded_port", guest: 5672, host: 5672 # RABBITMQ Port

    #resource allocation, Configuration libvirt spécifique pour cette VM
    billing.vm.provider "libvirt" do |lv|
      lv.memory = "1024"
      lv.cpus = 1
    end

    #provisioning script
    billing.vm.provision "shell", path: "scripts/provision.sh", args: ["billing"]
  end
end 