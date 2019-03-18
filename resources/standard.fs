#version 100

//#version 330

precision lowp float;

const int maxLights = 1;
const vec3 viewDir = vec3(1.0);

varying vec3 fragPosition;
varying vec2 fragTexCoord;
varying vec4 fragColor;
varying vec3 fragNormal;

uniform sampler2D texture0;
uniform sampler2D texture1;
uniform sampler2D texture2;

//uniform vec4 colAmbient;
const vec4 colAmbient = vec4(0.125, 0.125, 0.125, 1.0);
uniform vec4 colDiffuse;
uniform vec4 colSpecular;
uniform float glossiness;

uniform int useNormal;
uniform int useSpecular;

uniform mat4 mvp;
uniform mat4 projection;
uniform mat4 view;

struct Light {
    int enabled;
    int type;
    vec3 position;
    vec3 direction;
    vec4 diffuse;
    float intensity;
    float radius;
    float coneAngle;
};
uniform Light lights0;


vec3 ComputeLightPoint(Light l, vec3 n, vec3 v, float s)
{
    vec3 surfacePos = vec3(mvp*vec4(fragPosition, 1.0));
    vec3 surfaceToLight = l.position - surfacePos;
    
    // Diffuse shading
    float brightness = clamp(float(dot(n, surfaceToLight)/(length(surfaceToLight)*length(n))), 0.0, 1.0);
    float diff = 1.0/dot(surfaceToLight/l.radius, surfaceToLight/l.radius)*brightness*l.intensity;

    //// Specular shading
    float spec = 0.0;
    if (diff > 0.0)
    {

    //return vec3(0.0, 1.0, 0.1);

        vec3 h = normalize(-l.direction + v);
        spec = pow(abs(dot(n, h)), 3.0 + glossiness)*s;
    }

    //return vec3(1.0, 0.1, 0.1);
    
    return (diff*l.diffuse.rgb + spec*colSpecular.rgb);
}

vec3 ComputeLightDirectional(Light l, vec3 n, vec3 v, float s)
{
    vec3 lightDir = normalize(-l.direction);
    
    // Diffuse shading
    float diff = clamp(float(dot(n, lightDir)), 0.0, 1.0)*l.intensity;
    
    // Specular shading
    float spec = 0.0;
    if (diff > 0.0)
    {
        vec3 h = normalize(lightDir + v);
        spec = pow(abs(dot(n, h)), 3.0 + glossiness)*s;
    }
    
    // Combine results
    return (diff*l.intensity*l.diffuse.rgb + spec*colSpecular.rgb);
}

vec3 ComputeLightSpot(Light l, vec3 n, vec3 v, float s)
{
    vec3 surfacePos = vec3(mvp*vec4(fragPosition, 1));
    vec3 lightToSurface = normalize(surfacePos - l.position);
    vec3 lightDir = normalize(-l.direction);
    
    // Diffuse shading
    float diff = clamp(float(dot(n, lightDir)), 0.0, 1.0)*l.intensity;
    
    // Spot attenuation
    float attenuation = clamp(float(dot(n, lightToSurface)), 0.0, 1.0);
    attenuation = dot(lightToSurface, -lightDir);
    
    float lightToSurfaceAngle = degrees(acos(attenuation));
    if (lightToSurfaceAngle > l.coneAngle) attenuation = 0.0;
    
    float falloff = (l.coneAngle - lightToSurfaceAngle)/l.coneAngle;
    
    // Combine diffuse and attenuation
    float diffAttenuation = diff*attenuation;
    
    // Specular shading
    float spec = 0.0;
    if (diffAttenuation > 0.0)
    {
        vec3 h = normalize(lightDir + v);
        spec = pow(abs(dot(n, h)), 3.0 + glossiness)*s;
    }
    
    return (falloff*(diffAttenuation*l.diffuse.rgb + spec*colSpecular.rgb));
}

void main()
{
    // Calculate fragment normal in screen space
    // NOTE: important to multiply model matrix by fragment normal to apply model transformation (rotation and scale)
    mat3 normalMatrix = mat3(mvp);
    vec3 normal = normalize(normalMatrix*fragNormal);

    // Normalize normal and view direction vectors
    vec3 n = normalize(normal);
    vec3 v = normalize(viewDir);

    // Calculate diffuse texture color fetching
    vec4 texelColor = vec4(0.0, 1.0, 1.0, 1.0); //texture2D(texture0, fragTexCoord);
    //vec4 texelColor = texture2D(texture0, fragTexCoord);
    vec3 lighting = colAmbient.rgb;
    //vec3 lighting = vec3(1.0, 0.1, 0.1);
    
    // Calculate normal texture color fetching or set to maximum normal value by default
    if (useNormal == 1)
    {
        n *= texture2D(texture1, fragTexCoord).rgb;
        n = normalize(n);
    }
    
    // Calculate specular texture color fetching or set to maximum specular value by default
    float spec = 1.0;
    if (useSpecular == 1) spec = texture2D(texture2, fragTexCoord).r;

    //for (int i = 0; i < maxLights; i++)
    //{
    //    // Check if light is enabled
    //    if (lights[i].enabled == 1)
    //    {
    //        // Calculate lighting based on light type
    //        if (lights[i].type == 0) {
    //          lighting += ComputeLightPoint(lights[i], n, v, spec);
    //        }
    //        if (lights[i].type == 1) {
    //          lighting += ComputeLightDirectional(lights[i], n, v, spec);
    //        }
    //        if (lights[i].type == 2) {
    //          lighting += ComputeLightSpot(lights[i], n, v, spec);
    //        }
    //        
    //        // NOTE: It seems that too many ComputeLight*() operations inside for loop breaks the shader on RPI
    //    }
    //}

        // Check if light is enabled
        if (lights0.enabled == 1)
        {
            // Calculate lighting based on light type
            if (lights0.type == 0) {
              lighting += ComputeLightPoint(lights0, n, v, spec);
            }

            if (lights0.type == 1) {
              lighting += ComputeLightDirectional(lights0, n, v, spec);
            }

            if (lights0.type == 2) {
              lighting += ComputeLightSpot(lights0, n, v, spec);
            }
            
            // NOTE: It seems that too many ComputeLight*() operations inside for loop breaks the shader on RPI
        }

    // Calculate final fragment color
    //gl_FragColor = vec4(texelColor.rgb*lighting*colDiffuse.rgb, texelColor.a*colDiffuse.a);
    //gl_FragColor = vec4(texelColor.rgb, 1.0);
    gl_FragColor = vec4(lighting, 1.0);
    //gl_FragColor = vec4(colAmbient.rgb, 1.0);
    //gl_FragColor = vec4(colDiffuse.rgb, colDiffuse.a);
    //gl_FragColor = vec4(lighting*colDiffuse.rgb, 1.0);
}

