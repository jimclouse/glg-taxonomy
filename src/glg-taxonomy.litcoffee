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
          result.closed = true
          result.highlight = result.fullPath.replace re, "<em>#{@payload.body.term}</em>"
          result

        @items = results

      itemsChanged: (oldItems, newItems) ->
        newItems[0].focused = true if newItems?.length > 0

##Event Handlers

      nop: (e, _, src) ->
        e.preventDefault()
        e.stopPropagation()
        return false      

      filter: (e, _, src) ->
        e.preventDefault()
        e.stopPropagation()
        
        model =  src.templateInstance.model

        @selectedItems = @selectedItems.slice 0, model.b
        selectedItem = model.branches[model.b][src.selectedIndex]
        @selectedItems.push selectedItem

        @selectedPath = @selectedItems.map (item) -> item.nodeName
        
        @payload.body.id = selectedItem.id
        @payload.body.browse = true
        @send @payload

        return false      

      select: (e, _, src) ->
        e.preventDefault()
        e.stopPropagation()

        model = src.templateInstance.model
        parent = src.parentElement.querySelector("select")

        selectedItem = model.branches[model.b][parent.selectedIndex]
        return false if selectedItem.id == -1

        @value.push selectedItem
        @$.typeahead.value = @value.map (v) -> {item:v}
        return false

      browse: (e, _, src) ->
        e.preventDefault()
        e.stopPropagation()

        @showBrowse = true
        item = src.templateInstance.model.item

        @selectedPath = item.fullPath.split(' > ')
        @selectedItems = []
        
        @opened?.closed = true
        @opened = item
        @opened.closed = false
        
        @payload.body.id = item.id
        @payload.body.browse = true
        @payload.body.term = @$.typeahead.$.input.value

        @send @payload
        return false

      send: (payload) ->
        @loading = true
        @$.websocket.send payload

      sendTermQuery: (e) ->
        delete @termMatched
        @showBrowse = false
        @payload.body.term = e.detail.value
        @payload.body.browse = false
        @send @payload

      queryResult: (e) ->
        results = e.detail.text || []
        if @payload.body.browse

          @branches = results.reduce (acc, item) => 
            index = @selectedPath.indexOf item.nodeName
            @selectedItems.push item if index > -1
            acc[item.depth] ||= [{id:-1,nodeName:""}]
            acc[item.depth].push(item)
            acc
          ,[]
        else
          @termMatched = results.length > 0
          @results = results
          
        @loading = false
        @$.typeahead.open()

        
      close: ->
        @$.typeahead.close()
        @results = []
        @branches = []
        @payload.body.term = null
        @showBrowse = false

##Polymer Lifecycle

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
        @branches = []
        @value ||= []
        @loading = false

        @payload = 
          verb: "post"
          url: @endpoint
          json: true
          body:
            type: typeMap[@type]
            limit: @limit
            term: null
            parts: []

        @$.typeahead.addEventListener 'inputchange', @sendTermQuery.bind(@)
        @$.websocket.addEventListener 'data', @queryResult.bind(@)
        
        document.addEventListener 'click', (e) =>
          return if e.target is @

        @addEventListener 'itemremoved', (e) ->
          index = @value.indexOf e.detail.item
          @value.splice index, 1
          @close() if @value.length == 0 && !@payload.body.term

        @addEventListener 'itemadded', (e) ->
          @results = []
          @value.push e.detail.item

      publish:
        value:
          reflect: true

