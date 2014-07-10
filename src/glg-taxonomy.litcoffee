#glg-taxonomy
*TODO* tell me all about your element.


    Polymer 'glg-taxonomy',

##Events
*TODO* describe the custom event `name` and `detail` that are fired.

##Attributes and Change Handlers
      
      elasticParams:
          query:
              match:
                  name: null

          facets:
              firstLevel:
                  terms:
                      field: "firstLevel"

          highlight:
              order: "score"
              fields:
                  name:
                      number_of_fragments: 0

      payload:
        verb: "POST"
        url: "http://localhost:9200/taxonomy_sectors/_search"

      resultsChanged: (oldVal, newVal) ->
        @mapTree(newVal) if newVal

##Methods

      mapElasticResults: (response) ->  
        @results = response.hits.hits.map (h) -> h._source
        console.log response.facets
        @facets = response.facets[@filterPropertes[@filterLevel]].terms
        @total = response.hits.total

      mapTree: (results) ->
        
        results.sort (a, b) ->
          if (a.fullPath > b.fullPath)
           return 1
          if (a.fullPath < b.fullPath)
            return -1
          return 0

        paths = {}
        @items = []
        results.forEach (r, j) =>

          r.parts = r.fullPath.split(" > ")
          r.parts.forEach (p, i, list) =>

            parentKey = list.slice(0, i).join(" > ")
            parentKey = "root-#{p}" if i == 0

            if !paths[parentKey] && r.name != p
              @items.push({name:p, depth:i}) 
            paths[parentKey] = true
            
            if r.name == p
              r.match = true
              @items.push(r)

##Event Handlers

      removeFacet: (e, _, src) ->
        console.log arguments


      addFacet: (e, _, src) ->
        #set filter on clicked facet
        @activeFacet = e.target.templateInstance.model.f
        @activeFacets.push(@activeFacet)
        @elasticParams.filter ?= {bool:{must:{terms:{}}}}
        @elasticParams.filter.bool.must.terms[@filterPropertes[@filterLevel]] = [@activeFacet.term]

        # field = @filterPropertes[@filterLevel]
        # @elasticParams.facets[field] = {filter:{term: {}}}
        # @elasticParams.facets[field].filter.term[field] = @activeFacet.term

        #get facets back for next level
        @filterLevel += 1
        field = @filterPropertes[@filterLevel]
        @elasticParams.facets[field] = 
          terms:
            field: field

        @payload.data = @elasticParams
        @$.imposter.send @payload

      sendQuery: (e) ->
        @elasticParams.query.match.name = e.detail.value
        delete @activeFacet 
        @payload.data = @elasticParams
        @$.imposter.send @payload

      queryResult: (e) ->
        return unless e.detail.text
        @mapElasticResults e.detail.text

##Polymer Lifecycle

      created: ->

      ready: () ->
          @page ?= 1
          @pageSize ?= 20
          @items ?= []

          @filterLevel = 0
          @filterPropertes = [
            "firstLevel"
            "secondLevel"
            "thirdLevel"
          ]
          @activeFacets = []

      attached: ->
        @elasticParams.from = (@page - 1) * @pageSize
        @elasticParams.size = @pageSize

        @$.typeahead.addEventListener 'inputChange', @sendQuery.bind(@)
        @$.imposter.addEventListener 'data', @queryResult.bind(@)

      domReady: ->

      detached: ->
