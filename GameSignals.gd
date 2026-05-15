# Autoload — global event bus
extends Node

signal score_changed(new_score: int)
signal best_changed(new_best: int)
signal coins_changed(new_coins: int)
signal state_changed(new_state: String)
signal achievement_unlocked(id: String, name: String)
signal mode_started(mode: String)
signal mode_ended(mode: String, score: int, reason: String)
