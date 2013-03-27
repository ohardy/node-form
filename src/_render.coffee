widgets = require './widgets'

renderWidget = (widget) -> widget.toHTML()

wrapWith = (tag) ->
  (widget) ->
    return widgets.html tag,
      content: renderWidget widget

    # if field.widget.type is "multipleCheckbox" or field.widget.type is "multipleRadio"
      # html = html.concat(["<fieldset>", "<legend>", field.labelText(name), "</legend>", field.errorHTML(), field.widget.toHTML(name, field), "</fieldset>"])
    # else
      # html.push field.errorHTML() + field.labelHTML(name, field.id) + field.widget.toHTML(name, field)
    # html.join("") + "</" + tag + ">"

['div', 'p', 'li'].forEach (elt) ->
  exports[elt] = wrapWith elt

exports.table = (name, field) ->
  ["<tr class=\"", field.classes().join(" "), "\">", "<th>", field.labelHTML(name), "</th>", "<td>", field.errorHTML(), field.widget.toHTML(name, field), "</td>", "</tr>"].join ""

exports.getRenderer = (name) ->
  exports[name]

exports.none = (field) -> renderWidget widget
