// Window closing: rotate around the bottom centre, fall, and fade away.
// Umbriel supplies main(), precision, uniforms, and umbriel_sample().
vec4 animation(vec2 uv) {
    float progress = umbriel_clamped_progress;
    float fall_progress = progress * progress;

    vec2 coords = (uv - vec2(0.5, 1.0)) * umbriel_size;
    coords.y -= fall_progress * 1440.0;

    float random_angle = (umbriel_random_seed.x - 0.5) / 2.0;
    random_angle = sign(random_angle) - random_angle;
    float angle = fall_progress * 0.5 * random_angle;

    mat2 rotation = mat2(
        cos(angle), -sin(angle),
        sin(angle),  cos(angle)
    );

    coords = rotation * coords;
    vec2 sample_uv = coords / umbriel_size + vec2(0.5, 1.0);

    // Umbriel expects premultiplied RGBA, so fade every channel together.
    return umbriel_sample(sample_uv) * (1.0 - fall_progress);
}
