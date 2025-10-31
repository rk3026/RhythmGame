@tool
extends EditorScript
# Creates AnimatedTexture resources for all star sprite-sheet PNGs in the Notes folder.
# Assumptions:
# - Each PNG is a sprite sheet laid out as 4 columns x 4 rows (16 frames).
# - Files are located in "res://Assets/Textures/Notes/" and have "star" in their filename.
# - The script will save an AnimatedTexture resource next to each PNG with the same base name
#   and the extension `.anim.tres` (e.g. `star_blue.anim.tres`).
# Usage: Open this script in the Godot Script Editor and press Run (it runs as an EditorScript).

const NOTES_DIR := "res://Assets/Textures/Notes/"
const COLS := 4
const ROWS := 4
const FPS := 16

func _run():
    var da = DirAccess.open(NOTES_DIR)
    if not da:
        printerr("Could not open directory: %s" % NOTES_DIR)
        return

    da.list_dir_begin()
    var filename = da.get_next()
    var processed := []
    while filename != "":
        if da.current_is_dir():
            filename = da.get_next()
            continue

        var lower = filename.to_lower()
        if lower.ends_with(".png") and lower.find("star") >= 0:
            var path = NOTES_DIR + filename
            var ok = _process_sprite_sheet(path)
            if ok:
                processed.append(filename)

        filename = da.get_next()

    da.list_dir_end()

    if processed.size() == 0:
        print("No star PNGs found in %s" % NOTES_DIR)
    else:
        print("Processed %d star files:" % processed.size())
        for f in processed:
            print(" - %s" % f)

func _process_sprite_sheet(path: String) -> bool:
    # Load texture
    var tex = ResourceLoader.load(path)
    if not tex:
        push_error("Failed to load texture: %s" % path)
        return false

    if not tex is Texture2D:
        push_error("Not a Texture2D: %s" % path)
        return false

    var img = tex.get_image()
    if not img:
        push_error("Failed to get image from texture: %s" % path)
        return false

    var w = img.get_width()
    var h = img.get_height()
    if w % COLS != 0 or h % ROWS != 0:
        push_warning("Sprite sheet size not divisible by %dx%d: %s (w=%d h=%d)" % [COLS, ROWS, path, w, h])

    var frame_w = int(w / COLS)
    var frame_h = int(h / ROWS)

    # Create and save one AtlasTexture resource per frame (star_blue1.tres ... star_blue16.tres)
    var base = path.get_file().get_basename() # e.g. star_blue
    var index := 0
    for r in range(ROWS):
        for c in range(COLS):
            var rect = Rect2i(c * frame_w, r * frame_h, frame_w, frame_h)
            var atlas = AtlasTexture.new()
            atlas.atlas = tex
            atlas.region = rect

            index += 1
            var dest = NOTES_DIR + base + str(index) + ".tres"
            var err = ResourceSaver.save(atlas, dest)
            if err != OK:
                push_error("Failed to save AtlasTexture for %s frame %d -> %s (err=%s)" % [path, index, dest, str(err)])
                return false

    print("Saved %d AtlasTexture frames for %s" % [index, base])
    return true
