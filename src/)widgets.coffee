
# 'id', 'name', 'class', 'classes']

# attrs = (a) ->
#   html = ' name="' + a.name + '"';
#   html += ' id=' + (a.id ? '"' + a.id + '"' : '"id_' + a.name + '"');
#   html += a.classes.length > 0 ? ' class="' + a.classes.join(' ') + '"' : '';
#   return html;

class Widget
	@toHTML: (field, data) ->
	@html: (field, data, name, options) ->
		if _.isObject(name) and not options?
			options = name
			name = 'input'
		else if not name? and not options?
			name = 'input'

		html name, _.extend
			name: "#{field.name}"
			id: "id_#{field.name}"
			type: 'text'
			value: data
		, options
	renderLabel: (field) ->
		html field, 'label',
			content: @name
			for: "id_#{field.name}"

class TextWidget extends Widget
	@toHTML: (field, data, name, options) ->
		@html field, data, name, options

class TextareaWidget extends Widget
	@toHTML: (field, data, name, options) ->
		@html field, data, 'textarea', options

class PasswordWidget extends TextWidget
	@toHTML: (field, data, name, options) ->
		super field, data,
			type: 'password'

class CheckboxWidget extends Widget
	@toHTML: (field, data, name, options) ->
		@html field, data, type: 'checkbox'

class SelectWidget extends Widget
	@toHTML: (field, data, name, options) ->
		@html field, data, 'select'

class RadioWidget extends Widget
	@toHTML: (field, data, name, options) ->

class MultipleCheckboxWidget extends Widget
	@toHTML: (field, data, name, options) ->

class MultipleRadioWidget extends Widget
	@toHTML: (field, data, name, options) ->

class MultipleSelectWidget extends Widget
	@toHTML: (field, data, name, options) ->

exports.html           = html
exports.TextWidget     = TextWidget
exports.PasswordWidget = PasswordWidget
exports.CheckboxWidget = CheckboxWidget
exports.SelectWidget   = SelectWidget
exports.RadioWidget    = RadioWidget
	# html: html
	# Widget: Widget
	# TextWidget: TextWidget
