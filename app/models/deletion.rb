class Deletion < ApplicationRecord
  # this class is used to keep track of records which are deleted,
  #   so that when users in the Office Zone ping the server for updated data,
  #   we can inform the client which records have been deleted
  # we delete old 'deletion' records from time to time
end