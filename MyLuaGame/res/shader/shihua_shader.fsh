#ifdef GL_ES
precision mediump float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
uniform sampler2D u_texture;

uniform vec2  samp;
uniform float brightness;

void main()
{
    vec4 color = texture2D(CC_Texture0, v_texCoord);

    vec3 rgb;

    vec4 color1 = texture2D(u_texture, fract(vec2(v_texCoord.x*samp.x,v_texCoord.y*samp.y)));
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    color.rgb = vec3(gray, gray, gray);
    color.rgb *= color1.rgb * brightness;
    
	gl_FragColor = color * v_fragmentColor;
}