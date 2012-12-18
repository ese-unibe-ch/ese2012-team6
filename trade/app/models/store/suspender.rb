require 'rufus/scheduler'

module Store
  # The Suspender is responsible for suspending users. It keeps track of suspended users and will also
  # allow suspensions to be lifted. Suspender will delete users after a predefined period of time
  class Suspender
    SUSPEND_TIMEOUT = 10

    class << self
      attr_accessor :suspended_users

      def timed(frequency)
        scheduler = Rufus::Scheduler.start_new
        scheduler.every frequency do
          check_suspended_users
        end
      end

      def check_suspended_users
        self.suspended_users.delete_if { |username, suspend_time|
          if Time.now >= suspend_time + SUSPEND_TIMEOUT
            puts "Deleting user #{username}"
            User.by_name(username).delete
            true
          else
            false
          end
        }
      end

      # suspend a user
      def suspend_user(user)
        puts "Suspending user #{user.name}"
        self.suspended_users[user.name] = Time.now
      end

      # release suspension of a user
      def release_suspension_of(user)
        if self.suspended_users.has_key? user.name
          puts "Releasing suspension of user #{user.name}"
          self.suspended_users.delete user.name
        end
      end
    end

    @suspended_users = {}
  end
end