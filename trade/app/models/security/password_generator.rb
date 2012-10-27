require 'rand62'

module Security
  class PasswordGenerator

    def generate_new_password
      random_string = Rand62.safe(8)
      user.pwd_hash = BCrypt::Engine.hash_secret(random_string, user.pwd_salt)
    end

  end
end