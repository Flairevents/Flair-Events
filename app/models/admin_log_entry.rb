class AdminLogEntry < ApplicationRecord
  # If a table has a 'type' column, ActiveRecord automatically thinks the model class
  #   is polymorphic. Suppress this dubious 'cleverness':
  self.inheritance_column = '__ridiculous_workaround__'
end