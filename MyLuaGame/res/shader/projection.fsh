varying vec2 v_texCoord;
 
vec4 composite(vec4 over, vec4 under)
{
	return over + (1 - over.a)*under;
}
void main(){
	vec2 shadowOffset =vec2(-0.05, -0.05);
	vec4 textureColor = texture2D(CC_Texture0,v_texCoord );
	float shadowMask = texture2D(CC_Texture0,v_texCoord + shadowOffset).a;
	const float shadowOpacity = 0.5;
	vec4 shadowColor = vec4(1*shadowMask, 0, 0.349*shadowMask,shadowMask*shadowOpacity);
	gl_FragColor = composite(textureColor,shadowColor);
}