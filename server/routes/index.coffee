express = require 'express'
asset = require '../modules/asset'

router = express.Router()

router.get '/', (req, res) ->
  res.render 'index', title: 'Container'
router.get '/:keyID/:vCode/:characterID', (req, res, next) ->
  asset.load req.params
  .then (result) -> res.send result
  .catch (err) -> next err

module.exports = router
