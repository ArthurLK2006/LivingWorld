class_name JsonSaveCodec
extends SaveCodec
## Formato atual do save (DEC-084, proposta): texto gzip com uma linha de cabeçalho em JSON
## (formato, versão do save, versão do jogo, checksum SHA-256 e tamanho do payload), uma quebra
## de linha e o payload em JSON canônico. O checksum cobre os bytes exatos do payload.
## Só lê dados simples: nunca carrega recursos, scripts ou objetos (AGENTS 4.16).

const FORMAT_NAME: String = "lwsave"
const CURRENT_SAVE_VERSION: int = 2
## Teto do tamanho descomprimido, contra arquivo malicioso que explode ao descomprimir.
const MAX_UNCOMPRESSED_BYTES: int = 268435456
const HEADER_SEPARATOR: String = "\n"
const GZIP_MAGIC_FIRST: int = 0x1f
const GZIP_MAGIC_SECOND: int = 0x8b
const CHECKSUM_LENGTH: int = 64

var _migrations: SaveMigrations = SaveMigrations.new()


func encode(payload: Dictionary, game_version: String) -> PackedByteArray:
	return encode_with_version(payload, game_version, CURRENT_SAVE_VERSION)


## Grava numa versão específica; usado para gerar a fixture da versão anterior nos testes.
func encode_with_version(payload: Dictionary, game_version: String, save_version: int) -> PackedByteArray:
	var payload_text: String = JSON.stringify(payload, "", true, true)
	var header: Dictionary = {
		"format": FORMAT_NAME,
		"save_version": save_version,
		"game_version": game_version,
		"checksum": payload_text.sha256_text(),
		"payload_bytes": payload_text.to_utf8_buffer().size(),
	}
	var full_text: String = JSON.stringify(header, "", true, true) + HEADER_SEPARATOR + payload_text
	return full_text.to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP)


func decode(bytes: PackedByteArray) -> DecodedSave:
	if bytes.size() < 2 or bytes[0] != GZIP_MAGIC_FIRST or bytes[1] != GZIP_MAGIC_SECOND:
		return DecodedSave.failed("SAVE_NOT_GZIP", "Arquivo de save inválido: não é um arquivo comprimido do jogo.")
	var raw: PackedByteArray = bytes.decompress_dynamic(MAX_UNCOMPRESSED_BYTES, FileAccess.COMPRESSION_GZIP)
	if raw.is_empty():
		return DecodedSave.failed("SAVE_CORRUPT", "Arquivo de save corrompido: não foi possível descomprimir.")
	var text: String = raw.get_string_from_utf8()
	var separator_at: int = text.find(HEADER_SEPARATOR)
	if separator_at < 0:
		return DecodedSave.failed("SAVE_CORRUPT", "Arquivo de save corrompido: cabeçalho ausente.")
	var header_result: DecodedSave = _read_header(text.substr(0, separator_at))
	if not header_result.result.ok:
		return header_result
	var payload_text: String = text.substr(separator_at + 1)
	var header: Dictionary = header_result.payload
	if payload_text.to_utf8_buffer().size() != int(header["payload_bytes"]) or payload_text.sha256_text() != header["checksum"]:
		return DecodedSave.failed("SAVE_CHECKSUM_MISMATCH", "Save adulterado ou corrompido: o checksum não confere.")
	var save_version: int = int(header["save_version"])
	if save_version > CURRENT_SAVE_VERSION:
		return DecodedSave.failed("SAVE_VERSION_NEWER", "Este save é da versão %d do formato, mais nova que a suportada (%d). Atualize o jogo." % [save_version, CURRENT_SAVE_VERSION])
	var parser: JSON = JSON.new()
	if parser.parse(payload_text) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return DecodedSave.failed("SAVE_CORRUPT", "Arquivo de save corrompido: conteúdo não é JSON válido.")
	var payload: Dictionary = parser.data
	var migration: Result = _migrations.migrate(payload, save_version, CURRENT_SAVE_VERSION)
	if not migration.ok:
		return DecodedSave.failed(migration.code, migration.message)
	var decoded: DecodedSave = DecodedSave.new(Result.success())
	decoded.save_version = save_version
	decoded.game_version = str(header["game_version"])
	decoded.payload = payload
	return decoded


## Confere o cabeçalho; em caso de sucesso devolve o próprio cabeçalho em `payload`.
func _read_header(header_text: String) -> DecodedSave:
	var parser: JSON = JSON.new()
	if parser.parse(header_text) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return DecodedSave.failed("SAVE_CORRUPT", "Arquivo de save corrompido: cabeçalho ilegível.")
	var header: Dictionary = parser.data
	if header.get("format") != FORMAT_NAME:
		return DecodedSave.failed("SAVE_WRONG_FORMAT", "Arquivo não é um save do Living World (formato '%s')." % str(header.get("format")))
	var version: Variant = header.get("save_version")
	var size: Variant = header.get("payload_bytes")
	var checksum: Variant = header.get("checksum")
	var is_whole_version: bool = (typeof(version) == TYPE_FLOAT or typeof(version) == TYPE_INT) and version == floorf(float(version)) and version >= 1
	var is_whole_size: bool = (typeof(size) == TYPE_FLOAT or typeof(size) == TYPE_INT) and size == floorf(float(size)) and size >= 0
	if not is_whole_version or not is_whole_size or typeof(checksum) != TYPE_STRING or str(checksum).length() != CHECKSUM_LENGTH or typeof(header.get("game_version")) != TYPE_STRING:
		return DecodedSave.failed("SAVE_CORRUPT", "Arquivo de save corrompido: cabeçalho com campos inválidos.")
	var ok_header: DecodedSave = DecodedSave.new(Result.success())
	ok_header.payload = header
	return ok_header
