class_name SaveCodec
extends RefCounted
## Interface do formato de save (arquitetura 18.3): transforma o estado (dados simples) em bytes
## e de volta. Hoje só existe `JsonSaveCodec`; o binário é plano B se as medições do SP5 exigirem.


func encode(_payload: Dictionary, _game_version: String) -> PackedByteArray:
	push_error("SaveCodec.encode: não implementado por esta subclasse.")
	return PackedByteArray()


func decode(_bytes: PackedByteArray) -> DecodedSave:
	return DecodedSave.failed("SAVE_NOT_IMPLEMENTED", "SaveCodec.decode: não implementado por esta subclasse.")
