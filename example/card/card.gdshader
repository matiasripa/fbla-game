shader_type canvas_item;
render_mode blend_premul_alpha;

uniform float Line_Smoothness : hint_range(0, 0.1) = 0.045;
uniform float Line_Width : hint_range(0, 0.2) = 0.09;
uniform float Brightness = 3.0;
uniform float Rotation_deg : hint_range(-90, 90) = 30;
uniform float Distortion : hint_range(1, 2) = 1.8;
uniform float Speed = 0.7;
uniform float Position : hint_range(0, 1) = 0;
uniform float Position_Min = 0.25;
uniform float Position_Max = 0.5;
uniform float Alpha : hint_range(0, 1) = 1;
uniform float is_clicked : hint_range(0, 1) = 0.0; // New uniform to control when effect is active

void fragment() {
    // Get the original texture color
    vec4 tex_color = texture(TEXTURE, UV);

    // Only apply effect if the card is clicked
    if (is_clicked > 0.5) {
        // Calculate center and gradient towards edges
        vec2 center_uv = UV - vec2(0.5, 0.5);
        float gradient_to_edge = max(abs(center_uv.x), abs(center_uv.y));
        gradient_to_edge = gradient_to_edge * Distortion;
        gradient_to_edge = 1.0 - gradient_to_edge;

        // Apply rotation based on Rotation_deg
        float rotation_radians = radians(Rotation_deg);
        mat2 rotation_matrix = mat2(vec2(cos(rotation_radians), sin(rotation_radians)),
                                    vec2(-sin(rotation_radians), cos(rotation_radians)));
        vec2 rotated_uv = rotation_matrix * center_uv;

        // Remap position for dynamic effect
        float output_range = Position_Max - Position_Min;
        float remapped_position = Position_Min + output_range * Position;

        // Animate the texture offset over time
        float remapped_time = fract(TIME * Speed + remapped_position);
        remapped_time = -2.0 + 4.0 * remapped_time;

        // Calculate offset UV and line effect
        vec2 offset_uv = rotated_uv + vec2(remapped_time, 0.0);
        float line = abs(offset_uv.x);
        line = gradient_to_edge * line;
        line = sqrt(line);

        // Adjust line width and smoothness
        float line_smoothness = clamp(Line_Smoothness, 0.001, 1.0);
        float offset_plus = Line_Width + line_smoothness;
        float offset_minus = Line_Width - line_smoothness;

        // Remap the line effect for highlight
        float remapped_line = (line - offset_plus) / (offset_minus - offset_plus);
        remapped_line = clamp(remapped_line, 0.0, 1.0);

        // Apply the highlight effect to the texture
        tex_color.rgb += vec3(remapped_line) * Brightness;
    }

    // Keep the original alpha channel intact
    tex_color.a *= Alpha;

    // Output the final color
    COLOR = tex_color;
}