@tool
class_name Chart
extends ReferenceRect

enum LABELS_TO_SHOW {
  NO_LABEL = 0,
  X_LABEL = 1,
  Y_LABEL = 2,
  LEGEND_LABEL = 4
}

enum CHART_TYPE {
  LINE_CHART,
  PIE_CHART
}

const COLOR_LINE_RATIO = 0.5
const LABEL_SPACE = Vector2(64.0, 32.0)

@export var label_font: Font
@export var MAX_VALUES = 12 # (int, 6, 24)
@export var dot_texture: Texture2D = preload('graph-plot-white.png')
@export var default_chart_color: Color = Color('#ccffffff')
@export var grid_color: Color = Color('#b111171c')
@export var chart_type = CHART_TYPE.LINE_CHART: set = set_chart_type
@export var line_width = 2.0
@export var hovered_radius_ratio = 1.1 # (float, 1.0, 2.0, 0.1)
@export var chart_background_opacity = 0.334 # (float, 0.0, 1.0, 0.01)

var current_data = []
var min_value = 0.0
var max_value = 1.0
var current_animation_duration = 1.0
var current_point_color = {}
var current_show_label = LABELS_TO_SHOW.NO_LABEL
var current_mouse_over = null


class PieChartData:
	var data
	var hovered_item = null
	var hovered_radius_ratio = 1.1

	func _init():
		data = {}

	func _set(param, value):
		data[param] = value
		return true

	func _get(param):
		if not data.has(param):
			data[param] = 0.0
		return data[param]

	func set_hovered_item(name):
		hovered_item = name

	func set_radius(param, value):
		return _set(_format_radius_key(param), value)

	func get_radius(param):
		var radius_ratio = 1.0
		if param == hovered_item:
			radius_ratio = hovered_radius_ratio
		return _get(_format_radius_key(param)) * radius_ratio

	func _format_radius_key(param):
		return '%s_radius' % [param]

	func get_property_list():
		return data.keys()
		

var pie_chart_current_data = PieChartData.new()

# Node create in the initializion phase
var tween_node:Tween
var tooltip_data = null

@onready var texture_size = dot_texture.get_size()
@onready var min_x = 0.0
@onready var max_x = get_size().x

@onready var min_y = 0.0
@onready var max_y = get_size().y

@onready var current_data_size = MAX_VALUES
@onready var global_scale = Vector2(1.0, 1.0) / sqrt(MAX_VALUES)
@onready var interline_color = Color(grid_color.r, grid_color.g, grid_color.b, grid_color.a * 0.5)


func _init():
	# add_child(tween_node)
	pass


func _ready():
	# tween_node.set_active(true)
	# tween_node.start()

	set_process_input(chart_type == CHART_TYPE.PIE_CHART)
	pie_chart_current_data.hovered_radius_ratio = hovered_radius_ratio


func _exit_tree():
	# pie_chart_current_data.free()
	#pie_chart_current_data.data.clear()
	#pie_chart_current_data.hovered_item = null
	pass
	


func set_chart_type(value):
	if chart_type != value:
		clear_chart()
		chart_type = value
		update_tooltip()
		set_process_input(chart_type == CHART_TYPE.PIE_CHART)

		queue_redraw()
		# tween_node.start()


func _input(event):
	if event is InputEventMouseMotion:
		var center_point = get_global_position() + Vector2(min_x + max_x, min_y + max_y) / 2.0
		var computed_radius = round(min(max_y - min_y, max_x - min_x) / 2.0)
		var hovered_data = null
		var hovered_name = null

		if event.position.distance_to(center_point) <= computed_radius and \
			current_data != null and current_data.size() > 0:
			
			var centered_position = event.position - center_point
			
			# var computed_angle = (360.0 - rad_to_deg(centered_position.angle() + PI))
			var computed_angle = fmod(rad_to_deg(centered_position.angle()) + 450.0, 360.0)

			var total_value = 0.0
			var initial_angle = 0.0

			for item_key in current_data[0].keys():
				total_value += pie_chart_current_data.get(item_key)
			
			total_value = max(1, total_value)

			for item_key in current_data[0].keys():
				var item_value = pie_chart_current_data.get(item_key)
				var ending_angle = min(initial_angle + item_value * 360.0 / total_value, 359.99)
				var item_angle = ending_angle - initial_angle
				var item_percent = (item_value / total_value) * 100

				if computed_angle > initial_angle and computed_angle <= ending_angle:
					hovered_name = item_key
					hovered_data = {
						name = item_key,
						value = item_value,
						angle = item_angle,
						percent = item_percent
					}
					break

				initial_angle = ending_angle

		pie_chart_current_data.set_hovered_item(hovered_name)
		update_tooltip(hovered_data)


func update_tooltip(data = null):
	var update_frame = false

	if data != null:
		if tooltip_data != data:
			# sprite.tooltip_text = "%s: %.02f%%" % [data.name, data.value]
			# set_tooltip('%s: %.02f%%' % [data.name, data.value])
			self.tooltip_text = "%s: %.01f%%\n%.02f" % [data.name, data.percent, data.value]
			update_frame = true
			
	elif tooltip_data != null:
		# sprite.tooltip_text = ""
		# set_tooltip('')
		self.tooltip_text = ""
		update_frame = true

	tooltip_data = data

	if update_frame:
		queue_redraw()



func initialize(show_label, points_color = {}, animation_duration = 1.0):
	set_labels(show_label)
	current_animation_duration = animation_duration

	for key in points_color:
		current_point_color[key] = {
			dot = points_color[key],
			line = Color(
				points_color[key].r,
				points_color[key].g,
				points_color[key].b,
				points_color[key].a * COLOR_LINE_RATIO)
		}



func reset_min_max() -> void:
	# Reset values
	min_y = 0.0
	min_x = 0.0
	max_y = get_size().y
	max_x = get_size().x

	if current_show_label & LABELS_TO_SHOW.X_LABEL:
		max_y -= LABEL_SPACE.y

	if current_show_label & LABELS_TO_SHOW.Y_LABEL:
		min_x += LABEL_SPACE.x
		max_x -= min_x

	if current_show_label & LABELS_TO_SHOW.LEGEND_LABEL:
		min_y += LABEL_SPACE.y
		max_y -= min_y
		
		
func set_labels(show_label) -> void:
	# print("set_labels")
	current_show_label = show_label

	# Reset values
	reset_min_max()

	# move sprites
	current_data_size = max(0, current_data_size - 1)
	move_other_sprites()
	current_data_size = current_data.size()
	
	queue_redraw()
	# tween_node.start() 
	# _print_points()


func _on_mouse_over(label_type):
	current_mouse_over = label_type
	queue_redraw()


func _on_mouse_out(label_type):
	if current_mouse_over == label_type:
		current_mouse_over = null
	queue_redraw()


func set_max_values(max_values):
	MAX_VALUES = max_values

	_update_scale()
	clean_chart()

	# tween_node.start()
	current_data_size = max(0, current_data_size - 1)
	move_other_sprites()
	current_data_size = current_data.size()
	


func draw_circle_arc_poly(center, radius, angle_from, angle_to, color):
	var nb_points = int(radius / 2.0)
	var points_arc = PackedVector2Array()
	var colors = PackedColorArray([color])

	points_arc.push_back(center)

	for i in range(nb_points + 1):
		var angle_point = deg_to_rad(angle_from + i * (angle_to - angle_from) / nb_points - 90)

		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)

	draw_polygon(points_arc, colors)


func _draw():
	if chart_type == CHART_TYPE.LINE_CHART:
		draw_line_chart()
	else:
		draw_pie_chart()

	_draw_labels()


func draw_pie_chart():
	var center_point = Vector2(min_x + max_x, min_y + max_y) / 2.0
	var total_value = 0
	var initial_angle = 0.0

	if not current_data.is_empty():
		for item_key in current_data[0].keys():
			total_value += pie_chart_current_data.get(item_key)

		total_value = max(1, total_value)

		for item_key in current_data[0].keys():
			var item_value = pie_chart_current_data.get(item_key)
			var ending_angle = min(initial_angle + item_value * 360.0 / total_value, 359.99)
			var color = current_point_color[item_key].dot
			var radius = pie_chart_current_data.get_radius(item_key)

			if item_value > 0.0 and radius > 1.0 and (ending_angle - initial_angle) > 2.0:
				draw_circle_arc_poly(center_point, radius, initial_angle, ending_angle, color)
				initial_angle = ending_angle


func _draw_chart_background(pointListObject):
	for key in pointListObject.keys():
		var pointList = pointListObject[key]
		var color_alpha_ratio = COLOR_LINE_RATIO if current_mouse_over != null and current_mouse_over != key else 1.0

		if pointList.size() < 2:
			continue

		var colors = []
		var max_y_value = min_y + max_y

		for point in pointList:
			if max_y_value < point.y:
				max_y_value = point.y

		pointList.push_front(Vector2(pointList[0].x, min_y + max_y))
		pointList.push_back(Vector2(pointList[-1].x, min_y + max_y))

		for point in pointList:
			var computed_color = current_point_color[key].dot
			var lerp_value = 1.0 - (point.y) / (max_y_value)

			computed_color.a = computed_color.a * (lerp_value) * chart_background_opacity * color_alpha_ratio
			colors.push_back(computed_color)

		draw_polygon(pointList, colors)



func draw_line_chart():
	var vertical_line = [Vector2(min_x, min_y), Vector2(min_x, min_y + max_y)]
	var horizontal_line = [vertical_line[1], Vector2(min_x + max_x, min_y + max_y)]
	var previous_point = {}

	# Need to draw the 0 ordinate line
	if min_value < 0:
		horizontal_line[0].y = min_y + max_y - compute_y(0.0)
		horizontal_line[1].y = min_y + max_y - compute_y(0.0)

	var pointListObject = {}

	for point_data in current_data:
		var point

		for key in point_data.sprites:
			var current_dot_color = current_point_color[key].dot

			if current_mouse_over != null and current_mouse_over != key:
				current_dot_color = Color(
				current_dot_color.r,
				current_dot_color.g,
				current_dot_color.b,
				current_dot_color.a * COLOR_LINE_RATIO)

			point_data.sprites[key].sprite.set_modulate(current_dot_color)

			point = point_data.sprites[key].sprite.get_position() + texture_size * global_scale / 2.0

			if not pointListObject.has(key):
				pointListObject[key] = []

			if point.y < (min_y + max_y - 1.0):
				pointListObject[key].push_back(point)
			else:
				pointListObject[key].push_back(Vector2(point.x, min_y + max_y - 2.0))

			if previous_point.has(key):
				var current_line_width = line_width

				if current_mouse_over != null and current_mouse_over != key:
					current_line_width = 1.0
				elif current_mouse_over != null:
					current_line_width = 3.0

				draw_line(previous_point[key], point, current_point_color[key].line, current_line_width)

				# Don't add points that are too close of each others
				if abs(previous_point[key].x - point.x) < 10.0:
					pointListObject[key].pop_back()

			previous_point[key] = point

		draw_line(
			Vector2(point.x, vertical_line[0].y),
			Vector2(point.x, vertical_line[1].y),
			interline_color, 1.0)

		if current_show_label & LABELS_TO_SHOW.X_LABEL:
			var label = tr(point_data.label).left(3)
			var string_decal = Vector2(14, -LABEL_SPACE.y + 8.0)

			_draw_string(label_font, Vector2(point.x, vertical_line[1].y) - string_decal, label, grid_color)
  
	
	_draw_chart_background(pointListObject)

	if current_show_label & LABELS_TO_SHOW.Y_LABEL:
		var ordinate_values = compute_ordinate_values(max_value, min_value)

		for ordinate_value in ordinate_values:
			var label = format(ordinate_value)
			var position = Vector2(max(0, 6.0 -label.length()) * 9.5, min_y + max_y - compute_y(ordinate_value))
			_draw_string(label_font, position, label, grid_color)

	draw_line(vertical_line[0], vertical_line[1], grid_color, 1.0)
	draw_line(horizontal_line[0], horizontal_line[1], grid_color, 1.0)




# https://docs.godotengine.org/en/stable/classes/class_canvasitem.html#class-canvasitem-method-draw-string
# ThemeDB.fallback_font
func _draw_string(label_font, position, text, color) -> void:
	draw_string(
		label_font,
		position,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		16,
		color,
		3,
		0,
		0
	)

	
	
	
func _draw_labels():
	if current_show_label & LABELS_TO_SHOW.LEGEND_LABEL:
		var nb_labels = current_point_color.keys().size()
		var position = Vector2(min_x, 0.0)

		for legend_label in current_point_color.keys():
			var dot_color = current_point_color[legend_label].dot
			var rect = Rect2(position, LABEL_SPACE / 1.5)
			var label_position = position + LABEL_SPACE * Vector2(1.0, 0.4)

			if current_mouse_over != null and current_mouse_over != legend_label:
				dot_color = Color(
				dot_color.r,
				dot_color.g,
				dot_color.b,
				dot_color.a * COLOR_LINE_RATIO)

			_draw_string(label_font, label_position, tr(legend_label), grid_color)
			draw_rect(rect, dot_color)

			position.x += 1.0 * max_x / nb_labels



#func compute_y(value):
	#var amplitude = max_value - min_value
	#return ((value - min_value) / amplitude) * (max_y - texture_size.y)

func compute_y(value: float) -> float:
	# Normalize the data value to a 0-1 scale based on min_value and max_value
	var normalized_value = (value - min_value) / (max_value - min_value)
	# Map the normalized value to the plot area (min_y to max_y)
	var computed_y = min_y + normalized_value * (max_y - min_y)
	
	# TODO -- Adjust for texture size (values close to texture size might look off.)
	# var sprite_height = texture_size.y * global_scale.y
	# computed_y += sprite_height  # Offset to center the sprite on the computed Y position
	
	return computed_y




func compute_sprites(points_data):
	var sprites = {}
	
	for key in points_data.values:
		var value = points_data.values[key]

		# Création d'un Sprite
		var sprite = TextureRect.new()

		# Positionne le Sprite
		var initial_pos = Vector2(max_x, max_y)

		sprite.set_position(initial_pos)

		# Attache une texture a ce node
		sprite.set_texture(dot_texture)
		sprite.set_modulate(current_point_color[key].dot)

		# Attacher le sprite à la scène courante
		add_child(sprite)

		var end_pos = initial_pos - Vector2(-min_x, compute_y(value) - min_y)

		sprite.mouse_filter = MOUSE_FILTER_STOP
		# sprite.set_tooltip('%s: %s' % [tr(key), format(value)])
		sprite.tooltip_text = '%s: %s' % [tr(key), format(value)]

		sprite.connect('mouse_entered', Callable(self, '_on_mouse_over').bind(key))
		sprite.connect('mouse_exited', Callable(self, '_on_mouse_out').bind(key))

		# Appliquer le déplacement
		# animation_move_dot(sprite, end_pos - texture_size * global_scale / 2.0, global_scale, 0.0, current_animation_duration)

		sprites[key] = {
			sprite = sprite,
			value = value
		}

	return sprites



func _compute_max_value(point_data):
	# Being able to manage multiple points dynamically
	for key in point_data.values:
		max_value = max(point_data.values[key], max_value)
		min_value = min(point_data.values[key], min_value)

		# Set default color
		if not current_point_color.has(key):
			current_point_color[key] = {
				dot = default_chart_color,
				line = Color(default_chart_color.r,
					default_chart_color.g,
					default_chart_color.b,
					default_chart_color.a * COLOR_LINE_RATIO)
			}



func clean_chart():
	# If there is too many points, remove old ones
	while current_data.size() >= MAX_VALUES:
		var point_to_remove = current_data[0]

		if point_to_remove.has('sprites'):
			for key in point_to_remove.sprites:
				var sprite = point_to_remove.sprites[key]

				sprite.sprite.queue_free()

		current_data.remove_at(0)
		_update_scale()



#func _stop_tween():
	## Reset current tween
	## tween_node.remove_all()
	## tween_node.stop_all()
	#if tween_node:
		#tween_node.kill()
	#pass



func clear_chart():
	# _stop_tween()
	max_value = 1.0
	min_value = 0.0

	for point_to_remove in current_data:
		if point_to_remove.has('sprites'):
			for key in point_to_remove.sprites:
				var sprite = point_to_remove.sprites[key]

				sprite.sprite.queue_free()

	current_data = []
	_update_scale()
	queue_redraw()
	
	pass
	
	
	

func create_new_point(point_data):
	# _stop_tween()
	clean_chart()

	if chart_type == CHART_TYPE.LINE_CHART:

		_compute_max_value(point_data)

		# Move others current_data
		# move_other_sprites()

		# Sauvegarde le sprite courant
		current_data.push_back({
			label = point_data.label,
			sprites = await compute_sprites(point_data)
		})
		
	else:
		if current_data.is_empty():
			var data = {}

			for item_key in point_data.values.keys():
				data[item_key] = 0
				pie_chart_current_data.set(item_key, 0.0)
				pie_chart_current_data.set_radius(item_key, 2.0)

			current_data.push_back(data)

		for item_key in point_data.values.keys():
			current_data[0][item_key] += max(0, point_data.values[item_key])

		# Move others current_data
		# move_other_sprites()

	_update_scale()
	# tween_node.start()
	
	# update positions of sprite nodes
	current_data_size = max(0, current_data_size - 1)
	move_other_sprites()
	current_data_size = current_data.size()
	
	


func _print_points() -> void:
	print("points:")
	for point in current_data:
		print(point.label)
	print()
	
	
func _update_scale():
	# debug code -- set scale to 1.0
	
	#current_data_size = current_data.size()
	##global_scale = Vector2(1.0, 1.0) / sqrt(min(5, current_data_size))
	#
	## print(current_data_size)
	#global_scale = Vector2(1.0, 1.0)
	##if current_data_size > 0:
		##global_scale = global_scale / sqrt(min(5, current_data_size))
		
		
	# normal code (from 3.1): seems working again now after latest commit 5/7/25
	current_data_size = current_data.size()
	global_scale = Vector2(1.0, 1.0) / sqrt(min(5, current_data_size))



func _move_other_sprites(points_data, index):
	if chart_type == CHART_TYPE.LINE_CHART:
		
		# print(points_data.sprites)
		for key in points_data.sprites:
			var point_data = points_data.sprites[key]
			var delay = sqrt(index) / 10.0
			var sprite = point_data.sprite
			var value = point_data.value
			
			var computed_y = compute_y(value)
			var y = min_y + max_y - computed_y
			
			
			# print("min_y = ", min_y)
			# print("max_y = ", max_y)
			
			#print("value = ", value)
			#print("computed_y = ", computed_y)
			#print("y = ", y)
			#print()
			
			
			var x = min_x + (max_x / max(1.0, current_data_size)) * index

			animation_move_dot(sprite, Vector2(x, y) - texture_size * global_scale / 2.0, global_scale, delay)
			
	else:
		var sub_index = 0

		for item_key in points_data.keys():
			animation_move_arcpolygon(item_key, points_data[item_key], sqrt(sub_index) / 5.0)
			sub_index += 1



func move_other_sprites():
	# reset_min_max()
	# current_data_size = max(0, current_data_size - 1)
	
	#print("---- Redrawing all ----")
	#for i in range(current_data.size()):
		#print("data %d: %s" % [i, current_data[i]])
	
	var index = 0
	# var i = current_data.size()
	for points_data in current_data:
		_move_other_sprites(points_data, index)
		index += 1
		# i -= 1
	
	# current_data_size = current_data.size()
	# queue_redraw()
	

func animation_move_dot(node, end_pos, end_scale, delay = 0.0, duration = 0.5):
	# animation
	if node == null:
		return
	
	# create tween
	# TODO -- fix warning start: Target object freed before starting, aborting Tweener.
	var _tween_node = create_tween()
	
	_tween_node.set_parallel(true)
	_tween_node.set_trans(Tween.TRANS_CIRC)
	_tween_node.set_ease(Tween.EASE_OUT)
	
	# TODO -- add delay from 3.1 code.
	# currently delaying the position can cause some issues, so disabling that one for now
	# print("delay = ", delay)

	_tween_node.tween_property(node, 'position', end_pos, duration)#.set_delay(delay)
	_tween_node.tween_property(node, 'scale', end_scale, duration).set_delay(delay)
	_tween_node.tween_method(Callable(self, '_update_draw'), 0.0, 1.0, duration).set_delay(delay)

	_tween_node.finished.connect((func():
		# moved to
		#print("moved to: ")
		#print(node.position)
		#print(node.scale)
		#print()
		# print("moved point")
		# set_labels(current_show_label)
		pass
	), CONNECT_ONE_SHOT)
	
	# print("dot moved")
	# node.position = end_pos
	# node.scale = end_scale
	
	# _update_draw()
	



func animation_move_arcpolygon(key_value, end_value, delay = 0.0, duration = 0.667):

	var radius_key = '%s_radius' % [key_value]
	var computed_radius = round(min(max_y - min_y, max_x - min_x) / 2.0)


	# create tween
	# TODO -- fix warning start: Target object freed before starting, aborting Tweener.
	var _tween_node = create_tween()
	
	_tween_node.set_parallel(true)
	_tween_node.set_trans(Tween.TRANS_CIRC)
	_tween_node.set_ease(Tween.EASE_OUT)
	
	_tween_node.tween_property(pie_chart_current_data, NodePath(key_value), end_value, duration).set_delay(delay)
	_tween_node.tween_property(pie_chart_current_data, radius_key, computed_radius, duration).set_delay(delay)
	_tween_node.tween_method(Callable(self, '_update_draw'), 0.0, 1.0, duration).set_delay(delay)

	_tween_node.finished.connect((func():
		# moved to
		#print("moved to: ")
		#print(node.position)
		#print(node.scale)
		#print()
		# print("moved point")
		# set_labels(current_show_label)
		pass
	), CONNECT_ONE_SHOT)
	
	
	
	#pie_chart_current_data.set(key_value, end_value)
	#pie_chart_current_data.set(radius_key, computed_radius)
	
	
	_update_draw()
	
	
	



func _update_draw(object = null):
	queue_redraw()



############################################################
# Utilitary functions
const ordinary_factor = 10
const range_factor = 1000
const units = ['', 'K', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y']
############################################################


func format(number, format_text_custom = '%.2f %s'):
	var unit_index = 0
	var format_text = '%d %s'
	var ratio = 1

	for index in range(0, units.size()):
		var computed_ratio = pow(range_factor, index)

		if abs(number) > computed_ratio:
			ratio = computed_ratio
			unit_index = index

			if index > 0:
				format_text = format_text_custom

	return format_text % [(number / ratio), units[unit_index]]



func compute_ordinate_values(max_value, min_value):
	var amplitude = max_value - min_value
	var ordinate_values = [-10, -8, -6, -4, -2, 0, 2, 4, 6, 8, 10]
	var result = []
	var ratio = 1

	for index in range(0, ordinary_factor):
		var computed_ratio = pow(ordinary_factor, index)

		if abs(amplitude) > computed_ratio:
			ratio = computed_ratio
			ordinate_values = []

			for sub_index in range(-6, 6):
				ordinate_values.push_back(5 * sub_index * computed_ratio / ordinary_factor)

	# Keep only valid values
	for value in ordinate_values:
		if value <= max_value and value >= min_value:
			result.push_back(value)

	return result
