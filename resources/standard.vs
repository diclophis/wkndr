#version 330

// Input vertex attributes
in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec3 vertexNormal;
in vec4 vertexColor;

// Input uniform values
uniform mat4 mvp;
uniform mat4 matModel;

// Output vertex attributes (to fragment shader)
out vec3 fragPosition;
out vec2 fragTexCoord;
out vec4 fragColor;
out vec3 fragNormal;

// NOTE: Add here your custom variables
//attribute vec4 vertexColor; // in_Color

void main()
{

    // Send vertex attributes to fragment shader
    fragPosition = vec3(matModel*vec4(vertexPosition, 1.0f));
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;
    
    mat3 normalMatrix = transpose(inverse(mat3(matModel)));
    fragNormal = normalize(normalMatrix*vertexNormal);

    // Calculate final vertex position
    gl_Position = mvp*vec4(vertexPosition, 1.0);

//     // Send vertex attributes to fragment shader
//     fragPosition = vec3(matModel*vec4(vertexPosition, 1.0f));
//     fragTexCoord = vertexTexCoord;
//     fragColor = vertexColor;
//     
//     //mat3 normalMatrix = transpose(inverse(mat3(matModel)));
//     //fragNormal = normalize(normalMatrix*vertexNormal);
// 
//     mat3 normalMatrix = transpose((mat3(matModel)));
//     fragNormal = normalize(normalMatrix*vertexNormal);
// 
//     // Calculate final vertex position
//     gl_Position = mvp*vec4(vertexPosition, 1.0);
}


//#version 100
//
//uniform mat4 mvp;             // VS: ModelViewProjection matrix
//uniform matModel              // VS: Matrix model
//# uniform mat4 projection;      // VS: Projection matrix
//# uniform mat4 view;            // VS: View matrix
//# uniform vec4 colDiffuse;      // FS: Diffuse color
//# uniform sampler2D texture0;   // FS: GL_TEXTURE0
//# uniform sampler2D texture1;   // FS: GL_TEXTURE1
//# uniform sampler2D texture2;   // FS: GL_TEXTURE2
//# uniform vec3 LightPosition_worldspace;
//
//attribute vec3 vertexPosition; // in_Position
//attribute vec2 vertexTexCoord; // in_UV
//attribute vec3 vertexNormal; // in_Normal
//
//varying vec3 fragPosition; // Position_worldspace
//varying vec2 fragTexCoord; // UV
//varying vec4 fragColor;
//varying vec3 fragNormal; // Normal_cameraspace
//#varying vec3 EyeDirection_cameraspace;
//#varying vec3 LightDirection_cameraspace;
//
//
//void main()
//{
//    #gl_Position = mvp*vec4(vertexPosition, 1.0);
//
//    #//fragPosition = vertexPosition;
//    #//Position_worldspace = 
//    #fragPosition = (mvp * vec4(vertexPosition, 1)).xyz;
//
//    #//fragNormal = vertexNormal;
//    #//Normal_cameraspace =
//    #fragNormal = (view * mvp * vec4(vertexNormal, 0)).xyz; // Only correct if ModelMatrix does not scale the model ! Use its inverse transpose if not.
//
//    #fragTexCoord = vertexTexCoord;
//    #fragColor = vertexColor;
//
//
//	  #vec3 vertexPosition_cameraspace = (view * mvp * vec4(vertexPosition, 1)).xyz;
//	  #EyeDirection_cameraspace = vec3(0, 0, 0) - vertexPosition_cameraspace;
//
//		#// Vector that goes from the vertex to the light, in camera space. M is ommited because it's identity.
//		#vec3 LightPosition_cameraspace = (view * vec4(LightPosition_worldspace, 1)).xyz;
//		#LightDirection_cameraspace = LightPosition_cameraspace + EyeDirection_cameraspace;
//
//    fragPosition = vec3(matModel*vec4(vertexPosition, 1.0f));
//    fragTexCoord = vertexTexCoord;
//    fragColor = vertexColor;
//    
//    mat3 normalMatrix = transpose(inverse(mat3(matModel)));
//    fragNormal = normalize(normalMatrix*vertexNormal);
//
//    // Calculate final vertex position
//    gl_Position = mvp*vec4(vertexPosition, 1.0);
//}
