extends Resource
class_name settingsHelper

@export var saved_events: Array[InputEvent] = [] #are retrieved from InputMap in order, so the actions related to each event shouldnt really need to be saved!
@export var saved_bus_volumes: Array[float] = []

@export var window_mode: DisplayServer.WindowMode = DisplayServer.WindowMode.WINDOW_MODE_WINDOWED
@export var fps_limit: int = 0
