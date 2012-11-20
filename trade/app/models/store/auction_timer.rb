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
        Store::Item.allAuction_of_active_users.each{ |item|
          if item.end_time <= DateTime.now
            finish_auction item
          end
        }
      end

      def finish_auction(item)
        seller = item.owner
        buyer = item.current_winner

        if buyer == nil || item.currentSellingPrice == nil
          item.deactivate
          return
        end

        seller.release_item(item)

        selling_price = item.currentSellingPrice
        buyers_bid = item.bidders[buyer]

        seller.credits += selling_price # + Integer((price * SELL_BONUS).ceil)

        item.deactivate
        buyer.attach_item(item)

        item.notify_change

        Analytics::ItemBuyActivity.with_buyer_item_price_success(buyer, item).log
      end
    end
  end
end