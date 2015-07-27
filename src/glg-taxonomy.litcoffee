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

      getSearchBody: (term) ->
        body =
          query:
            function_score:
              filter:
                query:
                  match:
                    "nodeName.trigram": term
              functions: [
                {
                  script_score:
                    script: 'tf_script_score'
                    params:
                      field: "nodeName.trigram"
                      querystring: term
                      lowercase: true
                      foldascii: true
                    lang: 'native'
                },{
                  filter:
                    query:
                      match:
                        "nodeName.edgetrigram": term
                  boost_factor: 0.001
                },{
                  filter:
                    query:
                      match:
                        "nodeName.sort": term
                  boost_factor: 0.001
                }
              ]
              score_mode: 'sum',
              boost_mode: 'replace'
          # highlight:
          #   fields:
          #     fullPath:
          #       number_of_fragments: 0
          #       highlight_query:
          #         match:
          #           "fullPath.trigram": term

          size: @limit

        body

      formatResults: (results) ->
        results = results.map (h) ->
          #h._source.highlight = h.highlight?.fullPath[0] || h._source.fullPath
          h._source.highlight = h._source.fullPath
          h._source._score  = h._score
          h._source.closed = true
          h._source

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

        @sendBrowseQuery selectedItem

        return false

      select: (e, _, src) ->
        e.preventDefault()
        e.stopPropagation()

        model = src.templateInstance.model
        parent = src.parentElement.querySelector("select")

        selectedItem = model.branches[model.b][parent.selectedIndex]
        return false if selectedItem.id == -1

        @value = @value.concat selectedItem
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

        @sendBrowseQuery item

        return false

      sendBrowseQuery: (item) ->
        body =
          id: item.id
          type: @typeMap[@type]
          browse: true

        @$.queryXhr.body = JSON.stringify body
        @$.queryXhr.go()

      sendTermQuery: (e) ->
        delete @termMatched
        @term = e.detail.value
        @showBrowse = false
        @$.searchXhr.body = JSON.stringify @getSearchBody(e.detail.value)
        @$.searchXhr.go()

      handleQueryResponse: (e) ->
        results = e.detail.response || []
        @branches = results.reduce (acc, item) =>
          index = @selectedPath.indexOf item.nodeName
          @selectedItems.push item if index > -1
          acc[item.depth] ||= [{id:-1,nodeName:""}]
          acc[item.depth].push(item)
          acc
        ,[]

        @loading = false
        @$.typeahead.open()

      handleSearchResponse: (e) ->
        results = e.detail.response.hits?.hits || []
        @termMatched = results.length > 0
        @results = results
        @loading = false
        @$.typeahead.open()

      close: ->
        @$.typeahead.close()
        @results = []
        @branches = []
        @term = null
        @showBrowse = false

##Polymer Lifecycle

      ready: () ->
        @items ||= []
        @placeholder ||= " "

      attached: ->

        @typeMap =
          'sector': "sector"
          'job-function': "job_function"
          'region': "region"

        @limit ||= 8
        @branches = []
        @value ||= []
        @loading = false

        @$.queryXhr.withCredentials = true
        @$.typeahead.addEventListener 'inputchange', @sendTermQuery.bind(@)

        document.addEventListener 'click', (e) =>
          return if e.target is @

        @addEventListener 'itemremoved', (e) ->
          @value = @value.filter (v) -> v.id != e.detail.item.id
          @value = @value
          @close() if @value.length == 0 && !@term

        @addEventListener 'itemadded', (e) ->
          @results = []
          @value = @value.concat e.detail.item

      publish:
        value:
          reflect: true
        searchurl:
          reflect: true
        queryurl:
          reflect: true
