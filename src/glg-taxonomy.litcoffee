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

      resultsChanged: (oldVal, newVal) ->
        @mapTree(newVal) if newVal

##Methods

      mapTree: (results) ->
        
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
            items.push({header:true, parts:parents})
            
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

      partClicked: (e, _, src) ->
        e.preventDefault()
        e.stopPropagation()
        part = src.templateInstance.model.part
        value = @$.typeahead.$.input.value
        @$.typeahead.$.input.value = "#{part}"
        

      onClick: (e, _, src) ->
        console.log arguments, "onClick"
        e.preventDefault()
        e.stopPropagation()
        item = src.templateInstance.model.item
        return if item.header
        @selected.push(item)

      sendQuery: (e) ->
        @nectarParams.query = e.detail.value
        @$.websocket.send @nectarParams

      queryResult: (e) ->
        @results = e.detail.results[@type]

##Polymer Lifecycle

      created: ->

      ready: () ->
          @items ?= []
          @selected ?= []

      attached: ->
        @nectarParams.entity.push @type
        @nectarParams.options.howMany = 48
        
        @$.typeahead.addEventListener 'inputChange', @sendQuery.bind(@)
        @$.websocket.addEventListener 'data', @queryResult.bind(@)
        
        document.addEventListener 'click', () =>
          @$.typeahead.$.results.classList.remove 'open'

        @addEventListener 'remove', (e) ->
          # something weird happens with the target
          # a log shows path with 15 nodes, then on inspect it has 0 and the target is glg-taxonomy
          # for now cheat and grab path[0] which is the ui-pill
          node = e.path[0].templateInstance.model
          index = @selected.indexOf node
          @selected.splice index, 1

      domReady: ->

      detached: ->
