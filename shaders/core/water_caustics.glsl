float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

vec3 calculateWaterCaustics(vec3 uv, vec3 waterColor, float time) {
    // TODO: something more fancy than some stupid boxes
    float d = smoothstep(0.0, 0.05, sdBox(mod(uv - time * 0.05, 0.3) - 0.15, vec3(0.1)));
    vec3 col = mix(waterColor * 0.5, pow(waterColor, vec3(0.99)), d);

    return col;
}