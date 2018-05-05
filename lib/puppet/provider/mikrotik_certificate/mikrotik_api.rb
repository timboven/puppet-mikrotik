require 'puppet/provider/mikrotik_api'
require 'openssl'
require 'net/scp'

Puppet::Type.type(:mikrotik_certificate).provide(:mikrotik_api, :parent => Puppet::Provider::Mikrotik_Api) do
  confine :feature => :mtik

  mk_resource_methods

  def self.instances
    certs = Puppet::Provider::Mikrotik_Api::get_all("/certificate")
    certs.map {|data| cert(data) }
  end

  def self.cert(data)
    new(
      ensure: :present,
      name: data['name'],
      fingerprint: data['fingerprint'],
      has_private_key: data['private-key']
    )
  end

  def flush
    cert_filename = "#{resource[:name]}.crt"
    upload_data(resource[:certificate], cert_filename)
    self.class.import('file-name' => cert_filename)

    if !resource[:private_key].nil?
      key_filename = "#{resource[:name]}.key"
      upload_data(resource[:private_key],key_filename)
      if resource[:private_key_passphrase]
        self.class.import('file-name': key_filename, passphrase: resource[:private_key_passphrase])
      else
        self.class.import('file-name': key_filename)
      end
    end
  end


  def self.import(params_hash)
    Puppet.debug("Importing certificate: #{params_hash.inspect}")
    
    params = []
    params << params_hash.collect { |k,v| "=#{k}=#{v}" }
    
    result = connection.get_reply("/certificate/import", *params)
    Puppet.debug("Import Result: #{result}")
    result.each do |res|
      if res.key?('!trap')
        raise "Error while importing certificate: #{res['message']}"
      end
    end
  end

  def upload_data(data,filename)
    Puppet.debug("Uploading data to file #{filename}")
    c = self.class.transport.connection
    data = StringIO.new(data)
    path = filename
    Net::SCP.upload!(c.host,c.user,data,path,ssh: {password: c.pass})
  end

end