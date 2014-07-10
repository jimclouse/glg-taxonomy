
#ui-typeahead-item

    Polymer 'ui-typeahead-item',

##Event Handlers

Rebubbles click events with target as this element
simplifies the checking in ui-typeahead that determines whether or not
an item has beens elected

      rebubbleClick: (evt) ->
        if evt.target isnt @
          evt.preventDefault()
          evt.stopPropagation()
          @fire 'click'

      attached: ->
        @addEventListener "click", @rebubbleClick
