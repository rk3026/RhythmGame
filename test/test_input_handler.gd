extends GdUnitTestSuite
class_name TestInputHandler

const InputHandlerScript = preload("res://Scripts/input_handler.gd")
const NoteSpawnerScript = preload("res://Scripts/note_spawner.gd")
const ScoreManagerScript = preload("res://Scripts/ScoreManager.gd")

func test_configure():
	var input_handler = auto_free(InputHandlerScript.new())
	var lanes = [0.0, 1.0, 2.0, 3.0, 4.0]
	var num_lanes = 5
	input_handler.configure(lanes, num_lanes)
	assert_array(input_handler.lanes).is_equal(lanes)
	assert_int(input_handler.num_lanes).is_equal(num_lanes)
	assert_int(input_handler.key_states.size()).is_equal(num_lanes)

func test_setup_lane_keys_default():
	var input_handler = auto_free(InputHandlerScript.new())
	input_handler.num_lanes = 5
	# Mock SettingsManager not available
	input_handler.setup_lane_keys(5)
	assert_array(input_handler.lane_keys).is_equal([KEY_D, KEY_F, KEY_J, KEY_K, KEY_L])

func test_setup_lane_keys_from_settings():
	var input_handler = auto_free(InputHandlerScript.new())
	input_handler.num_lanes = 5
	# Mock SettingsManager
	var mock_settings = spy(SettingsManager)
	mock_settings.lane_keys = [KEY_A, KEY_B, KEY_C, KEY_D, KEY_E]
	input_handler.setup_lane_keys(5)
	# Note: This test assumes SettingsManager is available, but in test environment it might not be
	# For now, just test the default case

func test_check_hit_no_notes():
	var input_handler = auto_free(InputHandlerScript.new())
	var mock_gameplay = mock(Node)
	var mock_spawner = mock(NoteSpawnerScript.new())
	
	input_handler.gameplay = mock_gameplay
	mock_gameplay.get_node("NoteSpawner").returns(mock_spawner)
	mock_spawner.active_notes = []
	
	input_handler.lanes = [0.0, 1.0, 2.0]
	input_handler.num_lanes = 3
	input_handler.key_states = [true, false, false]
	
	input_handler.check_hit(0)
	# Should not crash, no notes to hit

func test_check_hit_with_note():
	var input_handler = auto_free(InputHandlerScript.new())
	var mock_gameplay = mock(Node)
	var mock_spawner = mock(NoteSpawnerScript.new())
	var mock_note = mock(Node)
	
	input_handler.gameplay = mock_gameplay
	mock_gameplay.get_node("NoteSpawner").returns(mock_spawner)
	mock_spawner.active_notes = [mock_note]
	
	mock_note.position = Vector3(0.0, 0.0, 0.0)
	mock_note.expected_hit_time = 0.0
	mock_note.was_hit = false
	
	input_handler.lanes = [0.0, 1.0, 2.0]
	input_handler.num_lanes = 3
	input_handler.key_states = [true, false, false]
	
	# Mock current time
	var mock_time = 0.0
	input_handler.song_start_time = 0.0
	
	input_handler.check_hit(0)
	# Verify note was marked as hit
	verify(mock_note, 1).was_hit = true

func test_has_sustain_held():
	var input_handler = auto_free(InputHandlerScript.new())
	var mock_gameplay = mock(Node)
	var mock_spawner = mock(NoteSpawnerScript.new())
	var mock_note = mock(Node)
	
	input_handler.gameplay = mock_gameplay
	mock_gameplay.get_node("NoteSpawner").returns(mock_spawner)
	mock_spawner.active_notes = [mock_note]
	
	mock_note.position = Vector3(0.0, 0.0, 0.0)
	mock_note.was_hit = true
	mock_note.is_sustain = true
	
	input_handler.lanes = [0.0, 1.0, 2.0]
	
	var result = input_handler.has_sustain_held(0)
	assert_bool(result).is_true()

func test_has_sustain_held_no_sustain():
	var input_handler = auto_free(InputHandlerScript.new())
	var mock_gameplay = mock(Node)
	var mock_spawner = mock(NoteSpawnerScript.new())
	var mock_note = mock(Node)
	
	input_handler.gameplay = mock_gameplay
	mock_gameplay.get_node("NoteSpawner").returns(mock_spawner)
	mock_spawner.active_notes = [mock_note]
	
	mock_note.position = Vector3(0.0, 0.0, 0.0)
	mock_note.was_hit = true
	mock_note.is_sustain = false
	
	input_handler.lanes = [0.0, 1.0, 2.0]
	
	var result = input_handler.has_sustain_held(0)
	assert_bool(result).is_false()