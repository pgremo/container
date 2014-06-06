require 'es6-shim'
neow = require 'neow'
_ = require 'lodash'
fs = require 'fs'
client = new neow.EveClient()

Promise.promisify = (func, thisObject) ->
  return () ->
    args = Array.prototype.slice.call arguments
    return new Promise (resolve, reject) ->
      args.push (err, result) ->
        if err? then reject err
        else resolve result
      func.apply thisObject or null, args

Promise::spread = (resolve, reject) ->
  this.then (result) ->
    resolve result...
  , reject

Array::chunk = (size) ->
  this[x..x + size] for x in [0..this.length] by size

loadFile = (file) ->
  Promise.promisify(fs.readFile)(file, 'utf8')
  .then (result) -> JSON.parse result

locations = loadFile './server/modules/asset/locations.json'
stations = loadFile './server/modules/asset/stations.json'
types = loadFile './server/modules/asset/types.json'

exports.load = (props) ->
  assets = Promise.all [types, client.fetch 'corp:AssetList', props]
  .spread (types, assets) ->
    walk = (items, func) ->
      for key, value of items
        do (value) ->
          func value
          if value.contents?
            value.contents = walk value.contents, func
          value

    named = []
    items = walk assets.assets, (value) ->
      type = types[value.typeID]
      value.typeName = value.itemName = type?.typeName
      if value.singleton is "1" and (type.groupID in ["12", "340", "365", "448", "649"] or type.categoryID is "6")
        named.push value

    chunks = for x in named.chunk 250
      client.fetch 'corp:Locations', _.assign {}, props, {IDs: x.map((x) -> x.itemID).join(',')}
    Promise.all chunks
    .then (results) ->
      results.reduce (seed, x) ->
        _.assign seed, x.locations
      , {}
    .then (locations) ->
      for item in named
        item.itemName = locations[item.itemID].itemName
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
