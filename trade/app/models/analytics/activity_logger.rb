require 'rbtree'
require 'require_relative'
require_relative '../helpers/time/time_helper'

module Analytics
  # Responsible for storing activities and performing operations (e.g sorting) on said activities
  class ActivityLogger

    @@activities = RBTree.new
    @@last_id = 0

    # clear all logged activities
    def self.clear
      @@activities.clear
      @@last_id = 0
    end

    # log an activity
    def self.log(activity)
      @@last_id += 1
      activity.id = @@last_id
      @@activities[activity.id] = activity
    end

    # get all stored activities in descending order by timestamp (more recent come first)
    def self.get_all_activities
      @@activities.values.reverse
    end

    # retrieve activity by id
    def self.by_id(id)
      @@activities[id]
    end

    # get the previous description of an item
    # returns empty string if no previous description was found
    def self.get_previous_description(item)
      activities = @@activities.values
      edit_activities = activities.select { |act| act.type == :ITEM_EDIT && act.item_id == item.id }

      most_recent_activity = nil
      most_recent_timestamp = Time.utc(2000, "jan", 1, 20, 15, 1)

      edit_activities.each { |activity|
        if activity.timestamp > most_recent_timestamp
          most_recent_activity = activity
          most_recent_timestamp = activity.timestamp
        end
      }

      return "" if most_recent_activity.nil?
      return most_recent_activity.old_values[:description]
    end

    # get a list of most recent buy activities
    def self.get_most_recent_purchases(amount)
      activities = @@activities.values
      buy_activities = activities.select { |act| act.type == :ITEM_BUY }
      buy_activities = buy_activities.select { |act| act.success == true }
      sorted = buy_activities.sort! { |a, b| b.id <=> a.id }
      sorted[0..amount-1]
    end

    def self.get_transaction_statistics_of_last(time_str)
      timeframe = Time.from_string time_str
      purchases = @@activities.values.select { |act| act.type == :ITEM_BUY && act.success == true }
      purchases_in_time = purchases.select {|act| act.timestamp > Time.now - timeframe}
      activity_count = purchases_in_time.length
      total_credits = 0
      purchases_in_time.each {|act| total_credits += act.price}

      return activity_count, total_credits
    end
  end
end
