module Analytics
  class ActivityLogger
    @@activities = {}

    def self.log(activity)
      @@activities[activity.id] = activity
    end

    def self.get_all_activities
      return @@activities.values.sort! {|a,b| b.timestamp <=> a.timestamp}
    end

    def self.by_id(id)
      return @@activities[id]
    end

    def self.get_previous_description(item)
      activities = @@activities.values
      edit_activities = activities.select{|act| act.type == ActivityType::ITEM_EDIT && act.item_id == item.id}

      most_recent_activity = nil
      most_recent_timestamp = Time.utc(2000,"jan",1,20,15,1)

      edit_activities.each { |activity|
        if activity.timestamp > most_recent_timestamp
          most_recent_activity = activity
          most_recent_timestamp = activity.timestamp
        end
      }

      return "" if most_recent_activity.nil?
      return most_recent_activity.old_values[:description]
    end

    def self.get_most_recent_purchases(amount)
      activities = @@activities.values
      buy_activities = activities.select{|act| act.type == ActivityType::ITEM_BUY}
      buy_activities = buy_activities.select{|act| act.success == true}
      sorted = buy_activities.sort! { |a,b| b.timestamp <=> a.timestamp }
      return sorted[0..amount-1]
    end
  end
end
