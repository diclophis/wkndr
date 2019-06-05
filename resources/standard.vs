#version 100

uniform mat4 mvp;             // VS: ModelViewProjection matrix
uniform mat4 projection;      // VS: Projection matrix
uniform mat4 view;            // VS: View matrix
uniform vec4 colDiffuse;      // FS: Diffuse color
uniform sampler2D texture0;   // FS: GL_TEXTURE0
uniform sampler2D texture1;   // FS: GL_TEXTURE1
uniform sampler2D texture2;   // FS: GL_TEXTURE2

//uniform mat4 mvp;

attribute vec3 vertexPosition;
attribute vec3 vertexNormal;
attribute vec2 vertexTexCoord;
attribute vec4 vertexColor;

varying vec3 fragPosition;
varying vec2 fragTexCoord;
varying vec4 fragColor;
varying vec3 fragNormal;


void main()
{
    fragPosition = vertexPosition;
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;
    fragNormal = vertexNormal;

    gl_Position = mvp*vec4(vertexPosition, 1.0);
}
