// Window opening: settle downward into place with a subtle scale and fade.
// Umbriel supplies main(), precision, uniforms, and umbriel_sample().
vec4 animation(vec2 uv) {
    float progress = umbriel_clamped_progress;

    // Sample above the target so the window appears 60 px lower at the start.
    float slide = (1.0 - progress) * 60.0 / max(umbriel_size.y, 1.0);
    float scale = 0.985 + 0.015 * progress;

    vec2 sample_uv = (uv - 0.5) / scale + 0.5;
    sample_uv.y -= slide;

    // Umbriel expects premultiplied RGBA, so fade every channel together.
    return umbriel_sample(sample_uv) * progress;
}
