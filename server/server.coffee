express = require 'express'
path = require 'path'
favicon = require 'static-favicon'
cookieParser = require 'cookie-parser'
bodyParser = require 'body-parser'
logger = require 'morgan'
jade = require 'jade'
routes = require './routes'

app = express()

# view engine setup
app.set 'views', path.join __dirname, 'views'
app.set 'view engine', 'jade'

app.use favicon()
app.use logger 'dev'
app.use bodyParser.json()
app.use bodyParser.urlencoded()
app.use cookieParser()
app.use express.static path.join __dirname, 'app'

app.use '/', routes

app.use (err, req, res, next) ->
  return next() if err.status isnt 404
  res.status 404
  res.send err.message || 'Not Found'

# catch 404 and forwarding to error handler
app.get '*', (req, res, next) ->
  err = new Error 'Not Found'
  err.status = 404
  next(err)

# error handlers

# development error handler
# will print stacktrace
if app.get('env') is 'development'
  app.use (err, req, res, next) ->
    res.status err.status or 500
    res.render 'error', {
      message: err.message,
      error: err
    }

# production error handler
# no stacktraces leaked to user
app.use (err, req, res, next) ->
  res.status err.status or 500
  res.render 'error', {
    message: err.message,
    error: {}
  }

module.exports = app
