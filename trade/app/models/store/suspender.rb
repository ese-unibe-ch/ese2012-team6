require 'rufus/scheduler'

module Store
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

      def suspend_user(user)
        puts "Suspending user #{user.name}"
        self.suspended_users[user.name] = Time.now
      end

      def release_suspension_of(user)
        if self.suspended_users.has_key? user.name
          puts "Releasing suspension of user #{user.name}"
          user.state = :active
          self.suspended_users.delete user.name
        end
      end
    end

    @suspended_users = {}
  end
end