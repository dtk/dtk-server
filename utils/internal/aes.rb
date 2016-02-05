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

# This part of the code has been taken from:
# http://www.brentsowers.com/2007/12/aes-encryption-and-decryption-in-ruby.html
# this is to avoid using a gem for encryption and code is to be used for cookie encryption

module AESCrypt
  # Decrypts a block of data (encrypted_data) given an encryption key
  # and an initialization vector (iv).  Keys, iv's, and the data
  # returned are all binary strings.  Cipher_type should be
  # "AES-256-CBC", "AES-256-ECB", or any of the cipher types
  # supported by OpenSSL.  Pass nil for the iv if the encryption type
  # doesn't use iv's (like ECB).
  #:return: => String
  #:arg: encrypted_data => String
  #:arg: key => String
  #:arg: iv => String
  #:arg: cipher_type => String
  def self.decrypt(encrypted_data, key, iv = nil, cipher_type = 'AES-256-CBC')
    aes = OpenSSL::Cipher::Cipher.new(cipher_type)
    aes.decrypt
    aes.key = key
    aes.iv = iv unless iv.nil?
    aes.update(encrypted_data) + aes.final
  end

  # Encrypts a block of data given an encryption key and an
  # initialization vector (iv).  Keys, iv's, and the data returned
  # are all binary strings.  Cipher_type should be "AES-256-CBC",
  # "AES-256-ECB", or any of the cipher types supported by OpenSSL.
  # Pass nil for the iv if the encryption type doesn't use iv's (like
  # ECB).
  #:return: => String
  #:arg: data => String
  #:arg: key => String
  #:arg: iv => String
  #:arg: cipher_type => String
  def self.encrypt(data, key, iv = nil, cipher_type = 'AES-256-CBC')
    aes = OpenSSL::Cipher::Cipher.new(cipher_type)
    aes.encrypt
    aes.key = key
    aes.iv = iv unless iv.nil?
    aes.update(data.to_s) + aes.final
  end
end