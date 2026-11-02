class_name SimResult
extends RefCounted

var ok: bool
var code: String
var message: String


func _init(is_ok: bool, result_code: String = "", result_message: String = "") -> void:
	ok = is_ok
	code = result_code
	message = result_message
