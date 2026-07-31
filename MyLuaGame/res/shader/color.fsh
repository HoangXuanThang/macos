varying vec2 v_texCoord;
uniform vec3 color;       //can reuse

void main() {
	vec4 tex = texture2D(CC_Texture0, v_texCoord);
	gl_FragColor = vec4(tex.a * color, tex.a);
}