module Store

  # Governs all trading users and watches over user's credits. Swings hammer of doom once every day and reduces
  # user's credits by a certain percentage. Handles user's credits after item trade
  class TradingAuthority

    CREDIT_REDUCE_RATE = 0.05 unless defined? CREDIT_REDUCE_RATE
    SELL_BONUS = 0.05 unless defined? SELL_BONUS

    # public for testing
    attr_accessor :credit_reduce_time, :last_refresh, :reduce_thread

    def initialize
      self.credit_reduce_time = 24*60*60 # 24 Hours
      self.last_refresh = Time.now
    end

    # create new TradingAuthority with a timeout
    def self.timed(time)
      ta = TradingAuthority.new
      ta.credit_reduce_time = time
      ta
    end

    # start governing trader's credits
    def start
      Thread.abort_on_exception = true
      self.last_refresh = Time.now

      self.reduce_thread = Thread.new {
        while true do
          if Time.now - self.last_refresh >= self.credit_reduce_time
            TradingAuthority.swing_hammer_of_doom
            self.last_refresh = Time.now
          end

          sleep 1
        end
      }
      self
    end

    # stop governing user's credits
    def stop
      self.reduce_thread.kill if self.reduce_thread
    end

    class << self
      # all credits get reduced in a special time interval
      def swing_hammer_of_doom
        all_users = Trader.all
        all_users.each { |user| self.reduce_credits(user) }
      end

      # reduce credit of each user
      def reduce_credits(user)
        user.credits -= Integer(user.credits * CREDIT_REDUCE_RATE)
      end

      # update seller's and buyer's credits according to item pricing and sell bonus
      def settle_item_purchase(seller, buyer, item, quantity = 1)
        seller.credits += item.price * quantity + Integer((item.price * quantity * SELL_BONUS).ceil)
        buyer.credits -= item.price * quantity
      end
    end
  end
end