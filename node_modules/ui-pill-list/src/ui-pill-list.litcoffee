#ui-pill-list
A collection of ui-pill items

    Polymer 'ui-pill-list',

##Attributes and Change Handlers

      itemsChanged: (oldVal, items) ->
        @setValue(items)

##Methods

      setValue: (value) ->
        if @useDefault
          @items = value
        else
          @template.model = {items:value}

      getValue: () ->
        values = []
        for child in @querySelectorAll("ui-pill")
          values.push child.value || child.templateInstance?.model || child.innerText

        for child in @shadowRoot.querySelectorAll("ui-pill")
          values.push child.templateInstance.model
        values

Add a new item to the collection
      
      add: (item) -> 
        @items = @items.concat(item)

##Event Handlers

      pillRemoved: (e) ->
          e.stopPropagation()

          #lightdom children
          for child in @querySelectorAll("ui-pill")
            @removeChild child if child == e.detail.target

          #shadowdom children
          for child in @shadowRoot.querySelectorAll("ui-pill")
            @shadowRoot.removeChild child if child == e.detail.target


##Polymer Lifecycle

      created: ->
        # does the lightdom have a template, if so it's a custom template
        @template = @querySelector("template")
        @useDefault = @template == null

        #getters/setters in coffeescript
        Object.defineProperty @, "value",
          get: @getValue
          set: @setValue

      attached: ->
        
        @addEventListener "pill-removed", @pillRemoved