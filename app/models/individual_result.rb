
module CQM
  class IndividualResult
    store_in collection: 'individual_results'

    field :population_set_key, type: String
    field :correlation_id, type: String
    field :file_name, type: String

    # <!-- Yockler Code 06/12/2024 -->
    # adds the observation values found in an individual_result to the observation_hash
    # Set agg_results to true if you are collecting aggregate results for multiple patients
    #
    # Below is an example hash for an individual (the hash key is the patient id)
    # {BSON::ObjectId('60806298c1c388315523be47')=>{"IPP"=>{:values=>[]},
    # "MSRPOPL"=>{:values=>[{:episode_index=>0, :value=>75}, {:episode_index=>1, :value=>50}], :statement_name=>"Measure Population"},
    # "MSRPOPLEX"=>{:values=>[]}}}

    # Below is an example hash for aggregate results (the hash keys are the population set keys)
    # {"PopulationSet_1"=>{"IPP"=>{:values=>[]},
    # "DENOM"=>{:values=>[{:episode_index=>0, :value=>9}, {:episode_index=>0, :value=>2}, :statement_name=>"Denominator"},
    # "NUMER"=>{:values=>[]}}}
    def collect_observations(observation_hash = {}, agg_results: false)
      return unless episode_results

      key = agg_results ? population_set_key : patient_id
      setup_observation_hash(observation_hash, key)
      population_set = measure.population_set_for_key(population_set_key).first
      # collect the observation_statements for the population_set. There may be more than one. episode_results are recorded in the same order
      observation_statements = population_set.observations.map { |obs| obs.observation_parameter.statement_name }
      # collect the observation_values from and individual_result
      # a scenario with multiple episodes and multiple observations would look like this [[2], [9, 1]]
      observation_values = get_observ_values(episode_results).compact
      observation_values.each_with_index do |observation_value, episode_index|
        observation_value.each_with_index do |observation, index|
          # lookup the population code (e.g., DENOM is the population code for the statement named 'Denominator')
          obs_pop = measure.population_keys.find { |pop| population_set.populations[pop]['statement_name'] == observation_statements[index] }
          # The Index of the Population Set ('Population Criteria 1')
          popset_index = measure.population_sets_and_stratifications_for_measure.find_index do |pop_set|
            pop_set[:population_set_id] == population_set[:population_set_id]
          end

          # Skip recording observations that are for a different population set.
          # This will occur when all of the observation_statements are for the same population (e.g., 'MSRPOPL')
          # And when the index of the observation does not match the index of the population set
          next if observation_statements.uniq.size == 1 && index != popset_index

          # add the observation to the hash
          observation_hash[key][obs_pop][:values] << { episode_index:, value: observation }
          observation_hash[key][obs_pop][:statement_name] = observation_statements[index]
        end
      end
      observation_hash
    end

    def setup_observation_hash(observation_hash, key)
      observation_hash[key] = {} unless observation_hash[key]
      measure.population_keys.each do |pop|
        observation_hash[key][pop] = { values: [] } unless observation_hash[key][pop]
      end
    end

    def get_observ_values(episode_results)
      episode_results.collect do |_id, episode_result|
        # Only use observed values when a patient is in the MSRPOPL and not in the MSRPOPLEX
        next unless (episode_result['MSRPOPL']&.positive? && !episode_result['MSRPOPLEX']&.positive?) || episode_result['MSRPOPL'].nil?

        episode_result['observation_values']
      end
    end
  end
end

IndividualResult = CQM::IndividualResult
