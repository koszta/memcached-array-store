chai = require 'chai'
chai.Assertion.includeStack = true
chai.use require 'chai-fuzzy'
global.should = chai.should()
