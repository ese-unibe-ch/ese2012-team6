require 'date'
require 'require_relative'
require_relative '../security/string_checker'
class Time
  def to_datetime
    # Convert seconds + microseconds into a fractional number of seconds
    seconds = sec + Rational(usec, 10**6)

    # Convert a UTC offset measured in minutes to one measured in a
    # fraction of a day.
    offset = Rational(utc_offset, 60 * 60 * 24)
    DateTime.new(year, month, day, hour, min, seconds, offset)
  end

  def self.from_string(time_str)
    if Security::StringChecker.matches_regex?(time_str, /\d+[smhd]/)
      match = time_str.scan(/(\d+)([smhd])/)
      amount = match[0][0].to_i
      unit = match[0][1]

      seconds = amount
      case unit
        when 's'
          seconds *= 1
        when 'm'
          seconds *= 60
        when 'h'
          seconds *= 60*60
        when 'd'
          seconds *= 60*60*24
      end

      seconds
    end
  end
end