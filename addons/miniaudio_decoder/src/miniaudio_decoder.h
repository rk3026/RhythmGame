#ifndef MINIAUDIO_DECODER_H
#define MINIAUDIO_DECODER_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/string.hpp>

// Forward declare miniaudio structures to avoid including in header
struct ma_decoder;

namespace godot {

class MiniaudioDecoder : public RefCounted {
    GDCLASS(MiniaudioDecoder, RefCounted)

private:
    ma_decoder* decoder;
    bool is_initialized;
    int sample_rate;
    int channel_count;
    String format_name;
    PackedByteArray file_data; // Keep file data alive for memory decoder
    
    void cleanup();

protected:
    static void _bind_methods();

public:
    MiniaudioDecoder();
    ~MiniaudioDecoder();

    // Main API - extract all PCM samples from file
    PackedFloat32Array extract_pcm(const String& file_path);
    
    // Metadata accessors
    int get_sample_rate() const;
    int get_channel_count() const;
    String get_format() const;
};

}

#endif // MINIAUDIO_DECODER_H
