#glg-taxonomy
*TODO* tell me all about your element.

    Polymer 'glg-taxonomy',

##Events
*TODO* describe the custom event `name` and `detail` that are fired.

##Attributes and Change Handlers

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
        # highlighting
        re = new RegExp @payload.body.term, "ig"
        results = results.map (result) =>
          result.highlight = result.fullPath.replace re, "<em>#{@payload.body.term}</em>"
          return result

        @items = results
            

##Event Handlers

      sendQuery: (e) ->
        delete @termMatched
        @payload.body.term = e.detail.value
        @$.websocket.send @payload

      queryResult: (e) ->
        results = e.detail.text || []
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

        typeMap = 
          'sector': "sector"
          'job-function': "job_function"
          'region': "region"

        @limit = 8

        @payload = 
          verb: "post"
          url: @endpoint
          headers:
            authorization: "Basic c3ZjU3RhcnBobGVldExEQVA6NHJhdFVSYXM="
          json: true
          body:
            type: typeMap[@type]
            limit: @limit
            term: null

        @$.typeahead.addEventListener 'inputchange', @sendQuery.bind(@)
        @$.websocket.addEventListener 'data', @queryResult.bind(@)
        
        document.addEventListener 'click', () =>
          @$.typeahead.$.results.classList.remove 'open'

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

