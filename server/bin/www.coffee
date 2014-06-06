#!/usr/bin/env coffee
debug = require('debug') 'container'
app = require '../server'

port = process.env.PORT or 3000

app.set 'port', port

server = app.listen port, () ->
  debug "Express server listening on port #{server.address().port}"
