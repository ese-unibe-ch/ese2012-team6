module Converter
  class TimeConverter
    def self.convert_seconds_to_string time_delta
      year = 31556926 # one year in seconds
      month = 2592000 # 30 days in seconds
      day = 86400 # one day in seconds
      hour = 3600 # one hour in seconds
      minute = 60

      seconds = time_delta

      before = false
      if seconds < 0
        before = true
        seconds = -seconds
      end

      if seconds >= year
        years = (seconds / year).floor
      else
        years = 0
      end

      year_seconds = years * year

      if seconds - year_seconds >= month
        months = ((seconds - year_seconds) / month).floor
      else
        months = 0
      end

      month_seconds = months * month

      if seconds - year_seconds - month_seconds >= day
        days = ((seconds - year_seconds - month_seconds) / day).floor
      else
        days = 0
      end

      day_seconds = days * day

      if seconds - year_seconds - month_seconds - day_seconds >= hour
        hours = ((seconds - year_seconds - month_seconds - day_seconds) / hour).floor
      else
        hours = 0
      end

      hour_seconds = hours * hour

      if seconds - year_seconds - month_seconds - day_seconds - hour_seconds >= minute
        minutes = ((seconds - year_seconds - month_seconds - day_seconds - hour_seconds) / minute).floor
      else
        minutes = 0
      end

      time_string = ""

      if years >= 2
        time_string = years.to_s + " years"
      elsif years == 1 && months >= 2
        time_string = "One year, " + months.to_s + " months"
      elsif years == 1 || months >= 10
        time_string = "One year"
      elsif months >= 2
        time_string = months.to_s + " months"
      elsif months == 1 && days >= 8
        time_string = "One month, " + days.to_s + " days"
      elsif months == 1 || days >= 25
        time_string = "One month"
      elsif days >=2
        time_string = days.to_s + " days"
      elsif days == 1 && hours >= 5
        time_string = "One day, " + hours.to_s + " hours"
      elsif days == 1 || hours >= 22
        time_string = "One day"
      elsif hours >=2
        time_string = hours.to_s + " hours"
      elsif hours == 1 || minutes >= 50
        time_string = "One hour"
      elsif minutes >=2
        time_string = minutes.to_s + " minutes"
      else
        time_string = seconds.to_s + " seconds"
      end

      if before
        time_string = time_string + " ago"
      end

      return time_string
    end
  end
end