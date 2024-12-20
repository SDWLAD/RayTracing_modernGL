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

struct Shape {
    vec3 position;
    vec3 size;
    int type;
};

const int SHAPE_COUNT = 3;
uniform Shape shapes[SHAPE_COUNT];

struct Hit {
    float distanceNear;
    float distanceFar;
    vec3 normal;
};

Hit SphereCast(Ray ray, Shape sphere) {
    vec3 oc = ray.origin - sphere.position;
    float b = dot(oc, ray.direction);
    float c = dot(oc, oc) - sphere.size.x*sphere.size.x;
    float h = b*b - c;
    if(h<0.0) return Hit(-1.0, -1.0, vec3(0.0));
    h = sqrt(h);
    return Hit(-b-h, -b+h, normalize(sphere.position - (ray.origin + ray.direction*(-b-h))));
}

Hit BoxCast(Ray ray, Shape box) {
    vec3 m = 1.0/ray.direction;
    vec3 n = m*(ray.origin - box.position);
    vec3 k = abs(m)*box.size;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max(max(t1.x, t1.y), t1.z);
    float tF = min(min(t2.x, t2.y), t2.z);
    if(tN>tF || tF<0.0) return Hit(-1.0, -1.0, vec3(0.0));
    vec3 outNormal = sign(ray.direction) * step(t1.yzx, t1.xyz) * step(t1.zxy, t1.xyz);
    return Hit(tN, tF, outNormal);
}

Hit PlaneCast(Ray ray, Shape plane) {
    return Hit(-(dot(ray.origin,vec3(0, 1, 0))-plane.position.y)/dot(ray.direction,vec3(0, 1, 0)), 0.0, vec3(0, 1, 0));
}

Hit ShapeCast(Ray ray, Shape shape) {
    if(shape.type == 0) return SphereCast(ray, shape);
    if(shape.type == 1) return BoxCast(ray, shape);
    if(shape.type == 2) return PlaneCast(ray, shape);
    return Hit(-1.0, -1.0, vec3(0.0));
}

vec3 GetLight(Ray ray, Hit hit) {
    vec3 lightDirection = normalize(vec3(0.6, -1.0, 0.4));

    float diffuce = dot(hit.normal, lightDirection);

    return vec3(diffuce);
}
vec3 getSky(vec3 rd){
    vec2 uv = vec2(atan(rd.x, rd.z), asin(-rd.y)*2.)/3.14159265;
    uv = uv*0.5-0.5;
    vec3 col = texture2D(skyTexture, uv).rgb;
    return col;
}

Hit RayCast(inout Ray ray) {
    Hit minHit = Hit(MAX_DISTANCE, -1.0, vec3(0.0));

    for (int i = 0; i < SHAPE_COUNT; i++) {
        Shape shape = shapes[i];
        Hit hit = ShapeCast(ray, shape);
        if(hit.distanceNear > 0.0 && hit.distanceNear < minHit.distanceNear) {
            minHit = hit;
        }
    }

    ray.origin += ray.direction * (minHit.distanceNear - EPSILON);
    ray.direction = reflect(ray.direction, minHit.normal);

    return minHit;
}

vec3 RayTrace(Ray ray){
    vec3 col = vec3(1.0);
    for(int i = 0; i < 100; i++)
    {
        Hit refCol = RayCast(ray);
        if(refCol.distanceNear == MAX_DISTANCE) return col * getSky(ray.direction);
        col *= vec3(1.0);
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
