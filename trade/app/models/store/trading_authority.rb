module Store
  class TradingAuthority
    CREDIT_REDUCE_RATE = 0.05
    SELL_BONUS = 0.05

    attr_accessor :credit_reduce_time, :last_refresh, :reduce_thread

    def initialize
      self.credit_reduce_time = 60
      self.last_refresh = Time.now
    end

    def self.timed(time)
      ta = TradingAuthority.new
      ta.credit_reduce_time = time
      return ta
    end

    def start
      Thread.abort_on_exception = true
      self.last_refresh = Time.now

      self.reduce_thread = Thread.new {
        while true do
          if Time.now - self.last_refresh >= self.credit_reduce_time
            self.swing_hammer_of_doom
            self.last_refresh = Time.now
          end

          sleep 1
        end
      }
      self
    end

    # all credits get reduced in a special time interval
    def swing_hammer_of_doom
      all_users = SystemUser.all
      all_users.each{|user| self.reduce_credits(user) }
      puts "Swung hammer of doom"
    end

    # reduce credit of each user
    def reduce_credits(user)
      user.credits -= Integer(user.credits * CREDIT_REDUCE_RATE)
    end
  end
end