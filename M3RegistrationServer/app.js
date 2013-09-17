
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

var sequelize = new Sequelize(registrationManager.connectionString);

// development only
if ('development' == app.get('env')) {
  app.use(express.errorHandler());
}

app.get('/', routes.index);
app.get('/users', user.list);
app.post('/createDevice', function(req, res) {
    registrationManager.createDevice(req, res);
});

app.get('/showUsers', function(req, res) {
    var User = sequelize.import(__dirname + "/models/User");

    User.findAll().success(function(users) {
        res.writeHead(200, {"Content-Type": "application/json"});
        for (var i = 0; i < users.length; i++) {
            var user = users[i];
            if (user.facebookId) {
                res.write('facebook '+ user.email + '\n');
            } else if (user.googleId) {
                res.write('google '+ user.email + '\n');
            } else if (user.twitterId) {
                res.write('twitter '+ user.twitterName + '\n');
            } else {
                res.write('email '+ user.email + '\n');
            }
        }
        res.end();
    });
});

http.createServer(app).listen(app.get('port'), function(){
  console.log('Express server listening on port ' + app.get('port'));
});
