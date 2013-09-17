/**
 * User_device
 *
 * @module      :: Model
 * @description :: A short summary of how this model works and what it represents.
 *
 */

var Sequelize = require('sequelize-mysql').sequelize

module.exports = function(sequelize, DataTypes) {
    return sequelize.define('userDevice', {
        datetimeActivated: Sequelize.DATE,

        activationCode: Sequelize.STRING,
        email: Sequelize.STRING,
        isActivated: Sequelize.BOOLEAN,

        userId: Sequelize.INTEGER,

        secureCode: Sequelize.STRING,
        name: Sequelize.STRING
    }, {
        freezeTableName: true
    })
}