class Thorax.Models.Measure extends Thorax.Model
  idAttribute: '_id'
  url: ->
    url = @collection?.url
    subId = @get 'sub_id'
    url += "/#{@get 'hqmf_id'}" unless @isNew()
    url += "?sub_id=#{subId}" if subId = @get('sub_id')
    return url
  parse: (attrs) ->
    data = _(attrs).omit 'subs', 'sub_ids'
    subs = for sub in attrs.subs or []
      subData = _(sub).extend(data)
      subData.isPrimary = true
      subData
    @effectiveDate = @collection?.effectiveDate
    @effectiveStartDate = @collection?.effectiveStartDate

    attrs.submeasures = new SubCollection subs, parent: this
    attrs

  sync: (method, model, options) ->
    if method isnt 'update'
      super
    else
      options.url = 'api/measures/update_metadata'
      super('create', model, options) # POST to this URL to update


class Thorax.Collections.Measures extends Thorax.Collection
  model: Thorax.Models.Measure
  url: '/api/measures'
  comparator: 'title'
  initialize: (models, options) ->
    @parent = options?.parent
    @hasMoreResults = true
    @effectiveDate = @parent?.effectiveDate
    @effectiveStartDate = @parent?.effectiveStartDate
  currentPage: (perPage = 100) -> Math.ceil(@length / perPage)
  fetch: ->
    result = super
    #DONE WAS CHANGED TO SUCCESS HERE
    result.success => @hasMoreResults = /rel="next"/.test(result.getResponseHeader('Link'))
  fetchNextPage: (options = {perPage: 10}) ->
    data = {page: @currentPage(options.perPage) + 1, per_page: options.perPage}
    @fetch(remove: false, data: data) if @hasMoreResults

class Thorax.Models.Submeasure extends Thorax.Model
  idAttribute: 'sub_id'
  url: -> "/api/measures/#{@get('id')}"
  initialize: ->
    # TODO remove @get('query') when we upgrade to Thorax 3
    @effectiveDate = @collection?.effectiveDate
    @effectiveStartDate = @collection?.effectiveStartDate
    query = new Thorax.Models.Query({measure_id: @get('id'), sub_id: @get('sub_id'), effective_date: @effectiveDate, effective_start_date: @effectiveStartDate }, parent: this)
    @set 'query', query
    @queries = {}
  isPopulated: -> @has 'IPP'
  fetch: (options = {}) ->
    options.data = {sub_id: @get('sub_id')} unless options.data?
    super(options)
  parse: (attrs) ->
    attrs = $.extend true, {}, attrs
    attrs.id = attrs.hqmf_id
    # turn {someKey: {title: 'title'}} into {id: 'someKey', title: 'title'}
    dataCriteria = for id, criteria of attrs.source_data_criteria
      _(criteria).extend id: id
    attrs.data_criteria = new Thorax.Collections.DataCriteria dataCriteria, parse: true
    # only create populations for those that apply to this submeasure
    # LET'S USE DEFAULT POPULATION CRITERIA INSTEAD
    for popName, population of attrs.population_criteria when population.hqmf_id is attrs.population_criteria[population.type].hqmf_id
    #for popName, population of attrs.population_criteria when population.hqmf_id is attrs.population_ids[population.type]
      # track the original type of the population (NUMER, or NUMER_1)
      population.original_type = popName
      attrs[population.type] = new Thorax.Models.Population population, parse: true
      attrs[population.type].parent = this
    attrs
  getQueryForProvider: (providerId) ->
    query = @queries[providerId] or new Thorax.Models.Query({measure_id: @get('hqmf_id'), sub_id: @get('sub_id'), effective_date: @effectiveDate, effective_start_date: @effectiveStartDate, providers: [providerId]}, parent: this)
    query


class SubCollection extends Thorax.Collection
  model: Thorax.Models.Submeasure
  initialize: (models, options) -> 
    @parent = options.parent
    @effectiveDate = @parent?.effectiveDate
    @effectiveStartDate = @parent?.effectiveStartDate
  comparator: 'sub_id'

class Thorax.Models.Staticmeasure extends Thorax.Model
  idAttribute: 'id'
  url: -> "api/admin/caches/static_measure/#{@get('id')}"
  parse: (attrs) ->
    attrs

class Thorax.Collections.StatCollection extends Thorax.Collection
  model: Thorax.Models.Staticmeasure
