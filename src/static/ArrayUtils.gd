extends Node
class_name ArrayUtils

static func union(a: Array, b: Array, type: Variant.Type, hint: StringName) -> Array[Variant]:
	for element in b:
		if element not in a:
			a.append(element)
	return Array(a, type, hint, null)


static func difference(a: Array, b: Array, type: Variant.Type, hint: StringName) -> Array[Variant]:
	var result: Array
	for element in a:
		if element not in b:
			result.append(element)
	return Array(result, type, hint, null)


static func intersect(a: Array, b: Array, type: Variant.Type, hint: StringName) -> Array[Variant]:
	var result: Array
	for element in b:
		if element in a:
			result.append(element)
	return Array(result, type, hint, null)