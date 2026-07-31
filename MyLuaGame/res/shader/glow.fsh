varying vec4 v_fragmentColor;
varying vec2 v_texCoord;


void main()
{
    float u_gtime = 2.0;
    vec4 u_color = vec4(1.0, 1.0, 1.0, 1.0);
    float radius = 10.0;
    float u_ctime = mod(CC_Time.y, u_gtime);
    
    vec4 accum = vec4(0.0);
    vec4 normal = vec4(0.0);
    
    //normal = texture2D(CC_Texture0, vec2(v_texCoord.x, v_texCoord.y));
    normal = texture2D(CC_Texture0, v_texCoord);
    
    for(float i = 1.0; i <= radius; i += 1.0)
    {
        accum += texture2D(CC_Texture0, vec2(v_texCoord.x - 0.01 * i, v_texCoord.y - 0.01 * i));
        accum += texture2D(CC_Texture0, vec2(v_texCoord.x + 0.01 * i, v_texCoord.y - 0.01 * i));
        accum += texture2D(CC_Texture0, vec2(v_texCoord.x + 0.01 * i, v_texCoord.y + 0.01 * i));
        accum += texture2D(CC_Texture0, vec2(v_texCoord.x - 0.01 * i, v_texCoord.y + 0.01 * i));
    }
    
    accum.rgb =  u_color.rgb * u_color.a * accum.a * 0.95;
    float opacity = ((1.0 - normal.a) / radius) * (u_ctime / u_gtime);
    
    normal = (accum * opacity) + (normal * normal.a);
    
    gl_FragColor = v_fragmentColor * normal;
}