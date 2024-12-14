#version 330 core

uniform vec2 resolution;

struct Ray {
    vec3 origin;
    vec3 direction;
};

struct Shape {
    vec3 position;
    vec3 size;
    int type;
};

struct Hit {
    float distanceNear;
    float distanceFar;
};

Hit SphereCast(Ray ray, Shape sphere) {
    vec3 oc = ray.origin - sphere.position;
    float b = dot(oc, ray.direction);
    float c = dot(oc, oc) - sphere.size.x*sphere.size.x;
    float h = b*b - c;
    if(h<0.0) return Hit(-1.0, -1.0);
    h = sqrt(h);
    return Hit(-b-h, -b+h);
}

vec3 RayCast(Ray ray) {
    Shape sphere = Shape(vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0), 0);
    Hit hit = SphereCast(ray, sphere);
    if(hit.distanceNear != -1.0) {
        return vec3(1.0);
    }
    else {
        return vec3(0.0);
    }
}

vec3 Render(vec2 uv) {
    Ray ray = Ray(vec3(0.0, 0.0, -5), normalize(vec3(uv, 1.0)));

    vec3 color = RayCast(ray);

    return color;
}

void main(){
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;

    vec3 color = Render(uv);

    gl_FragColor = vec4(pow(color, vec3(0.4545)), 1);
}
