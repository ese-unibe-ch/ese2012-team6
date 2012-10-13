module Analytics
  class ActivityLogger
    def self.log_activity(activity)
      database = Storage::Database.instance
      database.add_activity(activity)
    end

    def self.get_all_activities
      database = Storage::Database.instance
      activities = database.get_all_activities
      return activities
    end

    def self.by_id(id)
      database = Storage::Database.instance
      activity = database.get_activity_by_id(id)
      return activity
    end

    def self.get_previous_description(item)
      database = Storage::Database.instance
      activities = database.get_all_activities
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
      return most_recent_activity.old_values[2] #description
    end
  end
end
