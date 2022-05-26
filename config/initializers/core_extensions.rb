module Kernel
  # I hate always having to type ActiveRecord::Base.connection when I want to talk directly to the DB...
  def db
    ::ActiveRecord::Base.connection
  end
  def pg
    # get PG::Connection -- for when we want to bypass ActiveRecord
    db.instance_eval { @connection }
  end

  # Shorthand for lambdas:
  def fn(&block)
    Proc.new(&block)
  end
end

module Enumerable
  def to_histogram
    reduce(Hash.new(0)) { |h,x| h[x] += 1; h }
  end

  def mappend
    reduce([]) { |a,x| x = yield x; a.concat(x) if x; a }
  end
end

class String
  # ActiveSupport defines String#to_date, but it doesn't parse dates the way we want
  def to_date
    case self
    when /\A\s*((19|20)\d\d)\s*\z/ # YYYY
      Date.civil($1.to_i,1,1)
    when /\A\s*(\d?\d)\/(\d?\d)\/(\d{2}?\d\d)\s*\z/ # DD/MM/YYYY
      year  = $3.to_i
      year += 2000 if year < 100
      Date.civil(year, $2.to_i, $1.to_i)
    else
      # Chronic returns a Time object, and comparisons of Times with Dates can fail
      # so convert to a Date
      Chronic.parse(self).try(:to_date)
    end
  end
  def is_numeric?
    true if Float(self) rescue false
  end
end

class Date
  # 2 different date formats which we use in various parts of the application
  # It would be nice to have more meaningful names!
  def to_print
    strftime('%d/%m/%Y')
  end
  def for_show
    self.strftime('%-d %b %y')
  end
  def for_show_a_d_m_y
    self.strftime('%a %-d %b %y')
  end
  def for_show_a_d_o_m
    self.strftime("%a %-d<sup>#{self.day.ordinalize.split(//).last(2).join}&nbsp;</sup> %b")
  end
  def for_show_a_d_o_m_mobile
    self.strftime("%a #{self.day.ordinalize} %b")
  end
  def for_show_d_m
    self.strftime('%-d %b')
  end
  def for_show_a_d_m
    self.strftime('%a %-d %b')
  end
  def for_show_a_d
    self.strftime('%a %-d')
  end
  def for_show_d
    self.strftime('%-d')
  end
  # Returns specific next occurring day of week
  def next_occurring(day_of_week)
    current_day_number = wday != 0 ? wday - 1 : 6
    from_now = DAYS_INTO_WEEK.fetch(day_of_week) - current_day_number
    from_now += 7 unless from_now > 0
    since(from_now.days)
  end
end
class Time
  def to_print
    to_date.to_print
  end
  def for_show
    to_date.for_show
  end
end


class Hash
  def extract_keys(*keys)
    result = {}
    keys.each { |k| result[k] = self[k] if key?(k) }
    result
  end
  def deep_merge(new)
    self.merge(new) do |key, old, new|
      if new.respond_to?(:blank?) && new.blank?
        old
      elsif old.kind_of?(Hash) and new.kind_of?(Hash)
        old.deep_merge(new)
      elsif old.kind_of?(Array) and new.kind_of?(Array)
        old.concat(new).uniq
      elsif old.kind_of?(String) and new.kind_of?(String)
        old.concat("\n#{new}")
      else
        new
      end
    end
  end
end

class Range
  def time_step(step, &block)
    return enum_for(:time_step, step) unless block_given?

    start_time, end_time = first, last
    begin
      yield(start_time)
    end while (start_time += step) <= end_time
  end
end
