#version 330

// Input vertex attributes (from vertex shader)
in vec3 fragPosition;
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragNormal;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

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
uniform mat4 matModel;

const float glossiness = 0.1;
//const vec4 colSpecular = vec4(1.0, 1.0, 1.0, 1.0);

vec3 ComputeLightPoint(Light l, vec3 n, vec3 v, vec3 s)
{
    vec3 surfacePos = vec3(vec4(fragPosition, 1.0));
    vec3 surfaceToLight = l.position - surfacePos;

    //TODO: backport enhanced lighting model
    //l.intensity = 1.0;
    //l.radius = 2.0;

    // Diffuse shading
    float brightness = clamp(float(dot(n, surfaceToLight)/(length(surfaceToLight)*length(n))), 0.0, 1.0);
    float diff = 1.0/dot(surfaceToLight/l.radius, surfaceToLight/l.radius)*brightness*l.intensity;
    
    //////// Specular shading
    float spec = 0.0;
    //if (diff > 0.0)
    //{
    //    vec3 h = normalize(-l.target + v);
    //    spec = pow(abs(dot(n, h)), 3.0 + glossiness)*0.3;
    //}

    vec3 actualR = (diff*l.color.rgb + spec*s.rgb);
    return actualR;
}


vec3 ComputeLightDirectional(Light l, vec3 n, vec3 v, vec3 s)
{
    //return vec3(1.0, 0, 1.0);

    //vec3 lightDir = normalize(-l.target);
    vec3 lightDir = -normalize(l.target - l.position);

    //l.intensity = 1.0;

    // Diffuse shading
    float diff = clamp(float(dot(n, lightDir)), 0.0, 1.0)*l.intensity;

    // Specular shading
    float spec = 0.0;
    //if (diff > 0.0)
    //{
    //    vec3 h = normalize(lightDir + v);
    //    spec = pow(abs(dot(n, h)), 3.0 + glossiness)*0.3;
    //}
    
    // Combine results
    return (diff*l.intensity*l.color.rgb + spec*s.rgb);
}


vec3 ComputeLightSpot(Light l, vec3 n, vec3 v, vec3 s)
{
    //vec3 surfacePos = vec3(modelMatrix*vec4(fragPosition, 1));

    vec3 surfacePos = vec3(vec4(fragPosition, 1.0));
    //vec3 lightToSurface = l.position - surfacePos;
    vec3 lightToSurface = normalize(surfacePos - l.position);

    //vec3 lightDir = normalize(-l.direction);
    vec3 lightDir = -normalize(l.target - l.position);
    
    //l.intensity = 1.00;
    //l.coneAngle = 7.0;

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
    //if (diffAttenuation > 0.0)
    //{
    //    vec3 h = normalize(lightDir + v);
    //    spec = pow(abs(dot(n, h)), 3.0 + glossiness)*0.3; //s
    //}
    
    return (falloff*(diffAttenuation*l.color.rgb + spec*s.rgb));
}


void main()
{
  vec4 texelColor = vec4(0.0);
  vec3 lighting = vec3(0.0);
  vec3 lightDot = vec3(0.0);
  vec3 specular = texture(texture0, fragTexCoord).rgb;

  vec3 n = normalize(fragNormal);
  vec3 v = normalize(viewPos - fragPosition);

  for (int i = 0; i < MAX_LIGHTS; i++)
  {
      // Check if light is enabled
      if (lights[i].enabled == 1)
      {
          // Calculate lighting based on light type
          if(lights[i].type == LIGHT_POINT) lighting += ComputeLightPoint(lights[i], n, v, specular);
          else if(lights[i].type == LIGHT_DIRECTIONAL) lighting += ComputeLightDirectional(lights[i], n, v, specular);
          else if(lights[i].type == LIGHT_SPOT) lighting += ComputeLightSpot(lights[i], n, v, specular);

          float NdotL = max(dot(n, lighting), 0.0);
          lightDot += lights[i].color.rgb*NdotL;
      }
  }

  //finalColor = (vec4(lighting, 1.0)*((colDiffuse + vec4(specular, 1.0))*vec4(lightDot, 1.0)));
  //finalColor = (vec4(lighting, 1.0)*((vec4(specular, 1.0))*vec4(lightDot, 1.0)));
  
  //brokefinalColor = vec4(texelColor.rgb*lighting*colDiffuse.rgb, texelColor.a*colDiffuse.a);
  //finalColor = vec4(specular*lighting*colDiffuse.rgb, texelColor.a*colDiffuse.a);
  //finalColor += colDiffuse*(ambient/1.0);

  // Gamma correction
  //finalColor = pow(finalColor, vec4(1.0/1.1));

  //// Calculate final fragment color
  ////finalColor = vec4(texelColor.rgb*lighting*colDiffuse.rgb, texelColor.a*colDiffuse.a);
  //finalColor = vec4(texelColor.rgb*lighting*colDiffuse.rgb, texelColor.a*colDiffuse.a);
  //finalColor += colDiffuse*(ambient/1.0);

  //////// TODO: Gamma correction
  //finalColor = pow(finalColor, vec4(1.0/2.0));

  //absolute diffuse color
  //finalColor = colDiffuse;

  //everything one solid color
  //finalColor = vec4(1.0, 0.0, 1.0, 0.5);

  ////color of default raylib model
  //finalColor = vec4(spec, 1.0);

  //just ambient
  //finalColor = ambient;

  //just texture
  //finalColor = texelColor;

  //just lighting
  finalColor = vec4(lighting, 1.0);
}
