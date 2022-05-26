# Be sure to restart your server when you modify this file.

# Specify a serializer for the signed and encrypted cookie jars.
# Valid options are :json, :marshal, and :hybrid.
# We are staying with the (old) :marshal format because the :json format
# converts Date/Times into strings, that give parse errors when parsed
# with the JSON parser, affects lib/authentication.rb
Rails.application.config.action_dispatch.cookies_serializer = :marshal
