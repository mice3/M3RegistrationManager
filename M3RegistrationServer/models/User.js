/**
 * User
 *
 * @module      :: Model
 * @description :: A short summary of how this model works and what it represents.
 *
 */

var Sequelize = require('sequelize-mysql').sequelize

module.exports = function(sequelize, DataTypes) {
    return sequelize.define('user', {
        datetimeRegistered: Sequelize.DATE,
        secureCode: Sequelize.STRING,

        password: Sequelize.STRING,
        email: Sequelize.STRING,

        facebookId: Sequelize.STRING,
        googleId: Sequelize.STRING,
        twitterId: Sequelize.STRING
    }, {
        freezeTableName: true
    })
}