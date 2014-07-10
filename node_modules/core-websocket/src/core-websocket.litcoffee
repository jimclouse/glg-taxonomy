#core-websocket

A polymer websocket adapter that provides a declarative way to drop 
reconnecting websockets onto a page.  If multiple URLs are provided, 
the socket will automatically connect to the fastest and roll through
them in the event that a connection is lost.

    _       = require('lodash')
    HuntingWebsocket  = require('./hunting-websocket.litcoffee')

    Polymer 'core-websocket',

##Events
####data
Emits data as it's retreived, with the detail containing the data received and 
the source (assuming one was provided in the data request)

####serverChange
If servers are changed for any reason this event is fired


##Attributes
####json
Specifies whether the adapter will automatically attempt to json serialize/deserialize messages.  Defaults to `true`.
####urls
As urls change, the socket reinitializes with the new target servers.  *In process messages could be lost 
during the switch to a new set of servers.*
      
      urlsChanged: ->
        @socket.close() if @socket
        urls = @urls
        urls = JSON.parse(urls) if @urls.match /[^[.*]$]/
        urls = [urls] unless _.isArray urls
        @socket = new HuntingWebsocket(urls)

        @socket.onserver = (evt) => 
          @fire "serverChange", { server: evt.server }

        @socket.onerror = (err) => 
          @fire "error", err

        @socket.onmessage = (evt) =>
          @handleData(evt.data) if evt.data

##Methods
####send
Sends the provided message via the websocket.  Optional callback parameter can be provided
will be called with the response, or you can listen for the `data` event.  The send call 
returns a queryId or messageId that will be included in the response assuming the responding server includes it.
*The callback will only function if this is the case.*

      send: (message, cb) ->
        message.messageId = message.queryId = _.random(0,99999).toString()        
        @callbacks[message.messageId] = cb
        @socket.send(if @json then JSON.stringify(message) else message)
        return message.messageId

####handleData
As request data is returned, we bubble a data event but also if possible associate it
with the proper callback and fire that as well.

      handleData: (data) ->
        data = JSON.parse(data) if @json
        messageId = data.messageId or data.queryId or 'foo'
        @fire 'data', data
        @callbacks[messageId]?(data)
        delete @callbacks[messageId]

##Event Handlers
      
      attached: ->
        @callbacks = {}
        @json ?= true 

      detached: ->
        @socket.close()
