#glg-taxonomy
*TODO* tell me all about your element.


    Polymer 'glg-taxonomy',

##Events
*TODO* describe the custom event `name` and `detail` that are fired.

##Attributes and Change Handlers
      
      nectarParams:
        entity: []
        query: null
        options:
          howMany: 5

      resultsChanged: (oldResults, newResults) ->
        return unless newResults
        @formatResults newResults

      valueChanged: (oldValue, newValue) ->
        return unless newValue
        @$.typeahead.value = newValue.map (v) -> {item:v}
        @fire('change', newValue) if newValue != oldValue

##Methods

      formatResults: (results) ->
        
        results.sort (a, b) ->
          if (a.fullPath > b.fullPath)
           return 1
          if (a.fullPath < b.fullPath)
            return -1
          return 0

        @items = []

        groupKey = null
        groupDepth = 0
        groups = []
        items = []

        results.forEach (r, j) =>
        
          r.parts = r.fullPath.split(" > ")
          parents = r.parts.slice(0, r.parts.length - 1)
          parentKey = parents.join(" > ")

          # new group or last item in results
          if parentKey.indexOf(groupKey) == -1 || results.length - 1 == j
            
            # flush  items in group
            if items.length
              items[0].score = items.reduce (acc, v) ->
                acc += v.score if v.score?
                acc
              , 0

              groups.push items
              items = []

            #set new group
            groupDepth = parents.length - 1
            groupKey = parentKey

            items.push({header:true, parts:parents, fullPath: r.fullPath})
            
          #add items to open group
          r.groupDepth = groupDepth
          items.push(r)
          

        # sort the group by 'score'
        groups.sort (a, b) ->
          if (a[0].score < b[0].score)
           return 1
          if (a[0].score > b[0].score)
            return -1
          return 0

        # flatten group
        groups.forEach (g) => @items = @items.concat(g)
            

##Event Handlers
        
      noop: (e, _, src) ->
        e.preventDefault()
        e.stopPropagation()

      sendQuery: (e) ->
        @nectarParams.query = e.detail.value
        @$.websocket.send @nectarParams

      queryResult: (e) ->
        results = e.detail.results[@type] || []
        @termMatched = results.length > 0
        @results = results

##Polymer Lifecycle

      created: ->

      ready: () ->
          @items ||= []
          @placeholder ||= ""
          @debounce ||= 250

      attached: ->
        
        @nectarParams.entity.push @type
        @nectarParams.options.howMany = 48
        
        @$.typeahead.addEventListener 'inputchange', @sendQuery.bind(@)
        @$.websocket.addEventListener 'data', @queryResult.bind(@)
        
        document.addEventListener 'click', () =>
          @$.typeahead.$.results.classList.remove 'open'

        @addEventListener 'itemremoved', (e) ->
          @value = @$.typeahead.value.map (v) -> v.item

        @addEventListener 'itemadded', (e) ->
          @results = []
          @value = @$.typeahead.value.map (v) -> v.item


      domReady: ->

      detached: ->

      publish:
        value:
          value: []
          reflect: true

