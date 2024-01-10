class QualityReportResult
  include Mongoid::Document
  include Mongoid::Timestamps

  field :population_ids, type: Hash
  field :IPP, type: Integer
  field :DENOM, type: Integer
  field :NUMER, type: Integer
  field :antinumerator, type: Integer
  field :DENEX, type: Integer
  field :DENEXCEP, type: Integer
  field :MSRPOPL, type: Integer
  field :OBSERV, type: Float
  field :supplemental_data, type: Hash



  embedded_in :quality_report, inverse_of: :result
end

# A class that allows you to create and obtain the results of running a
# quality measure against a set of patient records.
class QualityReport

  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  store_in collection: 'query_cache'

  field :nqf_id, type: String
  field :npi, type: String
  field :calculation_time, type: Time
  field :status, type: Hash, default: {"state" => "unknown", "log" => []}
  field :measure_id, type: String
  field :sub_id, type: String
  field :effective_date, type: Integer
  field :filters, type: Hash
  field :prefilter, type: Hash

  #Add Jose Melendez
  field :filter_preferences, type: Array, default:[]

  embeds_one :result, class_name: "QualityReportResult", inverse_of: :quality_report

  index "measure_id" => 1
  index "sub_id" => 1
  index "filters.provider_performances.provider_id" => 1

  POPULATION = 'IPP'
  DENOMINATOR = 'DENOM'
  NUMERATOR = 'NUMER'
  EXCLUSIONS = 'DENEX'
  EXCEPTIONS = 'DENEXCEP'
  MSRPOPL = 'MSRPOPL'
  MSRPOPLEX = 'MSRPOPLEX'
  OBSERVATION = 'OBSERV'
  ANTINUMERATOR = 'antinumerator'
  CONSIDERED = 'considered'

  RACE = 'RACE'
  ETHNICITY = 'ETHNICITY'
  SEX ='SEX'
  POSTAL_CODE = 'POSTAL_CODE'
  PAYER   = 'PAYER'

  def patient_results
    #ex = QME::MapReduce::Executor.new(self.measure_id,self.sub_id, self.attributes)
    results = CQM::IndividualResult.where(patient_cache_matcher)

    results
  end

  def measure
    QME::QualityMeasure.where({"hqmf_id"=>self.measure_id, "sub_id" => self.sub_id}).first
  end

  # make sure all filter id arrays are sorted
  def self.normalize_filters(filters)
    filters.each {|key, value| value.sort_by! {|v| (v.is_a? Hash) ? "#{v}" : v} if value.is_a? Array} unless filters.nil?
  end

  def patient_result(patient_id = nil)
    query = patient_cache_matcher
    if patient_id
      query['value.medical_record_id'] = patient_id
    end
      QME::PatientCache.where(query).first()
  end

  def patient_cache_matcher
    measure_id = Measure.where(id: self.measure_id).pluck(:_id).first.to_s
    sub_id = self.sub_id.present? ? self.sub_id : "PopulationSet_1"
    match = {'measure_id' => measure_id,
            'population_set_key' => sub_id,
              #'qdmpatient.extendedData.effective_date'   => Time.at(self.effective_date).in_time_zone.to_formatted_s(:number),
              'extendedData.manual_exclusion' => {'$in' => [nil, false]}              
            }
    match
  end

  protected

    # In the older version of QME QualityReport was not treated as a persisted object. As
    # a result anytime you wanted to get the cached results for a calculation you would create
    # a new QR object which would then go to the db and see if the calculation was performed or
    # not yet and then return the results.  Now that QR objects are persisted you need to go through
    # the find_or_create by method to ensure that duplicate entries are not being created.  Protecting
    # this method causes an exception to be thrown for anyone attempting to use this version of QME with the
    # sematics of the older version to highlight the issue.
  def initialize(attrs = nil)
    super(attrs)
  end
=begin
  def self.enque_job(options,queue)
    Delayed::Job.enqueue(QME::MapReduce::MeasureCalculationJob.new(options), {queue: queue})
  end
=end
end