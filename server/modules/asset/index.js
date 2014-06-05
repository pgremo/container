require('es6-shim');
var neow = require('neow'),
  _ = require('lodash'),
  fs = require('fs'),
  client = new neow.EveClient();

Promise.promisify = function (original, callback) {

  callback = callback || function (err, result) {
    if (err) this.reject(err);
    else this.resolve(result);
  };

  return function () {
    var args = Array.prototype.slice.call(arguments);
    return new Promise(function (resolve, reject) {
      callback.resolve = resolve;
      callback.reject = reject;
      args.push(callback.bind(callback));
      original.apply(original, args);
    });
  };
};

Promise.prototype.spread = function (resolve) {
  return this.then(function (result) {
    return resolve.apply(this, result);
  });
};

Array.prototype.chunk = function (size) {
  var result = [];
  for (var i = 0; i < this.length; i += size)
    result.push(this.slice(i, i + size));
  return result;
};

loadFile = function (file) {
  return Promise.promisify(fs.readFile)(file, 'utf8')
    .then(function (result) {
      return JSON.parse(result);
    });
};

var locations = loadFile('./server/modules/asset/locations.json'),
  stations = loadFile('./server/modules/asset/stations.json'),
  types = loadFile('./server/modules/asset/types.json');

exports.load = function (props) {
  var assets = Promise.all([types, client.fetch('corp:AssetList', props)])
    .spread(function (types, assets) {
      var walk = function (items, func) {
        var result = []
        for (key in items) {
          if (items.hasOwnProperty(key)) {
            var value = items[key];
            func(value);
            if (value.contents != null) {
              value.contents = walk(value.contents, func);
            }
            result.push(value);
          }
        }
        return result;
      };
      var named = [];
      var items = walk(assets.assets, function (value) {
        var type = types[value.typeID];
        value.typeName = value.itemName = type != null ? type.typeName : null;
        var groupID = type.groupID;
        if (value.singleton === "1" && (groupID === "12" || groupID === "340" || groupID === "365" || groupID === "448" || groupID === "649" || type.categoryID === "6")) {
          named.push(value);
        }
      });
      var chunks = named.chunk(250).map(function (x) {
        return client.fetch('corp:Locations', _.assign({IDs: x.map(function (y) {
          return y.itemID;
        }).join(',')}, props));
      });
      return Promise.all(chunks)
        .then(function (results) {
          return results.reduce(function (seed, x) {
            return _.assign(seed, x.locations);
          }, {});
        })
        .then(function (locations) {
          for (var i = 0; i < named.length; i++) {
            var item = named[i];
            item.itemName = locations[item.itemID].itemName;
          }
          return items;
        });
    });
  var conquerables = client.fetch('eve:ConquerableStationList')
    .then(function (result) {
      return result.outposts;
    });
  return Promise.all([conquerables, stations, locations, assets])
    .spread(function (conquerables, stations, locations, assets) {
      return assets.map(function (item) {
        item.locationName = (function (locationID) {
          if (66000000 < locationID && locationID < 66014933)
            return stations[(locationID - 6000001).toString()];
          else if (66014934 < locationID && locationID < 67999999)
            return conquerables[(locationID - 6000000).toString()].stationName;
          else if (60014861 < locationID && locationID < 60014928)
            return conquerables[locationID.toString()].stationName;
          else if (60000000 < locationID && locationID < 61000000)
            return stations[locationID.toString()];
          else if (locationID >= 61000000)
            return conquerables[locationID.toString()].stationName;
          else
            return locations[locationID.toString()];
        })(item.locationID);
        return item;
      });
    }).then(function (result) {
      return _.groupBy(result, function (x) {
        return x.locationName;
      });
    });
};
