Promise = require 'bluebird'
neow = require 'neow'
_ = require 'lodash'
fs = require 'fs'
chunk = require 'chunk'
client = new neow.EveClient()

Promise.promisifyAll fs

loadFile = (file) ->
  fs.readFileAsync file, 'utf8'
  .then JSON.parse

locations = loadFile './server/modules/asset/locations.json'
stations = loadFile './server/modules/asset/stations.json'
types = loadFile './server/modules/asset/types.json'

exports.get = (props) ->
  raw = client.fetch 'corp:AssetList', props
  .then (result) -> result.assets
  assets = Promise.join types, raw,  (types, raw) ->
    walk = (items, func) ->
      for key, value of items
        do (value) ->
          func value
          if value.contents?
            value.contents = walk value.contents, func
          value

    named = []
    items = walk raw, (value) ->
      type = types[value.typeID]
      value.typeName = value.itemName = type.typeName
      value.groupID = type.groupID
      if value.singleton is '1' and (type.groupID in ['12', '340', '365', '448', '649'] or type.categoryID is '6')
        named.push value

    chunks = for x in chunk named, 250
      client.fetch 'corp:Locations', _.assign {IDs: x.map((x) -> x.itemID).join(',')}, props
    Promise.reduce chunks, (seed, x) ->
      _.assign seed, x.locations
    , {}
    .then (locations) ->
      for item in named
        item.itemName = locations[item.itemID].itemName
    .return items

  conquerables = client.fetch 'eve:ConquerableStationList'
  .then (result) -> result.outposts
  Promise.join conquerables, stations, locations, assets,  (conquerables, stations, locations, assets) ->
    for item in assets
      locationID = parseInt item.locationID
      item.locationName = switch
        when 66000000 < locationID < 66014933 then stations[(locationID - 6000001).toString()]
        when 66014934 < locationID < 67999999 then conquerables[(locationID - 6000000).toString()].stationName
        when 60014861 < locationID < 60014928 then conquerables[item.locationID].stationName
        when 60000000 < locationID < 61000000 then stations[item.locationID]
        when locationID >= 61000000 then conquerables[item.locationID].stationName
        else locations[item.locationID]
      item
