
class LogHash
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :hash, :type => String
  field :log_version_id, :type => BSON::ObjectId
  field :starting_character, :type => Integer
  field :ending_character, :type => Integer 
  field :created_at, type: Date

end
