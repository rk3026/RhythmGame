extends Node
"""
StarAnimator

Attach this as a child of a `Sprite3D` note node (or any node whose parent is a Sprite3D).
It looks for per-frame `.tres` atlas textures with the naming pattern:
  <frames_base>1.tres, <frames_base>2.tres, ... up to `frame_count`.

Example:
  frames_base = "res://Assets/Textures/Notes/star_blue"
  frame_count = 16

Usage:
 - Add this Node as a child of your `Sprite3D` note (or of the Note node itself).
 - Configure `frames_base` and `frame_count` in the Inspector.
 - Call `play()` / `stop()` or set `autoplay` to true.
"""

@export_category("Frames")
@export var frames_base: String = "res://Assets/Textures/Notes/star_blue"
@export var frame_count: int = 16
@export var fps: int = 16
@export var autoplay: bool = true

var frames: Array = []
var playing: bool = false
var _time: float = 0.0
var _index: int = 0
var _frame_duration: float = 0.0625

func _ready() -> void:
    _frame_duration = 1.0 / max(fps, 1)
    _load_frames()
    # Enable processing so _process is called
    set_process(true)
    # Apply first frame immediately so the sprite isn't empty until the first tick
    if frames.size() > 0:
        _apply_frame()
    if autoplay:
        play()

func _process(delta: float) -> void:
    if not playing or frames.size() == 0:
        return
    _time += delta
    if _time >= _frame_duration:
        var steps = int(_time / _frame_duration)
        _time -= steps * _frame_duration
        _index = (_index + steps) % frames.size()
        _apply_frame()

func _load_frames() -> void:
    frames.clear()
    for i in range(1, frame_count + 1):
        var path = "%s%d.tres" % [frames_base, i]
        var res = ResourceLoader.load(path)
        if res:
            frames.append(res)
            continue

        # fallback: try png files (if someone exported frames differently)
        var pngpath = "%s%d.png" % [frames_base, i]
        var pngres = ResourceLoader.load(pngpath)
        if pngres:
            frames.append(pngres)

    if frames.size() == 0:
        push_warning("StarAnimator: no frames found for base '%s' (checked %d frames)" % [frames_base, frame_count])

func _apply_frame() -> void:
    if frames.size() == 0:
        return
    var tex = frames[_index]
    var parent_node = get_parent()
    if parent_node and parent_node is Sprite3D:
        parent_node.texture = tex
    else:
        # If attached somewhere else, try to find a Sprite3D child on the same node
        # (useful if you attach this to the Note node rather than the Sprite3D directly)
        var sprite = null
        if parent_node:
            for child in parent_node.get_children():
                if child is Sprite3D:
                    sprite = child
                    break
        if sprite:
            sprite.texture = tex

func play() -> void:
    if frames.size() == 0:
        return
    playing = true

func stop() -> void:
    playing = false

func restart() -> void:
    _index = 0
    _time = 0.0
    _apply_frame()

func set_frame_count(count: int) -> void:
    frame_count = count
    _load_frames()
