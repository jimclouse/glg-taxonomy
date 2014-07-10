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
        @results = response.hits.hits.map (h) -> 
          h._source._score = h._score
          h._source
        @total = response.hits.total


      mapTree: (results) ->
        
        results.sort (a, b) ->
          if (a.fullPath > b.fullPath)
           return 1
          if (a.fullPath < b.fullPath)
            return -1
          return 0

        @items = []
        lastKey = null
        groupDepth = 0
        groups = []
        items = []

        results.forEach (r, j) =>
          parents = r.parts.slice(0, r.parts.length - 1)
          parentKey = parents.join(" > ")

          if parentKey.indexOf(lastKey) == -1
            
            if items.length
              items[0].score = items.reduce (acc, v) ->
                if v._score?
                  acc += v._score
                acc
              , 0

              groups.push items
              items = []

            groupDepth = parents.length - 1
            items.push({header:true, parts:parents})
          
          r.groupDepth = groupDepth
          items.push(r)
          lastKey = parentKey

        groups.sort (a, b) ->
          if (a[0].score < b[0].score)
           return 1
          if (a[0].score > b[0].score)
            return -1
          return 0

        groups.forEach (g) => @items = @items.concat(g)
            

##Event Handlers

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
