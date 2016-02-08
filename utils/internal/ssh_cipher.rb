#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'openssl'
require 'base64'
require 'yaml'

#
# We need this to be able to SSH encrypt larger messages. Since SSH encryption suffers from not being able to
# encrypt larger sets of data. Inspired by: http://stuff-things.net/2008/02/05/encrypting-lots-of-sensitive-data-with-ruby-on-rails/
#

module DTK
  class SSHCipher

    def self.encrypt_password(plain_text_password)
      return nil unless plain_text_password
      public_key = OpenSSL::PKey::RSA.new(File.read(R8::Config[:encryption][:tenant][:private_key])).public_key
      Base64.encode64(public_key.public_encrypt(plain_text_password))
    end

    def self.decrypt_password(hashed_password)
      return nil unless hashed_password
      private_key = OpenSSL::PKey::RSA.new(File.read(R8::Config[:encryption][:tenant][:private_key]))
      private_key.private_decrypt(Base64.decode64(hashed_password))
    end

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