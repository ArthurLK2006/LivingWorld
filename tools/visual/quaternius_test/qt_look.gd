extends RefCounted
## ART-11 (ferramenta de arte, teste isolado, fora de `src/`): o "olhar" aplicado às malhas da Quaternius. LOOK_ASIS = como vem; LOOK_FLAT = normais planas por triângulo, sem mapa de normais, cores originais; LOOK_PALETTE = facetado mais as cores da direção (ardósia/petróleo, couro vinho, areia/creme, carvão e um acento ocre), por remapeamento de matiz no sombreador, sem pintar textura.

const LOOK_ASIS: int = 0
const LOOK_FLAT: int = 1
const LOOK_PALETTE: int = 2
const HEAD_BONES: PackedStringArray = ["Head", "neck_01"]
const SHADER_CODE: String = """
shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;
uniform sampler2D tex_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 slate : source_color = vec3(0.15, 0.24, 0.28);
uniform vec3 wine : source_color = vec3(0.26, 0.12, 0.12);
uniform vec3 sand : source_color = vec3(0.72, 0.63, 0.49);
uniform vec3 coal : source_color = vec3(0.12, 0.12, 0.13);
uniform vec3 accent : source_color = vec3(0.60, 0.38, 0.14);
uniform float rough = 0.9;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 0.0001)), d / (q.x + 0.0001), q.x);
}

void fragment() {
	vec3 lin = texture(tex_albedo, UV).rgb;
	vec3 hsv = rgb2hsv(pow(lin, vec3(1.0 / 2.2)));
	float h = hsv.x;
	float s = hsv.y;
	float v = hsv.z;
	float k = clamp(v / 0.62, 0.3, 1.2);
	vec3 target = slate;
	if (s < 0.16) {
		if (v > 0.62) {
			target = sand;
			k = clamp(v / 0.9, 0.55, 1.0);
		} else {
			target = coal;
			k = clamp(v / 0.2, 0.5, 1.4);
		}
	} else if (h < 0.11 || h > 0.93) {
		target = wine;
	} else if (h < 0.2) {
		if (s > 0.55) {
			target = accent;
		} else {
			target = sand;
			k = clamp(v / 0.9, 0.55, 1.0);
		}
	}
	ALBEDO = target * k;
	ROUGHNESS = rough;
	METALLIC = 0.0;
}
"""

static var _cache: Dictionary = {}
static var _shader: Shader = null


@warning_ignore("integer_division")
static func triangles(mesh: Mesh) -> int:
	var total: int = 0
	for s: int in mesh.get_surface_count():
		var count: int = mesh.surface_get_array_index_len(s)
		if count <= 0:
			count = mesh.surface_get_array_len(s)
		total += count / 3
	return total


## Nome do osso de um índice de ligação (bind) da malha: pelo `Skin`, ou pelo próprio esqueleto se a malha não tiver `Skin`.
static func bind_name(skin: Skin, skeleton: Skeleton3D, index: int) -> String:
	if skin != null and index < skin.get_bind_count():
		var named: String = String(skin.get_bind_name(index))
		if not named.is_empty():
			return named
		var bone: int = skin.get_bind_bone(index)
		if skeleton != null and bone >= 0:
			return String(skeleton.get_bone_name(bone))
	if skeleton != null and index < skeleton.get_bone_count():
		return String(skeleton.get_bone_name(index))
	return ""


## Aplica o olhar a uma malha já pendurada no esqueleto; `keep` (não vazio) corta a malha de pele do corpo-base, deixando só os triângulos cujos vértices são dominados por esses ossos (só a cabeça, como manda o Readme da Quaternius).
static func apply(mi: MeshInstance3D, look: int, keep: PackedStringArray) -> void:
	var is_skin: bool = keep.size() > 0 and String(mi.name).to_lower().begins_with("superhero")
	if look == LOOK_ASIS and not is_skin:
		for s: int in mi.mesh.get_surface_count():
			var original: Material = mi.mesh.surface_get_material(s)
			var tinted: Material = material_for(original, look)
			if tinted != original:
				mi.set_surface_override_material(s, tinted)
		return
	var cut: PackedStringArray = keep if is_skin else PackedStringArray()
	mi.mesh = rebuild(mi.mesh, mi.skin, mi.get_parent() as Skeleton3D, cut, look)


## Reconstrói cada superfície sem índices (um triângulo = três vértices próprios); em LOOK_FLAT/LOOK_PALETTE a normal é a do plano do triângulo (orientada para o lado da normal suave original) e as tangentes somem.
@warning_ignore("integer_division")
static func rebuild(src: Mesh, skin: Skin, skeleton: Skeleton3D, keep: PackedStringArray, look: int) -> ArrayMesh:
	var flat: bool = look != LOOK_ASIS
	var out: ArrayMesh = ArrayMesh.new()
	for s: int in src.get_surface_count():
		var a: Array = src.surface_get_arrays(s)
		var pos: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var nrm: PackedVector3Array = PackedVector3Array()
		var tang: PackedFloat32Array = PackedFloat32Array()
		var col: PackedColorArray = PackedColorArray()
		var uv: PackedVector2Array = PackedVector2Array()
		var uv2: PackedVector2Array = PackedVector2Array()
		var bones: PackedInt32Array = PackedInt32Array()
		var wts: PackedFloat32Array = PackedFloat32Array()
		var idx: PackedInt32Array = PackedInt32Array()
		if a[Mesh.ARRAY_NORMAL] != null:
			nrm = a[Mesh.ARRAY_NORMAL]
		if a[Mesh.ARRAY_TANGENT] != null:
			tang = a[Mesh.ARRAY_TANGENT]
		if a[Mesh.ARRAY_COLOR] != null:
			col = a[Mesh.ARRAY_COLOR]
		if a[Mesh.ARRAY_TEX_UV] != null:
			uv = a[Mesh.ARRAY_TEX_UV]
		if a[Mesh.ARRAY_TEX_UV2] != null:
			uv2 = a[Mesh.ARRAY_TEX_UV2]
		if a[Mesh.ARRAY_BONES] != null:
			bones = a[Mesh.ARRAY_BONES]
			wts = a[Mesh.ARRAY_WEIGHTS]
		if a[Mesh.ARRAY_INDEX] != null:
			idx = a[Mesh.ARRAY_INDEX]
		else:
			idx.resize(pos.size())
			for i: int in pos.size():
				idx[i] = i
		var bpv: int = 0
		if bones.size() > 0:
			bpv = bones.size() / pos.size()
		var keep_vertex: PackedByteArray = PackedByteArray()
		if keep.size() > 0 and bpv > 0:
			var bind_count: int = skin.get_bind_count() if skin != null else (skeleton.get_bone_count() if skeleton != null else 0)
			var ok_bind: PackedByteArray = PackedByteArray()
			ok_bind.resize(bind_count + 1)
			for b: int in bind_count:
				ok_bind[b] = 1 if keep.has(bind_name(skin, skeleton, b)) else 0
			keep_vertex.resize(pos.size())
			for v: int in pos.size():
				var best: int = 0
				var best_w: float = -1.0
				for k: int in bpv:
					if wts[v * bpv + k] > best_w:
						best_w = wts[v * bpv + k]
						best = bones[v * bpv + k]
				keep_vertex[v] = ok_bind[best] if best < bind_count else 0
		var tri_ids: PackedInt32Array = PackedInt32Array()
		for t: int in idx.size() / 3:
			var i0: int = idx[t * 3]
			var i1: int = idx[t * 3 + 1]
			var i2: int = idx[t * 3 + 2]
			if keep_vertex.size() > 0 and not (keep_vertex[i0] == 1 and keep_vertex[i1] == 1 and keep_vertex[i2] == 1):
				continue
			tri_ids.append(i0)
			tri_ids.append(i1)
			tri_ids.append(i2)
		var n: int = tri_ids.size()
		if n == 0:
			continue
		var o_pos: PackedVector3Array = PackedVector3Array()
		var o_nrm: PackedVector3Array = PackedVector3Array()
		var o_uv: PackedVector2Array = PackedVector2Array()
		var o_uv2: PackedVector2Array = PackedVector2Array()
		var o_col: PackedColorArray = PackedColorArray()
		var o_tan: PackedFloat32Array = PackedFloat32Array()
		var o_bones: PackedInt32Array = PackedInt32Array()
		var o_wts: PackedFloat32Array = PackedFloat32Array()
		o_pos.resize(n)
		o_nrm.resize(n)
		if uv.size() > 0:
			o_uv.resize(n)
		if uv2.size() > 0:
			o_uv2.resize(n)
		if col.size() > 0:
			o_col.resize(n)
		if tang.size() > 0 and not flat:
			o_tan.resize(n * 4)
		if bpv > 0:
			o_bones.resize(n * bpv)
			o_wts.resize(n * bpv)
		for j: int in n:
			var i: int = tri_ids[j]
			o_pos[j] = pos[i]
			if not flat and nrm.size() > 0:
				o_nrm[j] = nrm[i]
			if uv.size() > 0:
				o_uv[j] = uv[i]
			if uv2.size() > 0:
				o_uv2[j] = uv2[i]
			if col.size() > 0:
				o_col[j] = col[i]
			if tang.size() > 0 and not flat:
				for k: int in 4:
					o_tan[j * 4 + k] = tang[i * 4 + k]
			for k: int in bpv:
				o_bones[j * bpv + k] = bones[i * bpv + k]
				o_wts[j * bpv + k] = wts[i * bpv + k]
		if flat:
			for t: int in n / 3:
				var p0: Vector3 = o_pos[t * 3]
				var face: Vector3 = (o_pos[t * 3 + 2] - p0).cross(o_pos[t * 3 + 1] - p0).normalized()
				if nrm.size() > 0:
					var smooth: Vector3 = nrm[tri_ids[t * 3]] + nrm[tri_ids[t * 3 + 1]] + nrm[tri_ids[t * 3 + 2]]
					if face.dot(smooth) < 0.0:
						face = -face
				o_nrm[t * 3] = face
				o_nrm[t * 3 + 1] = face
				o_nrm[t * 3 + 2] = face
		var arr: Array = []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = o_pos
		arr[Mesh.ARRAY_NORMAL] = o_nrm
		if o_uv.size() > 0:
			arr[Mesh.ARRAY_TEX_UV] = o_uv
		if o_uv2.size() > 0:
			arr[Mesh.ARRAY_TEX_UV2] = o_uv2
		if o_col.size() > 0:
			arr[Mesh.ARRAY_COLOR] = o_col
		if o_tan.size() > 0:
			arr[Mesh.ARRAY_TANGENT] = o_tan
		if bpv > 0:
			arr[Mesh.ARRAY_BONES] = o_bones
			arr[Mesh.ARRAY_WEIGHTS] = o_wts
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		out.surface_set_material(out.get_surface_count() - 1, material_for(src.surface_get_material(s), look))
	return out


static func material_for(mat: Material, look: int) -> Material:
	if mat == null:
		return mat
	var hair_base: BaseMaterial3D = mat as BaseMaterial3D
	var is_hair: bool = hair_base != null and String(hair_base.resource_name).to_lower().contains("hair")
	if look == LOOK_ASIS and not is_hair:
		return mat
	var key: String = "%d_%d" % [mat.get_instance_id(), look]
	if _cache.has(key):
		return _cache[key]
	var result: Material = mat
	var base: BaseMaterial3D = mat as BaseMaterial3D
	if base != null:
		var lowered: String = String(base.resource_name).to_lower()
		if look == LOOK_PALETTE and (lowered.contains("peasant") or lowered.contains("ranger")):
			if _shader == null:
				_shader = Shader.new()
				_shader.code = SHADER_CODE
			var shaded: ShaderMaterial = ShaderMaterial.new()
			shaded.resource_name = base.resource_name
			shaded.shader = _shader
			shaded.set_shader_parameter("tex_albedo", base.albedo_texture)
			result = shaded
		else:
			var plain: BaseMaterial3D = base.duplicate() as BaseMaterial3D
			plain.normal_enabled = look == LOOK_ASIS
			if lowered.contains("hair"):
				plain.albedo_color = plain.albedo_color * (Color(0.3, 0.25, 0.22) if look == LOOK_PALETTE else Color(0.5, 0.36, 0.25))
			result = plain
	_cache[key] = result
	return result
