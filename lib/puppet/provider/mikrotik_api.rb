require 'puppet/util/network_device/mikrotik'
require 'puppet/util/network_device/transport/mikrotik'

require 'mtik'

class Puppet::Provider::Mikrotik_Api < Puppet::Provider
  def self.prefetch(resources)
    nodes = instances
    resources.keys.each do |name|
      if provider = nodes.find { |node| node.name == name }
        resources[name].provider = provider
      end
    end
  end

  def self.transport
    if Puppet::Util::NetworkDevice.current
      # we are in `puppet device`
      Puppet::Util::NetworkDevice.current.transport
    else
      # we are in `puppet resource`
      Puppet::Util::NetworkDevice::Transport::Mikrotik.new(Facter.value(:url))
    end
  end

  def self.connection
    transport.connection
  end
  
  def self.get_all(path)
    Puppet.debug("Retrieving Config #{path}")
    
    objects = connection.get_reply("#{path}/getall")
    
    result = []
    objects.each do |object| 
      Puppet.debug("Object: #{object}")        
      
      if object.key?('!re')
        result << object.reject { |k, v| ['!re', '.tag'].include? k  }
      end
    end
    result
  end
  
  def self.set(path, params_hash)
    Puppet.debug("Storing Config #{path}: #{params_hash.inspect}")
    
    params = []
    params << params_hash.collect { |k,v| "=#{k}=#{v}" }
    #Puppet.debug("Params: #{params.inspect}")
    
    result = connection.get_reply("#{path}/set", *params)    # .id => ?.id ???
    
    Puppet.debug("Set Result: #{result}")        
    # => [{"!done"=>nil, ".tag"=>"5"}]
    # TODO will raise an exception on fail?
  end
  
  def self.add(path, params_hash)
    Puppet.debug("Creating Config #{path}: #{params_hash.inspect}")
    
    params = []
    params << params_hash.collect { |k,v| "=#{k}=#{v}" }
    #Puppet.debug("Params: #{params}")
    
    result = connection.get_reply("#{path}/add", *params)
    
    Puppet.debug("Add Result: #{result}")
    # => [{"!done"=>nil, ".tag"=>"5"}]
    # TODO will raise an exception on fail?
  end

  def self.remove(path, params_hash)
    Puppet.debug("Removing Config #{path}: #{params_hash.inspect}")
    
    params = []
    params << params_hash.collect { |k,v| "=#{k}=#{v}" }
    
    result = connection.get_reply("#{path}/remove", *params)
    #Puppet.debug("Params: #{params}")
    
    Puppet.debug("Remove Result: #{result}")    
    # => [{"!done"=>nil, ".tag"=>"5"}]
    # TODO will raise an exception on fail?
  end

  def initialize(value = {})
    super(value)
    
    if value.is_a? Hash
      @original_values = value.clone
    else
      @original_values = {}
    end
    
    @property_flush = {}
  end
  
  def exists?
    @property_hash[:ensure] == :present
  end
  
  def create
    @property_flush[:ensure] = :present
  end
  
  def destroy        
    @property_flush[:ensure] = :absent
  end
  
  def simple_flush(path, params, lookup)  
    #Puppet.debug("simple_flush(#{path}, #{params.inspect}, #{lookup.inspect})")
    
    # create
    if @property_flush[:ensure] == :present
      Puppet.debug("Creating #{path}")
      
      result = Puppet::Provider::Mikrotik_Api::add(path, params)
    end
  
    # destroy
    if @property_flush[:ensure] == :absent
      Puppet.debug("Deleting #{path}")
      
      id_list = Puppet::Provider::Mikrotik_Api::lookup_id(path, lookup)
      id_list.each do |id|
        id_lookup = { ".id" => id } 
        result = Puppet::Provider::Mikrotik_Api::remove(path, id_lookup)
      end      
    end      
    
    # update
    if @property_flush.empty?
      Puppet.debug("Updating #{path}")
        
      id_list = Puppet::Provider::Mikrotik_Api::lookup_id(path, lookup)
      id_list.each do |id|
        params = params.merge({ ".id" => id })
        result = Puppet::Provider::Mikrotik_Api::set(path, params)
      end
    end    
  end
  
  def self.lookup_id(path, lookup)
    id_list = []
      
    query_words = []
    query_words << lookup.collect { |k,v| "?#{k}=#{v}" }
    
    objects = connection.get_reply("#{path}/getall", *query_words)      
    objects.each do |object| 
      if object.key?('!re')
        id_list << object[".id"]
      end
    end      
    #Puppet.debug("ID list for #{path} with #{lookup.inspect}: #{id_list.inspect}")
      
    id_list
  end
end