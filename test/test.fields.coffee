libpath = '../lib'
if process.env['FORM_COV']?
  libpath = '../lib-cov'

assert = require 'assert'
should = require 'should'
http   = require 'http'
util   = require 'util'
form   = require libpath

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
  boolField: Boolean

describe "Field", ->
  describe "create", ->
    it "stringField should return a String instance", ->
      newForm.fields.stringField.should.be.an.instanceof form.fields.String
    it "dateField should return a Date instance", ->
      newForm.fields.dateField.should.be.an.instanceof form.fields.Date
    it "password should return a Password instance", ->
      newForm.fields.password.should.be.an.instanceof form.fields.Password
    it "confirm should return a Password instance", ->
      newForm.fields.confirm.should.be.an.instanceof form.fields.Password

  describe 'name', ->
    it "stringField name should be stringField", ->
      newForm.fields.stringField.name.should.equal 'stringField'
    it "dateField name should be dateField", ->
      newForm.fields.dateField.name.should.equal 'dateField'
    it "password name should be password", ->
      newForm.fields.password.name.should.equal 'password'
    it "confirm name should be confirm", ->
      newForm.fields.confirm.name.should.equal 'confirm'

  describe 'required', ->
    it "stringField should be not required", ->
      newForm.fields.stringField.required.should.be.false
    it "dateField should be not required", ->
      newForm.fields.dateField.required.should.be.false
    it "password should be required", ->
      newForm.fields.password.required.should.be.true
    it "confirm should be required", ->
      newForm.fields.confirm.required.should.be.true

  describe 'render', ->
    it "should render stringField", ->
      newForm.fields.stringField.toHTML().should.equal '<input name="stringField" id="id_stringField" type="text" />'
    it "should render dateField", ->
      newForm.fields.dateField.toHTML().should.equal '<input name="dateField" id="id_dateField" type="text" />'
    it "should render password", ->
      newForm.fields.stringField.toHTML().should.equal '<input name="stringField" id="id_stringField" type="text" />'
    it "should render confirm", ->
      newForm.fields.stringField.toHTML().should.equal '<input name="stringField" id="id_stringField" type="text" />'
    it "should render boolField", ->
      newForm.fields.boolField.toHTML().should.equal '<input name="boolField" id="id_boolField" type="checkbox" />'
