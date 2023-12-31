class Thorax.Models.Provider extends Thorax.Model
  urlRoot: '/api/providers'
  idAttribute: '_id'
  providerType: -> 
    if @get("cda_identifiers")?[0].root == "2.16.840.1.113883.4.6"
      'NPI'
    else
      @get("cda_identifiers")?[0].root
  providerExtension: -> @get("cda_identifiers")?[0].extension
  parse: (attrs) ->
    attrs = $.extend true, {}, attrs
    attrs.children = new Thorax.Collections.Providers attrs.children, parse: true if attrs.children?
    attrs
  toJSON: ->
    json = super
    json.children = json.children.toJSON() if json.children?
    json
  npi: ->
    if @providerType() == '2.16.840.1.113883.4.6' then @providerExtension()
  tin: ->
    if @get("cda_identifiers")?[1]?.extension == '2.16.840.1.113883.4.2' then @get("cda_identifiers")?[1]?.extension

class Thorax.Collections.Providers extends Thorax.Collection
  url: '/api/providers'
  model: Thorax.Models.Provider
  comparator: (p) ->
    root = p.get('cda_identifiers')?[0].root
    extension = parseInt(p.get('cda_identifiers')?[0].extension) || p.get('cda_identifiers')?[0].extension
    [root,extension]
  initialize: (attrs, options) ->
    @hasMoreResults = true
  currentPage: (perPage = 100) -> Math.ceil(@length / perPage)
  fetch: ->
    result = super
    #DONE WAS CHANGED TO SUCCESS HERE
    result.success => @hasMoreResults = /rel="next"/.test(result.getResponseHeader('Link'))
  fetchNextPage: (options = {perPage: 10}) ->
    data = {page: @currentPage(options.perPage) + 1, per_page: options.perPage}
    @fetch(remove: false, data: data) if @hasMoreResults

# A collection of providers under a given team. Setting the team ID from a parameter does not load the collection properly, so the Team ID is specified in the URL when called.  See Thorax.Views.TeamMeasuresView
class Thorax.Collections.TeamProviders extends Thorax.Collection
  url: "/api/teams/team_providers"
  model: Thorax.Models.Provider