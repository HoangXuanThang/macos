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

    if( Max != Min )
    {
        float delta = Max - Min;
        if( L < 0.5 )
            S = delta / sum;
        else
            S = delta / ( 2.0 - sum);

        if( rgb.r == Max )
            H = ( rgb.g - rgb.b ) / delta;
        else if( rgb.g == Max )
            H = 2.0 + ( rgb.b - rgb.r ) / delta;
        else
            H = 4.0 + ( rgb.r - rgb.g ) / delta;
    }

    H *= 60.0;

    //float t = fhue*180.0;
    float t = 0.0;

    H += t;

    if( H < 0.0 )
        H += 360.0;
    else if( H > 360.0 )
        H -= 360.0;

    vec3 HSL = vec3(H,S,L);
    return HSL;
}
vec3 HSLtoRGB(vec3 HSL)
{
    float L = HSL.z;
    float R = L;
    float G = L;
    float B = L;


    vec3 RGB = vec3(R,G,B);

    RGB.r = RGB.r > 1.0 ? 1.0 : RGB.r < 0.0 ? 0.0 : RGB.r;
    RGB.g = RGB.g > 1.0 ? 1.0 : RGB.g < 0.0 ? 0.0 : RGB.g;
    RGB.b = RGB.b > 1.0 ? 1.0 : RGB.b < 0.0 ? 0.0 : RGB.b;

    return RGB;
}

void main()
{
    vec4 color = texture2D(CC_Texture0, v_texCoord);
    vec3 hsl = RGBtoHSL(color.rgb);
    vec3 rgb = HSLtoRGB(hsl);

    float brightness = 0.12;
    if( brightness > 0.0 )
        rgb = rgb + ( 1.0 - rgb ) * brightness;
    else
        rgb = rgb + rgb * brightness;
    rgb = rgb * color.a;

    gl_FragColor = vec4(rgb, color.a) * v_fragmentColor;
}