#!/usr/bin/env node
var debug = require('debug')('container'),
  app = require('../server');

port = process.env.PORT || 3000;

app.set('port', port);

server = app.listen(port, function () {
  debug("Express server listening on port #{server.address().port}");
});
