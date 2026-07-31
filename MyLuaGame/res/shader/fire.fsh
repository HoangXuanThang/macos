varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

void main(void)
{
    vec4 u_color = vec4(1, 0.1, 0.1, 0.3);
    float radius = 1.0;
    float step = 0.002;
    float u_gtime = 2.0;
    float u_ctime = mod(CC_Time.y, u_gtime);
    
    vec4 accum = vec4(0.0);
    vec4 old = texture2D(CC_Texture0, v_texCoord) * v_fragmentColor;

    for(float i = 1.0; i <= radius; i += 0.5)
    {
        accum += texture2D(CC_Texture0, vec2(v_texCoord.x - step * i, v_texCoord.y - step * i));
        accum += texture2D(CC_Texture0, vec2(v_texCoord.x + step * i, v_texCoord.y - step * i));
        accum += texture2D(CC_Texture0, vec2(v_texCoord.x + step * i, v_texCoord.y + step * i));
        accum += texture2D(CC_Texture0, vec2(v_texCoord.x - step * i, v_texCoord.y + step * i));
    }
    accum.rgb = u_color.rgb * u_color.a * accum.a * 0.95;
    float opacity = clamp(abs(u_ctime / u_gtime - 0.5), 0.4, 0.8);

    vec4 normal = (accum * opacity) + old;

    if (old.a <= 0.0)
    {
        normal = old;
    }
    else
    {
        normal.a = old.a;
    }
    gl_FragColor = normal;
}