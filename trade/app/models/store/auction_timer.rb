module Store
  class AuctionTimer

    SELL_BONUS = 0.05 unless defined? SELL_BONUS

    # public for testing
    attr_accessor :check_interval, :last_refresh, :check_thread

    def initialize
      self.check_interval = 10 # 10 seconds
      self.last_refresh = Time.now
    end

    # create new AuctionTimer with a timeout
    def self.timed(time)
      at = AuctionTimer.new
      at.check_interval = time
      at
    end

    # start governing trader's credits
    def start
      Thread.abort_on_exception = true
      self.last_refresh = Time.now

      self.check_thread = Thread.new {
        while true do
          if Time.now - self.last_refresh >= self.check_interval
            AuctionTimer.check_auctions
            self.last_refresh = Time.now
          end

          sleep 1
        end
      }
      self
    end

    # stop governing user's credits
    def stop
      self.check_thread.kill if self.check_thread
    end

    class << self
      # all credits get reduced in a special time interval
      def check_auctions
        Store::Item.allFixed.each{|item|
          if !item.end_time.nil? and item.end_time<=DateTime.now
            item.deactivate
          end

        }
        Store::Item.allAuction_of_active_users.each{ |item|
          if item.end_time <= DateTime.now
            finish_auction item
          end

        }
      end

      def finish_auction(item)
        seller = item.owner
        buyer = item.current_winner

        if buyer == nil || item.current_selling_price == nil
          item.deactivate
          return
        end

        item.price = item.current_selling_price
        # unfreeze money
        buyers_bid = item.bidders[buyer]
        buyer.credits += buyers_bid

        purchase = Purchase.create(item, item.quantity, seller, buyer)
        purchase.prepare
        purchase.confirm

        Analytics::PurchaseActivity.successful(purchase).log
      end
    end
  end
end