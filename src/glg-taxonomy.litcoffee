#glg-taxonomy

    Polymer 'glg-taxonomy',

##Events


##Attributes and Change Handlers
      
      elasticParams:
        query:
          filtered:
            query:
              multi_match:
                query: null
                fields: ["fullPath"]
            filter:
              bool:
                must: []

        facets:
          level_0:
            terms:
              field: "level_0"

        highlight:
          order: "score"
          fields:
            fullPath:
              number_of_fragments: 0

      resultsChanged: (oldResults, newResults) ->
        return unless newResults
        @formatResults newResults

      valueChanged: (oldValue, newValue) ->
        return unless newValue
        @value = JSON.parse(newValue) if typeof(newValue) is "string"
        @$.typeahead.value = @value.map (v) -> {item:v}
        @fire('change', @value) if newValue != oldValue

##Methods

      formatResults: (results) ->
        @items = results.map (item) ->
          parts = item["_fullPath"].split(' > ')
          item.parts = parts.map (part, i) ->
            {nodeName:part, depth:i, parts: parts.slice 0, i + 1}
          item

      browseToPart: (e, _, src) ->
        e.preventDefault()
        e.stopPropagation()
        part = src.templateInstance.model.part
        
        @activeFacets = part.parts.map (term) -> {term}
        @availableFacets = []
        @elasticParams.query.filtered.filter.bool.must = []
        @facetDepth = 0
        @elasticParams.facets = {}

        part.parts.forEach (node, i) =>
          filter = {term:{}}
          filter.term["level_#{@facetDepth}"] = node
          @elasticParams.query.filtered.filter.bool.must.push filter
          @facetDepth += 1

        @elasticParams.facets = {}          
        @elasticParams.facets["level_#{@facetDepth}"] = 
          terms:
            field: "level_#{@facetDepth}"

        console.log @elasticParams.facets
        @$.websocket.send @payload
        console.log part
        return false

##Event Handlers

      nop: ->

      focusIn: (e) ->
        @showFilter = true

      clearFacets: (e) ->
        e?.preventDefault()
        e?.stopPropagation()

        @activeFacets = []
        @availableFacets = []
        @elasticParams.query.filtered.filter.bool.must = []
        @facetDepth = 0
        @elasticParams.facets = {}
        @elasticParams.facets["level_#{@facetDepth}"] = 
          terms:
            field: "level_#{@facetDepth}"
        
        @$.websocket.send @payload

      removeAfterFacet: (e) ->
        e.preventDefault()
        e.stopPropagation()

        facet = e.target.templateInstance.model.facet
        
        @activeFacets = @activeFacets.slice 0, facet.depth + 1
        @availableFacets = []
        
        @facetDepth = facet.depth + 1
        @elasticParams.facets = {}
        @elasticParams.facets["level_#{@facetDepth}"] = 
          terms:
            field: "level_#{@facetDepth}"

        @$.websocket.send @payload

      addFacet: (e) ->
        e.preventDefault()
        e.stopPropagation()
        
        facet = e.target.templateInstance.model.facet
        facet.depth = @facetDepth     
        @activeFacets.push facet

        filter = {term:{}}
        filter.term["level_#{@facetDepth}"] = facet.term
        @elasticParams.query.filtered.filter.bool.must.push filter
        @facetDepth += 1

        @elasticParams.facets["level_#{@facetDepth}"] = 
          terms:
            field: "level_#{@facetDepth}"
        
        @$.websocket.send @payload

      queryResult: (e) ->
        @availableFacets = []
        return unless e.detail.text
        response = e.detail.text
        
        @availableFacets = response.facets["level_#{@facetDepth}"].terms
        
        results = response.hits.hits.map (h) -> 
          h._source["_fullPath"] = h._source.fullPath
          Object.keys(h.highlight).forEach (k) -> 
            h._source[k] = h.highlight[k][0]
          h._source

        @termMatched = results.length > 0
        @results = results

##Polymer Lifecycle

      ready: () ->
          @items ||= []
          # hack for now because an empty placeholder has a different height than the input
          # play with styles later
          @placeholder ||= " "

      attached: ->

        urlMap = 
          'sector': "sectors"
          'job-function': "job_functions"
          'region': "regions"

        @pluralMap = 
          'sector': "industries"
          'job-function': "job roles"
          'region': "geographies"

        @payload = 
          verb: "post"
          url: "https://services.glgresearch.com/cerca/taxonomy_#{urlMap[@type]}/_search"
          json: true
          body: @elasticParams
          headers: 
            authorization: "Basic c3ZjU3RhcnBobGVldExEQVA6NHJhdFVSYXM="

        @activeFacets = []
        @availableFacets = []
        @facetDepth = 0
        @showFilter = false

        @elasticParams.from = 0
        @elasticParams.size = 12

        @$.typeahead.addEventListener 'inputchange', (e) =>
          @elasticParams.query.filtered.query.multi_match.query = e.detail.value
          @$.websocket.send @payload

        @$.websocket.addEventListener 'data', @queryResult.bind(@)

        @addEventListener 'itemremoved', (e) ->
          index = @value.indexOf e.detail.item
          @value.splice index, 1

        @addEventListener 'itemadded', (e) ->
          @results = []
          @clearFacets()
          @value.push e.detail.item



      publish:
        value:
          value: []
          reflect: true

