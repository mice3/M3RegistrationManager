
/**
 * Module dependencies.
 */

var express = require('express');
var routes = require('./routes');
var user = require('./routes/user');
var http = require('http');
var path = require('path');
var registrationManager = require('./M3RegistrationManager');
var Sequelize = require('sequelize-mysql').sequelize
var mysql     = require('sequelize-mysql').mysql

var app = express();

// all environments
app.set('port', process.env.PORT || 1337);
app.set('views', __dirname + '/views');
app.set('view engine', 'jade');
app.use(express.favicon());
app.use(express.logger('dev'));
app.use(express.bodyParser());
app.use(express.methodOverride());
app.use(app.router);
app.use(require('stylus').middleware(__dirname + '/public'));
app.use(express.static(path.join(__dirname, 'public')));


//var connectionString = "mysql://b3eabb3e7d63ad:07433fb9@eu-cdbr-west-01.cleardb.com/heroku_251c5e3cf529663";
var connectionString = "mysql://root:admin@127.0.0.1/registration";
var sequelize = new Sequelize(connectionString);

// development only
if ('development' == app.get('env')) {
  app.use(express.errorHandler());
}

app.get('/', routes.index);
app.get('/users', user.list);
app.post('/createDevice', function(req, res) {
    registrationManager.createDevice(req, res);
});

http.createServer(app).listen(app.get('port'), function(){
  console.log('Express server listening on port ' + app.get('port'));
});
