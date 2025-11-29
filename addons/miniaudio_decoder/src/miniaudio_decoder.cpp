#include "miniaudio_decoder.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/file_access.hpp>

// stb_vorbis is compiled separately to avoid Windows header conflicts
// Just include stb_vorbis.h declarations here
#define STB_VORBIS_HEADER_ONLY
#include "stb_vorbis.c"
#undef STB_VORBIS_HEADER_ONLY

#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"

using namespace godot;

MiniaudioDecoder::MiniaudioDecoder() {
    decoder = nullptr;
    is_initialized = false;
    sample_rate = 0;
    channel_count = 0;
    format_name = "unknown";
}

MiniaudioDecoder::~MiniaudioDecoder() {
    cleanup();
}

void MiniaudioDecoder::cleanup() {
    if (decoder != nullptr) {
        ma_decoder_uninit(decoder);
        memdelete(decoder);
        decoder = nullptr;
    }
    is_initialized = false;
    file_data.clear(); // Clear the file data buffer
}

PackedFloat32Array MiniaudioDecoder::extract_pcm(const String& file_path) {
    UtilityFunctions::print("=== MiniaudioDecoder::extract_pcm called for: " + file_path + " ===");
    
    PackedFloat32Array result;
    
    // Clean up any previous decoder
    cleanup();
    
    // Use Godot's FileAccess to read the entire file into memory
    // This avoids Windows Unicode path issues with miniaudio's file API
    Ref<FileAccess> file = FileAccess::open(file_path, FileAccess::READ);
    if (!file.is_valid()) {
        UtilityFunctions::push_error("Failed to open file: " + file_path);
        return result;
    }
    
    // Read entire file into buffer and store it in the class
    uint64_t file_size = file->get_length();
    file_data = file->get_buffer(file_size);
    file->close();
    
    if (file_data.size() == 0) {
        UtilityFunctions::push_error("File is empty or failed to read: " + file_path);
        return result;
    }
    
    UtilityFunctions::print("MiniaudioDecoder: Read " + String::num_int64(file_data.size()) + " bytes from file");
    
    // Get raw pointer - must use ptrw() for write access or ptr() might return null
    const uint8_t* data_ptr = file_data.ptr();
    size_t data_size = static_cast<size_t>(file_data.size());
    
    if (data_ptr == nullptr) {
        UtilityFunctions::push_error("Failed to get valid pointer from file data buffer");
        return result;
    }
    
    UtilityFunctions::print("MiniaudioDecoder: Data pointer valid, size = " + String::num_int64(data_size));
    
    // Allocate new decoder
    decoder = memnew(ma_decoder);
    
    // Initialize decoder from memory buffer using default config
    // This will auto-detect format, channels, and sample rate
    ma_decoder_config config = ma_decoder_config_init_default();
    config.format = ma_format_f32; // Request f32 output format
    
    UtilityFunctions::print("MiniaudioDecoder: Calling ma_decoder_init_memory...");
    
    ma_result init_result = ma_decoder_init_memory(
        data_ptr,
        data_size,
        &config,
        decoder
    );
    
    UtilityFunctions::print("MiniaudioDecoder: ma_decoder_init_memory returned " + String::num_int64((int64_t)init_result));
    
    if (init_result != MA_SUCCESS) {
        String error_msg = "Failed to initialize miniaudio decoder for file: " + file_path;
        error_msg += " (Error code: " + String::num_int64((int64_t)init_result) + ")";
        UtilityFunctions::push_error(error_msg);
        cleanup();
        return result;
    }
    
    is_initialized = true;
    
    // Store metadata
    sample_rate = decoder->outputSampleRate;
    channel_count = decoder->outputChannels;
    
    // Detect format
    switch (decoder->outputFormat) {
        case ma_format_f32:
            format_name = "float32";
            break;
        default:
            format_name = "unknown";
            break;
    }
    
    // Get total frame count
    ma_uint64 frame_count = 0;
    ma_result length_result = ma_decoder_get_length_in_pcm_frames(decoder, &frame_count);
    
    if (length_result != MA_SUCCESS || frame_count == 0) {
        UtilityFunctions::push_error("Failed to get frame count for file: " + file_path);
        cleanup();
        return result;
    }
    
    // Calculate total sample count (frames * channels)
    ma_uint64 total_samples = frame_count * channel_count;
    
    // Allocate buffer for all samples
    float* buffer = (float*)memalloc(total_samples * sizeof(float));
    if (buffer == nullptr) {
        UtilityFunctions::push_error("Failed to allocate memory for PCM data");
        cleanup();
        return result;
    }
    
    // Read all PCM frames
    ma_uint64 frames_read = 0;
    ma_result read_result = ma_decoder_read_pcm_frames(decoder, buffer, frame_count, &frames_read);
    
    if (read_result != MA_SUCCESS) {
        UtilityFunctions::push_error("Failed to read PCM frames from file: " + file_path);
        memfree(buffer);
        cleanup();
        return result;
    }
    
    // Convert to mono if stereo (mix channels)
    if (channel_count == 2) {
        // Resize result array for mono samples
        result.resize(frames_read);
        
        // Average left and right channels
        for (ma_uint64 i = 0; i < frames_read; i++) {
            float left = buffer[i * 2];
            float right = buffer[i * 2 + 1];
            result[i] = (left + right) * 0.5f;
        }
    } else {
        // Already mono, copy directly
        result.resize(frames_read);
        for (ma_uint64 i = 0; i < frames_read; i++) {
            result[i] = buffer[i];
        }
    }
    
    // Clean up
    memfree(buffer);
    cleanup();
    
    UtilityFunctions::print("Decoded ", frames_read, " frames (", result.size(), " mono samples) from ", file_path);
    
    return result;
}

int MiniaudioDecoder::get_sample_rate() const {
    return sample_rate;
}

int MiniaudioDecoder::get_channel_count() const {
    return channel_count;
}

String MiniaudioDecoder::get_format() const {
    return format_name;
}

void MiniaudioDecoder::_bind_methods() {
    ClassDB::bind_method(D_METHOD("extract_pcm", "file_path"), &MiniaudioDecoder::extract_pcm);
    ClassDB::bind_method(D_METHOD("get_sample_rate"), &MiniaudioDecoder::get_sample_rate);
    ClassDB::bind_method(D_METHOD("get_channel_count"), &MiniaudioDecoder::get_channel_count);
    ClassDB::bind_method(D_METHOD("get_format"), &MiniaudioDecoder::get_format);
}
