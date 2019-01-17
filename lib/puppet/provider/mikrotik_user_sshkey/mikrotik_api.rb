require 'puppet/provider/mikrotik_api'
require 'net/scp'

Puppet::Type.type(:mikrotik_user_sshkey).provide(:mikrotik_api, :parent => Puppet::Provider::Mikrotik_Api) do
  confine :feature => :mtik
  
  mk_resource_methods

  def self.instances
    ssh_keys = Puppet::Provider::Mikrotik_Api::get_all("/user/ssh-keys")
    instances = ssh_keys.collect { |ssh_key| sshKey(ssh_key) }
    instances
  end

  def self.sshKey(data)
    new(
      :ensure     => :present,
      :name       => data['user'],
      :public_key => data['public_key']
    )
  end

  def flush
    Puppet.debug("Flushing User SSH Key #{resource[:name]}")

    if resource[:ensure] == :present
      params = {}
      params["user"] = resource[:name]
      params["public-key-file"] = resource[:name] + "_ssh_key"

      lookup = {}
      lookup["user"] = resource[:name]

      Puppet.debug("Params: #{params.inspect} - Lookup: #{lookup.inspect}")

      c = self.class.transport.connection
      data = StringIO.new(resource[:public_key])
      path = resource['name'] + "_ssh_key"
      Net::SCP.upload!(c.host,c.user,data,path,ssh: {password: c.pass})

      result = Puppet::Provider::Mikrotik_Api::command("/user/ssh-keys/import", params)
    else
      # TODO Fix removing keys
      # result = Puppet::Provider::Mikrotik_Api::command("/user/ssh-keys/import", params)
    end
  end  
end
