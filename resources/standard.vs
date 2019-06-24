precision lowp float;

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
    /* first transform the normal into eye space and normalize the result */
    mat3 normalMatrix = transpose(inverse(mat3(matModel)));
    fragNormal = normalize(normalMatrix*vertexNormal);

    // Send vertex attributes to fragment shader
    fragPosition = vec3(matModel*vec4(vertexPosition, 1.0f));
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;

    //// Calculate final vertex position
    gl_Position = mvp*vec4(vertexPosition, 1.0);
}
