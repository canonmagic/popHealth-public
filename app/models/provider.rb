class Provider < CQM::Provider
  include Mongoid::Tree
  include Mongoid::Attributes::Dynamic

  field :level, type: String
  #FIELD NEED TO BE DEFINED, OTHERWISE MONGO WILL FAIL SAVING IDENTIFIERS
  field :npi, type: String

  embeds_many :cda_identifiers, class_name: "CDAIdentifier"

  scope :alphabetical, ->{order_by([:family_name, :asc], [:given_name, :asc])}
  scope :can_merge_with, ->(prov) { prov.npi.blank? ? all_except(prov) : all_except(prov).without_npi }
  scope :all_except, ->(prov) { where(:_id.ne => prov.id) }
  scope :selected, ->(provider_ids) { any_in(:_id => provider_ids)}
  scope :selected_or_all, ->(provider_ids) { provider_ids.nil? || provider_ids.empty? ? Provider.all : Provider.selected(provider_ids) }

  has_one :practice
  scope :by_npi, ->(an_npi){ where("cda_identifiers.root" => NPI_OID, "cda_identifiers.extension" => an_npi)}

  Specialties = {"100000000X" => "Behavioral Health and Social Service Providers",
                "110000000X" => "Chiropractic Providers",
                "120000000X" => "Dental Providers",
                "130000000X" => "Dietary and Nutritional Service Providers",
                "140000000X" => "Emergency Medical Service Providers",
                "150000000X" => "Eye and Vision Service Providers",
                "160000000X" => "Nursing Service Providers",
                "180000000X" => "Pharmacy Service Providers (Individuals)",
                "200000000X" => "Allopathic & Osteopathic Physicians",
                "210000000X" => "Podiatric Medicine and Surgery Providers",
                "220000000X" => "Respiratory, Rehabilitative and Restorative Service Providers",
                "230000000X" => "Speech, Language and Hearing Providers",
                "250000000X" => "Agencies",
                "260000000X" => "Ambulatory Health Care Facilities",
                "280000000X" => "Hospitals",
                "290000000X" => "Laboratories",
                "300000000X" => "Managed Care Organizations",
                "310000000X" => "Nursing and Custodial Care Facilities",
                "320000000X" => "Residential Treatment Facilities",
                "330000000X" => "Suppliers (including Pharmacies and Durable Medical Equipment)",
                "360000000X" => "Physician Assistants and Advanced Practice Nursing Providers"}

  # alias :full_name :name

  def full_name
    #for some reason, there are multiple properties for given name and family name: givenName and givenNames; familyName and family_name

    family = self.try(:family_name)
    if family.nil?
      family = self.try(:familyName)
    end

    given =  self.try(:given_name) 
    if given.nil?
      gb = self.try(:givenNames)   
      given = gb and gb.length > 0 ? gb[0] : nil
    end
    
    [family, given].compact.join(", ")
  end

  def specialty_name
    Specialties[specialty]
  end

  def merge_eligible
    Provider.can_merge_with(self).alphabetical
  end

  def to_json(options={})
    super(options)
  end

  def self.root
    #TODO
    return "Organization"
  end
  def npi=(an_npi)
    cda_id_npi = self.cda_identifiers.where(root: NPI_OID).first
    if cda_id_npi
      cda_id_npi.extension = an_npi
      cda_id_npi.save!
    else
      self.cda_identifiers << CDAIdentifier.new(root: NPI_OID, extension: an_npi)
    end
  end

  def npi
    cda_id_npi = self.cda_identifiers.where(root: NPI_OID).first
    cda_id_npi ? cda_id_npi.extension : nil
  end

  def tin=(a_tin)
    self.cda_identifiers << CDAIdentifier.new(root: TAX_ID_OID, extension: a_tin)
  end

  def tin
    cda_id_tin = self.cda_identifiers.where(root: TAX_ID_OID).first
    cda_id_tin ? cda_id_tin.extension : nil
  end

  def ccn=(a_ccn)
    cda_id_ccn = self.cda_identifiers.where(root: CCN_OID).first
    if cda_id_ccn
      cda_id_ccn.extension = a_ccn
      cda_id_ccn.save!
    else
      self.cda_identifiers << CDAIdentifier.new(root: CCN_OID, extension: a_ccn)
    end
  end

  def ccn
    cda_id_ccn = self.cda_identifiers.where(root: CCN_OID).first
    cda_id_ccn ? cda_id_ccn.extension : nil
  end

  def self.resolve_provider(provider_hash, patient=nil)
    catch_all_provider_hash = { :title => "",
                                :given_name => "",
                                :family_name=> "",
                                :specialty => "",
                                :cda_identifiers => [{root: APP_CONFIG['orphan_provider']['root'], extension:APP_CONFIG['orphan_provider']['extension']}]
                              }
    provider_info = provider_hash[:cda_identifiers].first
    patient_id = patient.medical_record_number if patient
    root = provider_info.try(:root)
    extension = provider_info.try(:extension)
    
    Log.create(:username => 'Background Event', :event => "No such provider with root '#{root}' and extension '#{extension}' exists in the database, patient has been assigned to the orphan provider.", :medical_record_number => patient_id)
    provider ||= Provider.in("cda_identifiers.root" => APP_CONFIG['orphan_provider']['root']).and.in("cda_identifiers.extension" => APP_CONFIG['orphan_provider']['extension']).first
    if provider.nil?
      provider = Provider.create(catch_all_provider_hash)
      Provider.root.children << provider
    end
    return provider
  end
end