require 'uniq_validator'

class User

  include ActiveModel::ForbiddenAttributesProtection
  include Mongoid::Document

  after_initialize :build_preferences, unless: Proc.new { |user| user.preferences.present? }
  before_save :denullify_arrays
  before_create :set_defaults

  DEFAULT_EFFECTIVE_DATE = Time.gm(2022, 12, 31)
  
  devise :database_authenticatable, :omniauthable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :authentication_keys => [:username], omniauth_providers:          
         %i[azure_activedirectory_v2]


   ## Database authenticatable
   field :encrypted_password, :type => String

   ## Recoverable
   field :reset_password_token,   :type => String
   field :reset_password_sent_at, :type => Time

   ## Rememberable
   field :remember_created_at, :type => Time

   ## Trackable
   field :sign_in_count,      :type => Integer
   field :current_sign_in_at, :type => Time
   field :last_sign_in_at,    :type => Time
   field :current_sign_in_ip, :type => String
   field :last_sign_in_ip,    :type => String


  :remember_created_at
  :reset_password_token
  :reset_password_sent_at
  :sign_in_count
  :current_sign_in_at
  :last_sign_in_at
  :current_sign_in_ip
  :last_sign_in_ip
  :effective_date
  :effective_start_date

  field :files, type: Object
  field :first_name, type: String
  field :last_name, type: String
  field :username, type: String
  field :email, type: String
  field :company, type: String
  field :company_url, type: String
  field :registry_id, type: String
  field :registry_name, type: String
  field :npi, :type => String
  field :tin, :type => String
  field :agree_license, type: Boolean
  field :effective_date, type: Integer, default: DEFAULT_EFFECTIVE_DATE.to_i
  field :effective_start_date, type: Integer, default: (DEFAULT_EFFECTIVE_DATE.beginning_of_year).to_i
  field :admin, type: Boolean
  field :approved, type: Boolean
  field :staff_role, type: Boolean
  field :disabled, type: Boolean
  field :provider_id, type: BSON::ObjectId

  has_and_belongs_to_many :teams, class_name: 'Team'
  has_one :preferences, class_name: 'Preference'
  belongs_to :practice, class_name: 'Practice', optional: true
  
  scope :ordered_by_username, -> { asc(:username) }

  accepts_nested_attributes_for :preferences

  validates_presence_of :first_name, :last_name

  validates_uniqueness_of :username
  validates_uniqueness_of :email

  validates_acceptance_of :agree_license, :accept => true

  validates :email, presence: true, length: {minimum: 3, maximum: 254}, format: {with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i}
  validates :username, :presence => true, length: {minimum: 3, maximum: 254}

  def set_defaults
    self.staff_role ||= APP_CONFIG["default_user_staff_role"]
    self.approved ||= APP_CONFIG["default_user_approved"]
    true
  end

  # replace nil with [] when it should be an array; see https://github.com/rails/rails/issues/8832
  def denullify_arrays
    # if self.preferences[:selected_measure_ids] == nil
    #   binding.pry
    # end
    self.preferences["selected_measure_ids"] ||= []
  end

  def active_for_authentication?
    super && approved? && !disabled?
  end

  def inactive_message
    if !approved?
      :not_approved
    else
      super # Use whatever other message
    end
  end

  # =============
  # = Accessors =
  # =============
  def full_name
    "#{first_name} #{last_name}"
  end

  # ===========
  # = Finders =
  # ===========
  def self.by_username(username)
    where(username: username).first
  end
  def self.by_email(email)
    where(email: email).first
  end

  # =============
  # = Modifiers =
  # =============

  def grant_admin
    update_attribute(:admin, true)
    update_attribute(:approved, true)
    
    if ! APP_CONFIG['use_opml_structure'] && Provider.root
      update_attribute(:provider_id, Provider.root.id)
    end
  end

  def approve
    update_attribute(:approved, true)
  end

  def revoke_admin
    update_attribute(:admin, false)
  end

end
