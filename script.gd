extends Control

const CANVAS_SIZE : Vector2i = Vector2i(480, 480)
const CELL_SIZE : int = 4

@onready var generation_label : Label = $CurrentGeneration
@onready var cells_label : Label = $CurrentCells

@onready var autoplay_label : Button = $Autoplay
@onready var reset_cells_label : Button = $ResetCells
@onready var generate_cells_label : Button = $GenerateCells
@onready var next_generation_label : Button = $NextGeneration
@onready var draw_mode_label : Button = $DrawMode

@onready var background : ColorRect = $Background

@onready var timer : Timer = $Timer

var current_generation : int = 0

var cell_frames : Dictionary[Vector2i, ColorRect] = {}
var cell_state : Dictionary[Vector2i, bool] = {}
var fast_noise : FastNoiseLite = FastNoiseLite.new()

var left_click : bool = false
var right_click : bool = false
var draw_mode : bool = false
var autoplay : bool = false

func generate_canvas():
	for x in int(CANVAS_SIZE.x / CELL_SIZE):
		for y in int(CANVAS_SIZE.y / CELL_SIZE):
			var new_cell : ColorRect = ColorRect.new()
			new_cell.size = (Vector2(1, 1) * CELL_SIZE) - Vector2(1, 1)
			
			if (x + y % 2) % 2 == 0:
				new_cell.color = Color(0.0, 0.0, 0.0, 1.0)
			
			new_cell.position = (Vector2(CELL_SIZE, CELL_SIZE) * Vector2(x, y)) + Vector2(0.5, 0.5)
			
			cell_frames[Vector2i(x, y)] = new_cell
			cell_state[Vector2i(x, y)] = false
			
			background.add_child(new_cell)

func generate_cells():
	current_generation = 0
	fast_noise.seed = randi_range(0, 4096)
	
	for x in int(CANVAS_SIZE.x / CELL_SIZE):
		for y in int(CANVAS_SIZE.y / CELL_SIZE):
			var noise_value = fast_noise.get_noise_2d(x, y)
			
			if noise_value > 0.2:
				cell_state[Vector2i(x, y)] = true
			else:
				cell_state[Vector2i(x, y)] = false
	
	update_canvas()

func update_canvas():
	var alive_cells : int = 0
	
	for x in int(CANVAS_SIZE.x / CELL_SIZE):
		for y in int(CANVAS_SIZE.y / CELL_SIZE):
			var new_cell : ColorRect = cell_frames[Vector2i(x, y)]
			var state : bool = cell_state[Vector2i(x, y)]
			
			if state == true:
				new_cell.color = Color(1.0, 1.0, 1.0, 1.0)
				alive_cells += 1
			else:
				new_cell.color = Color(0.0, 0.0, 0.0, 1.0)
	
	cells_label.text = "Current cells: " + str(alive_cells)

func clear_cells():
	current_generation = 0
	
	for x in int(CANVAS_SIZE.x / CELL_SIZE):
		for y in int(CANVAS_SIZE.y / CELL_SIZE):
			cell_state[Vector2i(x, y)] = false
	
	update_canvas()

func next_generation():
	current_generation += 1
	
	var new_states : Dictionary[Vector2i, bool] = {}
	var neighbor_list : Array[Vector2i] = [
		Vector2i(-1, 1),
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(-1, -1),
		Vector2i(0, -1),
		Vector2i(1, -1),
	]
	
	for x in int(CANVAS_SIZE.x / CELL_SIZE):
		for y in int(CANVAS_SIZE.y / CELL_SIZE):
			var curr_cell = cell_state[Vector2i(x, y)]
			var alive_neighbors : int = 0
			var new_cell_state : bool = false
			
			for pos in neighbor_list:
				if cell_state.has(Vector2i(x, y) + pos):
					var neighbor_state = cell_state[Vector2i(x, y) + pos]
					if neighbor_state == true:
						alive_neighbors += 1
			
			if curr_cell == true:
				if alive_neighbors < 2:
					new_cell_state = false
				elif alive_neighbors > 3:
					new_cell_state = false
				else:
					new_cell_state = true
			else:
				if alive_neighbors == 3:
					new_cell_state = true
			
			new_states[Vector2i(x, y)] = new_cell_state
	
	cell_state = new_states
	update_canvas()



func _ready() -> void:
	fast_noise.frequency = 0.1
	fast_noise.fractal_lacunarity = 10.0
	fast_noise.fractal_weighted_strength = 1.0
	
	generate_canvas()
	update_canvas()
	
	print(cell_frames.size())
	
	generate_cells_label.button_down.connect(generate_cells)
	next_generation_label.button_down.connect(next_generation)
	reset_cells_label.button_down.connect(clear_cells)
	
	draw_mode_label.button_down.connect(func():
		draw_mode = not draw_mode
	)
	
	autoplay_label.button_down.connect(func():
		autoplay = not autoplay
	)
	
	timer.timeout.connect(func():
		if autoplay == true:
			next_generation()
	)

func toggle_text(text : String, val : bool):
	if val == true:
		return text + "ON"
	else:
		return text + "OFF"

func _process(delta: float) -> void:
	generation_label.text = "Current generation: " + str(current_generation)
	
	draw_mode_label.text = toggle_text("Draw mode: ", draw_mode)
	autoplay_label.text = toggle_text("Autoplay: ", autoplay)
	
	left_click = Input.is_action_pressed("draw")
	right_click = Input.is_action_pressed("erase")
	
	var mouse_pos : Vector2 = get_viewport().get_mouse_position()
	
	if draw_mode == true:
		var update : bool = false
		
		for x in int(CANVAS_SIZE.x / CELL_SIZE):
			for y in int(CANVAS_SIZE.y / CELL_SIZE):
				var new_cell : ColorRect = cell_frames[Vector2i(x, y)]
				var curr_state : bool = cell_state[Vector2i(x, y)]
				var cell_pos : Vector2 = new_cell.position
				
				if cell_pos.distance_to(mouse_pos) <= float(CELL_SIZE) / 2:
					if left_click and curr_state == false:
						update = true
						cell_state[Vector2i(x, y)] = true
					elif right_click and curr_state == true:
						update = true
						cell_state[Vector2i(x, y)] = false
		
		if update:
			update_canvas()
