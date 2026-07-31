varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

uniform float u_stime;

float easeOutCubic(float t, float b, float c, float d) {
	t /= d;
	t--;
	return c*(t*t*t + 1.0) + b;
}

void main() {
	vec4 tex = texture2D(CC_Texture0, v_texCoord);
	float u_gtime = 1.0;
	float u_basealpha = 0.6;
	
	float progress = easeOutCubic(mod(CC_Time.y - u_stime, u_gtime), -2.0, 3.0, u_gtime);
	vec4 col = tex * v_fragmentColor;
	col.a *= progress * (1.0 - u_basealpha) + u_basealpha;
	gl_FragColor = col + tex.a * v_fragmentColor * u_basealpha * (1.0 - progress);
}