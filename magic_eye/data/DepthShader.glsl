void main(void){
	float depth = gl_FragCoord.z;
	float intensity = 1.0 - depth;
	gl_FragCoord = vec4(intensity, intensity, intensity, 1.0);
}