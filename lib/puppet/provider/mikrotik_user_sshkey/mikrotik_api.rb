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
    Puppet.debug("Creating User SSH Key " + data.inspect)

    new(
      :ensure     => :present,
      :user       => data['user'],
      :public_key => data['public_key']
    )
  end

  def flush
    Puppet.debug("Flushing User SSH Key #{resource[:name]}")
    Puppet.debug("Original values = " + @original_values.inspect )

    if resource[:ensure] == :present and @original_values.empty?
      params = {}
      params["user"] = resource[:user]
      params["public-key-file"] = resource[:name] + "_ssh_key"

      lookup = {}
      lookup["user"] = resource[:name]
      lookup["public_key"] = resource[:public_key]

      Puppet.debug("Params: #{params.inspect} - Lookup: #{lookup.inspect}")

      id = Puppet::Provider::Mikrotik_Api::lookup_id("/usr/ssh-keys/getall", lookup)

      c = self.class.transport.connection
      data = StringIO.new(resource[:content])
      path = resource['name'] + "_ssh_key"
      Net::SCP.upload!(c.host,c.user,data,path,ssh: {password: c.pass})

      result = Puppet::Provider::Mikrotik_Api::command("/user/ssh-keys/import", params)
    else
      # TODO Fix removing keys
      # result = Puppet::Provider::Mikrotik_Api::command("/user/ssh-keys/import", params)
    end
  end  
end
