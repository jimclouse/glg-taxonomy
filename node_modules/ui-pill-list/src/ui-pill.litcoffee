#ui-pill
*TODO* tell me all about your element.

    Polymer 'ui-pill',

##Events
*TODO* describe the custom event `name` and `detail` that are fired.

##Attributes and Change Handlers

##Methods

##Event Handlers

      onRemove: (e, _, src) ->
        e.stopPropagation()
        target = src.templateInstance.model
        @fire "pill-removed", {target}
      
      onClick: (e, _, src) ->
        @fire "pill-clicked", e