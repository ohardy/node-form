exports.widgets     = require './widgets'
exports.fields      = require './fields'
exports.render      = require './render'
exports.validators  = require './validators'

form = require './form'

forms = {}

exports.Form            = form.Form
exports.ModelForm       = form.ModelForm
exports.create          = form.create
exports.createFromModel = form.createFromModel

exports.form            = (name, schema) ->
  if schema?
    forms[name] = schema

  new form.Form schema

module.exports = exports
