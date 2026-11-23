
extends Control

var values: Array[float] = []
var graph_title := "Temperatura"
var x_title := "Tempo (s)"
var y_title := "Temperatura (°C)"
var duration := 20.0

const GRAPH_COLOR = Color("ed4d87ff")
const GRID_COLOR = Color("b85a8aff")
const TEXT_COLOR = Color.WHITE
var mouse_position := Vector2.ZERO
var hovered_point := -1

const HOVER_DISTANCE := 12.0
func set_data(
	new_values: Array[float],
	title: String,
	x_label := "Tempo (s)",
	y_label := "Temperatura (°C)",
	total_time := 20.0
) -> void:

	values = new_values.duplicate()
	graph_title = title
	x_title = x_label
	y_title = y_label
	duration = maxf(total_time, 0.001)

	queue_redraw()

func _gui_input(event: InputEvent) -> void:

	if event is InputEventMouseMotion:

		mouse_position = event.position

		hovered_point = -1

		if values.size() < 2:
			queue_redraw()
			return

		var rect = Rect2(
			75,
			65,
			size.x - 105,
			size.y - 145
		)

		var min_value = values.min()
		var max_value = values.max()

		var variation = max_value - min_value
		var margin = maxf(variation * 0.10, 0.001)

		var y_min = min_value - margin
		var y_max = max_value + margin
		var y_range = y_max - y_min

		var closest_distance = HOVER_DISTANCE

		for i in range(values.size()):

			var x_fraction = float(i) / (values.size() - 1)
			var y_fraction = (values[i] - y_min) / y_range

			var point = Vector2(
				rect.position.x + x_fraction * rect.size.x,
				rect.end.y - y_fraction * rect.size.y
			)

			var distance = mouse_position.distance_to(point)

			if distance < closest_distance:

				closest_distance = distance
				hovered_point = i

		queue_redraw()
func _draw() -> void:

	var rect = Rect2(
		75,
		65,
		size.x - 105,
		size.y - 145
	)

	if rect.size.x <= 0 or rect.size.y <= 0:
		return

	# Fundo
	draw_rect(rect, Color("57246fff"), true)

	draw_rect(
		rect,
		Color("b33b70ff"),
		false,
		2.0
	)

	# Título
	draw_string(
		ThemeDB.fallback_font,
		Vector2(65, 25),
		graph_title,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		17,
		TEXT_COLOR
	)

	if values.size() < 2:
		return

	# Encontrar limites
	var min_value = values.min()
	var max_value = values.max()

	var variation = max_value - min_value

	# Evitar divisão por zero e ampliar a escala
	var margin = maxf(variation * 0.10, 0.001)

	var y_min = min_value - margin
	var y_max = max_value + margin

	var y_range = y_max - y_min

	# Grade e valores do eixo Y
	for i in range(6):

		var fraction = float(i) / 5.0

		var y = rect.end.y - fraction * rect.size.y

		var value = y_min + fraction * y_range

		draw_line(
			Vector2(rect.position.x, y),
			Vector2(rect.end.x, y),
			GRID_COLOR,
			1.0
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(2, y + 4),
			"%.3f" % value,
			HORIZONTAL_ALIGNMENT_RIGHT,
			65,
			10,
			TEXT_COLOR
		)

	# Divisões do eixo X
	for i in range(6):

		var fraction = float(i) / 5.0

		var x = rect.position.x + fraction * rect.size.x

		var time = fraction * duration

		draw_line(
			Vector2(x, rect.position.y),
			Vector2(x, rect.end.y),
			Color("a5256b80"),
			1.0
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(x - 12, rect.end.y + 18),
			"%.1f" % time,
			HORIZONTAL_ALIGNMENT_CENTER,
			35,
			10,
			TEXT_COLOR
		)

	# Curva
	var previous_point = Vector2.ZERO

	for i in range(values.size()):

		var x_fraction = float(i) / (values.size() - 1)

		var y_fraction = (values[i] - y_min) / y_range

		var point = Vector2(
			rect.position.x + x_fraction * rect.size.x,
			rect.end.y - y_fraction * rect.size.y
		)

		if i > 0:

			draw_line(
				previous_point,
				point,
				GRAPH_COLOR,
				3.0,
				true
			)

		# Marcação dos pontos
		draw_circle(
			point,
			4.0,
			Color.WHITE
		)

		draw_circle(
			point,
			2.0,
			GRAPH_COLOR
		)

		previous_point = point

	# Nome dos eixos
	draw_string(
		ThemeDB.fallback_font,
		Vector2(
			rect.position.x + rect.size.x / 2 - 40,
			size.y - 12
		),
		x_title,
		HORIZONTAL_ALIGNMENT_CENTER,
		100,
		12,
		TEXT_COLOR
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(65, 48),
		y_title,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		11,
		TEXT_COLOR
	)
# Tooltip ao passar o mouse
	if hovered_point >= 0:

		var index = hovered_point

		var time = (float(index) / (values.size() - 1)) * duration

		var temperature = values[index]

		var x_fraction = float(index) / (values.size() - 1)
		var y_fraction = (temperature - y_min) / y_range

		var point = Vector2(
			rect.position.x + x_fraction * rect.size.x,
			rect.end.y - y_fraction * rect.size.y
		)

		# Destacar o ponto selecionado
		draw_circle(
			point,
			7.0,
			Color.WHITE
		)

		draw_circle(
			point,
			4.0,
			GRAPH_COLOR
		)

		# Caixa do tooltip
		var tooltip_size = Vector2(155, 55)

		var tooltip_position = point + Vector2(12, -65)

		# Evitar que o tooltip saia do gráfico
		tooltip_position.x = clampf(
			tooltip_position.x,
			0,
			size.x - tooltip_size.x
		)

		tooltip_position.y = clampf(
			tooltip_position.y,
			0,
			size.y - tooltip_size.y
		)

		draw_rect(
			Rect2(tooltip_position, tooltip_size),
			Color("57246fff"),
			true
		)

		draw_rect(
			Rect2(tooltip_position, tooltip_size),
			GRAPH_COLOR,
			false,
			1.5
		)

		draw_string(
			ThemeDB.fallback_font,
			tooltip_position + Vector2(8, 20),
			"Tempo: %.2f s" % time,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			12,
			TEXT_COLOR
		)

		draw_string(
			ThemeDB.fallback_font,
			tooltip_position + Vector2(8, 42),
			"Temperatura: %.3f °C" % temperature,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			12,
			TEXT_COLOR
		)
