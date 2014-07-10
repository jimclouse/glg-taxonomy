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
              rootName:
                  terms:
                      field: "rootName"
          highlight:
              order: "score"
              fields:
                  name:
                      number_of_fragments: 0

      payload:
        verb: "POST"
        url: "https://elastico.glgroup.com/taxonomy_sectors/_search"

      resultsChanged: (oldVal, newVal) ->
        @mapTree(newVal) if newVal

##Methods

      mapElasticResults: (response) ->  
        @results = response.hits.hits.map (h) -> h._source
        @facets = response.facets.rootName.terms
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

      facetClicked: (e, _, src) ->
        @activeFacet = e.target.templateInstance.model.f

        @elasticParams.filter = 
          bool:
            must:
              terms:
                rootName: [@activeFacet.term]

        @payload.data = @elasticParams
        @$.imposter.send @payload

      sendQuery: (e) ->
        @elasticParams.query.match.name = e.detail.value
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
          

      attached: ->
        @elasticParams.from = (@page - 1) * @pageSize
        @elasticParams.size = @pageSize

        @$.typeahead.addEventListener 'inputChange', @sendQuery.bind(@)
        @$.imposter.addEventListener 'data', @queryResult.bind(@)

      domReady: ->

      detached: ->
