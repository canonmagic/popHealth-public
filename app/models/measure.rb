module CQM
  class Measure

    validates_inclusion_of :reporting_program_type, in: %w[ep eh]

    field :reporting_program_type, type: String
    field :category, type: String
    field :annual_update, type: String
    field :bundle_id, type: BSON::ObjectId

    #I'VE ADDED THIS TO RELATE MEASURE WITH BUNDLE AND THIS WAY WE CAN GET VALUE SETS DIRECTLY
    belongs_to :bundle, class_name: 'Bundle', inverse_of: :measures

    def cms_int
      return 0 unless cms_id

      start_marker = 'CMS'
      end_marker = 'v'
      cms_id[/#{start_marker}(.*?)#{end_marker}/m, 1].to_i
    end

    # A measure may have 1 or more population sets that may have 1 or more stratifications
    # This method returns an array of hashes with the population_set and stratification_id for every combindation
    def population_sets_and_stratifications_for_measure
      population_set_array = []
      population_sets.each do |population_set|
        population_set_hash = { population_set_id: population_set.population_set_id }
        next if population_set_array.include? population_set_hash

        population_set_array << population_set_hash
        population_set.stratifications.each do |stratification|
          population_set_stratification_hash = { population_set_id: population_set.population_set_id,
                                                  stratification_id: stratification.stratification_id }
          population_set_array << population_set_stratification_hash
        end
      end
      population_set_array
    end

    # This method returns the population_set for a given 'population_set_key.'  The popluation_set_key is the key used
    # by the cqm-execution-service to reference the population set for a specific set of calculation results
    def population_set_for_key(population_set_key)
      ps_hash = population_sets_and_stratifications_for_measure
      ps_hash.keep_if { |ps| [ps[:population_set_id], ps[:stratification_id]].include? population_set_key }
      return nil if ps_hash.blank?

      [population_sets.where(population_set_id: ps_hash[0][:population_set_id]).first, ps_hash[0][:stratification_id]]
    end

    # This method returns an population_set_hash (from the population_sets_and_stratifications_for_measure)
    # for a given 'population_set_key.' The popluation_set_key is the key used by the cqm-execution-service
    # to reference the population set for a specific set of calculation results
    def population_set_hash_for_key(population_set_key)
      population_set_hash = population_sets_and_stratifications_for_measure
      population_set_hash.keep_if { |ps| [ps[:population_set_id], ps[:stratification_id]].include? population_set_key }.first
    end

    # This method returns a popluation_set_key for.a given population_set_hash
    def key_for_population_set(population_set_hash)
      population_set_hash[:stratification_id] || population_set_hash[:population_set_id]
    end

    # This method returns the subset of population keys used in a specific measure
    def population_keys
      %w[IPP DENOM NUMER NUMEX DENEX DENEXCEP MSRPOPL MSRPOPLEX].keep_if { |pop| (population_sets.first.populations[pop] && population_sets.first.populations[pop]['hqmf_id']) }
    end


    def self.categories(measure_properties = [])
      measure_properties = Array(measure_properties).map(&:to_s) | %w(
        title description cms_id hqmf_id measure_scoring
      )
      pipeline = []

      pipeline << {
        '$group' =>  measure_properties.inject(
          {
            '_id' => "$_id",
            'subs' => {'$push' => {"sub_id" => "$population_sets.stratifications.stratification_id", "short_subtitle" => "$population_sets.stratifications.title"}},
            'sub_ids' => {'$push' => "$population_sets.stratifications.stratification_id"},
            'populations' => {'$push' => "$population_sets.population_set_id"},
            'category' => {'$first' => "$category"}
          }) do |h, prop|
            h[prop] = {"$first" => "$#{prop}"}
            h
          end
        }

      pipeline << {
        '$group' => {
          _id: "$category",
          measures: {
            '$push' =>  measure_properties.inject(
              {
                'id' => "$_id",
                'hqmf_id' => "$_id",
                'subs' => "$subs",
                'sub_ids' => "$sub_ids",
                'populations' => "$populations"
              }) do |h, prop|
                h[prop] = "$#{prop}"
                h
              end
          }
        }
      }

      pipeline << {'$project' => {'category' => '$_id', 'measures' => 1, '_id' => 0}}

      pipeline << {'$sort' => {"category" => 1}}
      Mongoid.default_client.command(aggregate: 'cqm_measures', pipeline: pipeline, explain: false).documents[0]["cursor"]["firstBatch"]
    end
  end
end

Measure = CQM::Measure