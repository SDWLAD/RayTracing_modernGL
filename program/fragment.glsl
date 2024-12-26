#version 330 core

uniform vec2 resolution;
uniform vec3 cam_pos;
uniform vec3 cam_rot;
uniform sampler2D skyTexture;

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

Hit noHit = Hit(-1.0, -1.0, vec3(0.0), Material(vec3(0.0), 0));

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
    vec2 uv = vec2(atan(rd.x, rd.z), asin(-rd.y)*2.)/3.14159265;
    uv = uv*0.5-0.5;
    vec3 col = texture2D(skyTexture, uv).rgb;
    return col;
}

Hit RayCast(inout Ray ray) {
    Hit minHit = Hit(MAX_DISTANCE, MAX_DISTANCE, vec3(0.0), Material(vec3(0.0), 0));

    for (int i = 0; i < SHAPE_COUNT; i++) {
        Shape shape = shapes[i];
        Hit hit = ShapeCast(ray, shape);
        if(hit.distanceNear > 0.0 && hit.distanceNear < minHit.distanceNear) {
            minHit = hit;
        }
    }

    if (minHit.material.type == 0){
        ray.origin += ray.direction * (minHit.distanceNear - EPSILON);
        ray.direction = reflect(ray.direction, minHit.normal);
    }
    else if (minHit.material.type == 1){
		ray.origin += ray.direction * (minHit.distanceFar + EPSILON);
        ray.direction = refract(ray.direction, minHit.normal, 1.0 / (1.4));
    }

    return minHit;
}

vec3 RayTrace(Ray ray){
    vec3 col = vec3(1.0);
    for(int i = 0; i < 100; i++)
    {
        Hit refCol = RayCast(ray);
        if(refCol.distanceNear == MAX_DISTANCE) return col * getSky(ray.direction);
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

    vec3 color = Render(uv);

    gl_FragColor = vec4(pow(color, vec3(0.4545)), 1);
}