#glg-taxonomy

    Polymer 'glg-taxonomy',

##Events


##Attributes and Change Handlers
      
      elasticParams:
          query:
              multi_match:
                  query: null
                  fields: ["name","fullPath"]

          facets:
              firstLevel:
                  terms:
                      field: "firstLevel"

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
        @items = results

##Event Handlers

      sendQuery: (e) ->
        @elasticParams.query.multi_match.query = e.detail.value
        @payload.data = @elasticParams
        @$.websocket.send @payload

      queryResult: (e) ->
        return unless e.detail.text
        response = e.detail.text
        results = response.hits.hits.map (h) -> 
          Object.keys(h.highlight).forEach (k) -> 
            h._source[k] = h.highlight[k][0]
          h._source

        @termMatched = results.length > 0
        @results = results

##Polymer Lifecycle

      created: ->

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

        @payload = 
          verb: "POST"
          url: "https://elastico.glgroup.com/taxonomy_#{urlMap[@type]}/_search"

        @elasticParams.from = 0
        @elasticParams.size = 12

        @$.typeahead.addEventListener 'inputchange', @sendQuery.bind(@)
        @$.websocket.addEventListener 'data', @queryResult.bind(@)

        @addEventListener 'itemremoved', (e) ->
          index = @value.indexOf e.detail.item
          @value.splice index, 1

        @addEventListener 'itemadded', (e) ->
          @results = []
          @value.push e.detail.item


      domReady: ->

      detached: ->

      publish:
        value:
          value: []
          reflect: true

