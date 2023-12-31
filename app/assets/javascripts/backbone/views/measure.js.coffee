class SubmeasureView extends Thorax.View
  template: JST['measures/submeasure']
  context: ->
    _(super).extend measurementPeriod: moment(PopHealth.currentUser.get 'effective_date' * 1000).format('YYYY')
  logicIsActive: -> @parent.logicIsActive()
  patientResultsIsActive: -> @parent.patientResultsIsActive()
  teamMeasuresIsActive: -> @parent.teamMeasuresIsActive() or @parent.teamListIsActive()
  effectiveDate: -> PopHealth.currentUser.get 'effective_date'
  effectiveStartDate: -> PopHealth.currentUser.get 'effective_start_date'

class Thorax.Views.MeasureView extends Thorax.LayoutView
  id: 'measureSummary'
  template: JST['measures/show']
  initialize: ->
    submeasures = @submeasure.collection
    @sidebarView = if submeasures.length > 1
      new Thorax.Views.MultiQueryView model: @submeasure, submeasures: submeasures, providerId: @provider_id
    else
      new Thorax.Views.QueryView model: @submeasure.getQueryForProvider(@provider_id), providerId: @provider_id
    @submeasureView = new SubmeasureView model: @submeasure, provider_id: @provider_id
    @patientFilter = []
    @providerFilter = []
    @filterProvidersView = null
    @filterPatientsView = null
  events:
    'click #define-provider-filter': 'defineProviderFilterShow'
    'click #define-patient-filter': 'definePatientFilterShow'
    'click #reset-all-filters': 'resetAllFiltersShow'
  context: ->
    _(super).extend @submeasure.toJSON(), measurementPeriod: moment(PopHealth.currentUser.get 'effective_date' * 1000).format('YYYY')


  defineProviderFilterShow: (event) ->
    if (!@filterProvidersView)
      @filterProvidersView = new Thorax.Views.FilterProviders()
      @filterProvidersView.appendTo(@$el)
      @listenTo(@filterProvidersView, 'filterSaved', @providerFilterSaved);
    @filterProvidersView.filter = @providerFilter
    @filterProvidersView.display()
    event.preventDefault()

  providerFilterSaved: (filter) ->
    @providerFilter = filter
    this.saveFilter filter, 'api/queries/'+this.submeasure.attributes.id+'/filter'

  definePatientFilterShow: (event) ->
    if (!@filterPatientsView)
      @filterPatientsView = new Thorax.Views.FilterPatients()
      @filterPatientsView.appendTo(@$el)
      @listenTo(@filterPatientsView, 'filterSaved', @patientFilterSaved);
    @filterPatientsView.filter = @patientFilter
    @filterPatientsView.display()
    event.preventDefault()

  resetAllFiltersShow: (event) ->
    self=this;
    # hack to prevent subsequent page from looking for dead query_cache
    event.preventDefault()
    provider = self.provider_id || PopHealth.rootProvider.id
    self.provider_id=provider
    delete this.submeasure.queries[provider]
    PopHealth.currentUser.get('preferences').c4filters=[];
    $.post(
      'api/queries/'+this.submeasure.attributes.id+'/clearfilters'
      $.param({default_provider_id : provider})
      (data, xhr) ->
        PopHealth.currentUser.get('preferences').c4filters = null
        Backbone.history.navigate('/#providers/'+self.provider_id)
    )

  saveFilter: (filter, url) ->
    # hack to prevent subsequent page from looking for dead query_cache
    delete this.submeasure.queries[this.provider_id]
    json={}
    c4filters=[]
    for item in filter
      if item.items and item.items.length
        json[item.field] = item.items
        c4filters.push(item.field) if item.field!='asOf'
    provider = this.provider_id || PopHealth.rootProvider.id
    this.provider_id=provider
    json.default_provider_id=this.provider_id
    $.post(
      url
      $.param(json)
      (data, xhr)->
        PopHealth.currentUser.get('preferences').c4filters = c4filters
        Backbone.history.navigate('/#providers/'+json.default_provider_id)
    )

  patientFilterNames: () ->
    f=PopHealth.currentUser.get('preferences').c4filters
    if (f && f.length)
      return "Filters: #{f}"
    else
      return ''

  patientFilterSaved: (filter) ->
    @patientFilter = filter
    this.saveFilter filter, 'api/queries/'+this.submeasure.attributes.id+'/filter'

  changeFilter: (submeasure, population) ->
    if submeasure isnt @submeasure
      @submeasure = submeasure
      @submeasureView.setModel @submeasure
      @sidebarView.changeSubmeasure submeasure
      view = @getView()
      url = "measures/#{submeasure.collection.parent.get('id')}/#{submeasure.id}/providers/#{@provider_id}"
      if @logicIsActive()
        view.setModel @submeasure, render: true
      else
        url += '/patient_results'
        view.setQuery @submeasure.getQueryForProvider @provider_id
      PopHealth.router.navigate url
    @getView().updateFilter population
#    @getView().changeFilter population

  activateTeamListView: ->
    view = new Thorax.Views.TeamListView submeasure: @submeasure, provider_id: @provider_id, collection: new Thorax.Collections.Teams 
    @setView view
    
  activateLogicView: ->
    view = new Thorax.Views.LogicView model: @submeasure
    view.changeFilter @sidebarView.currentPopulation
    @setView view

  activateTeamMeasuresView: (team) ->
    view = new Thorax.Views.TeamMeasuresView model: team, submeasure: @submeasure
    @setView view

  activatePatientResultsView: (providerId) ->
    @provider_id = providerId
    view = new Thorax.Views.PatientResultsLayoutView query: @submeasure.getQueryForProvider(providerId), providerId: providerId
    view.changeFilter @sidebarView.currentPopulation
    @setView view

  teamListIsActive: -> if view = @getView() then view instanceof Thorax.Views.TeamListView else @viewType is 'team_list'
  
  teamMeasuresIsActive: -> if view = @getView() then view instanceof Thorax.Views.TeamMeasuresView else @viewType is 'team_measures'

  logicIsActive: -> if view = @getView() then view instanceof Thorax.Views.StaticmeasureView else @viewType is 'logic'
  patientResultsIsActive: -> if view = @getView() then view instanceof Thorax.Views.PatientResultsLayoutView else @viewType is 'patient_results'
