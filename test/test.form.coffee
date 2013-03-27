libpath = '../lib'
if process.env['FORM_COV']?
  libpath = '../lib-cov'

assert = require 'assert'
should = require 'should'
http   = require 'http'
util   = require 'util'
form   = require libpath

req     = undefined

newForm = new form.Form
  stringField: String
  dateField: Date
  password:
    type: 'Password'
    required: true
  confirm:
    type: 'Password'
    required: true
    validators: [
      form.validators.matchField 'password',
        invalid: 'Invalid !!'
    ]

describe "Form", ->
  describe "#new", ->
    it "should return a form instance", ->
      newForm.should.be.an.instanceof form.Form

  describe "#handle", ->

    describe "empty object", ->
      it "should call empty", (done) ->
        newForm.handle {},
          success: ->
            should.fail 'success should not be called'
            done()
          empty: ->
            should.ok true
            done()
      it "should call error", (done) ->
        newForm.handle {},
          success: ->
            should.fail 'success should not be called'
            done()
          error: ->
            should.ok true
            done()
      it "should call other", (done) ->
        newForm.handle {},
          success: ->
            should.fail 'success should not be called'
            done()
          other: ->
            should.ok true
            done()

    describe "good GET request", ->
      beforeEach ->
        req        = new http.IncomingMessage()
        req.method = 'GET'
        req.url    = '/?password=test&confirm=test'

      it "should call other", (done) ->
        newForm.handle req,
          error: ->
            should.fail 'error should not be called'
            done()
          other: ->
            should.ok true
            done()
      it "should call success", (done) ->
        newForm.handle req,
          error: (form) ->
            console.log form.errors()
            should.fail 'error should not be called'
            done()
          success: ->
            should.ok true
            done()

    describe "bad GET request", ->
      beforeEach ->
        req        = new http.IncomingMessage()
        req.method = 'GET'
        req.url    = '/?field=test'

      it "should call other", (done) ->
        newForm.handle req,
          success: ->
            should.fail 'success should not be called'
            done()
          other: ->
            should.ok true
            done()
      it "should call error", (done) ->
        newForm.handle req,
          success: (form) ->
            console.log form.errors()
            should.fail 'success should not be called'
            done()
          error: ->
            should.ok true
            done()

    describe "empty GET request", ->
      beforeEach ->
        req        = new http.IncomingMessage()
        req.method = 'GET'
        req.url    = '/'

      it "should call other", (done) ->
        newForm.handle req,
          success: ->
            should.fail 'success should not be called'
            done()
          other: ->
            should.ok true
            done()
      it "should call error", (done) ->
        newForm.handle req,
          success: (form) ->
            console.log form.errors()
            should.fail 'success should not be called'
            done()
          error: ->
            should.ok true
            done()
      it "should call empty", (done) ->
        newForm.handle req,
          success: (form) ->
            console.log form.errors()
            should.fail 'success should not be called'
            done()
          empty: ->
            should.ok true
            done()

    describe "good POST request", ->
      beforeEach ->
        req        = new http.IncomingMessage()
        req.method = 'POST'

      it "should call other", (done) ->
        newForm.handle req,
          error: ->
            should.fail 'error should not be called'
            done()
          other: ->
            should.ok true
            done()

        req.emit 'data', 'password=test&confirm=test'
        req.emit 'end'

      it "should call success", (done) ->
        newForm.handle req,
          error: (form) ->
            console.log form.errors()
            should.fail 'error should not be called'
            done()
          success: ->
            should.ok true
            done()

        req.emit 'data', 'password=test&confirm=test'
        req.emit 'end'

    describe "bad POST request", ->
      beforeEach ->
        req        = new http.IncomingMessage()
        req.method = 'POST'

      it "should call other", (done) ->
        newForm.handle req,
          success: ->
            should.fail 'success should not be called'
            done()
          other: ->
            should.ok true
            done()

        req.emit 'data', 'field=test'
        req.emit 'end'

      it "should call error", (done) ->
        newForm.handle req,
          success: (form) ->
            console.log form.errors()
            should.fail 'success should not be called'
            done()
          error: ->
            should.ok true
            done()

        req.emit 'data', 'field=test'
        req.emit 'end'

    describe "empty POST request", ->
      beforeEach ->
        req        = new http.IncomingMessage()
        req.method = 'POST'

      it "should call other", (done) ->
        newForm.handle req,
          success: ->
            should.fail 'success should not be called'
            done()
          other: ->
            should.ok true
            done()

        req.emit 'data', ''
        req.emit 'end'

      it "should call error", (done) ->
        newForm.handle req,
          success: (form) ->
            console.log form.errors()
            should.fail 'success should not be called'
            done()
          error: ->
            should.ok true
            done()

        req.emit 'data', ''
        req.emit 'end'

      it "should call empty", (done) ->
        newForm.handle req,
          success: (form) ->
            console.log form.errors()
            should.fail 'success should not be called'
            done()
          empty: ->
            should.ok true
            done()
        req.emit 'data', ''
        req.emit 'end'

    describe "Render", ->
      it "should render", (done) ->
        content = newForm.toHTML()
        console.log 'content : ', content
        done()

  describe "ModelForm", ->
    it 'should be ok', (done) ->
      mongoose      = require "mongoose"

      UserSchema = new mongoose.Schema
        name:
          first: Date
          last: String

        email:
          type: String
          unique: true
          index: true

      User = mongoose.model 'User', UserSchema
      userForm = new form.Form User
      console.log 'user form : ', userForm.toHTML('li')
      done()
