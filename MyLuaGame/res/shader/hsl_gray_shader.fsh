#ifdef GL_ES
precision mediump float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
uniform sampler2D u_texture;

// fhue -1~1
//uniform float fhue;
//uniform float saturation;
//uniform float brightness;
//uniform int programIdx;

float MinRGB(vec3 rgba)
{
    float t = (rgba.x < rgba.y) ? rgba.x : rgba.y;
    t = ( t < rgba.z) ? t : rgba.z;
    return t;
}

float MaxRGB(vec3 rgba)
{
    float t = (rgba.x > rgba.y) ? rgba.x : rgba.y;
    t = ( t > rgba.z) ? t : rgba.z;
    return t;
}

vec3 RGBtoHSL(vec3 rgb)
{
    float Max = MaxRGB(rgb);
    float Min = MinRGB(rgb);

    float sum = Max + Min;
    float L = sum / 2.0;
    float H = 0.0;
    float S = 0.0;

    return vec3(H,S,L);
}

vec3 HSLtoRGB(vec3 HSL)
{
    float L = HSL.z;
    float R = L;
    float G = L;
    float B = L;

    vec3 RGB = vec3(R,G,B);
    RGB.r = R > 1.0 ? 1.0 : R < 0.0 ? 0.0 : R;
    RGB.g = G > 1.0 ? 1.0 : G < 0.0 ? 0.0 : G;
    RGB.b = B > 1.0 ? 1.0 : B < 0.0 ? 0.0 : B;

    return RGB;
}

void main()
{
    vec4 color = texture2D(CC_Texture0, v_texCoord) * v_fragmentColor;
    vec3 hsl = RGBtoHSL(color.rgb);
    vec3 rgb = HSLtoRGB(hsl);

    float brightness = -0.15;
    if (brightness > 0.0)
        rgb = rgb + (1.0 - rgb) * brightness;
    else
        rgb = rgb + rgb * brightness;
    rgb = rgb * color.a;

    gl_FragColor = vec4(rgb, color.a);
}