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
      @@suspended_users.delete_if { |user, suspend_time|
        if Time.now >= suspend_time + SUSPEND_TIMEOUT
          puts "Deleting user #{user}"
          User.by_name(user).delete
          true
        else
          false
        end
      }
    end

    def self.suspend_user(user)
      @@suspended_users[user.name] = Time.now
    end
  end
end