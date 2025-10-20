extends GdUnitTestSuite
class_name TestChartParser

const ChartParserScript = preload("res://Scripts/Parsers/ChartParser.gd")

func test_get_resolution_valid():
	var parser = auto_free(ChartParserScript.new())
	var sections = {
		"Song": ["Resolution = 192"]
	}
	var result = parser.get_resolution(sections)
	assert_int(result).is_equal(192)

func test_get_resolution_default():
	var parser = auto_free(ChartParserScript.new())
	var sections = {
		"Song": []
	}
	var result = parser.get_resolution(sections)
	assert_int(result).is_equal(192)

func test_get_resolution_invalid():
	var parser = auto_free(ChartParserScript.new())
	var sections = {
		"Song": ["Resolution = -1"]
	}
	var result = parser.get_resolution(sections)
	assert_int(result).is_equal(192)

func test_get_offset_valid():
	var parser = auto_free(ChartParserScript.new())
	var sections = {
		"Song": ["Offset = 100"]
	}
	var result = parser.get_offset(sections)
	assert_float(result).is_equal(0.1)

func test_get_offset_default():
	var parser = auto_free(ChartParserScript.new())
	var sections = {
		"Song": []
	}
	var result = parser.get_offset(sections)
	assert_float(result).is_equal(0.0)

func test_get_music_stream_valid():
	var parser = auto_free(ChartParserScript.new())
	var sections = {
		"Song": ['MusicStream = "song.ogg"']
	}
	var result = parser.get_music_stream(sections)
	assert_str(result).is_equal("song.ogg")

func test_get_music_stream_absolute_path():
	var parser = auto_free(ChartParserScript.new())
	var sections = {
		"Song": ['MusicStream = "C:\\song.ogg"']
	}
	var result = parser.get_music_stream(sections)
	assert_str(result).is_empty()

func test_get_tempo_events():
	var parser = auto_free(ChartParserScript.new())
	var sections = {
		"SyncTrack": ["0 = B 120000", "192 = B 140000"]
	}
	var result = parser.get_tempo_events(sections)
	assert_int(result.size()).is_equal(2)
	assert_int(result[0].tick).is_equal(0)
	assert_float(result[0].bpm).is_equal(120.0)
	assert_int(result[1].tick).is_equal(192)
	assert_float(result[1].bpm).is_equal(140.0)

func test_get_notes_basic():
	var parser = auto_free(ChartParserScript.new())
	var sections = {
		"EasySingle": ["0 = N 0 0", "192 = N 1 0"]
	}
	var result = parser.get_notes(sections, "EasySingle", 192)
	assert_int(result.size()).is_equal(2)
	assert_int(result[0].pos).is_equal(0)
	assert_int(result[0].fret).is_equal(0)
	assert_int(result[1].pos).is_equal(192)
	assert_int(result[1].fret).is_equal(1)

func test_get_notes_with_sustain():
	var parser = auto_free(ChartParserScript.new())
	var sections = {
		"EasySingle": ["0 = N 0 192"]
	}
	var result = parser.get_notes(sections, "EasySingle", 192)
	assert_int(result.size()).is_equal(1)
	assert_int(result[0].length).is_equal(192)

func test_get_notes_open_note():
	var parser = auto_free(ChartParserScript.new())
	var sections = {
		"EasySingle": ["0 = N 7 0"]
	}
	var result = parser.get_notes(sections, "EasySingle", 192)
	assert_int(result.size()).is_equal(1)
	assert_int(result[0].fret).is_equal(5)

func test_get_notes_hopo_special():
	var parser = auto_free(ChartParserScript.new())
	var sections = {
		"EasySingle": ["0 = N 0 0", "48 = N 5 0", "96 = N 1 0"]
	}
	var result = parser.get_notes(sections, "EasySingle", 192)
	assert_int(result.size()).is_equal(2)
	assert_bool(result[1].is_hopo).is_false()  # Should be flipped by special

func test_get_note_times():
	var parser = auto_free(ChartParserScript.new())
	var notes = [{pos = 0}, {pos = 192}]
	var tempo_events = [{tick = 0, bpm = 120.0}]
	var result = parser.get_note_times(notes, 192, tempo_events)
	assert_int(result.size()).is_equal(2)
	assert_float(result[0]).is_equal(0.0)
	assert_float(result[1]).is_equal(1.0)  # 192 ticks at 120 BPM = 1 second

func test_get_available_instruments():
	var parser = auto_free(ChartParserScript.new())
	var sections = {
		"EasySingle": ["0 = N 0 0"],
		"HardSingle": ["0 = N 0 0"],
		"MediumDrums": []
	}
	var result = parser.get_available_instruments(sections)
	assert_bool(result.has("Single")).is_true()
	assert_int(result["Single"].size()).is_equal(2)
	assert_bool(result["Single"].has("Easy")).is_true()
	assert_bool(result["Single"].has("Hard")).is_true()
	assert_bool(result.has("Drums")).is_false()  # No notes

func test_has_notes_in_section_true():
	var parser = auto_free(ChartParserScript.new())
	var section_lines = ["0 = N 0 0"]
	var result = parser.has_notes_in_section(section_lines)
	assert_bool(result).is_true()

func test_has_notes_in_section_false():
	var parser = auto_free(ChartParserScript.new())
	var section_lines = ["0 = E something"]
	var result = parser.has_notes_in_section(section_lines)
	assert_bool(result).is_false()