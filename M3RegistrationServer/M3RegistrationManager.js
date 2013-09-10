/**
 * Created with JetBrains WebStorm.
 * User: dark
 * Date: 29/08/13
 * Time: 10:53
 */

var helpers = require('./Helpers');
var request = require('request');


var Sequelize = require('sequelize-mysql').sequelize

var connectionString = "mysql://b3eabb3e7d63ad:07433fb9@eu-cdbr-west-01.cleardb.com/heroku_251c5e3cf529663";

var sequelize = new Sequelize(connectionString);
var User = sequelize.import(__dirname + "/models/User")

module.exports = {
    createDevice: function (req, res) {
        res.writeHead(200, {"Content-Type": "application/json"});

        console.log('User log in / sign up');
        if (req.body.email) {
            emailLogin(req.body.email, req.body.password) (
                function callback (response) {
                    res.end(response);
                }
            );
        } else if (req.body.registrationType === 'facebook' && req.body.accessToken) {
            facebookLogin(req.body.accessToken, req.body.userDeviceId, req.body.secureCode) (
                function callback (response) {
                    res.end(response);
                }
            );
        } else if (req.body.registrationType === 'google' && req.body.accessToken) {
            googleLogin(req.body.accessToken, req.body.userDeviceId, req.body.secureCode) (
                function callback (response) {
                    res.end(response);
                }
            );
        } else if (req.body.registrationType === 'twitter' && req.body.accessToken) {
            twitterLogin(req.body.accessToken, req.body.userDeviceId, req.body.secureCode) (
                function callback (response) {
                    res.end(response);
                }
            );
        } else {
            var response = onFailureResponse('loginError', 'email or access token needs to be specified!');
            res.end(response);
        }
    },

    connectionString: connectionString
}

emailLogin = function(email, password) {
    return function (callback) {
        console.log('Email and password');

        User.findOrCreate({
            email: email
        }, {
            password: require('crypto').createHash('md5').update(password).digest('hex'),
            datetimeRegistered: new Date(),
            secureCode: helpers.randomString(100)
        }).success(function(user, created) {
            if (created) {
                console.log('User with email %s created', email);
                callback(onSuccessResponse('userRegistered', user.id, user.secureCode));
            } else if (user.password === require('crypto').createHash('md5').update(password).digest('hex')) {
                console.log('User %s logged in', email);
                callback(onSuccessResponse('userAuthenticated', user.id, user.secureCode));
            } else {
                console.log('Wrong password for email ', email);
                callback(onFailureResponse('wrongEmailOrPassword', 'Wrong email or password!'));
            }
        }).failure(function(err) {
            callback(onFailureResponse('serverError', err));
        })
    }
}

facebookLogin = function(accessToken, userDeviceId, secureCode) {
    return function (callback)  {
        console.log('Facebook');

        var connectionUrl = 'https://graph.Facebook.com/me?access_token=' + accessToken;

        request(connectionUrl, function (err, response, body) {
            if (err) callback(onFailureResponse('ConnectionError', err));

            if (response.statusCode == 200) {
                var responseJSON = JSON.parse(body);
                console.log('Facebook authenticated ');
                User.findOrCreate({
                    email: responseJSON.email
                }, {
                    facebookId: responseJSON.id,
                    datetimeRegistered: new Date(),
                    secureCode: helpers.randomString(100)
                }).success(function(user, created) {
                    if (created) {
                        console.log('User with facebook email %s created', responseJSON.email);
                        callback(onSuccessResponse('userRegistered', user.id, user.secureCode));
                    } else if (user.facebookId === responseJSON.id) {
                        console.log('User with facebook email %s logged in', responseJSON.email);
                        callback(onSuccessResponse('userAuthenticated', user.id, user.secureCode));
                    } else {
                        console.log('Facebook connected for email ', responseJSON.email);
                        user.updateAttributes({
                            facebookId: responseJSON.id
                        }).success(function(user) {
                            callback(onSuccessResponse('facebookConnected', user.id, user.secureCode));
                        })
                    }
                });
            } else {
                callback(onFailureResponse('permissionError', "You did not grant access to app"));
            }
        });
    }
}

googleLogin = function(accessToken, userDeviceId, secureCode) {
    return function (callback)  {
        console.log('Google');

        var connectionUrl = 'https://www.googleapis.com/oauth2/v2/userinfo?access_token=' + accessToken;

        request(connectionUrl, function (err, response, body) {
            if (err) callback(onFailureResponse('ConnectionError', err));

            var responseJSON = JSON.parse(body);

            if (response.statusCode == 200) {
                console.log('Permission granted');
            User.findOrCreate({
                email: responseJSON.email
            }, {
                googleId: responseJSON.id,
                datetimeRegistered: new Date(),
                secureCode: helpers.randomString(100)
            }).success(function(user, created) {
                    if (created) {
                        console.log('User with google email %s created', responseJSON.email);
                        callback(onSuccessResponse('userRegistered', user.id, user.secureCode));
                    } else if (user.googleId === responseJSON.id) {
                        console.log('User with google email %s logged in', responseJSON.email);
                        callback(onSuccessResponse('userAuthenticated', user.id, user.secureCode));
                    } else {
                        console.log('Google connected for email ', responseJSON.email);
                        user.updateAttributes({
                            googleId: responseJSON.id
                        }).success(function(user) {
                                callback(onSuccessResponse('googleConnected', user.id, user.secureCode));
                        })
                    }
                });
            } else {
                callback(onFailureResponse('permissionError', "You did not grant access to app"));
            }
        });
    }
}

twitterLogin = function(twitterData, userDeviceId, secureCode) {
    return function (callback)  {
        var OAuth = require('oauth');

        var CONSUMER_KEY = 'LaCI4JSXV1XkngJgc0A7A';
        var CONSUMER_SECRET = 'WIIye2uxaJUnIhSqZbw16oeI9O68YZubfawT3Np2RnY';

        var oauth = new OAuth.OAuth(
            'https://twitter.com/oauth/request_token',
            'https://twitter.com/oauth/access_token',
            CONSUMER_KEY,
            CONSUMER_SECRET,
            '1.0A',
            null,
            'HMAC-SHA1');

        var twitterDataArray = twitterData.split('&');
        var accessToken = twitterDataArray[0].split('=')[1];
        var accessSecret = twitterDataArray[1].split('=')[1];

        oauth.get('https://api.twitter.com/1.1/account/verify_credentials.json', accessToken, accessSecret, function (err, body, response) {
            if (err) onFailureResponse('500', err);

            var responseJSON = JSON.parse(body);
            console.log(responseJSON);

            if (response.statusCode == 200) {
                console.log('TwitterId: ', responseJSON.id);
                User.findOrCreate({
                    twitterId: responseJSON.id
                },{
                    twitterName: responseJSON.screen_name,
                    datetimeRegistered: new Date(),
                    secureCode: helpers.randomString(100)
                }).success(function(user, created) {
                    if (created) {
                        console.log('User with twitter it %s created', responseJSON.id);
                        callback(onSuccessResponse('userRegistered', user.id, user.secureCode));
                    } else if (user.twitterId === responseJSON.id) {
                        console.log('User with twitter id %s logged in', responseJSON.id);
                        callback(onSuccessResponse('userAuthenticated', user.id, user.secureCode));
                    } else {
                        console.log('Twitter connected');
                        user.updateAttributes({
                            twitterName: responseJSON.screen_name,
                            twitterId: responseJSON.id
                        }).success(function(user) {
                                callback(onSuccessResponse('twitterConnected', user.id, user.secureCode));
                        })
                    }
                });
            } else {
                callback(onFailureResponse('permissionError', 'Could not connect to Twitter'));
            }
        });
    }
}

onFailureResponse = function(errorCode, errorMessage) {
    console.log(errorMessage);

    return JSON.stringify({
        'hasError': true,
        'errorCode': errorCode,
        'errorMessage': errorMessage
    })
}

onSuccessResponse = function(status, deviceId, secureCode) {
    console.log(status);

    return JSON.stringify({
        'hasError': false,
        'status': status,
        'userDeviceId': deviceId,
        'secureCode': secureCode
    })
}