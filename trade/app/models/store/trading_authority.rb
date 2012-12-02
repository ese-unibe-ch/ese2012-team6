require_relative '../store/item'
module Store

  # Governs all trading users and watches over user's credits. Swings hammer of doom once every day and reduces
  # user's credits by a certain percentage. Handles user's credits after item trade
  class TradingAuthority

    # public for testing
    class << self
      attr_accessor :credit_reduce_time, :last_refresh, :reduce_thread, :credit_reduce_rate, :sell_bonus
    end

    @sell_bonus=5
    @credit_reduce_rate = 5
    @credit_reduce_time = 60*60*24

    # create new TradingAuthority with a timeout
    def self.timed(time)
      @credit_reduce_time = time
    end

    # start governing trader's credits
    def self.start
      Thread.abort_on_exception = true
      self.last_refresh = Time.now

      self.reduce_thread = Thread.new {
        while true do
          if Time.now - self.last_refresh >= self.credit_reduce_time
            puts "swing hammer of doom"
            TradingAuthority.swing_hammer_of_doom
            self.last_refresh = Time.now
          end

          sleep 1
        end
      }
      self
    end

    # stop governing user's credits
    def self.stop
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
        user.credits -= Integer(user.credits * @credit_reduce_rate*0.01)
      end

      # update seller's and buyer's credits according to item pricing and sell bonus
      def settle_item_purchase(seller, item, quantity = 1)
        seller.credits += item.price * quantity + Integer((item.price * quantity * @sell_bonus*0.01).ceil)
      end
    end
  end
end