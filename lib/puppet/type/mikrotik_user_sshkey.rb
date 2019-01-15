Puppet::Type.newtype(:mikrotik_user_sshkey) do
  apply_to_all
  
  #ensurable
  ensurable do
    defaultto :present

    newvalue(:present) do
      provider.create
    end

    newvalue(:absent) do
      provider.destroy
    end

    newvalue(:enabled) do
      provider.create
      provider.setState(:enabled)
    end

    newvalue(:disabled) do
      provider.create
      provider.setState(:disabled)
    end

    def retrieve
      provider.getState
    end

    def insync?(is)
      @should.each { |should|
        case should
          when :present
            return (provider.getState != :absent)
          when :absent
            return (provider.getState == :absent)
          when :enabled
            return (provider.getState == :enabled)
          when :disabled
            return (provider.getState == :disabled)
        end
      }
    end
  end

  newparam(:user) do
    desc 'The user that the public key belongs to'
    isnamevar
  end

  newparam(:public_key) do
    desc 'The SSH public key (DSA/RSA)'
  end

  newproperty(:bits) do
    desc "Key length"
  end
end
