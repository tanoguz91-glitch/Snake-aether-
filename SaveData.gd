# Autoload — persistent save data via ConfigFile
extends Node

const SAVE_PATH := "user://save.cfg"

var cfg := ConfigFile.new()

func _ready() -> void:
    load_data()

func load_data() -> void:
    var err := cfg.load(SAVE_PATH)
    if err != OK:
        # First run — initialize defaults
        cfg.set_value("progress", "coins", 0)
        cfg.set_value("progress", "best_classic", 0)
        cfg.set_value("progress", "best_maze", 0)
        cfg.set_value("progress", "best_arcade", 0)
        cfg.set_value("progress", "best_survival", 0)
        cfg.set_value("progress", "best_time", 0)
        cfg.set_value("progress", "best_blitz", 0)
        cfg.set_value("progress", "best_zen", 0)
        cfg.set_value("progress", "best_daily", 0)
        cfg.set_value("progress", "arcade_max", 1)
        cfg.set_value("settings", "sfx", true)
        cfg.set_value("settings", "music", true)
        cfg.set_value("settings", "haptics", true)
        cfg.set_value("settings", "show_dpad", true)
        cfg.set_value("settings", "show_fps", false)
        cfg.set_value("settings", "render_quality", "high")
        cfg.set_value("settings", "skin", "mint")
        cfg.set_value("settings", "mode", "classic")
        cfg.set_value("settings", "diff", 1)
        cfg.set_value("owned", "skins", ["mint"])
        cfg.set_value("achievements", "unlocked", [])
        cfg.set_value("stats", "lifetime_eats", 0)
        cfg.set_value("stats", "lifetime_bosses", 0)
        cfg.set_value("stats", "lifetime_rivals", 0)
        cfg.set_value("stats", "lifetime_rewinds", 0)
        cfg.set_value("stats", "best_combo", 0)
        cfg.set_value("stats", "best_run", 0)
        cfg.set_value("stats", "best_len", 0)
        save_data()

func save_data() -> void:
    cfg.save(SAVE_PATH)

func get_value(section: String, key: String, default = null):
    return cfg.get_value(section, key, default)

func set_value(section: String, key: String, value) -> void:
    cfg.set_value(section, key, value)
    save_data()

# Convenience getters
func get_coins() -> int: return cfg.get_value("progress", "coins", 0)
func add_coins(n: int) -> void:
    set_value("progress", "coins", max(0, get_coins() + n))
    GameSignals.coins_changed.emit(get_coins())

func get_best(mode: String) -> int:
    return cfg.get_value("progress", "best_" + mode, 0)

func set_best(mode: String, score: int) -> void:
    if get_best(mode) < score:
        set_value("progress", "best_" + mode, score)
        GameSignals.best_changed.emit(score)

func get_skin() -> String: return cfg.get_value("settings", "skin", "mint")
func set_skin(id: String) -> void: set_value("settings", "skin", id)

func get_owned_skins() -> Array: return cfg.get_value("owned", "skins", ["mint"])
func own_skin(id: String) -> void:
    var owned: Array = get_owned_skins()
    if id not in owned:
        owned.append(id)
        set_value("owned", "skins", owned)

func is_skin_owned(id: String) -> bool:
    return id in get_owned_skins()

func get_achievements() -> Array: return cfg.get_value("achievements", "unlocked", [])
func unlock_achievement(id: String) -> bool:
    var owned: Array = get_achievements()
    if id in owned: return false
    owned.append(id)
    set_value("achievements", "unlocked", owned)
    return true

func bump_stat(key: String, value: int) -> void:
    var v: int = cfg.get_value("stats", key, 0)
    if v < value:
        set_value("stats", key, value)

func add_stat(key: String, delta: int) -> void:
    var v: int = cfg.get_value("stats", key, 0)
    set_value("stats", key, v + delta)

func get_stat(key: String) -> int:
    return cfg.get_value("stats", key, 0)
