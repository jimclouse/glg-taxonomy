#glg-taxonomy

    Polymer 'glg-taxonomy',

##Events


##Attributes and Change Handlers

      elasticParams:
        query:
          filtered:
            query:
              bool:
                must: [
                  
                  {
                    prefix:
                      nodeName_simple:
                        value: null
                        boost: 4
                  }
                  {
                    match:
                      nodeName_stemmed:
                        query: null
                        type: "phrase_prefix"
                        boost: 2
                  }
                  {
                    constant_score:
                      query:
                        match:
                          nodeName_stemmed:
                            query: null
                            operator: "and"
                            boost: 3
                  }     
                  {
                    match:
                      nodeName_stemmed:
                        query: null
                        operator: "or"
                        boost: 2
                  }
                  # {
                  #   match:
                  #     fullPath:
                  #       query: null
                  #       operator: "and"
                  #       boost: 1.5
                  # }
                  # {
                  #   match:
                  #     fullPath:
                  #       query: null
                  #       operator: "or"
                  # }
                ]
            filter:
              bool:
                must: []

        sort:
          [
            # depth:
            #   order: "asc"
            
            _score:
             order: "desc"
            
            id:
              order: "asc"
          ]

        facets:
          level_0:
            terms:
              field: "level_0"

        highlight:
          order: "score"
          fields:
            nodeName:
              number_of_fragments: 0
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
          parts = item.fullPath.split(' > ')
          #highlights = item.highlight.fullPath.split(' > ') || []
          item.parts = parts.map (part, i) ->
            {nodeName:part, highlight: part, depth:i, parts: parts.slice 0, i + 1}
          item

      browseToPart: (e, _, src) ->

        e.preventDefault()
        e.stopPropagation()
        part = src.templateInstance.model.part
        console.log src.templateInstance.model
        
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

        @$.websocket.send @payload
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
          h._source.highlight = {}
          Object.keys(h.highlight).forEach (k) -> 
            h._source.highlight[k] = h.highlight[k][0]
          h._source["_score"]  = h._score
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
          url: "http://localhost:9200/taxonomy_#{urlMap[@type]}/_search"
          json: true
          body: @elasticParams
          # headers: 
          #   authorization: "Basic c3ZjU3RhcnBobGVldExEQVA6NHJhdFVSYXM="

        @activeFacets = []
        @availableFacets = []
        @facetDepth = 0
        @showFilter = false

        @queryTerm = ""

        @elasticParams.from = 0
        @elasticParams.size = 8
        
        @$.typeahead.addEventListener 'inputchange', (e) =>
          value = (e.detail.value || "").trim()
          @elasticParams.query.filtered.query.bool.should[0].prefix.nodeName_simple.value = value
          @elasticParams.query.filtered.query.bool.should[1].match.nodeName_stemmed.query = value
          @elasticParams.query.filtered.query.bool.should[2].constant_score.query.match.nodeName_stemmed.query = value
          @elasticParams.query.filtered.query.bool.should[3].match.nodeName_stemmed.query = value
          # @elasticParams.query.filtered.query.bool.should[4].match.fullPath.query = value
          # @elasticParams.query.filtered.query.bool.should[5].match.fullPath.query = value
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

