require 'openssl'
require 'yaml'

#
# We need this to be able to SSH encrypt larger messages. Since SSH encryption suffers from not being able to
# encrypt larger sets of data. Inspired by: http://stuff-things.net/2008/02/05/encrypting-lots-of-sensitive-data-with-ruby-on-rails/
#

module DTK
  class SSHCipher

    def self.decrypt_sensitive(encrypted_data, encrypted_key, encrypted_iv)
      if encrypted_data
        private_key = OpenSSL::PKey::RSA.new(File.read(R8::Config[:arbiter][:ssh][:remote][:private_key]),'')
        cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
        cipher.decrypt
        cipher.key = private_key.private_decrypt(encrypted_key)
        cipher.iv = private_key.private_decrypt(encrypted_iv)

        decrypted_data = cipher.update(encrypted_data)
        decrypted_data << cipher.final

        YAML.load(decrypted_data)
      else
        ''
      end
    end

    private

    def self.encrypt_sensitive(message)
      plain_data = message.to_yaml
      if !plain_data.empty?
        public_key = OpenSSL::PKey::RSA.new(File.read(R8::Config[:arbiter][:ssh][:remote][:private_key]),'').public_key
        cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
        cipher.encrypt
        cipher.key = random_key = cipher.random_key
        cipher.iv = random_iv = cipher.random_iv

        encrypted_data = cipher.update(plain_data)
        encrypted_data << cipher.final

        encrypted_key =  public_key.public_encrypt(random_key)
        encrypted_iv = public_key.public_encrypt(random_iv)

        [encrypted_data, encrypted_key, encrypted_iv]
      end
    end
  end
end