require 'rubygems'
require 'rand62'

module Security
  # provides a method to generate save passwords
  class PasswordGenerator
    # generate a new save password which is 8 characters long
    def self.generate_new_password
      random_string = Rand62.safe(8)
    end
  end
end