# =============================================================
# Snake Aether — Godot 4.3 Main script
# Builds the entire scene tree procedurally and runs the game.
# =============================================================
extends Node2D

# ---------- Constants ----------
const COLS := 24
const ROWS := 24
const POWER := {
    "NONE": 0, "BONUS": 1, "SLOW": 2, "SHRINK": 3, "GHOST": 4,
    "COIN": 5, "BOSS": 6, "MAGNET": 7, "SHIELD": 8, "MULTI": 9, "DOUBLE": 10
}
const REWIND_START := 3
const REWIND_STEPS := 12
const REWIND_BUFFER := 60
const POWER_DURATION_MS := 6000
const COMBO_WINDOW_MS := 2200
const COMBO_MAX := 8
const BOSS_INTERVAL_MS := 30000
const BOSS_LIFETIME_MS := 12000
const BOSS_POINTS := 25
const BOSS_COINS := 5
const TIME_LIMIT_MS := 60000
const TIME_EXTEND_MS := 2000
const BLITZ_LIMIT_MS := 30000
const BLITZ_EXTEND_MS := 1500
const SURVIVAL_WAVE_MS := 20000
const SURVIVAL_RIVAL_AT := 30000

const DIFFS := [
    {"step_ms": 140, "accel": 0.15},
    {"step_ms": 108, "accel": 0.32},
    {"step_ms":  82, "accel": 0.50},
    {"step_ms":  60, "accel": 0.78},
]

const PALETTES := {
    "cyan":    {"primary": Color8(94,234,212), "secondary": Color8(167,139,250), "accent": Color8(96,165,250)},
    "sunset":  {"primary": Color8(251,146,60), "secondary": Color8(245,158,11),  "accent": Color8(251,191,36)},
    "red":     {"primary": Color8(239,68,68),  "secondary": Color8(251,113,133), "accent": Color8(248,113,113)},
    "gold":    {"primary": Color8(253,224,71), "secondary": Color8(251,191,36),  "accent": Color8(254,240,138)},
    "lavender":{"primary": Color8(196,181,253),"secondary": Color8(167,139,250), "accent": Color8(221,214,254)},
    "pink":    {"primary": Color8(244,114,182),"secondary": Color8(236,72,153),  "accent": Color8(249,168,212)},
    "emerald": {"primary": Color8(34,197,94),  "secondary": Color8(132,204,22),  "accent": Color8(190,242,100)},
    "amber":   {"primary": Color8(251,191,36), "secondary": Color8(245,158,11),  "accent": Color8(254,240,138)},
}

const MODES := {
    "classic":  {"name": "Classic",     "short": "Endless",  "desc": "Walls wrap. Pure score chase.", "palette": "cyan"},
    "arcade":   {"name": "Arcade",      "short": "10 Levels","desc": "Hand-crafted goals. Beat to advance.", "palette": "sunset"},
    "survival": {"name": "Survival",    "short": "Waves",    "desc": "Obstacles spawn. Rival at 30s.", "palette": "red"},
    "time":     {"name": "Time Attack", "short": "60s",      "desc": "60s. Each eat +2s.", "palette": "gold"},
    "zen":      {"name": "Zen",         "short": "No Death", "desc": "No fail. Just play.", "palette": "lavender"},
    "daily":    {"name": "Daily",       "short": "Seeded",   "desc": "Same map for everyone today.", "palette": "cyan"},
    "blitz":    {"name": "Blitz",       "short": "30s+",     "desc": "30s sprint. +1.5s per eat.", "palette": "pink"},
    "gauntlet": {"name": "Gauntlet",    "short": "Boss/5",   "desc": "Endless. Boss every 5 levels.", "palette": "emerald"},
}

const SKINS := [
    {"id": "mint",     "name": "Mint",     "price":    0, "premium": false, "body": "10b981", "glow": "34d399", "head": "5eead4"},
    {"id": "sunset",   "name": "Sunset",   "price":   60, "premium": false, "body": "fb923c", "glow": "fdba74", "head": "fed7aa"},
    {"id": "cyber",    "name": "Cyber",    "price":  120, "premium": false, "body": "ec4899", "glow": "f472b6", "head": "fbcfe8"},
    {"id": "toxic",    "name": "Toxic",    "price":  180, "premium": false, "body": "84cc16", "glow": "a3e635", "head": "bef264"},
    {"id": "azure",    "name": "Azure",    "price":  260, "premium": false, "body": "3b82f6", "glow": "60a5fa", "head": "93c5fd"},
    {"id": "violet",   "name": "Violet",   "price":  320, "premium": false, "body": "8b5cf6", "glow": "a78bfa", "head": "c4b5fd"},
    {"id": "crimson",  "name": "Crimson",  "price":  400, "premium": false, "body": "dc2626", "glow": "f87171", "head": "fca5a5"},
    {"id": "aqua",     "name": "Aqua",     "price":  500, "premium": false, "body": "06b6d4", "glow": "22d3ee", "head": "67e8f9"},
    {"id": "silver",   "name": "Silver",   "price":  600, "premium": false, "body": "94a3b8", "glow": "cbd5e1", "head": "e2e8f0"},
    {"id": "pyro",     "name": "Pyro",     "price":  700, "premium": false, "body": "dc2626", "glow": "fb923c", "head": "fed7aa"},
    {"id": "gold",     "name": "Gold",     "price":    0, "premium": true,  "body": "fbbf24", "glow": "fde047", "head": "fef08a"},
    {"id": "shadow",   "name": "Shadow",   "price":    0, "premium": true,  "body": "1f2937", "glow": "6b7280", "head": "9ca3af"},
    {"id": "rainbow",  "name": "Rainbow",  "price":    0, "premium": true,  "body": "ffffff", "glow": "ffffff", "head": "ffffff", "animated": true},
    {"id": "phoenix",  "name": "Phoenix",  "price":    0, "premium": true,  "body": "ea580c", "glow": "fbbf24", "head": "fef08a", "phoenix": true},
]

const ACHIEVEMENTS := [
    {"id": "first",    "name": "First Bite",     "desc": "Eat your first orb",  "check": "lifetime_eats:1"},
    {"id": "combo3",   "name": "Combo x3",       "desc": "Reach a x3 combo",    "check": "best_combo:3"},
    {"id": "combo8",   "name": "Combo Master",   "desc": "Reach the max x8",    "check": "best_combo:8"},
    {"id": "score50",  "name": "Half Century",   "desc": "Score 50 in one run", "check": "best_run:50"},
    {"id": "score200", "name": "Snake Charmer",  "desc": "Score 200 in one run","check": "best_run:200"},
    {"id": "score500", "name": "Legend",         "desc": "Score 500 in one run","check": "best_run:500"},
    {"id": "long40",   "name": "Long Tail",      "desc": "Length 40",           "check": "best_len:40"},
    {"id": "boss",     "name": "Boss Slayer",    "desc": "Eat a boss orb",      "check": "lifetime_bosses:1"},
    {"id": "boss10",   "name": "Boss Hunter",    "desc": "Eat 10 boss orbs",    "check": "lifetime_bosses:10"},
    {"id": "kill",     "name": "Apex Predator",  "desc": "Eat the rival",       "check": "lifetime_rivals:1"},
    {"id": "rewind10", "name": "Time Bender",    "desc": "Use rewind 10 times", "check": "lifetime_rewinds:10"},
]

# ---------- State ----------
enum GameState { MENU, PLAY, PAUSE, GAME_OVER, SHOP, SETTINGS, ACHIEVEMENTS }
var state := GameState.MENU
var mode: String = "classic"
var diff: int = 1
var snake: Array = []                           # Array of Vector2i
var path: Array = []                            # Array of {pos: Vector2i, len: float}
var occupy: PackedByteArray
var obstacles: PackedByteArray
var trail: Array = []                           # ghost trail positions
var dir: Vector2i = Vector2i.RIGHT
var next_dir: Vector2i = Vector2i.RIGHT
var foods: Array = []                           # {id, pos, kind, spawn_at}
var food_id: int = 1
var step_ms: float = 100.0
var step_base: float = 100.0
var accel: float = 0.4
var score: int = 0
var best: int = 0
var level: int = 1
var next_level_at: int = 5
var power_until: float = 0.0
var power_kind: int = 0
var shield_stacks: int = 0
var double_stacks: int = 0
var combo: int = 0
var combo_timer_ms: float = 0.0
var rewind_left: int = REWIND_START
var revive_used: bool = false
var invul_until: float = 0.0
var coins_run: int = 0
var history: Array = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var seed_value: int = 0
var shake_amount: float = 0.0
var hitstop_until_ms: float = 0.0
var zoom_punch: float = 1.0
var slowmo_until_ms: float = 0.0
var slowmo_factor: float = 1.0
var next_boss_at_ms: float = 0.0
var boss_id: int = 0
var rival: Dictionary = {}
var rival_score: int = 0
var particles: Array = []
var floats: Array = []
var step_acc_ms: float = 0.0
var run_start_ms: float = 0.0
var time_remaining_ms: float = 0.0
var next_wave_at_ms: float = 0.0
var rival_spawned_at_ms: float = 0.0
var arcade_level: int = 1
var arcade_progress: Dictionary = {"eats": 0, "boss": 0, "rival": 0}
var gauntlet_level: int = 1
var run_stats: Dictionary = {"eats": 0, "boss": 0, "rivals": 0, "max_combo": 0}

# ---------- Visual layout ----------
var cell_size: float = 32.0
var grid_x: float = 0.0
var grid_y: float = 0.0
var grid_w: float = 0.0
var grid_h: float = 0.0

# ---------- Touch ----------
var touch_start: Vector2 = Vector2.ZERO
var touch_start_time: float = 0.0
const SWIPE_THRESHOLD := 18.0

# ---------- Node refs (built procedurally) ----------
var world_env: WorldEnvironment
var canvas_layer: CanvasLayer
var head_light: PointLight2D
var bg_node: Node2D
var board_node: Node2D
var fx_node: Node2D
var ui_root: Control
# HUD
var score_label: Label
var best_label: Label
var coins_label: Label
var combo_label: Label
var toast_label: Label
var time_label: Label
var time_value_label: Label
var boss_label: Label
# Overlays
var menu_panel: Control
var pause_panel: Control
var over_panel: Control
var shop_panel: Control
var settings_panel: Control
var ach_panel: Control
# D-pad
var dpad: Control

# ---------- Build the entire scene tree on ready ----------
func _ready() -> void:
    rng.randomize()
    _build_world_env()
    _build_canvas_layer()
    _build_world()
    _build_ui()
    _show_menu()
    AudioManager.start_music("menu")
    GameSignals.coins_changed.connect(_on_coins_changed)

func _build_world_env() -> void:
    world_env = WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color8(5, 7, 11)
    env.glow_enabled = true
    env.glow_intensity = 0.6
    env.glow_strength = 1.0
    env.glow_bloom = 0.25
    env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
    env.glow_hdr_threshold = 0.9
    env.adjustment_enabled = true
    env.adjustment_brightness = 1.05
    env.adjustment_contrast = 1.08
    env.adjustment_saturation = 1.15
    world_env.environment = env
    add_child(world_env)

func _build_canvas_layer() -> void:
    canvas_layer = CanvasLayer.new()
    add_child(canvas_layer)

func _build_world() -> void:
    bg_node = Node2D.new(); bg_node.name = "BG"; bg_node.z_index = -10
    board_node = Node2D.new(); board_node.name = "Board"; board_node.z_index = 0
    fx_node = Node2D.new(); fx_node.name = "FX"; fx_node.z_index = 5
    add_child(bg_node); add_child(board_node); add_child(fx_node)
    head_light = PointLight2D.new()
    head_light.texture = _make_light_texture()
    head_light.energy = 1.6
    head_light.texture_scale = 4.0
    head_light.shadow_enabled = false
    head_light.color = Color8(94, 234, 212)
    head_light.z_index = 4
    add_child(head_light)

func _make_light_texture() -> Texture2D:
    var size := 256
    var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
    var cx: float = size * 0.5
    var cy: float = size * 0.5
    for y in range(size):
        for x in range(size):
            var d: float = Vector2(x - cx, y - cy).length() / cx
            var a: float = clampf(1.0 - d, 0.0, 1.0)
            a = a * a
            img.set_pixel(x, y, Color(1, 1, 1, a))
    return ImageTexture.create_from_image(img)

# =============================================================
# UI BUILDING
# =============================================================
func _build_ui() -> void:
    ui_root = Control.new()
    ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
    ui_root.mouse_filter = Control.MOUSE_FILTER_PASS
    canvas_layer.add_child(ui_root)
    _build_hud()
    _build_menu()
    _build_pause()
    _build_over()
    _build_shop()
    _build_settings()
    _build_ach()
    _build_dpad()

func _build_hud() -> void:
    var top_bar := HBoxContainer.new()
    top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
    top_bar.position = Vector2(0, 0)
    top_bar.custom_minimum_size = Vector2(0, 70)
    top_bar.add_theme_constant_override("separation", 6)
    top_bar.offset_left = 10
    top_bar.offset_right = -10
    top_bar.offset_top = 10
    ui_root.add_child(top_bar)
    score_label = _make_hud_box("Score", "0"); top_bar.add_child(score_label.get_parent())
    best_label = _make_hud_box("Best", "0"); top_bar.add_child(best_label.get_parent())
    var spacer := Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top_bar.add_child(spacer)
    coins_label = _make_hud_box("Coins", str(SaveData.get_coins())); top_bar.add_child(coins_label.get_parent())
    var tparent := _make_hud_box_container("Time", "--")
    time_label = tparent[1]
    time_value_label = tparent[2]
    tparent[0].visible = false
    top_bar.add_child(tparent[0])
    var bparent := _make_hud_box_container("Boss", "--")
    boss_label = bparent[2]
    bparent[0].visible = false
    top_bar.add_child(bparent[0])
    # Combo display
    combo_label = Label.new()
    combo_label.text = ""
    combo_label.add_theme_font_size_override("font_size", 48)
    combo_label.add_theme_color_override("font_color", Color8(253, 224, 71))
    combo_label.position = Vector2(0, 100)
    combo_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
    combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    combo_label.visible = false
    ui_root.add_child(combo_label)
    # Toast
    toast_label = Label.new()
    toast_label.text = ""
    toast_label.add_theme_font_size_override("font_size", 14)
    toast_label.add_theme_color_override("font_color", Color8(230, 237, 243))
    toast_label.position = Vector2(0, 80)
    toast_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_label.modulate.a = 0.0
    ui_root.add_child(toast_label)

func _make_hud_box(small: String, big: String) -> Label:
    var box := Panel.new()
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.05, 0.08, 0.12, 0.85)
    sb.border_color = Color8(29, 39, 51)
    sb.set_border_width_all(1)
    sb.set_corner_radius_all(10)
    sb.content_margin_left = 8; sb.content_margin_right = 8
    sb.content_margin_top = 4; sb.content_margin_bottom = 4
    box.add_theme_stylebox_override("panel", sb)
    box.custom_minimum_size = Vector2(60, 50)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 2)
    box.add_child(v)
    var sLabel := Label.new()
    sLabel.text = small.to_upper()
    sLabel.add_theme_font_size_override("font_size", 10)
    sLabel.add_theme_color_override("font_color", Color8(125, 138, 153))
    sLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    v.add_child(sLabel)
    var bLabel := Label.new()
    bLabel.text = big
    bLabel.add_theme_font_size_override("font_size", 16)
    bLabel.add_theme_color_override("font_color", Color8(230, 237, 243))
    bLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    v.add_child(bLabel)
    return bLabel  # Caller can append .get_parent().get_parent() to get the box

func _make_hud_box_container(small: String, big: String) -> Array:
    var box := Panel.new()
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.05, 0.08, 0.12, 0.85)
    sb.border_color = Color8(29, 39, 51)
    sb.set_border_width_all(1)
    sb.set_corner_radius_all(10)
    sb.content_margin_left = 8; sb.content_margin_right = 8
    sb.content_margin_top = 4; sb.content_margin_bottom = 4
    box.add_theme_stylebox_override("panel", sb)
    box.custom_minimum_size = Vector2(60, 50)
    var v := VBoxContainer.new(); box.add_child(v)
    var sLabel := Label.new(); sLabel.text = small.to_upper(); sLabel.add_theme_font_size_override("font_size", 10); sLabel.add_theme_color_override("font_color", Color8(125, 138, 153)); sLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    v.add_child(sLabel)
    var bLabel := Label.new(); bLabel.text = big; bLabel.add_theme_font_size_override("font_size", 16); bLabel.add_theme_color_override("font_color", Color8(230, 237, 243)); bLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    v.add_child(bLabel)
    return [box, sLabel, bLabel]

func _make_overlay(title: String) -> Panel:
    var p := Panel.new()
    p.set_anchors_preset(Control.PRESET_FULL_RECT)
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.02, 0.03, 0.05, 0.95)
    p.add_theme_stylebox_override("panel", sb)
    p.visible = false
    var v := VBoxContainer.new()
    v.set_anchors_preset(Control.PRESET_CENTER)
    v.alignment = BoxContainer.ALIGNMENT_CENTER
    v.add_theme_constant_override("separation", 14)
    v.custom_minimum_size = Vector2(360, 400)
    p.add_child(v)
    var t := Label.new()
    t.text = title
    t.add_theme_font_size_override("font_size", 44)
    t.add_theme_color_override("font_color", Color8(94, 234, 212))
    t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    v.add_child(t)
    p.set_meta("body", v)
    ui_root.add_child(p)
    return p

func _make_button(text: String, primary := false) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(220, 44)
    var sb := StyleBoxFlat.new()
    if primary:
        sb.bg_color = Color8(94, 234, 212)
        b.add_theme_color_override("font_color", Color(0.02, 0.03, 0.05))
    else:
        sb.bg_color = Color(0.07, 0.10, 0.14)
        b.add_theme_color_override("font_color", Color8(230, 237, 243))
    sb.set_corner_radius_all(10)
    sb.content_margin_left = 14
    sb.content_margin_right = 14
    sb.content_margin_top = 8
    sb.content_margin_bottom = 8
    b.add_theme_stylebox_override("normal", sb)
    var sb_hover := sb.duplicate() as StyleBoxFlat
    sb_hover.bg_color = sb.bg_color.lightened(0.06)
    b.add_theme_stylebox_override("hover", sb_hover)
    var sb_pressed := sb.duplicate() as StyleBoxFlat
    sb_pressed.bg_color = sb.bg_color.darkened(0.1)
    b.add_theme_stylebox_override("pressed", sb_pressed)
    return b

func _build_menu() -> void:
    menu_panel = _make_overlay("SNAKE AETHER")
    var body: VBoxContainer = menu_panel.get_meta("body")
    var sub := Label.new()
    sub.text = "Eight modes · Twelve power-ups · Native Godot"
    sub.add_theme_font_size_override("font_size", 13)
    sub.add_theme_color_override("font_color", Color8(125, 138, 153))
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    body.add_child(sub)
    # Mode grid
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 8)
    grid.add_theme_constant_override("v_separation", 8)
    body.add_child(grid)
    for key in MODES.keys():
        var m: Dictionary = MODES[key]
        var btn := Button.new()
        btn.text = m.name + "\n" + m.short
        btn.custom_minimum_size = Vector2(170, 64)
        btn.add_theme_font_size_override("font_size", 13)
        var sb := StyleBoxFlat.new()
        sb.bg_color = Color(0.06, 0.09, 0.14)
        sb.border_color = PALETTES.get(m.palette, PALETTES.cyan).primary
        sb.border_color.a = 0.5
        sb.set_border_width_all(2)
        sb.set_corner_radius_all(12)
        btn.add_theme_stylebox_override("normal", sb)
        btn.pressed.connect(_select_mode.bind(key))
        grid.add_child(btn)
    # Difficulty
    var diff_h := HBoxContainer.new()
    body.add_child(diff_h)
    var diff_names := ["Chill", "Normal", "Hard", "Insane"]
    for i in range(4):
        var b := Button.new()
        b.text = diff_names[i]
        b.toggle_mode = true
        b.custom_minimum_size = Vector2(80, 32)
        b.pressed.connect(_select_diff.bind(i))
        if i == diff: b.button_pressed = true
        diff_h.add_child(b)
    # Play
    var play_btn := _make_button("Play", true)
    body.add_child(play_btn)
    play_btn.pressed.connect(_start_game)
    # Secondary row
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    body.add_child(row)
    var shop_b := _make_button("Shop"); shop_b.custom_minimum_size = Vector2(100, 36); shop_b.pressed.connect(func(): _open_panel(shop_panel))
    var ach_b := _make_button("Trophies"); ach_b.custom_minimum_size = Vector2(100, 36); ach_b.pressed.connect(func(): _open_panel(ach_panel))
    var set_b := _make_button("Settings"); set_b.custom_minimum_size = Vector2(100, 36); set_b.pressed.connect(func(): _open_panel(settings_panel))
    row.add_child(shop_b); row.add_child(ach_b); row.add_child(set_b)

func _build_pause() -> void:
    pause_panel = _make_overlay("Paused")
    var body: VBoxContainer = pause_panel.get_meta("body")
    var resume := _make_button("Resume", true); body.add_child(resume); resume.pressed.connect(_toggle_pause)
    var restart := _make_button("Restart"); body.add_child(restart); restart.pressed.connect(_start_game)
    var quit := _make_button("Quit"); body.add_child(quit); quit.pressed.connect(_back_to_menu)

func _build_over() -> void:
    over_panel = _make_overlay("Game Over")
    var body: VBoxContainer = over_panel.get_meta("body")
    over_panel.set_meta("body", body)
    var info := Label.new()
    info.add_theme_font_size_override("font_size", 13)
    info.add_theme_color_override("font_color", Color8(125, 138, 153))
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.name = "InfoLabel"
    body.add_child(info)
    var again := _make_button("Play Again", true); body.add_child(again); again.pressed.connect(_start_game)
    var menu_b := _make_button("Menu"); body.add_child(menu_b); menu_b.pressed.connect(_back_to_menu)

func _build_shop() -> void:
    shop_panel = _make_overlay("Shop")
    var body: VBoxContainer = shop_panel.get_meta("body")
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(340, 340)
    body.add_child(scroll)
    var grid := GridContainer.new()
    grid.columns = 3
    grid.add_theme_constant_override("h_separation", 8)
    grid.add_theme_constant_override("v_separation", 8)
    scroll.add_child(grid)
    for sk in SKINS:
        var card := Button.new()
        card.custom_minimum_size = Vector2(100, 80)
        var owned: bool = SaveData.is_skin_owned(sk.id)
        var label_text: String = str(sk.name) + "\n"
        if owned:
            label_text += "Equip"
        elif sk.premium:
            label_text += "★ Premium"
        else:
            label_text += str(sk.price) + "¢"
        card.text = label_text
        var sb := StyleBoxFlat.new()
        sb.bg_color = Color.html(str(sk.body)).darkened(0.5)
        sb.set_corner_radius_all(10)
        card.add_theme_stylebox_override("normal", sb)
        var sk_copy: Dictionary = sk
        card.pressed.connect(func(): _on_skin_tap(sk_copy))
        grid.add_child(card)
    var back := _make_button("Back"); body.add_child(back); back.pressed.connect(_close_panel)

func _build_settings() -> void:
    settings_panel = _make_overlay("Settings")
    var body: VBoxContainer = settings_panel.get_meta("body")
    var sfx_b := _make_button("Sound: " + ("On" if SaveData.get_value("settings", "sfx", true) else "Off"))
    sfx_b.pressed.connect(_toggle_setting.bind(sfx_b, "sfx", "Sound"))
    body.add_child(sfx_b)
    var mus_b := _make_button("Music: " + ("On" if SaveData.get_value("settings", "music", true) else "Off"))
    mus_b.pressed.connect(_toggle_music.bind(mus_b))
    body.add_child(mus_b)
    var hap_b := _make_button("Haptics: " + ("On" if SaveData.get_value("settings", "haptics", true) else "Off"))
    hap_b.pressed.connect(_toggle_haptics.bind(hap_b))
    body.add_child(hap_b)
    var pad_b := _make_button("D-pad: " + ("On" if SaveData.get_value("settings", "show_dpad", true) else "Off"))
    pad_b.pressed.connect(_toggle_dpad.bind(pad_b))
    body.add_child(pad_b)
    var back := _make_button("Back"); body.add_child(back); back.pressed.connect(_close_panel)

func _toggle_setting(btn: Button, key: String, label: String) -> void:
    var v: bool = not bool(SaveData.get_value("settings", key, true))
    SaveData.set_value("settings", key, v)
    btn.text = label + ": " + ("On" if v else "Off")

func _toggle_music(btn: Button) -> void:
    var v: bool = not bool(SaveData.get_value("settings", "music", true))
    SaveData.set_value("settings", "music", v)
    if v:
        AudioManager.start_music("menu")
    else:
        AudioManager.stop_music()
    btn.text = "Music: " + ("On" if v else "Off")

func _toggle_haptics(btn: Button) -> void:
    var v: bool = not bool(SaveData.get_value("settings", "haptics", true))
    SaveData.set_value("settings", "haptics", v)
    btn.text = "Haptics: " + ("On" if v else "Off")
    AudioManager.vibrate(20)

func _toggle_dpad(btn: Button) -> void:
    var v: bool = not bool(SaveData.get_value("settings", "show_dpad", true))
    SaveData.set_value("settings", "show_dpad", v)
    if dpad:
        dpad.visible = v
    btn.text = "D-pad: " + ("On" if v else "Off")

func _build_ach() -> void:
    ach_panel = _make_overlay("Trophies")
    var body: VBoxContainer = ach_panel.get_meta("body")
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(340, 340)
    body.add_child(scroll)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 6)
    scroll.add_child(v)
    var unlocked = SaveData.get_achievements()
    for a in ACHIEVEMENTS:
        var has = a.id in unlocked
        var l := Label.new()
        l.text = ("★ " if has else "☆ ") + a.name + " — " + a.desc
        l.add_theme_font_size_override("font_size", 12)
        l.add_theme_color_override("font_color", Color8(253, 224, 71) if has else Color8(125, 138, 153))
        v.add_child(l)
    var back := _make_button("Back"); body.add_child(back); back.pressed.connect(_close_panel)

func _build_dpad() -> void:
    dpad = Control.new()
    dpad.custom_minimum_size = Vector2(220, 220)
    dpad.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    dpad.offset_left = -240
    dpad.offset_top = -240
    dpad.offset_right = -20
    dpad.offset_bottom = -20
    dpad.visible = SaveData.get_value("settings", "show_dpad", true)
    canvas_layer.add_child(dpad)
    var add = func(dx: int, dy: int, label: String, pos: Vector2):
        var b := Button.new()
        b.text = label
        b.custom_minimum_size = Vector2(64, 64)
        b.position = pos
        var sb := StyleBoxFlat.new()
        sb.bg_color = Color(0.05, 0.08, 0.12, 0.85)
        sb.border_color = Color8(36, 48, 67)
        sb.set_border_width_all(1)
        sb.set_corner_radius_all(14)
        b.add_theme_stylebox_override("normal", sb)
        b.add_theme_font_size_override("font_size", 22)
        b.pressed.connect(func(): _try_turn(Vector2i(dx, dy)))
        dpad.add_child(b)
    add.call(0, -1, "▲", Vector2(72, 0))
    add.call(-1, 0, "◀", Vector2(0, 72))
    add.call(1, 0, "▶", Vector2(144, 72))
    add.call(0, 1, "▼", Vector2(72, 144))

# =============================================================
# MENU NAVIGATION
# =============================================================
func _show_menu() -> void:
    state = GameState.MENU
    menu_panel.visible = true
    pause_panel.visible = false
    over_panel.visible = false
    shop_panel.visible = false
    settings_panel.visible = false
    ach_panel.visible = false
    AudioManager.start_music("menu")

func _open_panel(p: Panel) -> void:
    menu_panel.visible = false
    p.visible = true
    AudioManager.sfx_click()

func _close_panel() -> void:
    shop_panel.visible = false
    settings_panel.visible = false
    ach_panel.visible = false
    menu_panel.visible = true
    AudioManager.sfx_click()

func _back_to_menu() -> void:
    state = GameState.MENU
    over_panel.visible = false
    pause_panel.visible = false
    menu_panel.visible = true
    queue_redraw()
    AudioManager.start_music("menu")

func _select_mode(key: String) -> void:
    mode = key
    SaveData.set_value("settings", "mode", key)
    AudioManager.sfx_click()

func _select_diff(d: int) -> void:
    diff = d
    SaveData.set_value("settings", "diff", d)
    AudioManager.sfx_click()

# =============================================================
# GAME LIFECYCLE
# =============================================================
func _layout() -> void:
    var vp := get_viewport_rect().size
    grid_w = min(vp.x - 20, vp.y - 240)
    grid_h = grid_w
    cell_size = grid_w / float(COLS)
    grid_h = cell_size * float(ROWS)
    grid_x = (vp.x - grid_w) * 0.5
    grid_y = 90.0

func _start_game() -> void:
    var d: Dictionary = DIFFS[diff]
    step_base = d.step_ms
    accel = d.accel
    score = 0
    level = 1
    next_level_at = 5
    power_until = 0
    power_kind = 0
    shield_stacks = 0
    double_stacks = 0
    particles.clear()
    floats.clear()
    trail.clear()
    shake_amount = 0
    combo = 0
    combo_timer_ms = 0
    rewind_left = REWIND_START
    revive_used = false
    invul_until = 0
    coins_run = 0
    history.clear()
    foods.clear()
    food_id = 1
    boss_id = 0
    next_boss_at_ms = Time.get_ticks_msec() + BOSS_INTERVAL_MS
    slowmo_until_ms = 0
    slowmo_factor = 1.0
    hitstop_until_ms = 0
    zoom_punch = 1.0
    run_stats = {"eats": 0, "boss": 0, "rivals": 0, "max_combo": 0}
    rival = {}
    rival_score = 0
    run_start_ms = Time.get_ticks_msec()
    next_wave_at_ms = run_start_ms + SURVIVAL_WAVE_MS
    rival_spawned_at_ms = 0
    arcade_progress = {"eats": 0, "boss": 0, "rival": 0}
    if mode == "time": time_remaining_ms = TIME_LIMIT_MS
    elif mode == "blitz": time_remaining_ms = BLITZ_LIMIT_MS
    else: time_remaining_ms = 0
    occupy = PackedByteArray()
    occupy.resize(COLS * ROWS)
    obstacles = PackedByteArray()
    obstacles.resize(COLS * ROWS)
    if mode == "daily":
        var dt := Time.get_datetime_dict_from_system()
        seed_value = dt.year * 10000 + dt.month * 100 + dt.day
        rng.seed = seed_value
    _build_obstacles()
    _reset_snake()
    _spawn_food()
    _spawn_food()
    _set_step_for_level()
    _layout()
    best = SaveData.get_best(mode)
    best_label.text = str(best)
    score_label.text = "0"
    coins_label.text = str(SaveData.get_coins())
    state = GameState.PLAY
    menu_panel.visible = false
    over_panel.visible = false
    pause_panel.visible = false
    AudioManager.start_music("boss" if mode == "survival" else ("blitz" if mode == "blitz" else ("zen" if mode == "zen" else "play")))
    AudioManager.vibrate(15)
    _toast(MODES[mode].name + "!")
    queue_redraw()

func _build_obstacles() -> void:
    for i in range(COLS * ROWS):
        obstacles[i] = 0
    if mode == "classic" or mode == "zen" or mode == "time" or mode == "blitz": return
    if mode == "survival":
        # 4 corner clusters
        for p in [[1, 1], [1, 2], [2, 1], [COLS - 2, 1], [COLS - 3, 1], [COLS - 2, 2],
                  [1, ROWS - 2], [1, ROWS - 3], [2, ROWS - 2],
                  [COLS - 2, ROWS - 2], [COLS - 3, ROWS - 2], [COLS - 2, ROWS - 3]]:
            obstacles[p[1] * COLS + p[0]] = 1
    elif mode == "arcade":
        # Different layout per level
        var lvl_obs := arcade_level % 5
        if lvl_obs == 0:
            for y in range(6, 18): obstacles[y * COLS + 11] = 1; obstacles[y * COLS + 12] = 1
        elif lvl_obs == 1:
            for x in range(6, 18): obstacles[12 * COLS + x] = 1
        elif lvl_obs == 2:
            for i in range(8): obstacles[(4 + i * 2) * COLS + (4 + i * 2)] = 1
        elif lvl_obs == 3:
            for x in range(2, 22): obstacles[5 * COLS + x] = 1; obstacles[18 * COLS + x] = 1
    elif mode == "gauntlet":
        var lvl_obs2: int = min(4, (gauntlet_level - 1) / 2)
        if lvl_obs2 >= 1:
            for y in range(6, 18): obstacles[y * COLS + 11] = 1
        if lvl_obs2 >= 2:
            for x in range(6, 18): obstacles[12 * COLS + x] = 1
        if lvl_obs2 >= 3:
            for i in range(8): obstacles[(4 + i * 2) * COLS + (4 + i * 2)] = 1
    elif mode == "daily":
        var k := rng.randi() % 4
        if k == 0:
            for y in range(6, 18): obstacles[y * COLS + 11] = 1
        elif k == 1:
            for x in range(6, 18): obstacles[12 * COLS + x] = 1
        elif k == 2:
            for p in [[3, 3], [3, 20], [20, 3], [20, 20]]:
                for dy in range(0, 3):
                    for dx in range(0, 3):
                        obstacles[(p[1] + dy) * COLS + (p[0] + dx)] = 1
        else:
            for i in range(8): obstacles[(4 + i * 2) * COLS + (4 + i * 2)] = 1

func _reset_snake() -> void:
    snake.clear()
    path.clear()
    for i in range(COLS * ROWS): occupy[i] = 0
    var cx := COLS / 2
    var cy := ROWS / 2
    for i in range(4):
        var s := Vector2i(cx - i, cy)
        snake.append(s)
        occupy[s.y * COLS + s.x] = 1
        var px: float = 0.0
        if path.size() > 0:
            var lp = path[path.size() - 1]
            px = lp.len + (Vector2(s.x, s.y) - Vector2(lp.pos.x, lp.pos.y)).length()
        path.append({"pos": s, "len": px})
    dir = Vector2i.RIGHT
    next_dir = Vector2i.RIGHT

func _set_step_for_level() -> void:
    var t: float = clamp(float(level - 1) / 14.0, 0.0, 1.0)
    step_ms = max(28.0, step_base * (1.0 - accel * t))
    if mode == "blitz": step_ms = max(40.0, step_ms * 0.85)

func _spawn_food(forced_kind: int = -1) -> void:
    if foods.size() >= 2 + (1 if mode == "time" else 0):
        return
    var free := []
    for y in range(ROWS):
        for x in range(COLS):
            if occupy[y * COLS + x] == 0 and obstacles[y * COLS + x] == 0:
                var taken := false
                for f in foods:
                    if f.pos.x == x and f.pos.y == y:
                        taken = true; break
                if not taken: free.append(Vector2i(x, y))
    if free.is_empty(): return
    var p: Vector2i = free[rng.randi() % free.size()]
    var kind: int = POWER.NONE
    if forced_kind >= 0:
        kind = forced_kind
    else:
        var r := rng.randf()
        if r < 0.18: kind = POWER.COIN
        elif r < 0.40:
            var pool := [POWER.BONUS, POWER.SLOW, POWER.SHRINK, POWER.GHOST, POWER.MAGNET, POWER.SHIELD, POWER.MULTI, POWER.DOUBLE]
            kind = pool[rng.randi() % pool.size()]
    foods.append({"id": food_id, "pos": p, "kind": kind, "spawn_at": Time.get_ticks_msec()})
    food_id += 1

func _try_turn(d: Vector2i) -> void:
    if snake.size() > 1 and d == -dir: return
    next_dir = d
    AudioManager.vibrate(8)

func _step() -> void:
    _snapshot()
    dir = next_dir
    var head: Vector2i = snake[0]
    var n: Vector2i = head + dir
    var ghost: bool = (power_kind == POWER.GHOST and Time.get_ticks_msec() < power_until)
    var invul: bool = Time.get_ticks_msec() < invul_until
    var wrap_mode := mode in ["classic", "zen", "time", "blitz"]
    if n.x < 0 or n.x >= COLS or n.y < 0 or n.y >= ROWS:
        if not wrap_mode and not ghost and not invul:
            _game_over("Hit the wall"); return
        n.x = (n.x + COLS) % COLS
        n.y = (n.y + ROWS) % ROWS
    if obstacles[n.y * COLS + n.x] == 1 and not ghost and not invul:
        _game_over("Hit an obstacle"); return
    var tail: Vector2i = snake[snake.size() - 1]
    var will_collide := occupy[n.y * COLS + n.x] == 1 and not (n.x == tail.x and n.y == tail.y)
    if will_collide and not ghost and not invul:
        _game_over("Bit yourself"); return
    # Eat?
    var grew := false
    var hit_food = null
    for f in foods:
        if f.pos == n: hit_food = f; break
    if hit_food != null:
        grew = true
        _on_eat(hit_food)
        foods.erase(hit_food)
        if hit_food.kind == POWER.BOSS:
            boss_id = 0
            next_boss_at_ms = Time.get_ticks_msec() + BOSS_INTERVAL_MS
        _spawn_food(); _spawn_food()
    snake.insert(0, n)
    occupy[n.y * COLS + n.x] = 1
    if not grew:
        var t: Vector2i = snake.pop_back()
        occupy[t.y * COLS + t.x] = 0
    # path
    var plen := 0.0
    if path.size() > 0:
        var last_p = path[path.size() - 1]
        plen = last_p.len + (Vector2(n.x, n.y) - Vector2(last_p.pos.x, last_p.pos.y)).length()
    path.append({"pos": n, "len": plen})
    while path.size() > 2 and path[1].len < path[path.size() - 1].len - float(snake.size() + 3):
        path.remove_at(0)
    # Trail
    trail.push_front({"pos": n, "t": Time.get_ticks_msec()})
    if trail.size() > 24: trail.pop_back()
    # Power expiry
    if power_kind != POWER.NONE and Time.get_ticks_msec() >= power_until:
        power_kind = POWER.NONE
        _set_step_for_level()
    # Combo decay
    if combo_timer_ms > 0:
        combo_timer_ms -= step_ms
        if combo_timer_ms <= 0:
            if combo > 1: _toast("Combo broken")
            combo = 0
            combo_label.visible = false

func _snapshot() -> void:
    var snap := {
        "snake": snake.duplicate(),
        "path": path.duplicate(),
        "foods": foods.duplicate(),
        "food_id": food_id,
        "boss_id": boss_id,
        "score": score,
        "level": level,
        "next_level_at": next_level_at,
        "power_until": power_until,
        "power_kind": power_kind,
        "coins_run": coins_run,
        "combo": combo,
        "combo_timer_ms": combo_timer_ms,
        "dir": dir,
        "step_ms": step_ms,
        "next_boss_at_ms": next_boss_at_ms,
        "shield_stacks": shield_stacks,
        "double_stacks": double_stacks,
        "time_remaining_ms": time_remaining_ms,
        "arcade_progress": arcade_progress.duplicate(),
    }
    history.append(snap)
    if history.size() > REWIND_BUFFER: history.pop_front()

func _do_rewind() -> void:
    if state != GameState.PLAY or rewind_left <= 0 or history.size() < 2: return
    var n: int = min(REWIND_STEPS, history.size() - 1)
    for i in range(n): history.pop_back()
    var snap = history[history.size() - 1]
    snake = snap.snake.duplicate()
    path = snap.path.duplicate()
    for i in range(COLS * ROWS): occupy[i] = 0
    for s in snake: occupy[s.y * COLS + s.x] = 1
    foods = snap.foods.duplicate()
    food_id = snap.food_id
    boss_id = snap.boss_id
    score = snap.score
    level = snap.level
    next_level_at = snap.next_level_at
    power_until = snap.power_until
    power_kind = snap.power_kind
    coins_run = snap.coins_run
    combo = snap.combo
    combo_timer_ms = snap.combo_timer_ms
    dir = snap.dir
    next_dir = snap.dir
    step_ms = snap.step_ms
    next_boss_at_ms = snap.next_boss_at_ms
    shield_stacks = snap.shield_stacks
    double_stacks = snap.double_stacks
    time_remaining_ms = snap.time_remaining_ms
    arcade_progress = snap.arcade_progress.duplicate()
    rewind_left -= 1
    invul_until = Time.get_ticks_msec() + 600
    AudioManager.sfx_rewind()
    AudioManager.vibrate(15)
    SaveData.add_stat("lifetime_rewinds", 1)
    _spawn_particles(snake[0], Color8(96, 165, 250), 24)
    _toast("Rewind!")
    _check_achievements()

func _on_eat(f) -> void:
    combo = min(COMBO_MAX, combo + 1)
    combo_timer_ms = COMBO_WINDOW_MS
    run_stats.eats += 1
    run_stats.max_combo = max(run_stats.max_combo, combo)
    arcade_progress.eats += 1
    if combo > 1:
        combo_label.text = "x" + str(combo)
        combo_label.visible = true
        AudioManager.sfx_combo(combo)
    var base_points := 1
    var coin_reward := 0
    match f.kind:
        POWER.BONUS:  base_points = 5
        POWER.COIN:   base_points = 1; coin_reward = 1
        POWER.SLOW:   base_points = 2
        POWER.SHRINK: base_points = 2
        POWER.GHOST:  base_points = 2
        POWER.MAGNET: base_points = 2
        POWER.SHIELD: base_points = 2
        POWER.MULTI:  base_points = 3
        POWER.DOUBLE: base_points = 2
        POWER.BOSS:
            base_points = BOSS_POINTS
            coin_reward = BOSS_COINS
            run_stats.boss += 1
            arcade_progress.boss += 1
    var doubled := 1
    if double_stacks > 0:
        doubled = 2
        double_stacks -= 1
    var points: int = base_points * combo * doubled
    score += points
    coins_run += coin_reward
    score_label.text = str(score)
    coins_label.text = str(SaveData.get_coins() + coins_run)
    hitstop_until_ms = Time.get_ticks_msec() + (80 if f.kind != POWER.NONE else 40)
    zoom_punch = 1.08 if f.kind != POWER.NONE else 1.04
    if mode == "time":
        time_remaining_ms = min(120000.0, time_remaining_ms + TIME_EXTEND_MS)
    elif mode == "blitz":
        time_remaining_ms = min(60000.0, time_remaining_ms + BLITZ_EXTEND_MS)
    match f.kind:
        POWER.NONE: AudioManager.sfx_eat()
        POWER.COIN: AudioManager.sfx_coin()
        POWER.BOSS: AudioManager.sfx_boss(); _toast("BOSS!")
        POWER.SHIELD:
            AudioManager.sfx_shield()
            shield_stacks += 1
            _toast("Shield!")
        POWER.MULTI:
            AudioManager.sfx_power()
            for i in range(2): _spawn_food()
            _toast("Multi!")
        POWER.DOUBLE:
            AudioManager.sfx_power()
            double_stacks += 5
            _toast("x2 next 5")
        _:
            AudioManager.sfx_power()
            power_kind = f.kind
            power_until = Time.get_ticks_msec() + POWER_DURATION_MS
            if f.kind == POWER.SLOW:
                step_ms = min(220.0, step_ms * 1.6)
            elif f.kind == POWER.SHRINK:
                for i in range(min(4, snake.size() - 3)):
                    var t: Vector2i = snake.pop_back()
                    occupy[t.y * COLS + t.x] = 0
                _set_step_for_level()
            else:
                _set_step_for_level()
            _toast(_power_label(f.kind))
    _spawn_particles(f.pos, _food_color(f.kind), 32 if f.kind != POWER.NONE else 16)
    _spawn_float("+" + str(points), f.pos, Color8(253, 230, 138) if f.kind != POWER.NONE else Color8(167, 243, 208))
    AudioManager.vibrate(10)
    if score >= next_level_at:
        level += 1
        next_level_at = score + 5 + level * 3
        _set_step_for_level()
        AudioManager.sfx_level()
        _toast("Level " + str(level))

func _power_label(k: int) -> String:
    match k:
        POWER.BONUS:  return "+5 Bonus"
        POWER.SLOW:   return "Slow-Mo"
        POWER.SHRINK: return "Shrink"
        POWER.GHOST:  return "Ghost"
        POWER.MAGNET: return "Magnet"
    return ""

func _food_color(k: int) -> Color:
    match k:
        POWER.BONUS:  return Color8(253, 224, 71)
        POWER.SLOW:   return Color8(96, 165, 250)
        POWER.SHRINK: return Color8(244, 114, 182)
        POWER.GHOST:  return Color8(167, 139, 250)
        POWER.COIN:   return Color8(253, 224, 71)
        POWER.BOSS:   return Color8(239, 68, 68)
        POWER.MAGNET: return Color8(192, 132, 252)
        POWER.SHIELD: return Color8(34, 211, 238)
        POWER.MULTI:  return Color8(251, 146, 60)
        POWER.DOUBLE: return Color8(250, 204, 21)
    return Color8(251, 113, 133)

func _game_over(reason: String) -> void:
    if mode == "zen": return
    if shield_stacks > 0:
        shield_stacks -= 1
        invul_until = Time.get_ticks_msec() + 1500
        AudioManager.sfx_shield()
        AudioManager.vibrate(30)
        _spawn_particles(snake[0], Color8(34, 211, 238), 26)
        _toast("Shield!")
        return
    state = GameState.GAME_OVER
    AudioManager.sfx_hit()
    AudioManager.vibrate(60)
    shake_amount = 22.0
    slowmo_until_ms = Time.get_ticks_msec() + 1200
    slowmo_factor = 0.18
    SaveData.add_coins(coins_run)
    SaveData.set_best(mode, score)
    SaveData.add_stat("lifetime_eats", run_stats.eats)
    SaveData.add_stat("lifetime_bosses", run_stats.boss)
    SaveData.add_stat("lifetime_rivals", run_stats.rivals)
    SaveData.bump_stat("best_combo", run_stats.max_combo)
    SaveData.bump_stat("best_run", score)
    SaveData.bump_stat("best_len", snake.size())
    AudioManager.stop_music()
    _check_achievements()
    _show_game_over_panel(reason)

func _show_game_over_panel(reason: String) -> void:
    var body: VBoxContainer = over_panel.get_meta("body")
    var info = body.get_node("InfoLabel")
    info.text = reason + "\nScore " + str(score) + " · Length " + str(snake.size()) + " · Best combo x" + str(run_stats.max_combo) + "\nCoins +" + str(coins_run)
    over_panel.visible = true

func _check_achievements() -> void:
    for a in ACHIEVEMENTS:
        var parts: Array = a.check.split(":")
        var stat_key: String = parts[0]
        var threshold: int = int(parts[1])
        if SaveData.get_stat(stat_key) >= threshold:
            if SaveData.unlock_achievement(a.id):
                _show_ach_toast(a.name)
                SaveData.add_coins(30)
                AudioManager.sfx_achievement()

func _show_ach_toast(name: String) -> void:
    _toast("★ " + name)

# =============================================================
# PARTICLES + FLOATS
# =============================================================
func _spawn_particles(grid_pos: Vector2i, color: Color, n: int) -> void:
    var cx: float = grid_x + grid_pos.x * cell_size + cell_size * 0.5
    var cy: float = grid_y + grid_pos.y * cell_size + cell_size * 0.5
    for i in range(n):
        if particles.size() >= 260: break
        var a: float = rng.randf() * TAU
        var s: float = 80.0 + rng.randf() * 240.0
        particles.append({
            "x": cx, "y": cy,
            "vx": cos(a) * s, "vy": sin(a) * s,
            "life": 0.5 + rng.randf() * 0.6, "age": 0.0,
            "r": 1.5 + rng.randf() * 2.6, "c": color,
        })

func _spawn_float(text: String, grid_pos: Vector2i, color: Color) -> void:
    floats.append({
        "text": text,
        "x": grid_x + grid_pos.x * cell_size + cell_size * 0.5,
        "y": grid_y + grid_pos.y * cell_size,
        "vy": -60.0, "age": 0.0, "life": 0.95, "c": color,
    })

func _update_effects(dt: float) -> void:
    for i in range(particles.size() - 1, -1, -1):
        var p = particles[i]
        p.age += dt
        if p.age >= p.life:
            particles.remove_at(i); continue
        p.x += p.vx * dt; p.y += p.vy * dt
        p.vx *= 0.94; p.vy *= 0.94
    for i in range(floats.size() - 1, -1, -1):
        var f = floats[i]
        f.age += dt
        if f.age >= f.life:
            floats.remove_at(i); continue
        f.y += f.vy * dt
        f.vy *= 0.94

# =============================================================
# TOAST
# =============================================================
var toast_tween: Tween
func _toast(text: String) -> void:
    toast_label.text = text
    if toast_tween:
        toast_tween.kill()
    toast_label.modulate.a = 1.0
    toast_tween = create_tween()
    toast_tween.tween_interval(0.9)
    toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.3)

# =============================================================
# MAIN LOOP
# =============================================================
var _last_ms: float = 0.0
func _process(delta: float) -> void:
    if state == GameState.PLAY:
        AudioManager._process(delta)
        var raw_dt_ms := delta * 1000.0
        var dt_ms := raw_dt_ms
        if Time.get_ticks_msec() < slowmo_until_ms:
            dt_ms *= slowmo_factor
        if Time.get_ticks_msec() < hitstop_until_ms:
            pass
        else:
            step_acc_ms += dt_ms
            var iters := 0
            while step_acc_ms >= step_ms and iters < 4:
                _step()
                step_acc_ms -= step_ms
                iters += 1
                if state != GameState.PLAY: step_acc_ms = 0; break
        _try_spawn_boss()
        _despawn_boss_if_expired()
        if mode == "time" or mode == "blitz":
            time_remaining_ms -= dt_ms
            if time_remaining_ms <= 0:
                time_remaining_ms = 0
                _game_over("Time up")
        if mode == "survival":
            if Time.get_ticks_msec() >= next_wave_at_ms:
                _survival_wave()
                next_wave_at_ms = Time.get_ticks_msec() + SURVIVAL_WAVE_MS
        # Update HUD timer
        if mode == "time" or mode == "blitz":
            time_label.get_parent().visible = true
            time_label.text = "TIME"
            time_value_label.text = "%.1f" % (time_remaining_ms / 1000.0)
        elif mode == "survival":
            time_label.get_parent().visible = true
            time_label.text = "SURVIVED"
            var sec: int = int((Time.get_ticks_msec() - run_start_ms) / 1000)
            time_value_label.text = "%dm%ds" % [sec / 60, sec % 60] if sec >= 60 else "%ds" % sec
        else:
            time_label.get_parent().visible = false
        # Boss HUD
        if boss_id != 0:
            for f in foods:
                if f.id == boss_id:
                    boss_label.get_parent().visible = true
                    boss_label.text = str(int(ceil((f.spawn_at + BOSS_LIFETIME_MS - Time.get_ticks_msec()) / 1000.0)))
                    break
        else:
            boss_label.get_parent().visible = false
        # Head light follow
        if snake.size() > 0:
            var h: Vector2i = snake[0]
            head_light.position = Vector2(grid_x + h.x * cell_size + cell_size * 0.5,
                                          grid_y + h.y * cell_size + cell_size * 0.5)
    _update_effects(delta)
    if zoom_punch > 1.001: zoom_punch = max(1.0, zoom_punch - delta * 0.5)
    if shake_amount > 0: shake_amount = max(0.0, shake_amount - delta * 40.0)
    queue_redraw()

func _try_spawn_boss() -> void:
    if boss_id != 0: return
    if mode in ["zen", "time", "blitz"]: return
    if Time.get_ticks_msec() < next_boss_at_ms: return
    _spawn_food(POWER.BOSS)
    if foods.size() > 0:
        var last = foods[foods.size() - 1]
        if last.kind == POWER.BOSS:
            boss_id = last.id
            AudioManager.sfx_boss()
            _toast("Boss orb!")

func _despawn_boss_if_expired() -> void:
    if boss_id == 0: return
    var f = null
    for ff in foods:
        if ff.id == boss_id: f = ff; break
    if f == null:
        boss_id = 0; return
    if Time.get_ticks_msec() >= f.spawn_at + BOSS_LIFETIME_MS:
        foods.erase(f)
        boss_id = 0
        next_boss_at_ms = Time.get_ticks_msec() + BOSS_INTERVAL_MS

func _survival_wave() -> void:
    for i in range(8):
        var x := rng.randi() % COLS
        var y := rng.randi() % ROWS
        if occupy[y * COLS + x] == 1: continue
        if obstacles[y * COLS + x] == 1: continue
        var near_snake := false
        for s in snake:
            if abs(s.x - x) + abs(s.y - y) < 3: near_snake = true; break
        if near_snake: continue
        obstacles[y * COLS + x] = 1
    _toast("Wave!")
    AudioManager.vibrate(20)

# =============================================================
# DRAW (custom 2D rendering)
# =============================================================
func _draw() -> void:
    var pal_key: String = MODES[mode].palette if MODES.has(mode) else "cyan"
    var pal = PALETTES[pal_key]
    var shake_x: float = 0.0
    var shake_y: float = 0.0
    if shake_amount > 0:
        shake_x = (rng.randf() * 2.0 - 1.0) * shake_amount
        shake_y = (rng.randf() * 2.0 - 1.0) * shake_amount
    if state == GameState.MENU:
        return
    # Background gradient
    var vp := get_viewport_rect().size
    draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.02, 0.03, 0.05))
    # Paper/grid
    draw_rect(Rect2(grid_x + shake_x - 6, grid_y + shake_y - 6, grid_w + 12, grid_h + 12), Color(0.06, 0.10, 0.14, 0.5), true)
    # Grid lines
    var line_col := Color(0.10, 0.13, 0.21, 0.8)
    for x in range(COLS + 1):
        var px = grid_x + x * cell_size + shake_x
        draw_line(Vector2(px, grid_y + shake_y), Vector2(px, grid_y + grid_h + shake_y), line_col, 1.0)
    for y in range(ROWS + 1):
        var py = grid_y + y * cell_size + shake_y
        draw_line(Vector2(grid_x + shake_x, py), Vector2(grid_x + grid_w + shake_x, py), line_col, 1.0)
    # Obstacles
    for y in range(ROWS):
        for x in range(COLS):
            if obstacles[y * COLS + x] == 1:
                draw_rect(Rect2(grid_x + x * cell_size + 1 + shake_x,
                                grid_y + y * cell_size + 1 + shake_y,
                                cell_size - 2, cell_size - 2),
                          Color8(59, 77, 104), true)
    # Trail (afterimage)
    var skin_for_trail: Dictionary = _get_skin()
    var trail_glow: Color = Color.html(str(skin_for_trail.glow))
    for i in range(trail.size()):
        var t: Dictionary = trail[i]
        var t_time: float = float(t.t)
        var age: float = (Time.get_ticks_msec() - t_time) / 600.0
        if age >= 1.0: continue
        var a: float = (1.0 - age) * 0.18
        var col: Color = trail_glow
        col.a = a
        var p: Vector2i = t.pos
        draw_circle(Vector2(grid_x + p.x * cell_size + cell_size * 0.5 + shake_x,
                            grid_y + p.y * cell_size + cell_size * 0.5 + shake_y),
                    cell_size * 0.4, col)
    # Food
    for f in foods:
        _draw_food(f, shake_x, shake_y)
    # Snake
    _draw_snake(pal, shake_x, shake_y)
    # Particles
    for p in particles:
        var k: float = 1.0 - p.age / p.life
        var c: Color = p.c
        c.a = k
        draw_circle(Vector2(p.x + shake_x, p.y + shake_y), p.r, c)
    # Floats
    var font: Font = ThemeDB.fallback_font
    for f in floats:
        var k2: float = 1.0 - float(f.age) / float(f.life)
        var c2: Color = f.c
        c2.a = k2
        draw_string(font, Vector2(float(f.x) - 16 + shake_x, float(f.y) + shake_y), str(f.text), HORIZONTAL_ALIGNMENT_CENTER, -1, 18, c2)

func _get_skin() -> Dictionary:
    var sid: String = SaveData.get_skin()
    for sk in SKINS:
        if sk.id == sid: return sk
    return SKINS[0]

func _draw_food(f, sx: float, sy: float) -> void:
    var col := _food_color(f.kind)
    var cx: float = grid_x + f.pos.x * cell_size + cell_size * 0.5 + sx
    var cy: float = grid_y + f.pos.y * cell_size + cell_size * 0.5 + sy
    var t: float = (Time.get_ticks_msec() - f.spawn_at) * 0.004
    var bob: float = sin(t * 2.0) * 2.0
    cy += bob
    var size: float = cell_size * 0.36 if f.kind != POWER.BOSS else cell_size * 0.75
    var halo: Color = col
    halo.a = 0.5
    draw_circle(Vector2(cx, cy), size * 1.6, halo)
    halo.a = 0.25
    draw_circle(Vector2(cx, cy), size * 2.2, halo)
    draw_circle(Vector2(cx, cy), size, col)
    # white highlight
    draw_circle(Vector2(cx - size * 0.25, cy - size * 0.32), size * 0.22, Color(1, 1, 1, 0.7))

func _draw_snake(pal, sx: float, sy: float) -> void:
    if snake.size() == 0: return
    var skin: Dictionary = _get_skin()
    var body_col := Color.html(skin.body)
    var head_col := Color.html(skin.head)
    var glow_col := Color.html(skin.glow)
    # Body
    for i in range(snake.size() - 1, 0, -1):
        var s: Vector2i = snake[i]
        var cx: float = grid_x + s.x * cell_size + cell_size * 0.5 + sx
        var cy: float = grid_y + s.y * cell_size + cell_size * 0.5 + sy
        var headness: float = 1.0 - float(i) / float(snake.size())
        var r: float = cell_size * 0.36 + headness * cell_size * 0.04
        var halo: Color = glow_col
        halo.a = 0.35
        draw_circle(Vector2(cx, cy), r * 1.6, halo)
        draw_circle(Vector2(cx, cy), r, body_col)
        draw_circle(Vector2(cx - r * 0.3, cy - r * 0.35), r * 0.18, head_col)
    # Head
    var h: Vector2i = snake[0]
    var hcx: float = grid_x + h.x * cell_size + cell_size * 0.5 + sx
    var hcy: float = grid_y + h.y * cell_size + cell_size * 0.5 + sy
    var hr: float = cell_size * 0.42
    var hhalo := glow_col; hhalo.a = 0.55
    draw_circle(Vector2(hcx, hcy), hr * 1.8, hhalo)
    draw_circle(Vector2(hcx, hcy), hr, head_col)
    draw_circle(Vector2(hcx - hr * 0.3, hcy - hr * 0.35), hr * 0.2, Color.WHITE)
    # Eyes
    var off: float = hr * 0.4
    var ox: float = dir.x * off
    var oy: float = dir.y * off
    var px: float = -dir.y * off * 0.6
    var py: float = dir.x * off * 0.6
    draw_circle(Vector2(hcx + ox + px, hcy + oy + py), hr * 0.15, Color(0.02, 0.03, 0.05))
    draw_circle(Vector2(hcx + ox - px, hcy + oy - py), hr * 0.15, Color(0.02, 0.03, 0.05))

# =============================================================
# INPUT
# =============================================================
func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var t: InputEventScreenTouch = event
        if t.pressed:
            touch_start = t.position
            touch_start_time = Time.get_ticks_msec()
        else:
            if state != GameState.PLAY: return
            var dx: float = t.position.x - touch_start.x
            var dy: float = t.position.y - touch_start.y
            var mag: float = max(abs(dx), abs(dy))
            var dt_ms: float = Time.get_ticks_msec() - touch_start_time
            if mag < SWIPE_THRESHOLD and dt_ms < 250:
                _toggle_pause()
                return
            if abs(dx) > abs(dy):
                _try_turn(Vector2i(1, 0) if dx > 0 else Vector2i(-1, 0))
            else:
                _try_turn(Vector2i(0, 1) if dy > 0 else Vector2i(0, -1))
    elif event is InputEventKey and event.pressed:
        if Input.is_action_just_pressed("ui_up"): _try_turn(Vector2i(0, -1))
        if Input.is_action_just_pressed("ui_down"): _try_turn(Vector2i(0, 1))
        if Input.is_action_just_pressed("ui_left"): _try_turn(Vector2i(-1, 0))
        if Input.is_action_just_pressed("ui_right"): _try_turn(Vector2i(1, 0))
        if Input.is_action_just_pressed("ui_rewind"): _do_rewind()
        if Input.is_action_just_pressed("ui_pause"): _toggle_pause()

func _toggle_pause() -> void:
    if state == GameState.PLAY:
        state = GameState.PAUSE
        pause_panel.visible = true
    elif state == GameState.PAUSE:
        state = GameState.PLAY
        pause_panel.visible = false

func _on_coins_changed(_n: int) -> void:
    coins_label.text = str(SaveData.get_coins() + coins_run)

func _on_skin_tap(sk: Dictionary) -> void:
    if SaveData.is_skin_owned(sk.id):
        SaveData.set_skin(sk.id)
        AudioManager.sfx_click()
        _toast("Equipped " + sk.name)
        return
    if sk.premium:
        _toast("Premium — coming soon")
        return
    if SaveData.get_coins() >= sk.price:
        SaveData.add_coins(-sk.price)
        SaveData.own_skin(sk.id)
        SaveData.set_skin(sk.id)
        AudioManager.sfx_power()
        _toast("Bought " + sk.name)
    else:
        _toast("Not enough coins")

# Handle Android back / app lifecycle
func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_GO_BACK_REQUEST:
        if state == GameState.PLAY:
            _toggle_pause()
        elif state == GameState.MENU:
            get_tree().quit()
