#version 330 core

uniform vec2 resolution;

void main(){
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    gl_FragColor = vec4(uv, 0, 1);
}
