require 'rand62'

module Security
  class PasswordGenerator

    def self.generate_new_password(user)

      random_string = Rand62.safe(8)
      user.pwd_hash = BCrypt::Engine.hash_secret(random_string, user.pwd_salt)
      random_string
    end

  end
end