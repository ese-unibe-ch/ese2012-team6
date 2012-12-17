require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../../app/models/helpers/time/time_helper'

class TimeParserTest < Test::Unit::TestCase

  # this class is testing the functionality of parsing for time inputs

  def test_parse_seconds
    assert_equal(1, Time.from_string('1s'))
    assert_equal(60, Time.from_string('60s'))
  end

  def test_parse_minutes
    assert_equal(60, Time.from_string('1m'))
    assert_equal(120, Time.from_string('2m'))
  end

  def test_parse_hours
    assert_equal(3600, Time.from_string('1h'))
    assert_equal(36000, Time.from_string('10h'))
  end

  def test_parse_days
    assert_equal(3600*24, Time.from_string('1d'))
    assert_equal(3600*24*20, Time.from_string('20d'))
  end
end