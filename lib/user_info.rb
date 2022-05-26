# The purpose of this module is to make 'current_user' available in a model
#
# To use:
#  In Model:
#    require 'user_info'
#
#    Then can reference current_user using UserInfo.current_user
#
# In controller, must setup to set current_user
#   require 'user_info'
#   class ControllerName
#     before_action :set_user
#     def :set_user
#       UserInfo.current_user = current_user
#     end
#   end

require 'request_store'

module UserInfo
  def self.current_user
    RequestStore.store[:user]
  end
  def self.current_user=(user)
    RequestStore.store[:user] = user
  end
  def self.controller_name
    RequestStore.store[:controller]
  end
  def self.controller_name=(controller)
    RequestStore.store[:controller] = controller
  end
end