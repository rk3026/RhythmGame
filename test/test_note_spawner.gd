extends GdUnitTestSuite
class_name TestNoteSpawner

const NoteSpawnerScript = preload("res://Scripts/note_spawner.gd")

func test_start_spawning():
	var spawner = auto_free(NoteSpawnerScript.new())
	spawner.notes = [{pos = 0, fret = 0, length = 0}, {pos = 192, fret = 1, length = 0}]
	spawner.tempo_events = [{tick = 0, bpm = 120.0}]
	spawner.resolution = 192
	spawner.offset = 0.0
	spawner.lanes = [0.0, 1.0, 2.0, 3.0, 4.0]
	
	spawner.start_spawning()
	
	assert_bool(spawner.spawning_started).is_true()
	assert_int(spawner.spawn_data.size()).is_equal(2)
	assert_float(spawner.spawn_data[0].spawn_time).is_equal(0.0)
	assert_float(spawner.spawn_data[1].spawn_time).is_less(1.0)

func test_get_note_type_regular():
	var spawner = auto_free(NoteSpawnerScript.new())
	var note = {fret = 0}
	var result = spawner.get_note_type(note)
	assert_int(result).is_equal(NoteType.Type.REGULAR)

func test_get_note_type_hopo():
	var spawner = auto_free(NoteSpawnerScript.new())
	var note = {fret = 0, is_hopo = true}
	var result = spawner.get_note_type(note)
	assert_int(result).is_equal(NoteType.Type.HOPO)

func test_get_note_type_tap():
	var spawner = auto_free(NoteSpawnerScript.new())
	var note = {fret = 0, is_tap = true}
	var result = spawner.get_note_type(note)
	assert_int(result).is_equal(NoteType.Type.TAP)

func test_get_note_type_open():
	var spawner = auto_free(NoteSpawnerScript.new())
	var note = {fret = 5}
	var result = spawner.get_note_type(note)
	assert_int(result).is_equal(NoteType.Type.OPEN)

func test_get_note_times():
	var spawner = auto_free(NoteSpawnerScript.new())
	var notes = [{pos = 0}, {pos = 192}]
	var tempo_events = [{tick = 0, bpm = 120.0}]
	var result = spawner.get_note_times(notes, 192, tempo_events)
	assert_int(result.size()).is_equal(2)
	assert_float(result[0]).is_equal(0.0)
	assert_float(result[1]).is_equal(1.0)

func test_get_current_bpm():
	var spawner = auto_free(NoteSpawnerScript.new())
	var tempo_events = [{tick = 0, bpm = 120.0}, {tick = 192, bpm = 140.0}]
	var result = spawner.get_current_bpm(tempo_events, 100)
	assert_float(result).is_equal(120.0)
	
	result = spawner.get_current_bpm(tempo_events, 200)
	assert_float(result).is_equal(140.0)

func test_add_spawn_entry():
	var spawner = auto_free(NoteSpawnerScript.new())
	spawner.spawn_data = []
	spawner.add_spawn_entry(1.0, 0, 2.0, NoteType.Type.REGULAR, false, 0.0, 1.0)
	assert_int(spawner.spawn_data.size()).is_equal(1)
	assert_float(spawner.spawn_data[0].spawn_time).is_equal(1.0)
	assert_int(spawner.spawn_data[0].lane).is_equal(0)

func test_add_spawn_entry_deduplicate():
	var spawner = auto_free(NoteSpawnerScript.new())
	spawner.spawn_data = []
	spawner.add_spawn_entry(1.0, 0, 2.0, NoteType.Type.REGULAR, false, 0.0, 1.0)
	spawner.add_spawn_entry(1.0, 0, 2.0, NoteType.Type.REGULAR, true, 1.0, 1.0)  # Same lane and time
	assert_int(spawner.spawn_data.size()).is_equal(1)
	assert_bool(spawner.spawn_data[0].is_sustain).is_true()
	assert_float(spawner.spawn_data[0].sustain_length).is_equal(1.0)

func test_reposition_active_notes():
	var spawner = auto_free(NoteSpawnerScript.new())
	var mock_note = mock(Node)
	spawner.active_notes = [mock_note]
	
	mock_note.travel_time = 1.0
	mock_note.spawn_time = 0.0
	mock_note.position = Vector3(0.0, 0.0, -25.0)
	
	spawner.reposition_active_notes(0.5)
	
	verify(mock_note, 1).position = Vector3(0.0, 0.0, 0.0)  # Halfway through travel

func test_cleanup_pass():
	var spawner = auto_free(NoteSpawnerScript.new())
	var mock_note = mock(Node)
	spawner.active_notes = [mock_note]
	
	mock_note.position = Vector3(0.0, 0.0, 25.0)  # Beyond end
	mock_note.visible = true
	
	spawner._cleanup_pass()
	
	assert_int(spawner.active_notes.size()).is_equal(0)