async       = require "async"
http        = require "http"
querystring = require 'querystring'
_           = require 'underscore'
url         = require 'url'
util        = require 'util'
fields      = require './fields'
path        = require 'path'
jade        = require 'jade'
parse       = url.parse
html        = require('./widgets').html

class Schema
  constructor: (fields, options) ->
    options     = options            or {}
    @messages   = options.messages   or {}
    @validators = options.validators or []

    @fields     = {}

    @addField fieldName, field for fieldName, field of fields

  addField: (name, options) ->
    if (typeof options isnt 'string') and (options instanceof fields.Field)
      @addField name, type: options
    else
      options.name = name
      if options.type?
        FieldClass = fields.getFieldClass options.type
      else
        FieldClass = fields.getFieldClass options

        options =
          name: name

      if FieldClass?
        delete options.type
        @fields[name] = new FieldClass options
      else
        throw new Error 'Invalid field type'

class ModelSchema extends Schema
  constructor: (@model, fields, options) ->
    @bridge = MongooseBrigde

    new_fields = {}
    for fieldName in fields
      field = @model.schema.paths[fieldName]
      if not field?
        throw new Error("Field #{fieldName} doesn't exist in model #{@model.modelName}")
      field = @bridge.toField field
      new_fields[field.name] = field

    super new_fields, options

# class BoundForm
#   constructor: (@form, data) ->
#     @bound         = true
#     @isValid       = false
#     @fields        = {}
#     @errors        = []
#     @fieldsErrors  = []

#     for fieldName, field of @form.fields
#       @fields[fieldName] = field.bind data[fieldName], @

#   handle: (obj, callbacks) -> @form.handle obj, callbacks
#   toHTML: (args..., callback) -> @form.toHTML.apply(@, args)
#   doc: (doc) ->
#     @form = @form.doc doc



class Form
  constructor: (@schema, options) ->
    options     = options or {}

    @messages   = options.messages or {}
    @validators = options.validators or []
    @bound      = false
    @isValid    = true
    @bridge     = null
    @model      = null

    @doc = (doc) ->
      newForm = new Form @schema, options
      newForm._doc doc
      newForm

    @bind = (data) ->
      newForm = new Form @schema, options
      newForm._bind data
      newForm

  _bind: (data) ->
    @bound         = true
    @isValid       = false
    @errors        = []
    @fieldsErrors  = []
    @fields        ?= {}

    for fieldName, field of @schema.fields
      @fields[fieldName] = field.bind data[fieldName], @
    return

  _doc: (@doc) ->
    @_bind @doc

    @bound = false

  validate: (callback) ->
    fields = @fields or @schema.fields
    async.concat (field for fieldName, field of fields), (field, fieldCallback) =>
      field.validate (err, errors) =>
        fieldCallback null, errors
    , (err, @fieldsErrors) =>
      console.log 'Form1.validate : ', err, @fieldsErrors
      @isValid = @fieldsErrors.length is 0
      if @isValid
        async.concat (validator for validator in @schema.validators), (validator, validatorCallback) =>
          validator @, null, (err, result) ->
            validatorCallback null, result
        , (err, @errors) =>
          console.log 'Form2.validate : ', err, @errors
          @isValid = @errors.length is 0
          callback null, @
      else
        callback null, @

  save: (args...) ->
    @form.save @, args...

  save: (boundForm, callback) ->
    if @bridge?
      @bridge.save boundForm, callback
    else
      throw new Error('No bridge')

  toHTML: (args...) ->
    defaultRender = 'ul'
    for arg in args
      render = arg if ['p', 'ul', 'ol'].indexOf(arg) isnt -1

    render ?= defaultRender
    renderEltTag = defaultRender

    content = []
    messages = @messages or @schema.messages
    fields = @fields or @schema.fields
    for error in @errors
      content.push html 'label',
        content : messages[error] or messages['error'] or error
        class   : 'error'
    for key, field of fields
      htmlField = field.toHTML(@, args...)
      content.push "<#{renderEltTag}>#{htmlField}</#{renderEltTag}>"

    return content.join ''

  # validate: (callback) ->
  #   callback null, @

  getCallback: (obj, callbacks, valid) ->
    func = null
    if not obj?
      func = callbacks.empty or callbacks.error or callbacks.other
    else if obj not instanceof http.IncomingMessage
      if _.isEmpty(obj) and callbacks.empty?
        func = callbacks.empty
      else if valid?
        if valid is true
          func = callbacks.success or callbacks.other
        else
          func = callbacks.error or callbacks.other
    func

  urlToObj: (url) ->
    return (parse url, 1).query

  errors: -> []

  doc: (doc) ->

  handle: (obj, callbacks) ->
    callback = @getCallback obj, callbacks
    if callback?
      callback @
    else
      if obj instanceof http.IncomingMessage
        if obj.method is 'GET'
          @handle (@urlToObj obj.url), callbacks
        else if ['POST', 'PUT'].indexOf obj.method isnt -1
          if obj.body?
            @handle obj.body, callbacks
          else
            buffer = ''
            obj.addListener 'data', (chunk) =>
              buffer += chunk
            obj.addListener 'end', =>
              @handle querystring.parse(buffer), callbacks
        else
          throw new Error('Cannot handle request method: ' + obj.method)
      else if typeof obj is 'object'
        binded = @bind obj
        binded.validate (err, form) =>
          func = @getCallback obj, callbacks, form.isValid

          if func?
            func form
          else
            throw new Error('Not found callback to call')
      else
        throw new Error('Cannot handle type: ' + typeof obj);

class Bridge

class MongooseBrigde extends Bridge
  _fields =
    'String'  : String
    'Boolean' : Boolean
    'Date'    : Date

  @toField: (field) ->
    if field.options.type.name isnt 'ObjectId'
      name: field.path
      type: _fields[field.options.type.name]

  @save: (boundForm, callback) ->
    updateDocument = (document) ->
      for fieldName, field of boundForm.fields
        document.set field.field.name, field.data

      document.save callback

    _id = boundForm._id
    if _id?
      boundForm.form.model.findOne
        _id: _id
      , (err, element) ->
        updateDocument element
    else
      updateDocument new boundForm.form.model()

  @formWithModel: (model) ->
    formOptions = {}

    for pathName, field of model.schema.paths
      field = MongooseBrigde.toField field
      if field? and field.type?
        formOptions[field.name] = field.type

    new Form formOptions

exports.Form      = Form
exports.create    = (fields, options) ->
  new Schema fields, options

exports.createFromModel = (model, fields, options) ->
  new ModelSchema model, fields, options
