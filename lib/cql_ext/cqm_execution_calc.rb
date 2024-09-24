require 'json'
require 'securerandom'

module Cypress
  class CqmExecutionCalc
    attr_accessor :patients, :measures, :options

    def initialize(patients, measures, correlation_id, options)
      @patients = patients
      # This is a key -> value pair of patients mapped in the form "qdm-patient-id" => BSON::ObjectId("cqm-patient-id")
      @cqm_patient_mapping = patients.map { |patient| [patient.id.to_s, patient.cqmPatient] }.to_h
      @measures = measures
      @correlation_id = correlation_id
      @options = options
    end

    def execute(save = true)
      results = @measures.map do |measure|
        request_for(measure, save)
      end.flatten

      results
    end

    def request_for(measure, save = true)
      ir_list = []
      #measure.bundle.value_sets does the reference though the bundle
      post_data = { patients: @patients, measure: measure, valueSets: measure.bundle.value_sets, options: @options }
      # cqm-execution-service expects a field called value_set_oids which is really just our
      # oids field. There is a value_set_oids on the measure for this explicit purpose.
      # Yockler Note: This method is taking too long...
      post_data = post_data.to_json(methods: %i[_type])

      begin
        response = RestClient::Request.execute(method: :post, url: self.class.create_connection_string, timeout: 120,
                                               payload: post_data, headers: { content_type: 'application/json' })
      rescue => e
        raise e.to_s || 'Calculation failed without an error message'
      #ensure
        #Delayed::Worker.logger.info("*** Response From CQM-Execution-Service *** ")
        #Delayed::Worker.logger.info(response)
      end

      results = JSON.parse(response)
      patient_result_hash = {}

      results.each do |patient_id, result|
        # Aggregate the results returned from the calculation engine for a specific patient.
        # If saving the individual results, update identifiers (patient id, population_set_key) in the individual result.
        aggregate_population_results_from_individual_results(result, @cqm_patient_mapping[patient_id], save, ir_list)
        patient_result_hash[patient_id] = result.values
      end

      #USING CREATE INSTEAD CONCAT CAUSES ERROR, IT EXPECTS AN KEY-OBJECT LIST, NOT A CLASS LIKE INDIVIDUALRESULT
      measure.calculation_results.concat(ir_list) if save
      patient_result_hash.values
    end

    def self.create_connection_string
      config = Rails.application.config
      "http://#{config.ces_host}:#{config.ces_port}/calculate"
    end

    private

    def aggregate_population_results_from_individual_results(individual_results, patient, save, ir_list)
      updated = false

      individual_results.each_pair do |population_set_key, individual_result|
        # store the population_set within the indivdual result
        individual_result['population_set_key'] = population_set_key
        # update the patient_id to match the cqm_patient id, not the qdm_patient id
        individual_result['patient_id'] = patient.id.to_s
        # save to database (if in the IPP, or has a file name (i.e., a file that was uploaded for CVU+))
        if (save && (individual_result['IPP'] != 0))
          ir_list << postprocess_individual_result(individual_result,patient)
          # update the patients, measure_relevance_hash
          patient.update_measure_relevance_hash(individual_result)
          updated = true
        end
      end

      patient.save! if (save && updated)
    end

    # This add/remove information for use in Cypress
    # extendedData and statement_results are currently remove as a remporary fix
    # Add correlation_id and file_name for searchability
    def postprocess_individual_result(individual_result,patient)
      individual_result = IndividualResult.new(individual_result)
      # when saving the individual result, include the provided correlation id
      individual_result['correlation_id'] = @correlation_id
      individual_result['file_name'] = @options[:file_name] if @options[:file_name]
      individual_result['extendedData'] = {}
      individual_result['extendedData']['effective_date'] = @options[:effectiveDate] if @options[:effectiveDate]
      individual_result['extendedData']['first'] = patient.givenNames[0]
      individual_result['extendedData']['last'] = patient.familyName
      individual_result['extendedData']['DOB'] = {}
      individual_result['extendedData']['DOB']['year'] = patient.qdmPatient.birthDatetime.year
      individual_result['extendedData']['DOB']['month'] = patient.qdmPatient.birthDatetime.month
      individual_result['extendedData']['DOB']['day'] = patient.qdmPatient.birthDatetime.day
      individual_result['extendedData']['DOB']['hour'] = patient.qdmPatient.birthDatetime.hour
      individual_result['extendedData']['DOB']['minute'] = patient.qdmPatient.birthDatetime.minute
      individual_result['extendedData']['DOB']['second'] = patient.qdmPatient.birthDatetime.second
      #individual_result['extendedData']['gender'] = patient.qdmPatient.dataElements.where("hqmfOid": "2.16.840.1.113883.10.20.28.4.55").first.dataElementCodes[0].code Edited by Yockler
      if patient.qdmPatient.dataElements.where("hqmfOid": "2.16.840.1.113883.10.20.28.4.55").first.nil?
        individual_result['extendedData']['gender'] = "UNK"
      else
        individual_result['extendedData']['gender'] = patient.qdmPatient.dataElements.where("hqmfOid": "2.16.840.1.113883.10.20.28.4.55").first.dataElementCodes[0]["code"]
      end
      individual_result['extendedData']['medical_record_number'] = patient.id.to_s
      mes = Measure.where("id" => individual_result.measure_id).first
      individual_result['extendedData']['hqmf_id'] = mes.hqmf_id

      # omniwound >
      #individual_result = CQM::IndividualResult.new(individual_result)
      # omniwound <

      individual_result.save!
      individual_result
    end

    def timeout
      @options[:timeout] || 60
    end
  end
end
