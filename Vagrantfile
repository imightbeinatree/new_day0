Vagrant::Config.run do |config|
  org = "new_day_0"


  config.vm.box     = "cloudspace_default_12.04"
  config.vm.box_url = "http://vagrant.cloudspace.com.s3.amazonaws.com/cloudspace_ubuntu_12.04.box"
  # config.vm.boot_mode = :gui

  config.ssh.private_key_path = File.join(ENV['HOME'], '.ssh', 'cs_vagrant.pem')
  config.vm.network :hostonly, "33.33.33.70"
  config.vm.share_folder("v-root", "/srv/#{org}", ".", :nfs => true)
  
  config.vm.customize ["modifyvm", :id, "--memory", "1024", "--name", "New Day 0","--cpus", "2"]
  
  config.vm.provision :chef_solo do |chef|

    chef.node_name = "#{org}_vagrant_#{ENV['USER']}"

    chef.cookbooks_path = "cloudspace_cookbooks"
    chef.add_recipe "ubuntu"
    chef.add_recipe "postgresql::server"
    chef.add_recipe "postfix"
    chef.add_recipe "nodejs"

    chef.json = {
      :postgresql => {
        :password => {
          :postgres => ''
        },
        :pg_hba => [
          {:comment => '# User For Rails Development', :type => 'host', :db => 'all', :user => 'all', :addr => "localhost", :method => 'trust'}]
      }, :postfix => {
        :mydomain => '#{org}.com'
      },
      :nodejs => {
        :install_method => 'source'
      }
    }

  end
end
