require 'cypress/criteria_picker.rb'
module Cypress
  class PatientFilter
    def self.filter(records, filters, options)
      filtered_patients = []
      records.each do |patient|
        filtered_patients << patient unless patient_missing_filter(patient, filters, options)
      end
      filtered_patients
    end

    def self.patient_missing_filter(patient, filters, params)
      @asofval = params[:as_of]
      if filters.key? ("asOf")
        if params[:as_of].present?
          @effective_date = Time.at(params[:as_of])
          filters.delete("asOf")
        else
          @effective_date = Time.at(params[:effective_date])
          filters.delete("asOf")
        end
      end

      return filters.any? {|k, v| 
      # return true if patient is missing any filter item
        # TODO: filter for age and problem (purposefully no prng)
        if k == 'age'
          # TODO: compare integers?? or dates?
          true if check_age(v, patient, params)
        elsif k == 'payers'
          # missing payer if value doesn't match any payer name (of multiple providers)
          true unless match_payers(v, patient)
        elsif k == 'problems'
          patient_missing_problems(patient, v)
        elsif k == 'providers'
          provider = patient.lookup_provider(include_address: true)
          v.each { |key, val| return true if val != provider[key] }
        elsif k == "provider_ids"
          provider_id = v
          if get_provider_info(provider_id, patient)
             false
          else
             true
          end  
        elsif k == "providerTypeTags"
          taxonomies = v
          if search_provider_by_taxonomy(taxonomies, patient)
             false
          else
             true
          end
        elsif v.instance_of?(Array)
          (Cypress::CriteriaPicker.send(k, patient, params) & v).empty?
        elsif v != Cypress::CriteriaPicker.send(k, patient, params)
          # races, ethnicities, genders, providers
          true
        end
      }
      false
    end

    def self.match_payers(v, patient)
      patient.payer == v.first
    end

    def self.check_age(v, patient, params)
      return true if v.first.key?('min') && patient.age_at(@asofval) < v.first['min']
      return true if v.first.key?('max') && patient.age_at(@asofval) > v.first['max']

      false
    end

    def self.patient_missing_problems(patient, problem)
      # TODO: first... different versions of value set... which version do we want?
      # 2.16.840.1.113883.3.666.5.748
      begin
      value_set = ValueSet.where(oid: problem[:oid].first).first
      !Cypress::CriteriaPicker.find_problem_in_records([patient], value_set)
      rescue Exception => e
            Delayed::Worker.logger.info(e.message)
            Delayed::Worker.logger.info(e.backtrace.inspect)
      end
    end
    
    def self.get_provider_info(id, patient)
      provider_performances = patient.qdmPatient.extendedData['provider_performances']
      if provider_performances.length > 0
        provider_performances.each do |pp|
          prov_perf = JSON.parse(pp)
          if prov_perf.instance_of? Array
            prov_perf = prov_perf[0]
          end
          provider = Provider.find(prov_perf['provider_id'])
            if id.instance_of?(Array)
              if id.include? provider["_id"].to_s
                return true
              else
                puts 'a'
                return false
              end
            elsif provider["_id"].to_s != id[0]
              return true
            else
              return false
            end
        end
      else
        return false
      end
    end

    def self.search_provider_by_taxonomy(taxonomy, patient)
      provider_performances = patient.qdmPatient.extendedData['provider_performances']
      if provider_performances.length > 0
        provider_performances.each do |pp|
          prov_perf = JSON.parse(pp)
          if prov_perf.instance_of? Array
            prov_perf = prov_perf[0]
          end
          provider = Provider.find(prov_perf['provider_id'])
            if taxonomy.instance_of?(Array)
              if taxonomy.include? provider["specialty"].to_s
                return true
              else
                return false
              end
            elsif provider["_id"].to_s != taxonomy[0]
              return true
            else
              return false
            end
        end
      else
        return false
      end
    end
  end
end
