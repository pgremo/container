var express = require('express'),
  path = require('path'),
  favicon = require('static-favicon'),
  cookieParser = require('cookie-parser'),
  bodyParser = require('body-parser'),
  logger = require('morgan'),
  jade = require('jade'),
  routes = require('./routes'),
  app = express();

app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');

app.use(favicon());
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded());
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'app')));

app.use('/', routes);

app.use(function (req, res) {
  res.status(404);
  res.send(err.message || 'Not Found');
});

app.get('*', function (req, res, next) {
  err = new Error('Not Found');
  err.status = 404;
  next(err);
});

app.use(function (err, req, res, next) {
  res.status(err.status || 500);
  res.render('error', {
    message: err.message,
    error: app.get('env') == 'development' ? err : {}
  });
});

module.exports = app;
