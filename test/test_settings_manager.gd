extends GdUnitTestSuite
class_name TestSettingsManager

const SettingsManagerScript = preload("res://Scripts/settings_manager.gd")

func test_validate_lane_keys_valid():
	var settings = auto_free(SettingsManagerScript.new())
	var keys = [KEY_A, KEY_B, KEY_C, KEY_D, KEY_E]
	var result = settings.validate_lane_keys(keys)
	assert_array(result).is_equal(keys)

func test_validate_lane_keys_invalid_type():
	var settings = auto_free(SettingsManagerScript.new())
	var result = settings.validate_lane_keys("invalid")
	assert_array(result).is_equal(settings.default_lane_keys)

func test_validate_lane_keys_too_few():
	var settings = auto_free(SettingsManagerScript.new())
	var keys = [KEY_A, KEY_B]
	var result = settings.validate_lane_keys(keys)
	assert_array(result).is_equal(settings.default_lane_keys)

func test_validate_lane_keys_too_many():
	var settings = auto_free(SettingsManagerScript.new())
	var keys = [KEY_A, KEY_B, KEY_C, KEY_D, KEY_E, KEY_F, KEY_G]
	var result = settings.validate_lane_keys(keys)
	assert_array(result).is_equal(settings.default_lane_keys)

func test_validate_lane_keys_negative_key():
	var settings = auto_free(SettingsManagerScript.new())
	var keys = [KEY_A, -1, KEY_C, KEY_D, KEY_E]
	var result = settings.validate_lane_keys(keys)
	assert_array(result).is_equal(settings.default_lane_keys)

func test_validate_note_speed_valid():
	var settings = auto_free(SettingsManagerScript.new())
	var result = settings.validate_note_speed(25.0)
	assert_float(result).is_equal(25.0)

func test_validate_note_speed_too_low():
	var settings = auto_free(SettingsManagerScript.new())
	var result = settings.validate_note_speed(2.0)
	assert_float(result).is_equal(5.0)

func test_validate_note_speed_too_high():
	var settings = auto_free(SettingsManagerScript.new())
	var result = settings.validate_note_speed(60.0)
	assert_float(result).is_equal(50.0)

func test_validate_volume_valid():
	var settings = auto_free(SettingsManagerScript.new())
	var result = settings.validate_volume(0.8)
	assert_float(result).is_equal(0.8)

func test_validate_volume_too_low():
	var settings = auto_free(SettingsManagerScript.new())
	var result = settings.validate_volume(-0.1)
	assert_float(result).is_equal(0.0)

func test_validate_volume_too_high():
	var settings = auto_free(SettingsManagerScript.new())
	var result = settings.validate_volume(1.5)
	assert_float(result).is_equal(1.0)

func test_validate_timing_offset_valid():
	var settings = auto_free(SettingsManagerScript.new())
	var result = settings.validate_timing_offset(-100.0)
	assert_float(result).is_equal(-100.0)

func test_validate_timing_offset_too_low():
	var settings = auto_free(SettingsManagerScript.new())
	var result = settings.validate_timing_offset(-600.0)
	assert_float(result).is_equal(-500.0)

func test_validate_timing_offset_too_high():
	var settings = auto_free(SettingsManagerScript.new())
	var result = settings.validate_timing_offset(600.0)
	assert_float(result).is_equal(500.0)