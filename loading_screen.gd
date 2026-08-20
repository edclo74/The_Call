extends CanvasLayer
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var progress_label: Label =  $ProgressBar/Label #adjust path as needed

var target_scene_path: String = ""
var progress: Array = []

func _ready() -> void:
	progress_bar.show_percentage = false
	ResourceLoader.load_threaded_request(target_scene_path)

func _process(_delta: float) -> void:
	var status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var pct = progress[0] * 100
			progress_bar.value = pct
			progress_label.text = str(int(pct))  # just the number, no %

		ResourceLoader.THREAD_LOAD_LOADED:
			var new_scene = ResourceLoader.load_threaded_get(target_scene_path) as PackedScene
			get_tree().change_scene_to_packed(new_scene)
			set_process(false)
			queue_free()

		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			print("Error: Failed to load scene.")
			set_process(false)
