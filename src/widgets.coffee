_  = require 'underscore'
_s = require 'underscore.string'

dataRegExp    = /^data-[a-z]+$/
ariaRegExp    = /^aria-[a-z]+$/
legalAttrs    = ['id', 'name', 'class', 'type', 'autocomplete', 'autocorrect', 'autofocus', 'autosuggest', 'checked', 'dirname', 'disabled', 'list', 'max', 'maxlength', 'min', 'multiple', 'multiple', 'novalidate', 'pattern', 'placeholder', 'readonly', 'required', 'size', 'step', 'value']
boolAttrs     = ['checked', 'disabled', 'readonly', 'required']
ignoreAttrs   = ['content']
selfCloseTags = ['input']

html = (name, options = {}) ->
  # Start
  selfClose = false
  if selfCloseTags.indexOf(name) isnt -1
    selfClose = true

  data = "<#{name}"

  Object.keys(options).forEach (k) ->
    if ignoreAttrs.indexOf(k) is -1 and legalAttrs.indexOf(k) isnt -1 or dataRegExp.test(k) or ariaRegExp.test(k)
      value = options[k]
      if value?
        if k is 'class' and _.isArray(value)
          value = value.join ' '
        data += ' ' + k + '="' + value.replace(/"/g, '&quot;') + '"'

  # Attributes
  if selfClose is false
    data += '>'

    if options.content
      data += options.content
    #In
  else
    data += ' />\n'

  if selfClose is false
    data += "</#{name}>\n"

  data

input = (options) ->
  html 'input', options

class Widget
  @toHTML: (field) ->

  @label: (field, content) ->
    content.push html 'label',
      content : _s.capitalize(field.name)
      for     : "id_#{field.name}"
      class

  @errors: (field, content) ->
    classes = []
    if field.errors.length > 0
      messages = field.field.messages
      classes.push 'invalid'

      for error in field.errors
        content.push html 'label',
          content : messages[error] or messages['error'] or error
          for     : "id_#{field.name}"
          class   : 'error'

    classes

class TextWidget extends Widget
  @toHTML: (field) ->
    content = []

    @label field, content
    classes = @errors field, content

    content.push input
      type    : 'text'
      name    : "#{field.name}"
      id      : "id_#{field.name}"
      value   : field.data
      class   : classes

    content.join ''

class PasswordWidget extends Widget
  @toHTML: (field) ->
    content = []

    @label field, content
    classes = @errors field, content

    content.push input
      type    : 'password'
      name    : "#{field.name}"
      id      : "id_#{field.name}"
      value   : field.data
      class   : classes

    content.join ''

class EmailWidget extends Widget
  @toHTML: (field) ->
    content = []

    @label field, content
    classes = @errors field, content

    content.push input
      type    : 'email'
      name    : "#{field.name}"
      id      : "id_#{field.name}"
      value   : field.data
      class   : classes

    content.join ''

class URLWidget extends Widget
  @toHTML: (field) ->
    content = []

    @label field, content
    classes = @errors field, content

    content.push input
      type    : 'url'
      name    : "#{field.name}"
      id      : "id_#{field.name}"
      value   : field.data
      class   : classes

    content.join ''

class CheckboxWidget extends TextWidget
class CheckboxWidget extends TextWidget
class SelectWidget extends TextWidget
class RadioWidget extends TextWidget

exports.html           = html
exports.Widget         = Widget
exports.TextWidget     = TextWidget
exports.PasswordWidget = PasswordWidget
exports.EmailWidget    = EmailWidget
exports.URLWidget      = URLWidget
exports.CheckboxWidget = CheckboxWidget
exports.SelectWidget   = SelectWidget
exports.RadioWidget    = RadioWidget
