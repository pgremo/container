gulp = require 'gulp'
mocha = require 'gulp-mocha'
coffeelint = require 'gulp-coffeelint'
nodemon = require 'gulp-nodemon'

onError = (err) ->
  console.log err.toString()
  this.emit 'end'

gulp.task 'lint',() ->
  gulp.src ['./server/**/*.coffee', './test/**/*.coffee', 'gulpfile.coffee']
  .pipe coffeelint().on 'error', onError
  .pipe coffeelint.reporter()

gulp.task 'mocha',() ->
  gulp.src ['./test/*.coffee']
  .pipe mocha(reporter: 'spec').on 'error', onError

gulp.task 'server', ->
  nodemon script: './server/bin/www.coffee'
  .on 'start', () ->
    console.log """
        Starting up context, serving on [localhost:#{process.env.PORT or 3000}]
        Hit CTRL-C to stop the server
      """
  .on 'quit', () ->
    console.log 'App has quit'
  .on 'restart', (files) ->
    console.log "App restarted due to: #{files}"
  gulp.watch ['./server/**/*.coffee','./test/*.coffee'], ['lint', 'mocha']

gulp.task 'build', ['lint', 'mocha']

gulp.task 'default', ['build']

