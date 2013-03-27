libpath = '../lib'
if process.env['FORM_COV']?
  libpath = '../lib-cov'

assert = require 'assert'
should = require 'should'
http   = require 'http'
util   = require 'util'
form   = require libpath

describe "HTML", ->
  describe "generator", ->
    it "should generate black input type text", ->
      content = form.widgets.html 'input',
        name: 'test'
        type: 'text'
        id: 'toto'
        class: 'tutu'
      console.log content

      content = form.widgets.html 'textarea',
        name: 'test'
        type: 'text'
        id: 'toto'
        class: 'tutu'
        content: 'ceci est un test'
      console.log content


