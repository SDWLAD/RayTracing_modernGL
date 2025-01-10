#version 130

uniform vec2 resolution;
uniform vec3 cam_pos;
uniform vec3 cam_rot;
uniform vec2 u_seed1;
uniform vec2 u_seed2;

uniform sampler2D sample;
uniform float sample_part;

void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

#define MAX_DISTANCE 999.0
#define EPSILON 0.001

struct Ray {
    vec3 origin;
    vec3 direction;
};

struct Material {
    vec3 color;
    int type;
    float strenght;
};

struct Shape {
    vec3 position;
    vec3 size;
    Material material;
    int type;
};

const int SHAPE_COUNT = 5;
uniform Shape shapes[SHAPE_COUNT];


struct Hit {
    float distanceNear;
    float distanceFar;
    vec3 normal;
    Material material;
};

Hit noHit = Hit(-1.0, -1.0, vec3(0.0), Material(vec3(0.0), 0, 0.0));

uvec4 R_STATE;

uint TausStep(uint z, int S1, int S2, int S3, uint M)
{
    uint b = (((z << S1) ^ z) >> S2);
    return (((z & M) << S3) ^ b);   
}

uint LCGStep(uint z, uint A, uint C)
{
    return (A * z + C); 
}

vec2 hash22(vec2 p)
{
    p += u_seed1.x;
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

float random()
{
    R_STATE.x = TausStep(R_STATE.x, 13, 19, 12, uint(4294967294));
    R_STATE.y = TausStep(R_STATE.y, 2, 25, 4, uint(4294967288));
    R_STATE.z = TausStep(R_STATE.z, 3, 11, 17, uint(4294967280));
    R_STATE.w = LCGStep (R_STATE.w, uint(1664525), uint(1013904223));
    return 2.3283064365387e-10 * float((R_STATE.x ^ R_STATE.y ^ R_STATE.z ^ R_STATE.w));
}

vec3 randomOnSphere() {
    vec3 rand = vec3(random(), random(), random());
    float theta = rand.x * 2.0 * 3.14159265;
    float v = rand.y;
    float phi = acos(2.0 * v - 1.0);
    float r = pow(rand.z, 1.0 / 3.0);
    float x = r * sin(phi) * cos(theta);
    float y = r * sin(phi) * sin(theta);
    float z = r * cos(phi);
    return vec3(x, y, z);
}


Hit SphereCast(Ray ray, Shape sphere) {
    vec3 oc = ray.origin - sphere.position;
    float b = dot(oc, ray.direction);
    float c = dot(oc, oc) - sphere.size.x*sphere.size.x;
    float h = b*b - c;
    if(h<0.0) return noHit;
    h = sqrt(h);
    return Hit(-b-h, -b+h, normalize((ray.origin-sphere.position) + ray.direction * (-b-h)), sphere.material);
}

Hit BoxCast(Ray ray, Shape box) {
    vec3 m = 1.0/ray.direction;
    vec3 n = m*(ray.origin - box.position);
    vec3 k = abs(m)*box.size;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max(max(t1.x, t1.y), t1.z);
    float tF = min(min(t2.x, t2.y), t2.z);
    if(tN>tF || tF<0.0) return noHit;
    vec3 outNormal = sign(ray.direction) * step(t1.yzx, t1.xyz) * step(t1.zxy, t1.xyz);
    return Hit(tN, tF, outNormal, box.material);
}

Hit PlaneCast(Ray ray, Shape plane) {
    return Hit(-(dot(ray.origin,vec3(0, 1, 0))-plane.position.y)/dot(ray.direction,vec3(0, 1, 0)), 0.0, vec3(0, 1, 0), plane.material);
}

Hit ShapeCast(Ray ray, Shape shape) {
    if(shape.type == 0) return SphereCast(ray, shape);
    if(shape.type == 1) return BoxCast(ray, shape);
    if(shape.type == 2) return PlaneCast(ray, shape);
    return noHit;
}

vec3 getSky(vec3 rd){
    return vec3(0.5,0.5,0.5);
}

Hit RayCast(inout Ray ray) {
    Hit minHit = Hit(MAX_DISTANCE, MAX_DISTANCE, vec3(0.0), Material(vec3(0.0), 0, 0.0));

    for (int i = 0; i < SHAPE_COUNT; i++) {
        Shape shape = shapes[i];
        Hit hit = ShapeCast(ray, shape);
        if(hit.distanceNear > 0.0 && hit.distanceNear < minHit.distanceNear) {
            minHit = hit;
        }
    }

    if (minHit.material.type == 0){
        ray.origin += ray.direction * (minHit.distanceNear - EPSILON);
        vec3 reflected = reflect(ray.direction, minHit.normal);
        vec3 r = randomOnSphere();
        vec3 diffuse = r;
        ray.direction = mix(reflected, diffuse, minHit.material.strenght);
    }
    else if (minHit.material.type == 1){
        float fresnel = 1.0 - abs(dot(-ray.direction, minHit.normal));
		if(random() - 0.1 < fresnel * fresnel) {
			ray.direction = reflect(ray.direction, minHit.normal);
			return minHit;
		}
        ray.origin += ray.direction * (minHit.distanceFar + EPSILON);
        ray.direction = refract(ray.direction, minHit.normal, 1.0 / (1.0 - minHit.material.strenght));
    }
    else if (minHit.material.type == 2){
        return minHit;
    }

    return minHit;
}

vec3 RayTrace(Ray ray){
    vec3 col = vec3(1.0);
    for(int i = 0; i < 100; i++)
    {
        Hit refCol = RayCast(ray);
        if(refCol.distanceNear == MAX_DISTANCE) return col * getSky(ray.direction);
        if(refCol.material.type == 2) return refCol.material.color;
        col *= refCol.material.color;
    }
    return col;
}

vec3 Render(vec2 uv) {
    Ray ray = Ray(vec3(cam_pos), normalize(vec3(uv, 1.0)));

    pR(ray.direction.yz, cam_rot.x);
    pR(ray.direction.xz, cam_rot.y);


    vec3 color = RayTrace(ray);

    return color;
}

void main(){
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec2 uvRes = hash22(uv + 1.0) * resolution + resolution;
	R_STATE.x = uint(u_seed1.x + uvRes.x);
	R_STATE.y = uint(u_seed1.y + uvRes.x);
	R_STATE.z = uint(u_seed2.x + uvRes.y);
	R_STATE.w = uint(u_seed2.y + uvRes.y);

    vec3 color = Render(uv);

	vec3 sampleColor = texture(sample, gl_FragCoord.xy).rgb;
	color = mix(sampleColor, color, sample_part);

    gl_FragColor = vec4(pow(color, vec3(0.4545)), 1);
}