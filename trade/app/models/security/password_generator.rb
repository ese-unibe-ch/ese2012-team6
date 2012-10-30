require 'rubygems'
require 'rand62'

module Security
  # provides a method to generate save passwords
  class PasswordGenerator
    # generate a new save password which is 8 characters long
    def self.generate_new_password
      length=10
      rand(36**length).to_s(36)
    end
  end
end