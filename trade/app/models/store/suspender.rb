require 'rufus/scheduler'

module Store
  class Suspender
    SUSPEND_TIMEOUT = 10
    @@suspended_users = {}

    def self.timed(frequency)
      scheduler = Rufus::Scheduler.start_new
      scheduler.every frequency do
        check_suspended_users
      end
    end

    def self.check_suspended_users
      @@suspended_users.delete_if { |username, suspend_time|
        if Time.now >= suspend_time + SUSPEND_TIMEOUT
          puts "Deleting user #{username}"
          User.by_name(username).delete
          true
        else
          false
        end
      }
    end

    def self.suspend_user(user)
      puts "Suspending user #{user.name}"
      @@suspended_users[user.name] = Time.now
    end

    def self.release_suspension_of(user)
      if @@suspended_users.has_key? user.name
        puts "Releasing suspension of user #{user.name}"
        @@suspended_users.delete user.name
      end
    end
  end
end