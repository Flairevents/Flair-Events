require 'active_support/concern'

module ActiveRecordExtension

  extend ActiveSupport::Concern

  # add your instance methods here
  #def foo
  #  "foo"
  #end

  # add your static(class) methods here
  class_methods do
    def pluck_to_hashes(*attributes)
      result = []
      self.pluck(*attributes).each do |values|
        hash = {} 
        [*values].each_with_index do |value, n|
          hash[attributes[n]] = value
        end
        result << hash 
      end
      result
    end
  end
end

# include the extension 
ActiveRecord::Base.send(:include, ActiveRecordExtension)
