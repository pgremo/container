Promise = require 'bluebird'
fs = require 'fs'

Promise.promisifyAll fs

loadFile = (file) ->
  fs.readFileAsync file, 'utf8'
  .then JSON.parse

exports.locations = loadFile './server/modules/data/locations.json'
exports.stations = loadFile './server/modules/data/stations.json'
exports.types = loadFile './server/modules/data/types.json'
exports.regions = loadFile './server/modules/data/regions.json'
