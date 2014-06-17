Promise = require 'bluebird'
express = require 'express'
numeral = require 'numeral'
asset = require '../modules/asset'
price = require '../modules/price'
data = require '../modules/data'
config = require '../../config'
_ = require 'lodash'

router = express.Router()

filter = (items, func, acc = []) ->
  for value in items
    do (value) ->
      acc.push value if func value
      if value.contents?
        acc.concat filter value.contents, func, acc
  return acc

router.get '/', (req, res) ->
  res.render 'index', title: 'Container'

regionID = _.invert(data.regions)[config.region]
router.get '/:keyID/:vCode/:characterID', (req, res, next) ->
  asset.get req.params
  .then (result) ->
    containers = filter result, (x) -> x.singleton is '1' and x.groupID is '448'
  .then (result) ->
    typeIDs = _.uniq(_.map(_.flatten(_.filter(result, (x) -> x.contents?), 'contents'), (x) -> x.typeID))
    Promise.all [result, price.get typeid: typeIDs, regionlimit: regionID]
  .spread (containers, prices) ->
    _.map(_.flatten(_.filter(containers, (x) -> x.contents?), 'contents'), (x) ->
      x.price = prices[x.typeID].sell.avg
      x.total = numeral(x.price) * numeral(x.quantity)
    )
    containers
  .map (x) ->
    items = x.contents ? []
    x.sum = _.reduce items, ((seed, y) -> seed + y.total), 0
    x
  .then (result) -> res.send result
  .catch (err) -> next err

module.exports = router
