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
  end
end
