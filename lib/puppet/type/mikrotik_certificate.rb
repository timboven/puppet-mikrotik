require 'openssl'

Puppet::Type.newtype(:mikrotik_certificate) do
  apply_to_all

  ensurable do
    defaultvalues
    defaultto(:present)
  end

  newparam(:name) do
    desc 'name of the certificate'
    isnamevar
  end

  newparam(:certificate) do
    desc 'certificate file'
    isrequired
  end

  newparam(:private_key) do
    desc 'private key file'
  end

  newparam(:private_key_passphrase) do
    desc 'private key password'
  end

  newproperty(:fingerprint) do
    desc 'certificate fingerprint'
    def value
      if @value.nil?
        cert = OpenSSL::X509::Certificate.new(resource[:certificate])
        OpenSSL::Digest::SHA256.hexdigest(cert.to_der)
      else
        super
      end
    end
  end

  newproperty(:has_private_key) do
    desc 'does this cert have an associated key?'
  end
 
end