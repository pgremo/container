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

exports.load = (props) ->
  conquerables = client.fetch 'eve:ConquerableStationList'
  .then (result) -> result.outposts
  assets = client.fetch 'char:AssetList', props

  assets = Promise.all [types, assets]
  .then (result) ->
    [types, assets] = result
    named = {}
    recur = (items) ->
      for key, value of items
        do (value) ->
          value.typeName = value.itemName = types[value.typeID]
          if value.contents?
            named[value.itemID] = value
            value.contents = recur value.contents
          value
    items = recur assets.assets
    new Promise (resolve, reject) ->
      client.fetch 'char:Locations', _.assign {}, props, {IDs: Object.keys named}
      .then (locations) ->
        for itemID, location of locations.locations
          named[itemID].itemName = location.itemName
        resolve items
      .catch (err) -> reject err
  .catch (err) -> console.log err

  Promise.all [conquerables, stations, locations, assets]
  .then (result) ->
    [conquerables, stations, locations, assets] = result
    for item in assets
      locationID = parseInt item.locationID
      item.locationName =
        if 66000000 < locationID < 66014933
          stations[(locationID - 6000001).toString()]
        else if 66014934 < locationID < 67999999
          conquerables[(locationID - 6000000).toString()].stationName
        else if 60014861 < locationID < 60014928
          conquerables[locationID.toString()].stationName
        else if 60000000 < locationID < 61000000
          stations[locationID.toString()]
        else if locationID >= 61000000
          conquerables[locationID.toString()].stationName
        else locations[locationID.toString()]
      item
  .catch (err) -> console.log err
