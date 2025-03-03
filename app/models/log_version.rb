
class LogVersion
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :ending_at, type: Date
  field :created_at, type: Date

end
