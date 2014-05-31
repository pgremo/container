require 'es6-shim'
neow = require 'neow'
_ = require 'lodash'
fs = require 'fs'
client = new neow.EveClient()

loadFile = (file) ->
  new Promise (resolve, reject) ->
    fs.readFile file, 'utf8', (err, data) ->
      if err?
        reject err
      else
        try
          resolve JSON.parse data
        catch error
          reject error

locations = loadFile './server/modules/asset/locations.json'
stations = loadFile './server/modules/asset/stations.json'
types = loadFile './server/modules/asset/types.json'

Promise::spread = (resolve, reject) ->
  this.then (result) ->
    resolve result...
  , reject

Array::chunk = (size) ->
  this[x..x + size] for x in [0..this.length] by size

exports.load = (props) ->
  assets = Promise.all [types, client.fetch 'char:AssetList', props]
  .spread (types, assets) ->
    named = {}
    recur = (items) ->
      for key, value of items
        do (value) ->
          type = types[value.typeID]
          value.typeName = value.itemName = type?.typeName
          if value.singleton is "1" and (type.groupID in ["12", "340", "448", "649"] or type.categoryID is "6")
            named[value.itemID] = value
          if value.contents?
            value.contents = recur value.contents
          value
    items = recur assets.assets
    chunks = for x in Object.keys(named).chunk(250)
      client.fetch 'char:Locations', _.assign {}, props, {IDs: x.join(',')}
    Promise.all chunks
    .then (results) ->
      results.reduce (seed, x) ->
        _.assign seed, x.locations
      , {}
    .then (locations) ->
      for itemID, location of locations
        named[itemID].itemName = location.itemName
      items

  conquerables = client.fetch 'eve:ConquerableStationList'
  .then (result) -> result.outposts
  Promise.all [conquerables, stations, locations, assets]
  .spread (conquerables, stations, locations, assets) ->
    for item in assets
      locationID = parseInt item.locationID
      item.locationName = switch
        when 66000000 < locationID < 66014933 then stations[(locationID - 6000001).toString()]
        when 66014934 < locationID < 67999999 then conquerables[(locationID - 6000000).toString()].stationName
        when 60014861 < locationID < 60014928 then conquerables[locationID.toString()].stationName
        when 60000000 < locationID < 61000000 then stations[locationID.toString()]
        when locationID >= 61000000 then conquerables[locationID.toString()].stationName
        else locations[locationID.toString()]
      item
  .then (result) ->
    _.groupBy result, (x) -> x.locationName
