
#ifdef NEWER_GL
precision mediump float;
#endif

//#version 300 es
//#version 100
//
//#define highp
//#define mediump
//#define lowp

// Input vertex attributes
#ifdef NEWER_GL
in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec3 vertexNormal;
in vec4 vertexColor;
#else
attribute vec3 vertexPosition;
attribute vec2 vertexTexCoord;
attribute vec3 vertexNormal;
attribute vec4 vertexColor;
#endif

//// Input uniform values
uniform mat4 mvp;
uniform mat4 matModel;

// Output vertex attributes (to fragment shader)
#ifdef NEWER_GL
out vec3 fragPosition;
out vec2 fragTexCoord;
out vec4 fragColor;
out vec3 fragNormal;
#else
varying vec3 fragPosition;
varying vec2 fragTexCoord;
varying vec4 fragColor;
varying vec3 fragNormal;
#endif

// NOTE: Add here your custom variables
//attribute vec4 vertexColor; // in_Color

#ifndef NEWER_GL
// https://github.com/glslify/glsl-inverse
mat3 inverse(mat3 m)
{
  float a00 = m[0][0], a01 = m[0][1], a02 = m[0][2];
  float a10 = m[1][0], a11 = m[1][1], a12 = m[1][2];
  float a20 = m[2][0], a21 = m[2][1], a22 = m[2][2];

  float b01 = a22*a11 - a12*a21;
  float b11 = -a22*a10 + a12*a20;
  float b21 = a21*a10 - a11*a20;

  float det = a00*b01 + a01*b11 + a02*b21;

  return mat3(b01, (-a22*a01 + a02*a21), (a12*a01 - a02*a11),
              b11, (a22*a00 - a02*a20), (-a12*a00 + a02*a10),
              b21, (-a21*a00 + a01*a20), (a11*a00 - a01*a10))/det;
}

// https://github.com/glslify/glsl-transpose
mat3 transpose(mat3 m)
{
  return mat3(m[0][0], m[1][0], m[2][0],
              m[0][1], m[1][1], m[2][1],
              m[0][2], m[1][2], m[2][2]);
}
#endif

void main()
{
    //    /* first transform the normal into eye space and normalize the result */
    //    mat3 normalMatrix = transpose(inverse(mat3(matModel)));
    //    fragNormal = normalize(normalMatrix*vertexNormal);

    //    // Send vertex attributes to fragment shader
    //    fragPosition = vec3(matModel*vec4(vertexPosition, 1.0f));
    //    fragTexCoord = vertexTexCoord;
    //    fragColor = vertexColor;

    //    //// Calculate final vertex position
    //    gl_Position = mvp*vec4(vertexPosition, 1.0);

    // Send vertex attributes to fragment shader
    fragPosition = vec3(matModel*vec4(vertexPosition, 1.0));
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;

    mat3 normalMatrix = transpose(inverse(mat3(matModel)));
    fragNormal = normalize(normalMatrix*vertexNormal);

    // Calculate final vertex position
    gl_Position = mvp*vec4(vertexPosition, 1.0);
}
