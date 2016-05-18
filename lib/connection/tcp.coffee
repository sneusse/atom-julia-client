net = require 'net'

client = require './client'

module.exports =
  server: null
  port: null
  sock: null

  buffer: (f) ->
    buffer = ['']
    (data) ->
      str = data.toString()
      lines = str.split '\n'
      buffer[0] += lines.shift()
      buffer.push lines...
      while buffer.length > 1
        f buffer.shift()

  listeners: []

  next: ->
    new Promise (resolve) =>
      @listeners.push resolve

  handle: (sock) ->
    return sock.end() unless @listeners.length > 0

    sock.on 'end', -> client.disconnected()
    sock.on 'error', (e) =>
      console.error 'Julia Client: TCP connection error:'
      console.error e
      client.disconnected()
    sock.on 'data', @buffer (s) =>
      client.input JSON.parse s

    @listeners.shift()
      message: (data) -> sock.write JSON.stringify data

  listen: (f) ->
    return f?(@port) if @port?
    @server = net.createServer (c) => @handle c
    @server.listen 0, '127.0.0.1', =>
      @port = @server.address().port
      f?(@port)

  disconnectFrom: ->
    @sock.end() if @sock?

  connectTo: ->
    @port = atom.config.get("julia-client.juliaClientListenPort")
    atom.notifications.addInfo "Connecting to localhost:" + @port.toString() + "..."
    client.booting()

    this.next().then (conn) =>
      client.connected conn
      atom.notifications.addInfo "Connected!"

    sock = net.createConnection @port , '127.0.0.1', =>
      sock.on 'end', =>
        client.disconnected()
        atom.notifications.addInfo "Disconnected from localhost:" + @port.toString()

      sock.on 'error', (e) =>
        console.error 'Julia Client: TCP connection error:'
        console.error e
        client.disconnected()
      sock.on 'data', @buffer (s) =>
        client.input JSON.parse s

      @sock = sock
      @listeners.shift()
        message: (data) -> sock.write JSON.stringify data

  listenOnly: ->
    p = atom.config.get("julia-client.juliaClientListenPort")
    @server = net.createServer (c) => @handle c
    @server.listen p, '127.0.0.1', =>
      client.booting()
      @port = @server.address().port
      atom.notifications.addInfo "listening on port " + @port.toString()
      this.next().then (conn) =>
        atom.notifications.addInfo "Connected!"
        client.connected conn
