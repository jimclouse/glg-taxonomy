#core-websocket

A polymer websocket adapter that provides a declarative way to drop 
reconnecting websockets onto a page.  If multiple URLs are provided, 
the socket will automatically connect to the fastest and roll through
them in the event that a connection is lost.




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














##Methods
####send
Sends the provided message via the websocket.  Optional callback parameter can be provided
will be called with the response, or you can listen for the `data` event.  The send call 
returns a queryId or messageId that will be included in the response assuming the responding server includes it.
*The callback will only function if this is the case.*






####handleData
As request data is returned, we bubble a data event but also if possible associate it
with the proper callback and fire that as well.







##Event Handlers







This socket is powerful. So powerful that it will try forever to reconnect to
all the specified servers until you call close. It will not give up. It will not
relent.

OK -- so this socket, on send, will roll through all connected sockets, and the
first one that does a successful transport wins. All connected sockets are
possible sources for incoming messages.

Oh -- and this is a *client side* WebSocket, and is set up to work
with [Browserify](http://browserify.org/). Client side matters since it initiates
the WebSocket connection, so is the only side in a place to reconnect.

If you explicitly call `close()`, then this socket will really close, otherwise
it will work to automatically reconnect `onerror` and `onclose` from the
underlying WebSocket.

#Events
##onserver(event)
This is fired when the active server changes, this will be after a `send` as
that is the only time the socket has activity to 'know' it switched servers.











Event relay. Maybe I should call it *baton* not *evt*. Anyhow, the
`ReconnectingWebSocket` handles the underlying `WebSocket` so we don't need
to hookup each time we reopen.












Send, hunting through every socket until one goes.



This is a very simple form of stick preference for the last socket that worked.















Close all the sockets.





Empty shims for the event handlers. These are just here for discovery via
the debugger.







Publish this object for browserify.


This has the exact same API as
[WebSocket](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket). So
you get going with:

```
ReconnectingWebSocket = require(reconnecting-websocket)
ws = new ReconnectingWebSocket('ws://...');
```

#Events
##onreconnect(event)
This callback is fired when the socket reconnects. This is separated from the
`onconnect(event)` callback so that you can have different behavior on the
first time connection from subsequent connections.
##onsend(event)
Fired after a message has gone out the socket.
##ws
A reference to the contained WebSocket in case you need to poke under the hood.

This may work on the client or the server. Because we love you.








The all powerful connect function, sets up events and error handling.




























Empty shims for the event handlers. These are just here for discovery via
the debugger.







Publish this object for browserify.

