# A notification which we want to include in a batched message to someone

class Notification < ApplicationRecord
  belongs_to :recipient, class_name: 'Account', foreign_key: 'recipient_id'

  # If a table has a 'type' column, ActiveRecord automatically thinks the model class
  #   is polymorphic. Suppress this dubious 'cleverness':
  self.inheritance_column = '__ridiculous_workaround__'
end
