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
        newValue = JSON.parse(newValue) if typeof(newValue) is "string"
        @$.typeahead.value = newValue.map (v) -> {item:v}
        @fire('change', newValue) if newValue != oldValue

##Methods

      formatResults: (results) ->        
        # highlighting
        re = new RegExp @payload.data.term, "ig"
        results = results.map (result) =>
          result.highlight = result.fullPath.replace re, "<em>#{@payload.data.term}</em>"
          return result

        @items = results
            

##Event Handlers

      sendQuery: (e) ->
        delete @termMatched
        @payload.data.term = e.detail.value
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

        urlMap = 
          'sector': "Sector"
          'job-function': "JobFunction"
          'region': "Region"

        @payload = 
          verb: "POST"
          url: "https://query.glgroup.com/taxonomy/search#{urlMap[@type]}.mustache"
          data:
            limit: 12

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

