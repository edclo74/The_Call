extends CanvasLayer
@onready var progress_bar: ProgressBar = $ProgressBar
var target_scene_path: String = ""
var progress: Array = []

func _ready() -> void:
	# Start the threaded loading request
	ResourceLoader.load_threaded_request(target_scene_path)

func _process(_delta: float) -> void:
	# Check the loading status of the asset
	var status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
	
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			# Update the progress bar (progress[0] contains a float from 0.0 to 1.0)
			progress_bar.value = progress[0] * 100
			
		ResourceLoader.THREAD_LOAD_LOADED:
			# Transfer to the fully loaded scene
			var new_scene = ResourceLoader.load_threaded_get(target_scene_path) as PackedScene
			get_tree().change_scene_to_packed(new_scene)
			set_process(false)
			queue_free()
			
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			print("Error: Failed to load scene.")
			set_process(false)
