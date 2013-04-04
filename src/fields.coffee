async      = require 'async'
render     = require './render'
widgets    = require './widgets'
validators = require './validators'
_s         = require 'underscore.string'

alias = {}

# class BoundField
#   constructor: (@field, @data, @form) ->
#     @bound   = true
#     @errors  = []
#     @widget  = @field.widget
#     @name    = @field.name



#   toHTML: (args..., callback) ->
#     @field.toHTML.apply @, args.concat callback
#     # Get widtget type
#     # Render widget template and return it

#     # defaultParts = ['widget']
#     # parts = []
#     # html = []
#     # for arg in args
#     #   parts.push arg if ['label', 'widget', 'error'].indexOf(arg) isnt -1

#     # if parts.length is 0
#     #   parts = defaultParts

#     # for part in parts
#     #   if part is 'widget'
#     #     classes = ''
#     #     classes = 'invalid' if @errors.length > 0
#     #     html.push @field.widget.toHTML @field, @data, class: classes
#     #   if part is 'label'
#     #     html.push "<label for=\"id_#{@field.name}\">#{_s.capitalize(@field.name)}</label>"
#     #   if part is 'error' and @errors.length > 0
#     #     for error in @errors
#     #       html.push "<label for=\"id_#{@field.name}\" class=\"error\">#{form.messages[error]}</label>"

#     # html.join ''

class Field
  constructor:  (options) ->
    options            ?=  {}
    options.required   ?= false
    options.validators ?= []
    options.messages   ?= {}

    @validators = []

    @initialize()

    @name       = options.name
    @label      = options.label or @name
    @required   = options.required
    @validators = @validators.concat options.validators
    @messages   = options.messages
    @errors     = []
    @bound      = false
    @errors     = []
    @isValid    = false
    @data       = ''

    @bind = (data, form) ->
      newField = new @constructor options
      newField._bind data, form
      newField

  initialize: ->
    @widget = widgets.TextWidget

  validate: (callback) ->
    valid = null

    fieldValidators = []
    if @required
      fieldValidators = fieldValidators.concat [validators.required()]

    if @validators?
      fieldValidators = fieldValidators.concat @validators

    async.concat fieldValidators , (validator, validatorCallback) =>
      validator @form, @, (err, result) ->
        result ?= []
        validatorCallback null, result
    , (err, @errors) =>
      console.log "Field.validate : #{@name} : #{errors}"
      @isValid = errors.length is 0
      callback err, @errors

  toHTML:   (args...) ->
    html = []
    html.push @widget.toHTML @
    return html.join ''

  _bind:     (@data, @form) ->
    @bound   = true
    @errors  = []

  getLabel: -> @label or @name
  classes:  -> []

class StringField   extends Field
class TextField     extends Field
  initialize: ->
    @widget = widgets.TextareaWidget

class PasswordField extends StringField
  initialize: ->
    @widget = widgets.PasswordWidget

class DateField     extends Field
class NumberField   extends Field
class URLField      extends Field
  initialize: ->
    @widget = widgets.URLWidget
    @validators.push validators.url()

class EmailField    extends Field
  initialize: ->
    @widget = widgets.EmailWidget
    @validators.push validators.email()

class RangeField    extends NumberField

class BooleanField  extends Field
  initialize: ->
    @widget = widgets.CheckboxWidget

exports.Field         = Field
exports.String        = StringField
exports.Password      = PasswordField
exports.Date          = DateField
exports.Number        = NumberField
# exports.BoundedField  = BoundField
exports.getFieldClass = (fieldType) ->
  return fieldType     if fieldType instanceof Field

  if typeof fieldType isnt 'string'
    fieldType = fieldType.name

  return alias[fieldType]

addAlias = exports.field = (name, field) ->
  alias[name] = field
  return field

addAlias 'String',   StringField
addAlias 'Text',     TextField
addAlias 'Date',     DateField
addAlias 'Number',   NumberField
addAlias 'Boolean',  BooleanField
addAlias 'Email',    EmailField
addAlias 'URL',      URLField
addAlias 'Password', PasswordField
