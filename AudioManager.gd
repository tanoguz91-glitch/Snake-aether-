# Autoload — procedural audio (SFX + music) generated at runtime
# No external audio files required.
extends Node

const SAMPLE_RATE := 44100

var sfx_pool: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var music_timer: float = 0.0
var music_seq_idx: int = 0
var music_root: float = 220.0
var music_step: float = 0.32
var music_on: bool = true
var music_track: String = ""

func _ready() -> void:
    # Pool for SFX
    for i in range(10):
        var p := AudioStreamPlayer.new()
        p.bus = "Master"
        add_child(p)
        sfx_pool.append(p)
    music_player = AudioStreamPlayer.new()
    music_player.bus = "Master"
    add_child(music_player)

func _process(delta: float) -> void:
    if not music_on or music_track == "": return
    music_timer -= delta
    if music_timer <= 0.0:
        music_timer = music_step
        _play_music_note()

# ---------- Tone generation ----------
func _gen_tone(freq: float, duration: float, volume: float, waveform: String) -> AudioStreamWAV:
    var sample_count: int = int(SAMPLE_RATE * duration)
    var data := PackedByteArray()
    data.resize(sample_count * 2) # 16-bit mono
    var two_pi := TAU
    for i in range(sample_count):
        var t: float = float(i) / float(SAMPLE_RATE)
        var envelope: float = minf(1.0, t * 30.0) * maxf(0.0, 1.0 - (t / duration))
        var v: float = 0.0
        match waveform:
            "sine":
                v = sin(two_pi * freq * t)
            "square":
                v = 1.0 if sin(two_pi * freq * t) > 0.0 else -1.0
            "triangle":
                var p := fmod(t * freq, 1.0)
                v = (4.0 * p - 1.0) if p < 0.5 else (3.0 - 4.0 * p)
            "saw":
                v = 2.0 * fmod(t * freq, 1.0) - 1.0
            _:
                v = sin(two_pi * freq * t)
        v *= envelope * volume
        var sample: int = int(clamp(v * 32767.0, -32768.0, 32767.0))
        if sample < 0: sample += 65536
        data[i * 2]     = sample & 0xff
        data[i * 2 + 1] = (sample >> 8) & 0xff
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = SAMPLE_RATE
    stream.stereo = false
    stream.data = data
    return stream

func play_tone(freq: float, dur: float = 0.08, vol: float = 0.18, wave: String = "sine") -> void:
    if not SaveData.get_value("settings", "sfx", true): return
    var p: AudioStreamPlayer = _next_free_sfx()
    p.stream = _gen_tone(freq, dur, vol, wave)
    p.play()

func _next_free_sfx() -> AudioStreamPlayer:
    for p in sfx_pool:
        if not p.playing: return p
    return sfx_pool[0]

# ---------- SFX shortcuts ----------
func sfx_eat() -> void:
    play_tone(660.0, 0.05, 0.12, "square")
    await get_tree().create_timer(0.04).timeout
    play_tone(880.0, 0.05, 0.10, "square")

func sfx_power() -> void:
    play_tone(523.0, 0.06, 0.14, "triangle")
    await get_tree().create_timer(0.06).timeout
    play_tone(784.0, 0.07, 0.14, "triangle")
    await get_tree().create_timer(0.07).timeout
    play_tone(1046.0, 0.09, 0.12, "triangle")

func sfx_hit() -> void:
    play_tone(180.0, 0.18, 0.16, "saw")
    await get_tree().create_timer(0.08).timeout
    play_tone(90.0, 0.22, 0.14, "saw")

func sfx_click() -> void:
    play_tone(420.0, 0.03, 0.10, "square")

func sfx_level() -> void:
    play_tone(523.0, 0.06, 0.12, "square")
    await get_tree().create_timer(0.06).timeout
    play_tone(659.0, 0.08, 0.12, "square")
    await get_tree().create_timer(0.06).timeout
    play_tone(784.0, 0.10, 0.12, "square")

func sfx_rewind() -> void:
    play_tone(800.0, 0.15, 0.10, "triangle")
    await get_tree().create_timer(0.06).timeout
    play_tone(400.0, 0.18, 0.10, "triangle")

func sfx_coin() -> void:
    play_tone(1318.0, 0.05, 0.10, "square")
    await get_tree().create_timer(0.05).timeout
    play_tone(1760.0, 0.08, 0.10, "square")

func sfx_combo(n: int) -> void:
    play_tone(660.0 + n * 60, 0.05, 0.10, "square")

func sfx_boss() -> void:
    play_tone(220.0, 0.10, 0.14, "saw")
    await get_tree().create_timer(0.08).timeout
    play_tone(330.0, 0.12, 0.14, "saw")
    await get_tree().create_timer(0.10).timeout
    play_tone(440.0, 0.18, 0.14, "saw")

func sfx_achievement() -> void:
    play_tone(659.0, 0.08, 0.14, "triangle")
    await get_tree().create_timer(0.08).timeout
    play_tone(880.0, 0.10, 0.14, "triangle")
    await get_tree().create_timer(0.10).timeout
    play_tone(1175.0, 0.16, 0.12, "triangle")

func sfx_win() -> void:
    play_tone(523.0, 0.10, 0.18, "triangle")
    await get_tree().create_timer(0.10).timeout
    play_tone(659.0, 0.10, 0.18, "triangle")
    await get_tree().create_timer(0.10).timeout
    play_tone(784.0, 0.10, 0.18, "triangle")
    await get_tree().create_timer(0.10).timeout
    play_tone(1046.0, 0.18, 0.18, "triangle")

func sfx_shield() -> void:
    play_tone(440.0, 0.10, 0.12, "triangle")
    await get_tree().create_timer(0.08).timeout
    play_tone(550.0, 0.12, 0.12, "triangle")

# ---------- Music ----------
func start_music(track: String) -> void:
    music_on = SaveData.get_value("settings", "music", true)
    if not music_on: return
    if music_track == track: return
    music_track = track
    music_seq_idx = 0
    music_timer = 0.0
    match track:
        "menu":   music_root = 220.0; music_step = 0.32
        "play":   music_root = 196.0; music_step = 0.24
        "boss":   music_root = 110.0; music_step = 0.18
        "blitz":  music_root = 247.0; music_step = 0.14
        "zen":    music_root = 174.0; music_step = 0.48
        _:        music_root = 196.0; music_step = 0.24

func stop_music() -> void:
    music_track = ""

func _play_music_note() -> void:
    if not music_on: return
    var seq: PackedInt32Array
    match music_track:
        "menu":  seq = PackedInt32Array([0, 7, 12, 7, 5, 12, 10, 7])
        "boss":  seq = PackedInt32Array([0, 7, 0, 10, 0, 12, 14, 7])
        "blitz": seq = PackedInt32Array([0, 5, 7, 12, 5, 7, 0, 10])
        "zen":   seq = PackedInt32Array([0, 4, 7, 12, 7, 4, 0, 5])
        _:       seq = PackedInt32Array([0, 7, 12, 19, 12, 7, 14, 12])
    var semi: int = seq[music_seq_idx % seq.size()]
    music_seq_idx += 1
    var f: float = music_root * pow(2.0, semi / 12.0)
    var wave: String = "saw" if music_track == "boss" else ("sine" if music_track == "zen" else "triangle")
    play_tone(f, music_step * 0.85, 0.05, wave)

# ---------- Haptics ----------
func vibrate(duration_ms: int = 30) -> void:
    if not SaveData.get_value("settings", "haptics", true): return
    if OS.has_feature("mobile"):
        Input.vibrate_handheld(duration_ms)
