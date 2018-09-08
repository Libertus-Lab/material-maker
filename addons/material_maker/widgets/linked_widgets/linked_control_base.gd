tool
extends VBoxContainer

var label = null
var buttons = null

var linked_widgets = []
var links = null

const Link = preload("res://addons/material_maker/widgets/linked_widgets/link.gd")

const WIDGETS = {
	SpinBox={ attrs=[ "min_value", "max_value", "step", "value" ], value_attr="value", sig="value_changed", sig_handler="_on_value_changed" },
	HSlider={ attrs=[ "min_value", "max_value", "step", "value" ], value_attr="value", sig="value_changed", sig_handler="_on_value_changed" },
	ColorPickerButton={ attrs=[ "edit_alpha", "color" ], value_attr="color", sig="color_changed", sig_handler="_on_color_changed" },
	OptionButton={ attrs=[ "selected" ], value_attr="selected", sig="item_selected", sig_handler="_on_item_selected" }
}

func get_widget_type(widget):
	if widget is SpinBox:
		return "SpinBox"
	elif widget is ColorPickerButton:
		return "ColorPickerButton"
	elif widget is OptionButton:
		return "OptionButton"
	else:
		return null

func _ready():
	set_process_input(false)

func get_associated_controls():
	label = Label.new()
	label.set_text("Unnamed")
	buttons = preload("res://addons/material_maker/widgets/linked_widgets/linked_control_buttons.tscn").instance()
	buttons.control = self
	return { label=label, buttons=buttons }

func delete():
	var parent = get_parent()
	label.queue_free()
	buttons.queue_free()
	queue_free()

func _on_mouse_entered():
	_on_mouse_exited()
	links = []
	var viewport = get_viewport()
	for w in linked_widgets:
		var link = Link.new()
		link.source = self
		link.target = w.widget
		viewport.add_child(link)
		links.append(link)

func _on_mouse_exited():
	if links != null:
		for l in links:
			l.queue_free()
		links = null

# Capture mouse to link to a control

var link = null
var graph_edit = null
var pointed_control = null

const Link = preload("res://addons/material_maker/widgets/linked_widgets/link.gd")

func find_control(gp):
	for c in graph_edit.get_children():
		if c is GraphNode:
			if c.get("property_widgets") != null:
				for w in c.property_widgets:
					if Rect2(w.rect_global_position, w.rect_size*w.get_global_transform().get_scale()).has_point(gp):
						return { node=c, widget=w }
	return null

func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE:
			set_process_input(false)
			link.queue_free()
			link = null
	elif event is InputEventMouseMotion:
		var control = find_control(event.global_position)
		link.end = event.global_position
		link.target = control.widget if control != null else null
		link.update()
	elif event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_LEFT:
				var control = find_control(event.global_position)
				if control != null:
					add_linked(control.node, control.widget)
			set_process_input(false)
			link.queue_free()
			link = null
	get_tree().set_input_as_handled()

func pick_linked():
	# Verify we are in a graph edit
	graph_edit = get_parent()
	while graph_edit != null && !(graph_edit is GraphEdit):
		graph_edit = graph_edit.get_parent()
	if graph_edit == null:
		return
	# Create line that will be shown when looking for a target
	var viewport = get_viewport()
	link = Link.new()
	link.source = self
	link.end = rect_global_position+0.5*rect_size*get_global_transform().get_scale()
	viewport.add_child(link)
	set_process_input(true)
	pointed_control = null

func serialize():
	var data = { linked_widgets=[] }
	for w in linked_widgets:
		data.linked_widgets.append( { node=w.node.name, widget=w.widget.name } )
	return data

func deserialize(data):
	if !data.has("linked_widgets"):
		return
	var graph_edit = get_parent()
	while !(graph_edit is GraphEdit):
		graph_edit = graph_edit.get_parent()
	for w in data.linked_widgets:
		var node = graph_edit.get_node(w.node)
		if node != null && node.get("property_widgets") != null:
			for widget in node.property_widgets:
				if widget.name == w.widget:
					add_linked(node, widget)
