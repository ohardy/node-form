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

class BoundForm
  constructor: (@form, data) ->
    @bound         = true
    @isValid       = false
    @fields        = {}
    @errors        = []
    @fieldsErrors  = []

    for fieldName, field of @form.fields
      @fields[fieldName] = field.bind data[fieldName], @

  handle: (args...) -> @form.handle args...
  toHTML: (args..., callback) -> @form.toHTML.apply(@, args)
  validate: (callback) ->
    async.concat (field for fieldName, field of @fields), (field, fieldCallback) =>
      field.validate (err, errors) =>
        fieldCallback null, errors
    , (err, @fieldsErrors) =>
      @isValid = @fieldsErrors.length is 0
      if @isValid
        async.concat (validator for validator in @form.validators), (validator, validatorCallback) =>
          validator @, null, (err, result) ->
            validatorCallback null, result
        , (err, @errors) =>
          @isValid = @errors.length is 0
          callback null, @
      else
        callback null, @

  save: (args...) ->
    @form.save @, args...

class Form
  constructor: (fields, options) ->
    options     = options or {}

    @fields     = {}
    @messages   = options.messages or {}
    @validators = options.validators or []
    @bound      = false
    @isValid    = false
    @bridge     = null
    @model      = null

    if fields.modelName? and fields.schema? and fields.schema.paths?
      @bridge = MongooseBrigde
      @model  = fields

    if @bridge?
      @fields = (@bridge.formWithModel fields).fields
    else
      @addField fieldName, field for fieldName, field of fields

  save: (boundForm, callback) ->
    if @bridge?
      @bridge.save boundForm, callback
    else
      throw new Error('No bridge')

  toHTML: (args...) ->
    defaultRender = 'ul'
    # defaultParts  = ['label', 'widget', 'error']
    # parts = []
    for arg in args
      # parts.push arg if ['label', 'widget'].indexOf(arg) isnt -1
      render = arg if ['p', 'ul', 'ol'].indexOf(arg) isnt -1

    # if parts.length is 0
    #   parts = defaultParts

    render ?= defaultRender
    renderEltTag = defaultRender

    content = []
    messages = @messages or @form.messages
    for error in @errors
      content.push html 'label',
        content : messages[error] or messages['error'] or error
        class   : 'error'
    for key, field of @fields
      htmlField = field.toHTML(@, args...)
      content.push "<#{renderEltTag}>#{htmlField}</#{renderEltTag}>"

    return content.join ''

    # async.concat @fields , (field, fieldCallback) =>
    #   field.toHTML args..., callback
    # , (err, renderedFields) =>
    #   console.log 'renderedFields : ', renderedFields
    #   callback()
      # @isValid = errors.length is 0
      # callback err, errors

    # jade.renderFile path.normalize(__dirname + "/../../views/emails/register/content.jade"),
    #   host: app.get("host")
    #   email: @email
    #   code: @emailVerification.code
    #   __i: app.locals.__i
    # , (err, html) =>

    # Render each field
    # Render render-ul with fields => field content

    # html = []
    # renderTag = renderRoot[render]
    # renderEltTag = renderElt[render]
    # # renderEltTag = renderRoot[render]
    # if renderTag?
    #   html.push "<#{renderTag}>"
    # if 'error' in parts and @errors.length > 0
    #   for error in @errors
    #     html.push "<label class=\"error\">#{@form.messages[error]}</label>"

    # if renderTag?
    #   html.push "</#{renderTag}>"

    # html.join ''

  addField: (name, fieldOptions) ->
    if (typeof fieldOptions isnt 'string') and (fieldOptions instanceof fields.Field)
      @addField name, type: fieldOptions
    else
      fieldOptions.name = name
      if fieldOptions.type?
        FieldClass = fields.getFieldClass fieldOptions.type
      else
        FieldClass = fields.getFieldClass fieldOptions

        fieldOptions =
          name: name

      if FieldClass?
        delete fieldOptions.type
        @fields[name] = new FieldClass fieldOptions
        # console.log 'after :', name, ' : ', @fields
      else
        throw new Error 'Invalid field type'

  bind: (data) ->
    new BoundForm @, data

  validate: (callback) ->
    callback null, @

  getCallback: (obj, callbacks, valid) ->
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
        (@bind obj).validate (err, form) =>
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
    String: 'string'
    Password: 'password'
    Email: 'email'
    Date: 'string'
    Boolean: 'boolean'

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

    getField = (field, formName, formCategory) ->
      if field.options.type.name isnt 'ObjectId'
        name: field.path
        type: field.options.type.name

    for pathName, field of model.schema.paths
      field = getField field
      if field? and field.type?
        formOptions[field.name] = field.type

    new Form formOptions

exports.Form      = Form
exports.create    = (fields, options) ->
  new Form fields, options
