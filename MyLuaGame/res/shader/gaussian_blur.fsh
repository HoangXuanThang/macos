#ifdef GL_ES
precision mediump float;
#endif
uniform vec3 iResolution;
varying vec2 v_texCoord;


float GetGaussWeight(float x, float y, float sigma)
{
  float sigma2 = pow(sigma, 2.0);
  float left = 1.0 / (2.0 * sigma2 * 3.1415926);
  float right = exp(-(x*x+y*y)/(2.0*sigma2));
  return left * right;
}

vec4 GaussBlur(vec2 resolution)
{
  //因为高斯函数中3σ以外的点的权重已经很小了，因此σ取半径r/3的值
  float _BlurRadius = 5.0;
  float sigma = _BlurRadius / 3.0;
  vec4 col = vec4(0.0);
  for (float x = - _BlurRadius; x <= _BlurRadius; ++x)
  {
    for (float y = - _BlurRadius; y <= _BlurRadius; ++y)
    {
      //获取周围像素的颜色
      //因为uv是0-1的一个值，而像素坐标是整形，我们要取材质对应位置上的颜色，需要将整形的像素坐标
      //转为uv上的坐标值
      vec4 color = texture2D(CC_Texture0, v_texCoord + vec2(x / resolution.x, y / resolution.y));
      //获取此像素的权重
      float weight = GetGaussWeight(x, y, sigma);
      //计算此点的最终颜色
      col += color * weight;

    }
  }
  return col;
}


void main() {
  gl_FragColor = GaussBlur(iResolution.xy);
}

