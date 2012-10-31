module Analytics
  # Responsible for storing activities and performing operations (e.g sorting) on said activities
  class ActivityLogger

    @@activities = {}

    # clear all logged activities
    def self.clear
      @@activities.clear
    end

    # log an activity
    def self.log(activity)
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
    def self.get_previous_description(item)
      activities = @@activities.values
      edit_activities = activities.select { |act| act.type == ActivityType::ITEM_EDIT && act.item_id == item.id }

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
      buy_activities = activities.select { |act| act.type == ActivityType::ITEM_BUY }
      buy_activities = buy_activities.select { |act| act.success == true }
      sorted = buy_activities.sort! { |a, b| b.timestamp <=> a.timestamp }
      sorted[0..amount-1]
    end
  end
end
