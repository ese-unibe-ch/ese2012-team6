require 'rubygems'
require 'rand62'

module Security
  class PasswordGenerator

    def self.generate_new_password
      random_string = Rand62.safe(8)
    end
  end
end