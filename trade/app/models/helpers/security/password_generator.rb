module Security
  # provides a method to generate save passwords
  class PasswordGenerator
    # generate a new save password which is 16 characters long
    def self.generate_new_password
      length = 16
      rand(36**length).to_s(36)
    end
  end
end