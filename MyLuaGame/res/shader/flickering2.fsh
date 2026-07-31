varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

float easeOutCubic(float t, float b, float c, float d) {
	t /= d;
	t--;
	return c*(t*t*t + 1.0) + b;
}

void main() {
	vec4 tex = texture2D(CC_Texture0, v_texCoord);
	vec4 u_color = vec4(1.0, 1.0, 1.0, 1.0);
	float u_gtime = 4.0;
	float progress = easeOutCubic(mod(CC_Time.y, u_gtime), -2.0, 3.0, u_gtime);
	progress += v_texCoord.y;
	
	float diff = 1.0 - v_texCoord.x - progress;
	if (diff <= 0.8 && diff > 0.0) {
		diff = (0.4 - diff) * 2.0;
		if(diff < 0.){
			diff = -diff;
		}
		diff = 0.8 - diff;
		tex = tex + (u_color * diff) * tex.a * u_color.a;
	}
	gl_FragColor = tex * v_fragmentColor;
}