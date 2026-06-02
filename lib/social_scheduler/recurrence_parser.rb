require 'ice_cube'
require 'chronic'

module SocialScheduler
  class RecurrenceParser
    def initialize(input_string, options = {})
      @input = input_string.downcase
      @options = options
    end

    def parse
      # Extract just the time of day from the -t rule (e.g., "4pm")
      time_match = @input.match(/at\s+(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)/i)
      time_part = time_match ? time_match[1] : "12:00pm"

      # Build the exact start time
      if @options[:start]
        base_time = Chronic.parse("#{@options[:start]} at #{time_part}")
      else
        base_time = Chronic.parse(time_part) || Time.now
      end

      interval = 1
      if @input.include?("every other") || @input.include?("alternate") || @input.include?("alternating")
        interval = 2
      elsif @input.include?("every third") || @input.include?("every three")
        interval = 3
      end

      days = []
      days << :monday if @input.include?("monday")
      days << :tuesday if @input.include?("tuesday")
      days << :wednesday if @input.include?("wednesday")
      days << :thursday if @input.include?("thursday")
      days << :friday if @input.include?("friday")
      days << :saturday if @input.include?("saturday")
      days << :sunday if @input.include?("sunday")

      # Default to today's day if none specified
      days << Date.today.strftime("%A").downcase.to_sym if days.empty?

      schedule = IceCube::Schedule.new(base_time)
      rule = IceCube::Rule.weekly(interval).day(days)

      # Apply End Date Priorities
      limit_match = @input.match(/(\d+)\s+times/)
      until_match = @input.match(/until\s+(.+)/)

      if @options[:end]
        # If user passed -e, it overrides everything. We add "11:59pm" to include the final day.
        end_date = Chronic.parse("#{@options[:end]} at 11:59pm", context: :future)
        rule.until(end_date) if end_date
      elsif limit_match
        count = limit_match[1].to_i
        rule.count(count)
      elsif until_match
        end_date = Chronic.parse(until_match[1], context: :future)
        rule.until(end_date) if end_date
      else
        rule.count(4) 
      end

      schedule.add_recurrence_rule(rule)
      schedule.all_occurrences
    end

    def self.recurring?(string)
      string.match?(/every|alternate|recurring|times|until/i)
    end
  end
end