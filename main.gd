
extends Control

const SIGMA = 5.670374419e-8

var calculation_label: RichTextLabel
var mode: OptionButton
var fields = {}
var result_label: Label
var graph: Control

# Parâmetros da simulação
var simulation_time := 80
var thermal_time_constant := 7.0
var stabilization_label: Label
var material_panel: VBoxContainer
var material_button: Button
var material_container: VBoxContainer
var material_buttons: VBoxContainer

var materials = {
	"Alumínio": {
		"value": 23e-6,
		"description": "Alta dilatação térmica."
	},
	"Cobre": {
		"value": 17e-6,
		"description": "Dilatação intermediária."
	},
	"Aço": {
		"value": 12e-6,
		"description": "Baixa dilatação térmica."
	},
	"Ferro": {
		"value": 12e-6,
		"description": "Coeficiente aproximado."
	},
	"Vidro comum": {
		"value": 9e-6,
		"description": "Baixa dilatação térmica."
	},
	"Concreto": {
		"value": 10e-6,
		"description": "Coeficiente aproximado."
	},
	"Latão": {
		"value": 19e-6,
		"description": "Liga de cobre e zinco."
	},
	"Aço inoxidável": {
	"value": 17e-6,
	"description": "Valor aproximado para aço inoxidável."
},
	"Invar": {
		"value": 1.2e-6,
		"description": "Baixíssima dilatação térmica."
	}
}

func _ready():
	build_interface()
	apply_theme()

# Interface

func build_interface():

	var background = ColorRect.new()
	background.color = Color("2f2644ff")
	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	add_child(background)
	
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	add_child(scroll)
	

	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("margin_left", 25)
	layout.add_theme_constant_override("margin_right", 25)

	scroll.add_child(layout)

	# Título

	var title = Label.new()
	title.text = "Simulador Térmico"
	title.add_theme_font_size_override("font_size", 26)
	layout.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Engenharia da Computação"
	layout.add_child(subtitle)

	# Seleção do modo

	mode = OptionButton.new()

	mode.add_item("Condução")
	mode.add_item("Convecção")
	mode.add_item("Radiação")
	mode.add_item("Dilatação térmica")

	layout.add_child(mode)

	mode.item_selected.connect(_on_mode_changed)

	# Campos de entrada

	add_field(layout, "Área (m²)", "area", 1.0)

	add_field(
		layout,
		"Temperatura inicial (°C)",
		"t1",
		100.0
	)

	add_field(
		layout,
		"Temperatura ambiente/final (°C)",
		"t2",
		25.0
	)

	add_field(
		layout,
		"Espessura ou comprimento (m)",
		"length",
		0.1
	)

	add_field(
		layout,
		"Propriedade física (k, h, ε ou α)",
		"property",
		0.5
	)
	build_material_panel(layout)

	# Botão de simulação

	var button = Button.new()
	button.text = "Executar Simulação"
	button.custom_minimum_size.y = 45

	layout.add_child(button)

	button.pressed.connect(calculate)

	# Resultado

	result_label = Label.new()
	result_label.text = "Insira os dados e execute a simulação."
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.add_theme_font_size_override("font_size", 18)

	layout.add_child(result_label)

	stabilization_label = Label.new()
	stabilization_label.text = "Tempo de estabilização: --"
	stabilization_label.add_theme_font_size_override("font_size", 18)
	stabilization_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	layout.add_child(stabilization_label)
	# Memória de cálculo

	var calculation_title = Label.new()
	calculation_title.text = "Cálculo"
	calculation_title.add_theme_font_size_override(
		"font_size",
		22
	)

	layout.add_child(calculation_title)

	calculation_label = RichTextLabel.new()
	calculation_label.custom_minimum_size = Vector2(0, 250)
	calculation_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	calculation_label.bbcode_enabled = true
	calculation_label.fit_content = true

	layout.add_child(calculation_label)
	# Gráfico

	graph = Control.new()
	graph.set_script(load("res://graphs.gd"))

	graph.custom_minimum_size = Vector2(550, 400)

	layout.add_child(graph)


# Input

func add_field(
	parent: Control,
	title: String,
	key: String,
	initial: float
):

	var label = Label.new()
	label.text = title

	parent.add_child(label)

	var input = SpinBox.new()

	input.min_value = 0.000001
	input.max_value = 1000000.0
	input.step = 0.000001
	input.value = initial

	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	parent.add_child(input)

	fields[key] = input


func get_value(key: String) -> float:

	return fields[key].value



func _on_mode_changed(index: int):

	var names = [
		"Condução",
		"Convecção",
		"Radiação",
		"Dilatação térmica"
	]

	# Atualizar mensagem de resultado
	result_label.text = (
		"Modo selecionado: " + names[index]
		+ "\nExecute uma nova simulação."
	)

	# Limpar tempo de estabilização
	stabilization_label.text = (
		"Tempo de estabilização térmica: --\n"
		+ "Temperatura final: --\n"
		+ "Tolerância: ±0.5 °C"
	)

	material_panel.visible = (index == 3)

	material_container.visible = false

	material_button.text = "▼ Biblioteca de Materiais"
	# Limpar memória de cálculo
	calculation_label.clear()


# Simular Temp

func generate_temperature_samples(
	t1: float,
	t2: float,
	total_time: float
) -> Array[float]:

	var samples: Array[float] = []

	for i in range(101):

		var time = total_time * float(i) / 100.0

		var temperature = t2 + (
			t1 - t2
		) * exp(-time / thermal_time_constant)

		samples.append(temperature)

	return samples


func calculate_stabilization_time(
	t1: float,
	t2: float,
	tolerance := 0.5
) -> float:

	var difference = absf(t1 - t2)

	if difference <= tolerance:
		return 0.0

	return thermal_time_constant * log(
		difference / tolerance
	)



# Cálculo


func calculate():

	var area = get_value("area")
	var t1 = get_value("t1")
	var t2 = get_value("t2")
	var dimension = get_value("length")
	var prop = get_value("property")

	var result = 0.0
	var description = ""
	var final_text = ""

	var samples: Array[float] = []

	# Calcular tempo de estabilização
	var stabilization_time = calculate_stabilization_time(
		t1,
		t2
	)

	var graph_time = maxf(
		stabilization_time,
		stabilization_time * 1.15
	)

	# Atualizar informações de estabilização
	stabilization_label.text = (
		"Tempo de estabilização térmica: %.2f segundos\n"
		+ "Temperatura final: %.2f °C\n"
		+ "Tolerância: ±0.5 °C"
	) % [
		stabilization_time,
		t2
	]

	# Gerar temperaturas ao longo do tempo
	var temperatures = generate_temperature_samples(
		t1,
		t2,
		graph_time
	)

	# Selecionar modo de simulação
	match mode.selected:

		# Condução
		0:

			result = prop * area * (t1 - t2) / dimension

			description = "Transferência de calor por condução"

			samples = temperatures

			final_text = (
				"Taxa de transferência de calor: %.3f W"
				% result
			)

		# Convecção
		1:

			result = prop * area * (t1 - t2)

			description = "Transferência de calor por convecção"

			samples = temperatures

			final_text = (
				"Taxa de transferência de calor: %.3f W"
				% result
			)

		# Radiação
		2:

			var tk1 = t1 + 273.15
			var tk2 = t2 + 273.15

			result = prop * SIGMA * area * (
				tk1 ** 4 - tk2 ** 4
			)

			description = "Transferência de calor por radiação"

			samples = temperatures

			final_text = (
				"Taxa de transferência de calor: %.3f W"
				% result
			)

		# Dilatação térmica
		3:

			result = prop * dimension * (t2 - t1)

			description = "Dilatação térmica"

			var final_length = dimension + result

			for temperature in temperatures:

				var expansion = prop * dimension * (
					temperature - t1
				)

				samples.append(
					dimension + expansion
				)

			final_text = (
				"Variação do comprimento: %.8f m\n"
				+ "Comprimento inicial: %.8f m\n"
				+ "Comprimento final: %.8f m"
			) % [
				result,
				dimension,
				final_length
			]

	# Atualizar gráfico
	if mode.selected == 3:

		graph.set_data(
			samples,
			"Dilatação térmica ao longo do tempo",
			"Tempo (s)",
			"Comprimento (m)",
			graph_time
		)

	else:

		graph.set_data(
			samples,
			"Temperatura ao longo do tempo",
			"Tempo (s)",
			"Temperatura (°C)",
			graph_time
		)

	# Atualizar resultado
	result_label.text = (
		description
		+ "\n"
		+ final_text
	)
	show_calculations(
	t1,
	t2,
	area,
	dimension,
	prop,
	result,
	stabilization_time
)


func show_calculations(
	t1: float,
	t2: float,
	area: float,
	dimension: float,
	prop: float,
	result: float,
	stabilization_time: float
):

	var text = ""

	match mode.selected:

		# CONDUÇÃO
		0:

			text += "[b]1. Condução térmica[/b]\n\n"

			text += "[b]Fórmula utilizada:[/b]\n"
			text += "Q = k · A · (T1 - T2) / L\n\n"

			text += "[b]Variáveis:[/b]\n"
			text += "k = %.4f W/(m·K)\n" % prop
			text += "A = %.4f m²\n" % area
			text += "T1 = %.2f °C\n" % t1
			text += "T2 = %.2f °C\n" % t2
			text += "L = %.4f m\n\n" % dimension

			text += "[b]Substituindo:[/b]\n"

			text += "Q = %.4f · %.4f · (%.2f - %.2f) / %.4f\n\n" % [
				prop, area, t1, t2, dimension
			]

			text += "[b]Resultado:[/b]\n"
			text += "%.4f W\n\n" % result

		# CONVECÇÃO
		1:

			text += "[b]1. Convecção térmica[/b]\n\n"

			text += "[b]Fórmula utilizada:[/b]\n"
			text += "Q = h · A · (T1 - T2)\n\n"

			text += "[b]Variáveis:[/b]\n"
			text += "h = %.4f W/(m²·K)\n" % prop
			text += "A = %.4f m²\n" % area
			text += "T1 = %.2f °C\n" % t1
			text += "T2 = %.2f °C\n\n" % t2

			text += "[b]Substituindo:[/b]\n"

			text += "Q = %.4f · %.4f · (%.2f - %.2f)\n\n" % [
				prop, area, t1, t2
			]

			text += "[b]Resultado:[/b]\n"
			text += "%.4f W\n\n" % result

		# RADIAÇÃO
		2:

			var tk1 = t1 + 273.15
			var tk2 = t2 + 273.15

			text += "[b]1. Radiação térmica[/b]\n\n"

			text += "[b]Fórmula utilizada:[/b]\n"
			text += "Q = ε · σ · A · (T1⁴ - T2⁴)\n\n"

			text += "[b]Constante de Stefan-Boltzmann:[/b]\n"
			text += "σ = 5.670374419 × 10⁻⁸ W/(m²·K⁴)\n\n"

			text += "[b]Conversão para Kelvin:[/b]\n"
			text += "T1 = %.2f + 273.15 = %.2f K\n" % [t1, tk1]
			text += "T2 = %.2f + 273.15 = %.2f K\n\n" % [t2, tk2]

			text += "[b]Substituindo:[/b]\n"

			text += "Q = %.4f · σ · %.4f · (%.2f⁴ - %.2f⁴)\n\n" % [
				prop, area, tk1, tk2
			]

			text += "[b]Resultado:[/b]\n"
			text += "%.8f W\n\n" % result

		# DILATAÇÃO TÉRMICA
		3:

			var expansion = prop * dimension * (t2 - t1)

			text += "[b]1. Dilatação térmica linear[/b]\n\n"

			text += "[b]Fórmula utilizada:[/b]\n"
			text += "ΔL = α · L0 · ΔT\n\n"

			text += "[b]Variáveis:[/b]\n"
			text += "α = %.8f °C⁻¹\n" % prop
			text += "L0 = %.6f m\n" % dimension
			text += "T1 = %.2f °C\n" % t1
			text += "T2 = %.2f °C\n\n" % t2

			text += "[b]Variação de temperatura:[/b]\n"
			text += "ΔT = T2 - T1\n"
			text += "ΔT = %.2f - %.2f = %.2f °C\n\n" % [
				t2, t1, t2 - t1
			]

			text += "[b]Substituindo:[/b]\n"

			text += "ΔL = %.8f · %.6f · %.2f\n\n" % [
				prop, dimension, t2 - t1
			]

			text += "[b]Resultado:[/b]\n"
			text += "ΔL = %.8f m\n\n" % expansion

	# MODELO TEMPORAL
	text += "[b]2. Evolução térmica no tempo[/b]\n\n"

	text += "[b]Equação utilizada:[/b]\n"
	text += "T(t) = T2 + (T1 - T2) · e^(-t/τ)\n\n"

	text += "[b]Parâmetros:[/b]\n"
	text += "T1 = %.2f °C\n" % t1
	text += "T2 = %.2f °C\n" % t2
	text += "τ = %.2f s\n\n" % thermal_time_constant

	text += "[b]3. Tempo de estabilização[/b]\n\n"

	text += "[b]Critério:[/b]\n"
	text += "|T(t) - T2| ≤ 0.5 °C\n\n"

	text += "[b]Fórmula utilizada:[/b]\n"
	text += "t = τ · ln(|T1 - T2| / tolerância)\n\n"

	text += "[b]Substituindo:[/b]\n"

	text += "t = %.2f · ln(%.2f / 0.5)\n\n" % [
		thermal_time_constant,
		absf(t1 - t2)
	]

	text += "[b]Tempo de estabilização:[/b]\n"
	text += "%.2f segundos\n" % stabilization_time

	calculation_label.text = text


func apply_theme():

	var theme = Theme.new()

	# CORES
	var background = Color("#0B0B12")
	var panel = Color("#151522")
	var purple = Color("#762BCE")
	var accent = Color("#A855F7")
	var text_color = Color("#E9E7F2")
	var muted = Color("#A5A1B5")

	# LABELS
	theme.set_color("font_color", "Label", text_color)
	theme.set_color("font_color", "RichTextLabel", text_color)

	# BOTÕES
	var button_normal = StyleBoxFlat.new()
	button_normal.bg_color = purple
	button_normal.set_corner_radius_all(8)
	button_normal.content_margin_left = 12
	button_normal.content_margin_right = 12
	button_normal.content_margin_top = 10
	button_normal.content_margin_bottom = 10

	var button_hover = button_normal.duplicate()
	button_hover.bg_color = accent

	var button_pressed = button_normal.duplicate()
	button_pressed.bg_color = Color("#54209A")

	theme.set_stylebox("normal", "Button", button_normal)
	theme.set_stylebox("hover", "Button", button_hover)
	theme.set_stylebox("pressed", "Button", button_pressed)

	theme.set_color("font_color", "Button", Color.WHITE)

	# CAMPOS DE ENTRADA
	var input_style = StyleBoxFlat.new()
	input_style.bg_color = panel
	input_style.border_color = purple
	input_style.set_border_width_all(1)
	input_style.set_corner_radius_all(6)

	theme.set_stylebox("normal", "SpinBox", input_style)
	theme.set_stylebox("focus", "SpinBox", input_style)

	# MENU DE SELEÇÃO
	theme.set_color("font_color", "OptionButton", text_color)

	# APLICAR TEMA
	self.theme = theme


func build_material_panel(parent: VBoxContainer):
	material_panel = VBoxContainer.new()

	material_panel.add_theme_constant_override(
		"separation", 8
	)

	parent.add_child(material_panel)

	# Botão para abrir e fechar

	material_button = Button.new()

	material_button.text = "▼ Biblioteca de Materiais"

	material_button.custom_minimum_size.y = 40

	material_panel.add_child(material_button)

	# Container dos materiais

	material_container = VBoxContainer.new()

	material_container.add_theme_constant_override(
		"separation", 6
	)

	material_panel.add_child(material_container)

	var title = Label.new()

	title.text = "Selecione um material:"

	material_container.add_child(title)

	# Botões dos materiais

	material_buttons = VBoxContainer.new()

	material_buttons.add_theme_constant_override(
		"separation", 5
	)

	material_container.add_child(material_buttons)

	for material_name in materials.keys():

		var button = Button.new()

		button.text = material_name

		button.custom_minimum_size.y = 38

		material_buttons.add_child(button)

		button.pressed.connect(
			func():
				select_material(material_name)
		)

	# Estado inicial

	material_container.visible = false

	material_button.pressed.connect(
		toggle_material_panel
	)

	# Painel só aparece na dilatação

	material_panel.visible = false


func select_material(material_name: String):

	var material = materials[material_name]

	# Atualizar o campo de propriedade física

	fields["property"].value = material.value

	# Atualizar o resultado informativo

	result_label.text = (
		"Material selecionado: %s\n" % material_name
		+ "Coeficiente de dilatação: %.8f °C⁻¹\n" % material.value
		+ material.description
		+ "\nExecute uma nova simulação."
	)

	# Fechar painel após seleção

	material_container.visible = false

	material_button.text = "▼ Biblioteca de Materiais"

func toggle_material_panel():

	material_container.visible = !material_container.visible

	if material_container.visible:

		material_button.text = "▲ Fechar Biblioteca"

	else:

		material_button.text = "▼ Biblioteca de Materiais"
