extends CharacterBody3D
class_name LivingBody

signal died

func kill():
	died.emit()
