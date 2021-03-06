precision highp float;

// Input vertex attributes (from vertex shader)
#ifdef NEWER_GL
in vec3 fragPosition;
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragNormal;
#else
varying vec3 fragPosition;
varying vec2 fragTexCoord;
varying vec4 fragColor;
varying vec3 fragNormal;
#endif

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
#ifdef NEWER_GL
out vec4 finalColor;
#endif

// NOTE: Add here your custom variables

#define     MAX_LIGHTS              4
#define     LIGHT_DIRECTIONAL       0
#define     LIGHT_POINT             1
#define     LIGHT_SPOT              2

struct MaterialProperty {
    vec3 color;
    int useSampler;
    sampler2D sampler;
};

struct Light {
    int enabled;
    int type;
    vec3 position;
    vec3 target;
    vec4 color;
    float intensity;
    float radius;
    float coneAngle;
};

// Input lighting values
uniform Light lights[MAX_LIGHTS];
uniform vec4 ambient;
uniform vec3 viewPos;
//uniform mat4 matModel;

const float glossiness = 0.0001;
//const vec4 colSpecular = vec4(1.0, 1.0, 1.0, 1.0);

vec3 ComputeLightPoint(Light l, vec3 n, vec3 v, vec3 s)
{
    //calculate the vector from this pixels surface to the light source
    vec3 surfaceToLight = l.position - fragPosition;

    //calculate the cosine of the angle of incidence
    float brightness = dot(n, surfaceToLight) / (length(surfaceToLight) * length(n));
    //TODO:
    brightness = clamp(brightness, 0.0, 1.0);

    //calculate final color of the pixel, based on:
    // 1. The angle of incidence: brightness
    // 2. The color/intensities of the light: light.intensities
    // 3. The texture and texture coord: texture(tex, fragTexCoord)
    float diff = 1.0/dot(surfaceToLight/l.radius, surfaceToLight/l.radius)*brightness*l.intensity;

    return (diff * l.color.rgb);
}


vec3 ComputeLightDirectional(Light l, vec3 n, vec3 v, vec3 s)
{
    vec3 lightDir = -normalize(l.target - l.position);

    // Diffuse shading
    //TODO: 
    float diff = clamp(float(dot(n, lightDir)), 0.0, 1.0)*l.intensity;
    //float diff = (float(dot(n, lightDir)))*l.intensity;

    //// Specular shading
    //float spec = 0.0;
    //if (diff > 0.0)
    //{
    //    vec3 h = normalize(lightDir + v);
    //    spec = pow(abs(dot(n, h)), 3.0 + glossiness)*0.3;
    //}
    //
    //// Combine results
    //return (diff*l.intensity*l.color.rgb + spec*s.rgb);

    return (diff * l.color.rgb);
}


vec3 ComputeLightSpot(Light l, vec3 n, vec3 v, vec3 s)
{
    vec3 lightToSurface = normalize(fragPosition - l.position);

    vec3 lightDir = -normalize(l.target - l.position);

    // Diffuse shading
    float diff = clamp(float(dot(n, lightDir)), 0.0, 1.0)*l.intensity;
    //float diff = (float(dot(n, lightDir)))*l.intensity;

    // Spot attenuation
    //float attenuation = clamp(float(dot(n, lightToSurface)), 0.0, 1.0);
    float attenuation = (float(dot(n, lightToSurface)));
    attenuation = dot(lightToSurface, -lightDir);

    float lightToSurfaceAngle = degrees(acos(attenuation));
    if (lightToSurfaceAngle > l.coneAngle) attenuation = 0.0;

    float falloff = (l.coneAngle - lightToSurfaceAngle)/l.coneAngle;

    // Combine diffuse and attenuation
    float diffAttenuation = diff*attenuation;

    //// Specular shading
    float spec = 0.0;
    if (diffAttenuation > 0.0)
    {
        vec3 h = normalize(lightDir + v);
        spec = pow(abs(dot(n, h)), 3.0 + glossiness)*1.0;
    }

    return (falloff*(diffAttenuation*l.color.rgb + spec*s.rgb));
}


void main()
{
#ifndef NEWER_GL
  vec4 finalColor = vec4(0.0);
#endif


// Texel color fetching from texture sampler
#ifdef NEWER_GL
    vec4 texelColor = texture(texture0, fragTexCoord);
#else
    vec4 texelColor = texture2D(texture0, fragTexCoord);
#endif

    vec3 lightDot = vec3(0.0);
    vec3 normal = normalize(fragNormal);
    vec3 viewD = normalize(viewPos - fragPosition);
    vec3 specular = vec3(0.0);

    // NOTE: Implement here your fragment shader code
    for (int i = 0; i < MAX_LIGHTS; i++)
    {
        if (lights[i].enabled == 1)
        {
            vec3 light = vec3(0.0);

  //        if (lights[i].enabled == 1)
  //        {
  //            // Calculate lighting based on light type
  //            if(lights[i].type == LIGHT_POINT) lighting += ComputeLightPoint(lights[i], n, v, specular);
  //            else if(lights[i].type == LIGHT_DIRECTIONAL) lighting += ComputeLightDirectional(lights[i], n, v, specular);
  //            else if(lights[i].type == LIGHT_SPOT) lighting += ComputeLightSpot(lights[i], n, v, specular);
  //            //float NdotL = max(dot(n, lighting), 0.0);
  //            ////lightDot += lights[i].color.rgb*NdotL;
  //            //lightDot += NdotL;
  //        }
            
            if (lights[i].type == LIGHT_DIRECTIONAL) 
            {
              //light = -normalize(lights[i].target - lights[i].position);
              light = ComputeLightDirectional(lights[i], normal, viewD, specular);
            }
       
            if (lights[i].type == LIGHT_POINT) 
            {
              //light = normalize(lights[i].position - fragPosition);
              light = ComputeLightPoint(lights[i], normal, viewD, specular);
            }

            float NdotL = max(dot(normal, light), 0.0);
            lightDot += lights[i].color.rgb*NdotL;
            float specCo = 0.0;
            if (NdotL > 0.0) specCo = pow(max(0.0, dot(viewD, reflect(-(light), normal))), 8.0); // 16 refers to shine
            specular += specCo;
        }
    }

    finalColor = (texelColor*((colDiffuse + vec4(specular, 0.5))*vec4(lightDot, 0.5)));
    finalColor += texelColor*(ambient);
    
    // Gamma correction
    //finalColor = pow(finalColor, vec4(1.0/4.0));

#ifdef NEWER_GL
#else
  gl_FragColor = finalColor;
#endif

}
