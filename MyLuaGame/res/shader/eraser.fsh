
#ifdef GL_ES
precision lowp float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
uniform float u_eraserX;
uniform float u_eraserY;

#ifdef GL_ES
uniform lowp int u_dirction;
// uniform lowp int u_remainder;
// uniform lowp int u_quotient;
#else
uniform int u_dirction;
// uniform int u_remainder;
// uniform int u_quotient;
#endif


float textureWidth = 0.0;
float textureHeight = 0.0;
// float preAimX = 0.0
// float preAimY = 0.0

void main()
{
    float bili = 0;
    float textureWidth = v_texCoord.x;
    float textureHeight = v_texCoord.y;
    float aimX = u_eraserX;
    float aimY = u_eraserY - u_eraserY * (textureWidth / aimX);
    // float index = u_quotient%2;
    float index = 0;
    // float preAimX = aimX - 0.16;
    // float preAimY = u_eraserY - u_eraserY * (textureWidth / preAimX);;
    if (index == 0)
    {
        if (textureWidth <= aimX && textureHeight <= aimY)
        {
             bili = 1;
        }
        else
        {
            bili = 0;
        }
    }
    else
    {
        if (textureWidth <= aimX && textureHeight <= aimY)
        {
            bili = 1;
        }
        else
        {
            bili = 0;
        }
    }

    vec4 color = texture2D(CC_Texture0, v_texCoord);
    gl_FragColor = v_fragmentColor*vec4(color.rgb*bili, bili);
}