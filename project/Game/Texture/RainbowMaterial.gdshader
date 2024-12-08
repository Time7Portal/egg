shader_type spatial;
render_mode unshaded;

uniform float width = 0.1;
uniform float portion = 0.0;
uniform float speed = -10.0;

// https://www.shadertoy.com/view/lsfBWs
// level is [0,5], assumed to be a whole number
vec3 rainbow(float level)
{
	/*
		Target colors
		=============
		
		L  x   color
		0  0.0 vec4(1.0, 0.0, 0.0, 1.0);
		1  0.2 vec4(1.0, 0.5, 0.0, 1.0);
		2  0.4 vec4(1.0, 1.0, 0.0, 1.0);
		3  0.6 vec4(0.0, 0.5, 0.0, 1.0);
		4  0.8 vec4(0.0, 0.0, 1.0, 1.0);
		5  1.0 vec4(0.5, 0.0, 0.5, 1.0);
	*/
	
	float r = float(level <= 2.0) + float(level > 4.0) * 0.5;
	float g = max(1.0 - abs(level - 2.0) * 0.5, 0.0);
	float b = (1.0 - (level - 4.0) * 0.5) * float(level >= 4.0);
	return vec3(r, g, b);
}

void fragment()
{
	float dist = distance(UV, vec2(0.5,0.5));
	float smooth_ring_1 = sin(dist * width + (TIME * speed));
	float smooth_ring_2 = sin(dist * (width*0.8) + (TIME * speed));
	float step_ring = step(portion, smooth_ring_1);
	float blend_alpha = smoothstep(0.5, 0.4, dist);
	if (dist > 0.5 || step_ring < 1.0)
	{
		ALPHA = 1.0;
	}
	else if (0.0 < step_ring)
	{
		ALBEDO = rainbow(smooth_ring_2 * 2.2 + 2.4);
		ALPHA = 1.0;
	}
}

