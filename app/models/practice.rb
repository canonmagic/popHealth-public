
class Practice
  include Mongoid::Document

  field :name, type: String
  field :organization, type: String
  field :address, type: String
  field :provider_id, type: BSON::ObjectId
  field :omniwound_id, type: String, default: nil
  
  validates_presence_of :name, :organization
  validates :name, uniqueness: true
  belongs_to :provider, dependent: :destroy, optional: true
  has_many :users
  has_many :cqmPatient, class_name: 'CQM::Patient'
  
  def providers
    Provider.all({"parent_ids" => self.provider_id })
  end
end
