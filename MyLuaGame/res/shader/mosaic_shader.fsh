#ifdef GL_ES
precision mediump float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
uniform sampler2D u_texture;

#ifdef GL_ES
uniform lowp float mosaicSizeX;
uniform lowp float mosaicSizeY;
#else
uniform float mosaicSizeX;
uniform float mosaicSizeY;
#endif

// void main()
// {
//     vec2 intXY = vec2(v_texCoord.x*TexSizeX, v_texCoord.y*TexSizeY);
//     vec2 XYMosaic = vec2(int(intXY.x/mosaicSizeX)*mosaicSizeX, int(intXY.y/mosaicSizeY)*mosaicSizeY);
//     vec2 UVMosaic = vec2(XYMosaic.x/TexSizeX, XYMosaic.y/TexSizeY);

//     gl_FragColor = texture2D(CC_Texture0, UVMosaic);
// }

vec2 getUvMapPos() {
	// 计算x轴格子宽度
	float xCount;
	if (mosaicSizeX <= 0.0) {
		xCount = 1.0;
	} else {
		xCount = mosaicSizeX;
	}
	float blockWidth = 1.0 / xCount;
	// 计算当前 v_texCoord 在x轴的哪个格子上
	float blockXIndex = floor(v_texCoord.x / blockWidth);
	// 同理，求出当前 v_texCoord 在y轴上的哪个格子
	float yCount;
	if (mosaicSizeY <= 0.0) {
		yCount = 1.0;
	} else {
		yCount = mosaicSizeY;
	}
	float blockHeight = 1.0 / yCount;
	float blockYIndex = floor(v_texCoord.y / blockHeight);
	// 找到该格子的中心点实际对应的uv坐标
	return vec2(blockWidth * (blockXIndex + 0.5), blockHeight * (blockYIndex + 0.5));
}

void main() {
	vec4 srcColor = texture2D(CC_Texture0, v_texCoord);
    vec2 pos = getUvMapPos();
	gl_FragColor = texture2D(CC_Texture0, pos);
}
