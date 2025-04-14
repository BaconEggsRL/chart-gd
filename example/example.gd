extends Control

@onready var chart_node:Chart = get_node('chart')
@onready var fps_label = get_node('benchmark/fps')
@onready var points_label = get_node('benchmark/points')

@onready var no_label: CheckBox = $options/group/noLabel
@onready var ordinate: CheckBox = $options/group/ordinate
@onready var absciss: CheckBox = $options/group/absciss
@onready var legend: CheckBox = $options/group/legend
@onready var all: CheckBox = $options/group/all

@onready var line: CheckBox = $options/groupType/line
@onready var pie: CheckBox = $options/groupType/pie



func _ready():
	# connect option btn signals
	_connect_signals()
	
	# init chart data
	chart_node.initialize(0,
	{
		depenses = Color(1.0, 0.18, 0.18),
		recettes = Color(0.58, 0.92, 0.07),
		interet = Color(0.5, 0.22, 0.6)
	})

	# debug
	chart_node.clear_chart()
	# add points
	reset()
	
	# process
	set_process(true)
	
	# init chart min x, max x
	# chart_node.set_labels(7)


func _process(_delta):
	fps_label.set_text('FPS: %02d' % [Engine.get_frames_per_second()])
	points_label.set_text('NB POINTS: %d' % [chart_node.current_data_size * 3.0])
	
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	elif Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()



func _connect_signals() -> void:
	# group
	no_label.pressed.connect(chart_node.set_labels.bind(0))
	ordinate.pressed.connect(chart_node.set_labels.bind(1))
	absciss.pressed.connect(chart_node.set_labels.bind(2))
	legend.pressed.connect(chart_node.set_labels.bind(4))
	# ***
	all.pressed.connect(chart_node.set_labels.bind(7))
	# groupType
	line.pressed.connect(chart_node.set_chart_type.bind(0))
	pie.pressed.connect(chart_node.set_chart_type.bind(1))
	
	
	
func reset():
	
	chart_node.create_new_point({
		label = 'JANVIER',
		values = {
			depenses = 150,
			recettes = 1025,
			interet = 1050
		}
	})

	chart_node.create_new_point({
		label = 'FEVRIER',
		values = {
			depenses = 500,
			recettes = 1020,
			interet = -150
		}
	})

	chart_node.create_new_point({
		label = 'MARS',
		values = {
			depenses = 10,
			recettes = 1575,
			interet = -450
		}
	})
#
	#chart_node.create_new_point({
		#label = 'AVRIL',
		#values = {
			## depenses = 350,
			## recettes = 750,
			#interet = -509
		#}
	#})
#
	#chart_node.create_new_point({
		#label = 'MAI',
		#values = {
			## depenses = 1350,
			## recettes = 750,
			#interet = -505
		#}
	#})
#
	#chart_node.create_new_point({
		#label = 'JUIN',
		#values = {
			#depenses = 350,
			#recettes = 1750,
			#interet = -950
		#}
	#})
#
	#chart_node.create_new_point({
		#label = 'JUILLET',
		#values = {
			#depenses = 100,
			#recettes = 1500,
			#interet = -350
		#}
	#})
#
	#chart_node.create_new_point({
		#label = 'AOUT',
		#values = {
			#depenses = 350,
			#recettes = 750,
			#interet = -500
		#}
	#})
#
	#chart_node.create_new_point({
		#label = 'SEPTEMBRE',
		#values = {
			#depenses = 1350,
			#recettes = 750,
			#interet = -50
		#}
	#})
#
	#chart_node.create_new_point({
		#label = 'OCTOBRE',
		#values = {
			#depenses = 350,
			#recettes = 1750,
			#interet = -750
		#}
	#})
#
	#chart_node.create_new_point({
		#label = 'NOVEMBRE',
		#values = {
			#depenses = 450,
			#recettes = 200,
			#interet = -150
		#}
	#})
#
	#chart_node.create_new_point({
		#label = 'DECEMBRE',
		#values = {
			#depenses = 1350,
			#recettes = 500,
			#interet = -500
		#}
	#})
