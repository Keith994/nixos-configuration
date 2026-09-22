// Manual floating: appear from a random point around the screen centre, then
// settle into the compositor-owned final position. The temporary config used by
// scripts/float.sh makes this shader active only for the Mod+F float transition.
vec4 animation(vec2 uv) {
    float p = umbriel_clamped_progress;
    float remaining = 1.0 - p;

    // float.sh sizes the window to 60% of the usable output. At the beginning,
    // ±20%/±15% of that window is roughly ±12%/±9% of the screen. Starting at
    // 60% scale keeps the translated presentation inside its shader target.
    vec2 random_direction = umbriel_random_seed.xy * 2.0 - 1.0;
    vec2 offset = random_direction * vec2(0.20, 0.15) * remaining;
    float scale = mix(0.60, 1.0, p);
    vec2 sample_uv = (uv - 0.5 - offset) / scale + 0.5;

    return umbriel_sample(sample_uv);
}
