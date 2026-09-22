// Manual re-tiling: add a restrained squash-and-release while Umbriel moves
// and resizes the floating window back into its layout slot.
vec4 animation(vec2 uv) {
    float p = umbriel_clamped_progress;
    float pulse = sin(3.14159265 * p);
    vec2 scale = vec2(1.0 - 0.05 * pulse, 1.0 - 0.10 * pulse);

    return umbriel_sample((uv - 0.5) / scale + 0.5);
}
