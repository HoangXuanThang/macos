
#ifdef GL_ES
precision lowp float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

void main()
{
    vec4 color = texture2D(CC_Texture0, v_texCoord);
    vec4 color2 = texture2D(CC_Texture1, v_texCoord);
    gl_FragColor = color * (1. - color2.a);
}