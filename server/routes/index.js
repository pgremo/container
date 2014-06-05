var express = require('express'),
  asset = require('../modules/asset');

var router = express.Router();

router.get('/', function (req, res) {
  res.render('index', {title: 'Container'});
});
router.get('/:keyID/:vCode/:characterID', function (req, res, next) {
  asset.load(req.params)
    .then(function (result) {
      res.send(result);
    })
    .catch(function (err) {
      next(err);
    });
});

module.exports = router;
