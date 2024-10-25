extends Node
class_name ArrayUtils

enum Transformation {
	MEAN,
	MEDIAN,
}

## Appends an array to another and removes the duplicates between the two.
static func union(a: Array, b: Array, type: Variant.Type, hint: StringName) -> Array[Variant]:
	for element in b:
		if element not in a:
			a.append(element)
	return Array(a, type, hint, null)

## Get an array of the elements only in the first array.
static func difference(a: Array, b: Array, type: Variant.Type, hint: StringName) -> Array[Variant]:
	var result: Array
	for element in a:
		if element not in b:
			result.append(element)
	return Array(result, type, hint, null)

## Get an array of the elements only in both arrays.
static func intersect(a: Array, b: Array, type: Variant.Type, hint: StringName) -> Array[Variant]:
	var result: Array
	for element in b:
		if element in a:
			result.append(element)
	return Array(result, type, hint, null)

## Get an array with only unique elements from the source array (removes duplicates).
static func to_set(array: Array) -> Array:
	var result: Array
	for element in array:
		if not result.has(element):
			result.append(element)
	return result

## Get an array of the median of a float array or a [Vector2] with the median of the x and y components.
static func transform(array: Array[Variant], transformation: Transformation, at_edges: bool = false) -> Variant:
	if array[0] is float or array[0] is int:
		var result: float
		if at_edges:
			array = [array[0], array[-1]]
		else:
			array = to_set(array)
		match transformation:
			Transformation.MEAN:
				result = _mean_float(array)
			Transformation.MEDIAN:
				result = _median_float(array)
		return result
	elif array[0] is Vector2 or array[0] is Vector2i:
		var result: Vector2
		var array_x = array.map(func(element): return round(element.x))
		var array_y = array.map(func(element): return round(element.y))
		if at_edges:
			array_x = [array_x[0], array_x[-1]]
			array_y = [array_y[0], array_y[-1]]
		else:
			array_x = to_set(array_x)
			array_y = to_set(array_y)
		match transformation:
			Transformation.MEAN:
				result.x = _mean_float(array_x)
				result.y = _mean_float(array_y)
			Transformation.MEDIAN:
				result.x = _median_float(array_x)
				result.y = _median_float(array_y)
		if array is Array[Vector2i]:
			return Vector2i(result)
		else:
			return result
	else:
		printerr("Array must be of type float, int, Vector2 or Vector2i")
		return null

static func _median_float(array: Array) -> float:
	array.sort()
	if len(array) % 2 == 1:
		return array[(len(array))*0.5]
	else:
		return (array[len(array)*0.5-1]+array[len(array)*0.5])*0.5

static func _mean_float(array: Array) -> float:
	return array.reduce(func(accum, number): return accum + number)/len(array)
