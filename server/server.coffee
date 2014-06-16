express = require 'express'
path = require 'path'
favicon = require 'static-favicon'
cookieParser = require 'cookie-parser'
bodyParser = require 'body-parser'
logger = require 'morgan'
jade = require 'jade'
routes = require './routes'

app = express()

app.set 'views', path.join __dirname, 'views'
app.set 'view engine', 'jade'

app.use favicon()
app.use logger 'dev'
app.use bodyParser.json()
app.use bodyParser.urlencoded()
app.use cookieParser()
app.use express.static path.join __dirname, 'app'

app.use '/', routes

app.use (req, res) ->
  res.status 404
  res.send 'Not Found'

app.get '*', (req, res, next) ->
  err = new Error 'Not Found'
  err.status = 404
  next err

app.use (err, req, res, next) ->
  res.status err.status or 500
  res.render 'error',
    message: err.message,
    error: if app.get('env') is 'development' then err else {}

module.exports = app
