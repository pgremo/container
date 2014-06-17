neow = require 'neow'
_ = require 'lodash'

client = new neow.EveCentralClient()

exports.get = (props) ->
  client.fetch 'marketstat', props
  .then (result) ->
    _.reduce _.flatten([result.marketstat.type ? []]), ((seed, x) -> seed[x.id] = x; seed), {}
