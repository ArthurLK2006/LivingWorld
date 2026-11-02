class_name SimModule
extends RefCounted

func setup(_ctx: SimContext) -> void: pass
func post_setup() -> void: pass
func on_new_game(_world_seed: int) -> void: pass
func on_load(_data: Dictionary) -> void: pass
func tick(_dt_sim: float) -> void: pass
func serialize() -> Dictionary: return {}
func validate() -> Array[String]: return []
func debug_summary() -> Dictionary: return {}
func teardown() -> void: pass
