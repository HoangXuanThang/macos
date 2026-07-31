#ifdef GL_ES
precision mediump float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
uniform sampler2D u_texture;

// fhue -1~1
uniform float fhue;       //can reuse
uniform float saturation; //can reuse
uniform float brightness; //can reuse
uniform float alpha;
uniform float time;
uniform int programSwitch;

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

    float t = fhue*180.0;

    H += t;

    if( H < 0.0 )
        H += 360.0;
    else if( H > 360.0 )
        H -= 360.0;

    vec3 HSL = vec3(H,S,L);
    return HSL;
}
float getRet(float v,float p,float q)
{
    if( v < 0.0 )
        v += 1.0;
    if( v > 1.0 )
        v -= 1.0;
    if( v * 6.0  < 1.0 )
        v = p + (( q - p ) * 6.0 * v);
    else if( v * 2.0 < 1.0 )
        v = q;
    else if( v * 3.0 < 2.0 )
        v = p + ( q - p ) * (( 2.0 / 3.0 ) - v) * 6.0;
    else
        v = p;
    return v;
}
vec3 HSLtoRGB(vec3 HSL)
{
    float H = HSL.x;
    float S = HSL.y;
    float L = HSL.z;
    float R = L;
    float G = L;
    float B = L;

    if( S != 0.0 )
    {
        float q = 0.0;
        if( L < 0.5 )
            q = L * ( 1.0 + S );
        else
            q = L + ( 1.0 - L ) * S;
        float p = 2.0 * L - q;
        H /= 360.0;
        R = getRet(H + 1.0/3.0,p,q);
        G = getRet(H,p,q);
        B = getRet(H - 1.0/3.0,p,q);
    }

    vec3 RGB = vec3(R,G,B);

    float t = saturation;
    if( t > 0.0 )
    {
        if( S > 0.0 )
        {
            t = t + S >= 1.0 ? S : 1.0 - t;
            t = 1.0/t - 1.0;
        }
    }

    RGB += ( RGB - L ) * t;
    RGB.r = RGB.r > 1.0 ? 1.0 : RGB.r < 0.0 ? 0.0 : RGB.r;
    RGB.g = RGB.g > 1.0 ? 1.0 : RGB.g < 0.0 ? 0.0 : RGB.g;
    RGB.b = RGB.b > 1.0 ? 1.0 : RGB.b < 0.0 ? 0.0 : RGB.b;

    return RGB;
}

vec3 HSLtoRGBEx(vec3 HSL)
{
    float H = HSL.x;    //[0,1)
    float S = HSL.y;
    float L = HSL.z;
    float R = L;
    float G = L;
    float B = L;

    if( S != 0.0 )
    {
        float q = 0.0;
        if( L < 0.5 )
            q = L * ( 1.0 + S );
        else
            q = L + ( 1.0 - L ) * S;
        float p = 2.0 * L - q;
        R = getRet(H + 1.0/3.0,p,q);
        G = getRet(H,p,q);
        B = getRet(H - 1.0/3.0,p,q);
    }

    vec3 RGB = vec3(R,G,B);

    RGB.r = RGB.r > 1.0 ? 1.0 : RGB.r < 0.0 ? 0.0 : RGB.r;
    RGB.g = RGB.g > 1.0 ? 1.0 : RGB.g < 0.0 ? 0.0 : RGB.g;
    RGB.b = RGB.b > 1.0 ? 1.0 : RGB.b < 0.0 ? 0.0 : RGB.b;

    return RGB;
}

float luminance(vec4 color)
{
	return 0.2125 * color.r + 0.7154*color.g + 0.0721*color.b;
}

void main()
{
    vec4 color = texture2D(CC_Texture0, v_texCoord);

    vec3 rgb;

     if(programSwitch == 2 )
     {
        rgb = vec3(fhue,saturation,brightness) * alpha;
		color = vec4(color.rgb * rgb,color.a * alpha);
     }
	 else if(programSwitch == 1)
     {
        rgb = HSLtoRGBEx(vec3(fhue,saturation,brightness)) * alpha;
		color = vec4(color.rgb * rgb,color.a * alpha);
     }
	 else if(programSwitch == 3) //rgb sin曲线变换
	 {
		float ratio = (sin(CC_Time.y*4.0/time) + 1.0)/2.0;
        rgb = vec3(fhue,saturation,brightness);
		rgb = vec3((1.0-rgb.x),(1.0-rgb.y),(1.0-rgb.z))*ratio + rgb;
		color.a = color.a*ratio + color.a;
		color = vec4(color.rgb * rgb,color.a * alpha);
	 }

	gl_FragColor = color * v_fragmentColor;
    //gl_FragColor = vec4(color.rgb * rgb,color.a * alpha) * v_fragmentColor;

	/*
    if ( programIdx == 1 ) //normal
    {
        gl_FragColor = vec4(rgb,color.a) * v_fragmentColor;
    }
    else
    {
        vec4 normalColor = vec4(rgb,color.a) * v_fragmentColor;
        if ( programIdx == 2 )  //frozen
        {
            normalColor *= vec4(0.8, 1.0, 0.8, 1.0);
            normalColor.b += normalColor.a * 0.2;
            gl_FragColor = normalColor;
        }
        if ( programIdx == 3 ) //stone
        {
            float bright = (normalColor.r + normalColor.g + normalColor.b) * (1. / 3.);
            float gray = (0.6) * bright;
            gl_FragColor = vec4(gray, gray, gray, normalColor.a);
        }
        if ( programIdx == 4 ) //gray
        {
            float gray = dot(normalColor.rgb, vec3(0.299 * 0.5, 0.587 * 0.5, 0.114 * 0.5));
            gl_FragColor = normalColor* vec4(0.4, 0.4, 0.4, 1.0);
        }
    }
	*/
}