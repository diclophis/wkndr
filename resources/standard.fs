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
    //vec3 direction;
    vec4 diffuse;
    float intensity;
    float radius;
    float coneAngle;
};

// Input lighting values
uniform Light lights[MAX_LIGHTS];
uniform vec4 ambient;
uniform vec3 viewPos;
uniform mat4 matModel;

const float glossiness = 0.001;
const vec4 colSpecular = vec4(0.001, 0.001, 0.001, 1.0);

vec3 ComputeLightPoint(Light l, vec3 n, vec3 v, vec3 s)
{
    vec3 surfacePos = vec3(matModel*vec4(fragPosition, 1.0));
    vec3 surfaceToLight = l.position - surfacePos;

    l.intensity = 10.0;
    l.radius = 1.0;

    // Diffuse shading
    float brightness = clamp(float(dot(n, surfaceToLight)/(length(surfaceToLight)*length(n))), 0.0, 1.0);
    float diff = 1.0/dot(surfaceToLight/l.radius, surfaceToLight/l.radius)*brightness*l.intensity;

    ////// Specular shading
    //float spec = 0.0;
    //if (diff > 0.0)
    //{
    //    vec3 h = normalize(-l.target + v);
    //    spec = pow(abs(dot(n, h)), 3.0 + glossiness)*0.1; //s.r;
    //}

    //vec3 actualR = (diff*l.diffuse.rgb + spec*colSpecular.rgb);

    //return vec3(0.1, actualR.g, 0.1);
    //return actualR;

    return vec3(diff);
}

void main()
{
    //// Texel color fetching from texture sampler
    //vec4 texelColor = vec4(1.0);
    vec4 texelColor = texture(texture0, fragTexCoord);

    ////vec4(1.0, 0.0, fragColor.b, 0.5); //fragColor; //texture(texture0, fragTexCoord);

    vec3 lighting = ambient.rgb;

    //vec3 normal = normalize(fragNormal);
    vec3 specular = vec3(1.0);

    // mat3 normalMatrix = mat3(matModel);
    // vec3 normal = normalize(normalMatrix*fragNormal);

    // // Normalize normal and view direction vectors
    // //vec3 n = normalize(normal);
    // //vec3 n = normal;
    // //float NdotL = max(dot(normal, light), 0.0);
    // 
    // vec3 viewDir = normalize(viewPos - fragPosition);
    // vec3 v = normalize(viewDir);


    ////mat3 normalMatrix = mat3(matModel);
    //vec3 normal = normalize(fragNormal);
    ////
    ////    // Normalize normal and view direction vectors
    //vec3 viewD = normalize(viewPos - fragPosition);
    //vec3 n = normalize(normal);
    //vec3 v = normalize(viewD);

    vec3 n = normalize(fragNormal);
    vec3 v = normalize(viewPos - fragPosition);


    // Calculate diffuse texture color fetching
    // broken
    //vec4 texelColor = texture2D(texture0, fragTexCoord);

    //
    //vec4 texelColor = vec4(1.0, 1.0, 1.0, 1.0);

    //vec3 lighting = colAmbient.rgb;
    
    // Calculate normal texture color fetching or set to maximum normal value by default
    //if (useNormal == 1)
    //{
    //    n *= texture2D(texture1, fragTexCoord).rgb;
    //    n = normalize(n);
    //}

    //// NOTE: Implement here your fragment shader code

    //vec3 lightDot = vec3(0.0);
    //for (int i = 0; i < MAX_LIGHTS; i++)
    //{
    //    if (lights[i].enabled == 1)
    //    {
    //        vec3 light = vec3(0.0);
    //        
    //        if (lights[i].type == LIGHT_DIRECTIONAL) 
    //        {
    //            light = -normalize(lights[i].target - lights[i].position);
    //        }
    //        
    //        if (lights[i].type == LIGHT_POINT) 
    //        {
    //            light = normalize(lights[i].position - fragPosition);
    //        }
    //        
    //        float NdotL = max(dot(normal, light), 0.0);
    //        lightDot += lights[i].color.rgb*NdotL;

    //        float specCo = 0.0;
    //        float shiny = 0.0; // 16 has visible shine
    //        if (NdotL > 0.0) specCo = pow(max(0.0, dot(viewD, reflect(-(light), normal))), shiny);
    //        specular += specCo;
    //    }
    //}

    for (int i = 0; i < MAX_LIGHTS; i++)
    {
        // Check if light is enabled
        if (lights[i].enabled == 1)
        {
            // Calculate lighting based on light type
            if(lights[i].type == LIGHT_POINT) lighting += ComputeLightPoint(lights[i], n, v, specular);
        }
    }

    //finalColor = (texelColor*((colDiffuse + vec4(specular, 1.0))*vec4(lightDot, 1.0)));
    //finalColor += texelColor*(ambient/10.0);
    //
    ////// Gamma correction
    //finalColor = pow(finalColor, vec4(1.0/2.0));

    // Calculate final fragment color
    //finalColor = vec4(texelColor.rgb*lighting*colDiffuse.rgb, texelColor.a*colDiffuse.a);
    //finalColor = vec4(texelColor.rgb*lighting*colDiffuse.rgb, texelColor.a*colDiffuse.a);

    //absolute diffuse color
    //finalColor = colDiffuse;

    //everything one solid color
    finalColor = vec4(1.0, 0.0, 1.0, 0.5);

    ////color of default raylib model
    //finalColor = vec4(spec, 1.0);

    //just ambient
    //finalColor = ambient;

    //just texture
    //finalColor = texelColor;

    //just lighting
    //finalColor = vec4(lighting, 1.0);
}

//     #version 330
//     
//     const float glossiness = 0.25;
//     const vec4 colSpecular = vec4(0.125, 0.125, 0.125, 1.0);
//     
//     // Input vertex attributes (from vertex shader)
//     in vec3 fragPosition;
//     in vec2 fragTexCoord;
//     in vec4 fragColor;
//     in vec3 fragNormal;
//     
//     
//     // Output fragment color
//     out vec4 finalColor;
//     
//     // NOTE: Add here your custom variables
//     
//     #define     MAX_LIGHTS              4
//     #define     LIGHT_DIRECTIONAL       0
//     #define     LIGHT_POINT             1
//     
//     struct MaterialProperty {
//         vec3 color;
//         int useSampler;
//         sampler2D sampler;
//     };
//     
//     struct Light {
//         int enabled;
//         int type;
//         vec3 position;
//         vec3 target;
//         vec4 color;
//         //vec3 direction;
//         vec4 diffuse;
//         float intensity;
//         float radius;
//         float coneAngle;
//     };
//     
//     // Input lighting values
//     uniform vec4 ambient;
//     uniform mat4 matModel;
//     uniform vec3 viewPos;
//     uniform int totalLights;
//     // Input uniform values
//     uniform sampler2D texture0;
//     uniform vec4 colDiffuse;
//     uniform Light lights[MAX_LIGHTS];
//     
//     vec3 ComputeLightPoint(Light l, vec3 n, vec3 v, float s)
//     {
//         vec3 surfacePos = vec3(matModel*vec4(fragPosition, 1.0));
//         vec3 surfaceToLight = l.position - surfacePos;
//         
//         // Diffuse shading
//         float brightness = clamp(float(dot(n, surfaceToLight)/(length(surfaceToLight)*length(n))), 0.0, 1.0);
//         float diff = 1.0/dot(surfaceToLight/l.radius, surfaceToLight/l.radius)*brightness*l.intensity;
//         
//         // Specular shading
//         float spec = 0.0;
//         if (diff > 0.0)
//         {
//             vec3 h = normalize(-l.target + v);
//             spec = pow(abs(dot(n, h)), 3.0 + glossiness)*s;
//         }
//         
//         return (diff*l.diffuse.rgb + spec*colSpecular.rgb);
//     }
//     
//     void main()
//     {
//         mat3 normalMatrix = mat3(matModel);
//         vec3 normal = normalize(normalMatrix*fragNormal);
//     
//     //////
//     //////    // Normalize normal and view direction vectors
//         vec3 viewD = normalize(viewPos - fragPosition);
//         vec3 specular = vec3(0.0);
//     
//         vec3 nwtf = normalize(normal);
//         vec3 vwtf = normalize(viewD);
//     
//         // Texel color fetching from texture sampler
//         //vec4 texelColor = vec4(0.1, 1.0, 0.1, 0.5); //texture(texture0, fragTexCoord);
//         vec4 texelColor = texture(texture0, fragTexCoord);
//         vec3 lightDot = vec3(0.0);
//         //vec3 normal = normalize(fragNormal);
//     
//         //vec3 view = normalize(viewPos - fragPosition);
//     
//         // NOTE: Implement here your fragment shader code
//     
//     //////    // Normalize normal and view direction vectors
//     //////    vec3 n = normalize(normal);
//     //////    vec3 v = normalize(viewDir);
//     //////
//     //////    // Calculate diffuse texture color fetching
//     //////    // broken
//     //////    //vec4 texelColor = texture2D(texture0, fragTexCoord);
//     //////
//     //////    //
//     //////    vec4 texelColor = vec4(1.0, 1.0, 1.0, 1.0);
//     //////
//     //////    vec3 lighting = colAmbient.rgb;
//     
//     
//         for (int i = 0; i < 4; i++)
//         {
//             //if (lights[i].enabled == 1)
//             if (i < totalLights)
//             {
//                   vec3 light = vec3(0.0);
//     
//                   if(lights[i].type == 0) light += ComputeLightPoint(lights[i], nwtf, vwtf, 0.5);
//     
//     //            
//     //            if (lights[i].type == LIGHT_DIRECTIONAL) 
//     //            {
//     //                light = -normalize(lights[i].target - lights[i].position);
//     //            }
//     //            
//     //            if (lights[i].type == LIGHT_POINT) 
//     //            {
//     //                light = normalize(lights[i].position - fragPosition);
//     //            }
//     //            
//     //            float NdotL = max(dot(normal, light), 0.0);
//     //            lightDot += lights[i].color.rgb*NdotL;
//     //
//     //            float specCo = 0.0;
//     //            float shinCo = 1.0;
//     //            if (NdotL > 0.0) {
//     //              specCo = pow(max(0.0, dot(viewD, reflect(-(light), normal))), shinCo); // 16 refers to shine
//     //            }
//     //            specular += specCo;
//     
//             }
//         }
//     
//         finalColor = (texelColor*((colDiffuse + vec4(specular, 1.0))*vec4(lightDot, 1.0)));
//         finalColor += texelColor*(ambient/10.0);
//         
//         // Gamma correction
//         finalColor = pow(finalColor, vec4(1.0/2.2));
//     }
//     
//     
//     
//     
//     //#version 100
//     //
//     //precision mediump float;
//     //
//     //uniform mat4 mvp;             // VS: ModelViewProjection matrix
//     //uniform mat4 projection;      // VS: Projection matrix
//     //uniform mat4 view;            // VS: View matrix
//     //
//     //uniform vec4 colDiffuse;      // FS: Diffuse color
//     //uniform sampler2D texture0;   // FS: GL_TEXTURE0
//     //uniform sampler2D texture1;   // FS: GL_TEXTURE1
//     //uniform sampler2D texture2;   // FS: GL_TEXTURE2
//     //
//     //
//     ////varying vec3 fragPosition;
//     ////varying vec2 fragTexCoord;
//     ////varying vec4 fragColor;
//     ////varying vec3 fragNormal;
//     ////
//     ////uniform sampler2D texture0;
//     ////uniform sampler2D texture1;
//     ////uniform sampler2D texture2;
//     ////
//     //////uniform vec4 colAmbient;
//     //////uniform vec4 colDiffuse;
//     //////uniform vec4 colSpecular;
//     //////uniform float glossiness;
//     ////const vec4 colAmbient = vec4(0.25, 0.25, 0.25, 1.0);
//     ////const vec4 colDiffuse = vec4(0.125, 0.125, 0.5, 1.0);
//     ////const vec4 colSpecular = vec4(0.125, 0.5, 0.125, 1.0);
//     ////const float glossiness = 0.5;
//     ////
//     ////uniform int useNormal;
//     ////uniform int useSpecular;
//     ////
//     ////uniform mat4 modelMatrix;
//     ////uniform vec3 viewDir;
//     ////
//     ////struct Light {
//     ////    int enabled;
//     ////    int type;
//     ////    vec3 position;
//     ////    vec3 direction;
//     ////    vec4 diffuse;
//     ////    float intensity;
//     ////    float radius;
//     ////    float coneAngle;
//     ////};
//     ////
//     ////const int maxLights = 1;
//     ////uniform Light lights[maxLights];
//     ////
//     ////vec3 ComputeLightPoint(Light l, vec3 n, vec3 v, float s)
//     ////{
//     ////    vec3 surfacePos = vec3(modelMatrix*vec4(fragPosition, 1.0));
//     ////    vec3 surfaceToLight = l.position - surfacePos;
//     ////    
//     ////    // Diffuse shading
//     ////    float brightness = clamp(float(dot(n, surfaceToLight)/(length(surfaceToLight)*length(n))), 0.0, 1.0);
//     ////    float diff = 1.0/dot(surfaceToLight/l.radius, surfaceToLight/l.radius)*brightness*l.intensity;
//     ////    
//     ////    // Specular shading
//     ////    float spec = 0.0;
//     ////    if (diff > 0.0)
//     ////    {
//     ////        vec3 h = normalize(-l.direction + v);
//     ////        spec = pow(abs(dot(n, h)), 3.0 + glossiness)*s;
//     ////    }
//     ////    
//     ////    return (diff*l.diffuse.rgb + spec*colSpecular.rgb);
//     ////}
//     ////
//     ////vec3 ComputeLightDirectional(Light l, vec3 n, vec3 v, float s)
//     ////{
//     ////    vec3 lightDir = normalize(-l.direction);
//     ////    
//     ////    // Diffuse shading
//     ////    float diff = clamp(float(dot(n, lightDir)), 0.0, 1.0)*l.intensity;
//     ////    
//     ////    // Specular shading
//     ////    float spec = 0.0;
//     ////    if (diff > 0.0)
//     ////    {
//     ////        vec3 h = normalize(lightDir + v);
//     ////        spec = pow(abs(dot(n, h)), 3.0 + glossiness)*s;
//     ////    }
//     ////    
//     ////    // Combine results
//     ////    return (diff*l.intensity*l.diffuse.rgb + spec*colSpecular.rgb);
//     ////}
//     ////
//     ////vec3 ComputeLightSpot(Light l, vec3 n, vec3 v, float s)
//     ////{
//     ////    vec3 surfacePos = vec3(modelMatrix*vec4(fragPosition, 1));
//     ////    vec3 lightToSurface = normalize(surfacePos - l.position);
//     ////    vec3 lightDir = normalize(-l.direction);
//     ////    
//     ////    // Diffuse shading
//     ////    float diff = clamp(float(dot(n, lightDir)), 0.0, 1.0)*l.intensity;
//     ////    
//     ////    // Spot attenuation
//     ////    float attenuation = clamp(float(dot(n, lightToSurface)), 0.0, 1.0);
//     ////    attenuation = dot(lightToSurface, -lightDir);
//     ////    
//     ////    float lightToSurfaceAngle = degrees(acos(attenuation));
//     ////    if (lightToSurfaceAngle > l.coneAngle) attenuation = 0.0;
//     ////    
//     ////    float falloff = (l.coneAngle - lightToSurfaceAngle)/l.coneAngle;
//     ////    
//     ////    // Combine diffuse and attenuation
//     ////    float diffAttenuation = diff*attenuation;
//     ////    
//     ////    // Specular shading
//     ////    float spec = 0.0;
//     ////    if (diffAttenuation > 0.0)
//     ////    {
//     ////        vec3 h = normalize(lightDir + v);
//     ////        spec = pow(abs(dot(n, h)), 3.0 + glossiness)*s;
//     ////    }
//     ////    
//     ////    return (falloff*(diffAttenuation*l.diffuse.rgb + spec*colSpecular.rgb));
//     ////}
//     ////
//     //
//     ////void main()
//     ////{
//     //////    // Calculate fragment normal in screen space
//     //////    // NOTE: important to multiply model matrix by fragment normal to apply model transformation (rotation and scale)
//     //////    mat3 normalMatrix = mat3(modelMatrix);
//     //////    vec3 normal = normalize(normalMatrix*fragNormal);
//     //////
//     //////    // Normalize normal and view direction vectors
//     //////    vec3 n = normalize(normal);
//     //////    vec3 v = normalize(viewDir);
//     //////
//     //////    // Calculate diffuse texture color fetching
//     //////    // broken
//     //////    //vec4 texelColor = texture2D(texture0, fragTexCoord);
//     //////
//     //////    //
//     //////    vec4 texelColor = vec4(1.0, 1.0, 1.0, 1.0);
//     //////
//     //////    vec3 lighting = colAmbient.rgb;
//     //////    
//     //////    // Calculate normal texture color fetching or set to maximum normal value by default
//     //////    //if (useNormal == 1)
//     //////    //{
//     //////        n *= texture2D(texture1, fragTexCoord).rgb;
//     //////        n = normalize(n);
//     //////    //}
//     //////    
//     //////    // Calculate specular texture color fetching or set to maximum specular value by default
//     //////    float spec = 1.0;
//     //////    //if (useSpecular == 1) {
//     //////      spec = texture2D(texture2, fragTexCoord).r;
//     //////    //}
//     //////    
//     //////    for (int i = 0; i < maxLights; i++)
//     //////    {
//     //////        // Check if light is enabled
//     //////        if (lights[i].enabled == 1)
//     //////        {
//     //////            // Calculate lighting based on light type
//     //////            if(lights[i].type == 0) lighting += ComputeLightPoint(lights[i], n, v, spec);
//     //////            else if(lights[i].type == 1) lighting += ComputeLightDirectional(lights[i], n, v, spec);
//     //////            else if(lights[i].type == 2) lighting += ComputeLightSpot(lights[i], n, v, spec);
//     //////            
//     //////            // NOTE: It seems that too many ComputeLight*() operations inside for loop breaks the shader on RPI
//     //////        }
//     //////    }
//     //////    
//     //////    // Calculate final fragment color
//     //////    //gl_FragColor = vec4(texelColor.rgb*lighting*colDiffuse.rgb, texelColor.a*colDiffuse.a);
//     //////
//     //////    //everything one solid color
//     //////    //gl_FragColor = vec4(1.0);
//     //////
//     //////    //color of default raylib model
//     //////    //gl_FragColor = vec4(spec, 1.0);
//     //////
//     //////    //just ambient
//     //////    //gl_FragColor = vec4(colAmbient.rgb, 1.0);
//     //////
//     //////    //just vertex raylib color
//     //////    //gl_FragColor = vec4(colDiffuse.rgb, colDiffuse.a);
//     ////
//     ////  gl_FragColor = colDiffuse; //.rgb*lighting*colDiffuse.rgb, texelColor.a*colDiffuse.a);
//     ////
//     ////  //gl_FragColor = vec4(1.0, 0.5, 0.25, 1.0);
//     ////
//     ////}
