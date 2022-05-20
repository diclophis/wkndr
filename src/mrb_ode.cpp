
#include "raylib.h"
#include "raymath.h"

#include <ode/ode.h>
#include "raylib.h"
#include "raymath.h"
#include "rlgl.h"

#include <ode/ode.h>

//      #include "raylibODE.h"
//      
//      
//      
//      // TODO extern for now - need to add function set these and keep them here...
//      //extern Model ball;
//      extern Model box;
//      //extern Model cylinder;
//      
//      //// 0 chassis / 1-4 wheel / 5 anti roll counter weight
//      //typedef struct vehicle {
//      //    dBodyID bodies[6];
//      //    dGeomID geoms[6];
//      //    dJointID joints[6];
//      //} vehicle;
//      
//      typedef struct geomInfo {
//          
//          bool collidable;
//      } geomInfo ;
//      
//      
//      void rayToOdeMat(Matrix* mat, dReal* R);
//      void odeToRayMat(const dReal* R, Matrix* matrix);
//      
//      //void drawAllSpaceGeoms(dSpaceID space);
//      //void drawGeom(dGeomID geom);
//      //vehicle* CreateVehicle(dSpaceID space, dWorldID world);
//      //void updateVehicle(vehicle *car, float accel, float maxAccelForce, 
//      //                    float steer, float steerFactor);
//      //void unflipVehicle (vehicle *car);
//      bool checkColliding(dGeomID g);
//      
//      //////////////////////////////////////////////////////////////////////
//      
//      // reused for all geoms that don't collide
//      // ie vehicle counter weights
//      static geomInfo disabled;
//      
//      // optionally a geom can have user data, in this case
//      // the only info our user data has is if the geom
//      // should collide or not
//      // this allows for bodies that effect COG without
//      // colliding
//      bool checkColliding(dGeomID g)
//      {
//          geomInfo* gi = (geomInfo*)dGeomGetData(g);
//          if (!gi) return true;
//          return gi->collidable;
//      }
//      
//      //// position rotation scale all done with the models transform...
//      //void MyDrawModel(Model model, Color tint)
//      //{
//      //    
//      //    for (int i = 0; i < model.meshCount; i++)
//      //    {
//      //        Color color = model.materials[model.meshMaterial[i]].maps[MAP_DIFFUSE].color;
//      //
//      //        Color colorTint = WHITE;
//      //        colorTint.r = (unsigned char)((((float)color.r/255.0)*((float)tint.r/255.0))*255.0f);
//      //        colorTint.g = (unsigned char)((((float)color.g/255.0)*((float)tint.g/255.0))*255.0f);
//      //        colorTint.b = (unsigned char)((((float)color.b/255.0)*((float)tint.b/255.0))*255.0f);
//      //        colorTint.a = (unsigned char)((((float)color.a/255.0)*((float)tint.a/255.0))*255.0f);
//      //
//      //        model.materials[model.meshMaterial[i]].maps[MAP_DIFFUSE].color = colorTint;
//      //        DrawMesh(model.meshes[i], model.materials[model.meshMaterial[i]], model.transform);
//      //        model.materials[model.meshMaterial[i]].maps[MAP_DIFFUSE].color = color;
//      //    }
//      //}
//      
//      
//      // these two just convert to column major and minor
//      void rayToOdeMat(Matrix* m, dReal* R) {
//          R[ 0] = m->m0;   R[ 1] = m->m4;   R[ 2] = m->m8;    R[ 3] = 0;
//          R[ 4] = m->m1;   R[ 5] = m->m5;   R[ 6] = m->m9;    R[ 7] = 0;
//          R[ 8] = m->m2;   R[ 9] = m->m6;   R[10] = m->m10;   R[11] = 0;
//          R[12] = 0;       R[13] = 0;       R[14] = 0;        R[15] = 1;   
//      }
//      
//      // sets a raylib matrix from an ODE rotation matrix
//      void odeToRayMat(const dReal* R, Matrix* m)
//      {
//          m->m0 = R[0];  m->m1 = R[4];  m->m2 = R[8];      m->m3 = 0;
//          m->m4 = R[1];  m->m5 = R[5];  m->m6 = R[9];      m->m7 = 0;
//          m->m8 = R[2];  m->m9 = R[6];  m->m10 = R[10];    m->m11 = 0;
//          m->m12 = 0;    m->m13 = 0;    m->m14 = 0;        m->m15 = 1;
//      }
//      
//      //void drawGeom(dGeomID geom) 
//      //{
//      //    const dReal* pos = dGeomGetPosition(geom);
//      //    const dReal* rot = dGeomGetRotation(geom);
//      //    int class = dGeomGetClass(geom);
//      //    Model* m = 0;
//      //    dVector3 size;
//      //    if (class == dBoxClass) {
//      //        m = &box;
//      //        dGeomBoxGetLengths(geom, size);
//      //    } else if (class == dSphereClass) {
//      //        m = &ball;
//      //        float r = dGeomSphereGetRadius(geom);
//      //        size[0] = size[1] = size[2] = (r*2);
//      //    } else if (class == dCylinderClass) {
//      //        m = &cylinder;
//      //        dReal l,r;
//      //        dGeomCylinderGetParams (geom, &r, &l);
//      //        size[0] = size[1] = r*2;
//      //        size[2] = l;
//      //    }
//      //    if (!m) return;
//      //    
//      //    Matrix matScale = MatrixScale(size[0], size[1], size[2]);
//      //    Matrix matRot;
//      //    odeToRayMat(rot, &matRot);
//      //    Matrix matTran = MatrixTranslate(pos[0], pos[1], pos[2]);
//      //    
//      //    m->transform = MatrixMultiply(MatrixMultiply(matScale, matRot), matTran);
//      //    
//      //    dBodyID b = dGeomGetBody(geom);
//      //    Color c = WHITE;
//      //    if (b) if (!dBodyIsEnabled(b)) c = RED;
//      //
//      //    MyDrawModel(*m, c);
//      //    m->transform = MatrixIdentity();
//      //}
//      
//      //void drawAllSpaceGeoms(dSpaceID space) 
//      //{
//      //    int ng = dSpaceGetNumGeoms(space);
//      //    for (int i=0; i<ng; i++) {
//      //        dGeomID geom = dSpaceGetGeom(space, i);
//      //        if (checkColliding(geom))  
//      //        {
//      //            // hide non colliding geoms (car counter weights)
//      //            drawGeom(geom);
//      //        }
//      //    }
//      //}
//      
//      
//      //vehicle* CreateVehicle(dSpaceID space, dWorldID world)
//      //{
//      //    // TODO these should be parameters
//      //    Vector3 carScale = (Vector3){2.5, 0.5, 1.4};
//      //    float wheelRadius = 0.5, wheelWidth = 0.4;
//      //    
//      //    vehicle* car = RL_MALLOC(sizeof(vehicle));
//      //    
//      //    // car body
//      //    dMass m;
//      //    dMassSetBox(&m, 1, carScale.x, carScale.y, carScale.z);  // density
//      //    dMassAdjust(&m, 550); // mass
//      //    
//      //    car->bodies[0] = dBodyCreate(world);
//      //    dBodySetMass(car->bodies[0], &m);
//      //    dBodySetAutoDisableFlag( car->bodies[0], 0 );
//      //
//      //
//      //    car->geoms[0] = dCreateBox(space, carScale.x, carScale.y, carScale.z);
//      //    dGeomSetBody(car->geoms[0], car->bodies[0]);
//      //    
//      //    // TODO used a little later and should be a parameter
//      //    dBodySetPosition(car->bodies[0], 15, 6, 15.5);
//      //    
//      //    dGeomID front = dCreateBox(space, 0.5, 0.5, 0.5);
//      //    dGeomSetBody(front, car->bodies[0]);
//      //    dGeomSetOffsetPosition(front, carScale.x/2-0.25, carScale.y/2+0.25 , 0);
//      //    
//      //    car->bodies[5] = dBodyCreate(world);
//      //    dBodySetMass(car->bodies[5], &m);
//      //    dBodySetAutoDisableFlag( car->bodies[5], 0 );
//      //    // see previous TODO
//      //    dBodySetPosition(car->bodies[5], 15, 6-1, 15.5);
//      //    car->geoms[5] = dCreateSphere(space,1);
//      //    dGeomSetBody(car->geoms[5],car->bodies[5]);
//      //    disabled.collidable = false;
//      //    dGeomSetData(car->geoms[5], &disabled);
//      //    
//      //    car->joints[5] = dJointCreateFixed (world, 0);
//      //    dJointAttach(car->joints[5], car->bodies[0], car->bodies[5]);
//      //    dJointSetFixed (car->joints[5]);
//      //    
//      //    // wheels
//      //    dMassSetCylinder(&m, 1, 3, wheelRadius, wheelWidth);
//      //    dMassAdjust(&m, 2); // mass
//      //    dQuaternion q;
//      //    dQFromAxisAndAngle(q, 0, 0, 1, M_PI * 0.5);
//      //    for(int i = 1; i <= 4; ++i)
//      //    {
//      //        car->bodies[i] = dBodyCreate(world);
//      //        dBodySetMass(car->bodies[i], &m);
//      //        dBodySetQuaternion(car->bodies[i], q);
//      //        car->geoms[i] = dCreateCylinder(space, wheelRadius, wheelWidth);
//      //        dGeomSetBody(car->geoms[i], car->bodies[i]);
//      //        dBodySetFiniteRotationMode( car->bodies[i], 1 );
//      //            dBodySetAutoDisableFlag( car->bodies[i], 0 );
//      //    }
//      //
//      //    const dReal* cp = dBodyGetPosition(car->bodies[0]);
//      //    // TODO wheel base and axel width should be parameters
//      //    dBodySetPosition(car->bodies[1], cp[0]+1.2, cp[1]-.5, cp[2]-1); 
//      //    dBodySetPosition(car->bodies[2], cp[0]+1.2, cp[1]-.5, cp[2]+1); 
//      //    dBodySetPosition(car->bodies[3], cp[0]-1.2, cp[1]-.5, cp[2]-1); 
//      //    dBodySetPosition(car->bodies[4], cp[0]-1.2, cp[1]-.5, cp[2]+1); 
//      //
//      //    // hinge2 (combined steering / suspension / motor !)
//      //    for(int i = 0; i < 4; ++i)
//      //    {
//      //        car->joints[i] = dJointCreateHinge2(world, 0);
//      //        dJointAttach(car->joints[i], car->bodies[0], car->bodies[i+1]);
//      //        const dReal* wPos = dBodyGetPosition(car->bodies[i+1]);
//      //        dJointSetHinge2Anchor(car->joints[i], wPos[0], wPos[1], wPos[2]);
//      //        
//      //        dReal axis1[] = { 0, -1, 0 };
//      //        dReal axis2[] = { 0, 0, ((i % 2) == 0) ? -1 : 1};
//      //        
//      //        // replacement for deprecated calls
//      //        dJointSetHinge2Axes (car->joints[i], axis1, axis2);
//      //        //dJointSetHinge2Axis1(joints[i], 0, 1, 0);
//      //        //dJointSetHinge2Axis2(joints[i], 0, 0, ((i % 2) == 0) ? -1 : 1);
//      //
//      //        dJointSetHinge2Param(car->joints[i], dParamLoStop, 0);
//      //        dJointSetHinge2Param(car->joints[i], dParamHiStop, 0);
//      //        dJointSetHinge2Param(car->joints[i], dParamLoStop, 0);
//      //        dJointSetHinge2Param(car->joints[i], dParamHiStop, 0);
//      //        dJointSetHinge2Param(car->joints[i], dParamFMax, 1500);
//      //
//      //        dJointSetHinge2Param(car->joints[i], dParamVel2, dInfinity);
//      //        dJointSetHinge2Param(car->joints[i], dParamFMax2, 1500);
//      //
//      //        dJointSetHinge2Param(car->joints[i], dParamSuspensionERP, 0.7);
//      //        dJointSetHinge2Param(car->joints[i], dParamSuspensionCFM, 0.0025);
//      //
//      //        // steering
//      //        if (i<2) {
//      //            dJointSetHinge2Param (car->joints[i],dParamFMax,500);
//      //            dJointSetHinge2Param (car->joints[i],dParamLoStop,-0.5);
//      //            dJointSetHinge2Param (car->joints[i],dParamHiStop,0.5);
//      //            dJointSetHinge2Param (car->joints[i],dParamLoStop,-0.5);
//      //            dJointSetHinge2Param (car->joints[i],dParamHiStop,0.5);
//      //            dJointSetHinge2Param (car->joints[i],dParamFudgeFactor,0.1);
//      //        }
//      //        
//      //    }
//      //    // disable motor on front wheels
//      // dJointSetHinge2Param(car->joints[0], dParamFMax2, 0);
//      // dJointSetHinge2Param(car->joints[1], dParamFMax2, 0);
//      //
//      //    return car;
//      //}
//      //
//      //
//      //void updateVehicle(vehicle *car, float accel, float maxAccelForce, 
//      //                    float steer, float steerFactor)
//      //{
//      //        float target;
//      //        target = 0;
//      //        if (fabs(accel) > 0.1) target = maxAccelForce;
//      //        //dJointSetHinge2Param( car->joints[0], dParamVel2, -accel );
//      //        //dJointSetHinge2Param( car->joints[1], dParamVel2, accel );
//      //        dJointSetHinge2Param( car->joints[2], dParamVel2, -accel );
//      //        dJointSetHinge2Param( car->joints[3], dParamVel2, accel );
//      //
//      //        //dJointSetHinge2Param( car->joints[0], dParamFMax2, target );
//      //        //dJointSetHinge2Param( car->joints[1], dParamFMax2, target );
//      //        dJointSetHinge2Param( car->joints[2], dParamFMax2, target );
//      //        dJointSetHinge2Param( car->joints[3], dParamFMax2, target );
//      //        
//      //        for(int i=0;i<2;i++) {
//      //            dReal v = steer - dJointGetHinge2Angle1 (car->joints[i]);
//      //            v *= steerFactor;
//      //            dJointSetHinge2Param (car->joints[i],dParamVel,v);
//      //        }
//      //}    
//      //
//      //
//      //void unflipVehicle (vehicle *car)
//      //{
//      //    const dReal* cp = dBodyGetPosition(car->bodies[0]);
//      //    dBodySetPosition(car->bodies[0], cp[0], cp[1]+2, cp[2]);
//      //
//      //    const dReal* R = dBodyGetRotation(car->bodies[0]);
//      //    dReal newR[16];
//      //    dRFromEulerAngles(newR, 0, -atan2(-R[2],R[0]) , 0);
//      //    dBodySetRotation(car->bodies[0], newR);
//      //    
//      //    // wheel offsets
//      //    // TODO make configurable & use in vehicle set up 
//      //    dReal wheelOffsets[4][3] = {
//      //           { +1.2, -.6, -1 },
//      //           { +1.2, -.6, +1 },
//      //           { -1.2, -.6, -1 },
//      //           { -1.2, -.6, +1 }
//      //        };
//      //
//      //    for (int i=1; i<5; i++) {
//      //        dVector3 pb;
//      //        dBodyGetRelPointPos(car->bodies[0], wheelOffsets[i-1][0], wheelOffsets[i-1][1], wheelOffsets[i-1][2], pb);
//      //        dBodySetPosition(car->bodies[i], pb[0], pb[1], pb[2]);
//      //    }
//      //
//      //}
//      
//      #include "raylib.h"
//      #include "raymath.h"
//      
//      #define RLIGHTS_IMPLEMENTATION
//      #include "rlights.h"
//      
//      #include <ode/ode.h>
//      #include "raylibODE.h"
//      
//      #include "assert.h"
//      
//      /*
//       * get ODE from https://bitbucket.org/odedevs/ode/downloads/
//       *
//       * extract ode 0.16.2 into the main directory of this project
//       * 
//       * cd into it
//       * 
//       * I'd suggest building it with this configuration
//       * ./configure --enable-double-precision --enable-ou --enable-libccd --with-box-cylinder=libccd --with-drawstuff=none --disable-demos --with-libccd=internal
//       *
//       * and run make, you should then be set to compile this project
//       */
//      
//      
//      // globals in use by near callback
//      dWorldID world;
//      dJointGroupID contactgroup;
//      
//      Model box;
//      //Model ball;
//      //Model cylinder;
//      
//      //int numObj = 100; // number of bodies
//      
//      
//      inline float rndf(float min, float max);
//      // macro candidate ? marcro's? eek!
//      
//      float rndf(float min, float max) 
//      {
//          return ((float)rand() / (float)(RAND_MAX)) * (max - min) + min;
//      }
//      
//      
//      
//      // when objects potentially collide this callback is called
//      // you can rule out certain collisions or use different surface parameters
//      // depending what object types collide.... lots of flexibility and power here!
//      #define MAX_CONTACTS 8
//      
//      static void nearCallback(void *data, dGeomID o1, dGeomID o2)
//      {
//          (void)data;
//          int i;
//      
//          // exit without doing anything if the two bodies are connected by a joint
//          dBodyID b1 = dGeomGetBody(o1);
//          dBodyID b2 = dGeomGetBody(o2);
//          //if (b1==b2) return;
//          if (b1 && b2 && dAreConnectedExcluding(b1, b2, dJointTypeContact))
//              return;
//              
//          if (!checkColliding(o1)) return;
//          if (!checkColliding(o2)) return;
//      
//          // getting these just so can sometimes be a little bit of a black art!
//          dContact contact[MAX_CONTACTS]; // up to MAX_CONTACTS contacts per body-body
//          for (i = 0; i < MAX_CONTACTS; i++) {
//              contact[i].surface.mode = dContactSlip1 | dContactSlip2 |
//                                          dContactSoftERP | dContactSoftCFM | dContactApprox1;
//              contact[i].surface.mu = 1000;
//              contact[i].surface.slip1 = 0.0001;
//              contact[i].surface.slip2 = 0.001;
//              contact[i].surface.soft_erp = 0.5;
//              contact[i].surface.soft_cfm = 0.0003;
//            
//              contact[i].surface.bounce = 0.1;
//              contact[i].surface.bounce_vel = 0.1;
//      
//          }
//          int numc = dCollide(o1, o2, MAX_CONTACTS, &contact[0].geom,
//                              sizeof(dContact));
//          if (numc) {
//              dMatrix3 RI;
//              dRSetIdentity(RI);
//              for (i = 0; i < numc; i++) {
//                  dJointID c =
//                      dJointCreateContact(world, contactgroup, contact + i);
//                  dJointAttach(c, b1, b2);
//              }
//          }
//      
//      }
//      
//      
//      int main(void)
//      {
//      
//      //
//      //    assert(sizeof(dReal) == sizeof(double));
//      
//          srand ( time(NULL) );
//      
//      //    // Initialization
//      //    //--------------------------------------------------------------------------------------
//      //    const int screenWidth = 1920/2;
//      //    const int screenHeight = 1080/2;
//      
//          // a space can have multiple "worlds" for example you might have different
//          // sub levels that never interact, or the inside and outside of a building
//          dSpaceID space;
//      
//          ////////////////////////////////////////////////////////////////////////////////////////////
//          // create an array of bodies
//          dBodyID obj[numObj];
//      
//          SetWindowState(FLAG_VSYNC_HINT | FLAG_MSAA_4X_HINT);
//          InitWindow(screenWidth, screenHeight, "raylib ODE and a car!");
//      
//          // Define the camera to look into our 3d world
//          Camera camera = {(Vector3){ 25.0f, 15.0f, 25.0f }, (Vector3){ 0.0f, 0.5f, 0.0f },
//                              (Vector3){ 0.0f, 1.0f, 0.0f }, 45.0f, CAMERA_PERSPECTIVE};
//      
//          box = LoadModelFromMesh(GenMeshCube(1,1,1));
//          ball = LoadModelFromMesh(GenMeshSphere(.5,32,32));
//          // alas gen cylinder is wrong orientation for ODE...
//          // so rather than muck about at render time just make one the right orientation
//          cylinder = LoadModel("data/cylinder.obj");
//          
//          Model ground = LoadModel("data/ground.obj");
//      
//          // texture the models
//          Texture earthTx = LoadTexture("data/earth.png");
//          Texture crateTx = LoadTexture("data/crate.png");
//          Texture drumTx = LoadTexture("data/drum.png");
//          Texture grassTx = LoadTexture("data/grass.png");
//      
//          box.materials[0].maps[MAP_DIFFUSE].texture = crateTx;
//          ball.materials[0].maps[MAP_DIFFUSE].texture = earthTx;
//          cylinder.materials[0].maps[MAP_DIFFUSE].texture = drumTx;
//          ground.materials[0].maps[MAP_DIFFUSE].texture = grassTx;
//      
//          Shader shader = LoadShader("data/simpleLight.vs", "data/simpleLight.fs");
//          // load a shader and set up some uniforms
//          shader.locs[SHADER_LOC_MATRIX_MODEL] = GetShaderLocation(shader, "matModel");
//          shader.locs[SHADER_LOC_VECTOR_VIEW] = GetShaderLocation(shader, "viewPos");
//      
//          
//          // ambient light level
//          int amb = GetShaderLocation(shader, "ambient");
//          SetShaderValue(shader, amb, (float[4]){0.2,0.2,0.2,1.0}, SHADER_UNIFORM_VEC4);
//      
//          // models share the same shader
//          box.materials[0].shader = shader;
//          ball.materials[0].shader = shader;
//          cylinder.materials[0].shader = shader;
//          ground.materials[0].shader = shader;
//          
//          // using 4 point lights, white, red, green and blue
//          Light lights[MAX_LIGHTS];
//      
//          lights[0] = CreateLight(LIGHT_POINT, (Vector3){ -25,25,25 }, Vector3Zero(),
//                          (Color){128,128,128,255}, shader);
//          lights[1] = CreateLight(LIGHT_POINT, (Vector3){ -25,25,-25 }, Vector3Zero(),
//                          (Color){64,64,64,255}, shader);
//      /*                    
//          lights[2] = CreateLight(LIGHT_POINT, (Vector3){ -25,25,-25 }, Vector3Zero(),
//                          GREEN, shader);
//          lights[3] = CreateLight(LIGHT_POINT, (Vector3){ -25,25,25 }, Vector3Zero(),
//                          BLUE, shader);
//      */
//      
//          dInitODE2(0);   // initialise and create the physics
//          dAllocateODEDataForThread(dAllocateMaskAll);
//          
//          world = dWorldCreate();
//          printf("phys iterations per step %i\n",dWorldGetQuickStepNumIterations(world));
//          space = dHashSpaceCreate(NULL);
//          contactgroup = dJointGroupCreate(0);
//          dWorldSetGravity(world, 0, -9.8, 0);    // gravity
//          
//          dWorldSetAutoDisableFlag (world, 1);
//          dWorldSetAutoDisableLinearThreshold (world, 0.05);
//          dWorldSetAutoDisableAngularThreshold (world, 0.05);
//          dWorldSetAutoDisableSteps (world, 4);
//      
//      
//          vehicle* car = CreateVehicle(space, world);
//          
//          // create some decidedly sub optimal indices!
//          // for the ground trimesh
//          int nV = ground.meshes[0].vertexCount;
//          int *groundInd = RL_MALLOC(nV*sizeof(int));
//          for (int i = 0; i<nV; i++ ) {
//              groundInd[i] = i;
//          }
//          
//          // static tri mesh data to geom
//          dTriMeshDataID triData = dGeomTriMeshDataCreate();
//          dGeomTriMeshDataBuildSingle(triData, ground.meshes[0].vertices,
//                                  3 * sizeof(float), nV,
//                                  groundInd, nV,
//                                  3 * sizeof(int));
//          dCreateTriMesh(space, triData, NULL, NULL, NULL);
//          
//      
//          /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//          // create the physics bodies
//          for (int i = 0; i < numObj; i++) {
//              obj[i] = dBodyCreate(world);
//              dGeomID geom;
//              dMatrix3 R;
//              dMass m;
//              float typ = rndf(0,1);
//              if (typ < .25) {                //  box
//                  Vector3 s = (Vector3){rndf(0.5, 2), rndf(0.5, 2), rndf(0.5, 2)};
//                  geom = dCreateBox(space, s.x, s.y, s.z);
//                  dMassSetBox (&m, 1, s.x, s.y, s.z);
//              } else if (typ < .5) {          //  sphere
//                  float r = rndf(0.5, 1);
//                  geom = dCreateSphere(space, r);
//                  dMassSetSphere(&m, 1, r);
//              } else if (typ < .75) {         //  cylinder
//                  float l = rndf(0.5, 2);
//                  float r = rndf(0.25, 1);
//                  geom = dCreateCylinder(space, r, l);
//                  dMassSetCylinder(&m, 1, 3, r, l);
//              } else {                        //  composite of cylinder with 2 spheres
//                  float l = rndf(.9,1.5);
//                  
//                  geom = dCreateCylinder(space, 0.25, l);
//                  dGeomID geom2 = dCreateSphere(space, l/2);
//                  dGeomID geom3 = dCreateSphere(space, l/2);
//      
//                  
//                  dMass m2,m3;
//                  dMassSetSphere(&m2, 1, l/2);
//                  dMassTranslate(&m2,0, 0, l - 0.25);
//                  dMassSetSphere(&m3, 1, l/2);
//                  dMassTranslate(&m3,0, 0, -l + 0.25);
//                  dMassSetCylinder(&m, 1, 3, .25, l);
//                  dMassAdd(&m2, &m3);
//                  dMassAdd(&m, &m2);
//                  
//                  dGeomSetBody(geom2, obj[i]);
//                  dGeomSetBody(geom3, obj[i]);
//                  dGeomSetOffsetPosition(geom2, 0, 0, l - 0.25);
//                  dGeomSetOffsetPosition(geom3, 0, 0, -l + 0.25);
//      
//              }
//      
//              // give the body a random position and rotation
//              dBodySetPosition(obj[i],
//                                  dRandReal() * 10 - 5, 4+(i/10), dRandReal() * 10 - 5);
//              dRFromAxisAndAngle(R, dRandReal() * 2.0 - 1.0,
//                                  dRandReal() * 2.0 - 1.0,
//                                  dRandReal() * 2.0 - 1.0,
//                                  dRandReal() * M_PI*2 - M_PI);
//              dBodySetRotation(obj[i], R);
//              // set the bodies mass and the newly created geometry
//              dGeomSetBody(geom, obj[i]);
//              dBodySetMass(obj[i], &m);
//      
//      
//          }
//          
//      
//          float accel=0,steer=0;
//          Vector3 debug = {0};
//          bool antiSway = true;
//          
//          // keep the physics fixed time in step with the render frame
//          // rate which we don't know in advance
//          double frameTime = 0; 
//          double physTime = 0;
//          const double physSlice = 1.0 / 240.0;
//          const int maxPsteps = 6;
//          int carFlipped = 0; // number of frames car roll is >90
//      
//          //--------------------------------------------------------------------------------------
//          //
//          // Main game loop
//          //
//          //--------------------------------------------------------------------------------------
//          while (!WindowShouldClose())            // Detect window close button or ESC key
//          {
//              //--------------------------------------------------------------------------------------
//              // Update
//              //----------------------------------------------------------------------------------
//      
//      
//              
//              // extract just the roll of the car
//              // count how many frames its >90 degrees either way
//              const dReal* q = dBodyGetQuaternion(car->bodies[0]);
//              double z0 = 2.0f*(q[0]*q[3] + q[1]*q[2]);
//              double z1 = 1.0f - 2.0f*(q[1]*q[1] + q[3]*q[3]);
//              double roll = atan2f(z0, z1);
//              if ( fabs(roll) > (M_PI_2-0.001) ) {
//                  carFlipped++;
//              } else {
//                  carFlipped=0;
//              }
//          
//              // if the car roll >90 degrees for 100 frames then flip it
//              if (carFlipped > 100) {
//                  unflipVehicle(car);
//              }
//      
//      
//              
//              accel *= .99;
//              if (IsKeyDown(KEY_UP)) accel +=2;
//              if (IsKeyDown(KEY_DOWN)) accel -=2;
//              if (accel > 50) accel = 50;
//              if (accel < -15) accel = -15;
//              
//              
//              if (IsKeyDown(KEY_RIGHT)) steer -=.1;
//              if (IsKeyDown(KEY_LEFT)) steer +=.1;
//              if (!IsKeyDown(KEY_RIGHT) && !IsKeyDown(KEY_LEFT)) steer *= .5;
//              if (steer > .5) steer = .5;
//              if (steer < -.5) steer = -.5;
//      
//                    
//              updateVehicle(car, accel, 800.0, steer, 10.0);
//      
//      
//              const dReal* cp = dBodyGetPosition(car->bodies[0]);
//              camera.target = (Vector3){cp[0],cp[1]+1,cp[2]};
//              
//              float lerp = 0.1f;
//      
//              dVector3 co;
//              dBodyGetRelPointPos(car->bodies[0], -8, 3, 0, co);
//              
//              camera.position.x -= (camera.position.x - co[0]) * lerp  ;// * (1/ft);
//              camera.position.y -= (camera.position.y - co[1])  * lerp ;// * (1/ft);
//              camera.position.z -= (camera.position.z - co[2]) * lerp ;// * (1/ft);
//              UpdateCamera(&camera);
//              
//              bool spcdn = IsKeyDown(KEY_SPACE);
//             
//             ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//              for (int i = 0; i < numObj; i++) {
//                  const dReal* pos = dBodyGetPosition(obj[i]);
//                  if (spcdn) {
//                      // apply force if the space key is held
//                      const dReal* v = dBodyGetLinearVel(obj[0]);
//                      if (v[1] < 10 && pos[1]<10) { // cap upwards velocity and don't let it get too high
//                          dBodyEnable (obj[i]); // case its gone to sleep
//                          dMass mass;
//                          dBodyGetMass (obj[i], &mass);
//                          // give some object more force than others
//                          float f = (6+(((float)i/numObj)*4)) * mass.mass;
//                          dBodyAddForce(obj[i], rndf(-f,f), f*4, rndf(-f,f));
//                      }
//                  }
//      
//                  
//                  if(pos[1]<-10) {
//                      // teleport back if fallen off the ground
//                      dBodySetPosition(obj[i], dRandReal() * 10 - 5,
//                                              12 + rndf(1,2), dRandReal() * 10 - 5);
//                      dBodySetLinearVel(obj[i], 0, 0, 0);
//                      dBodySetAngularVel(obj[i], 0, 0, 0);
//                  }
//              }
//              
//              UpdateCamera(&camera);              // Update camera
//      
//              if (IsKeyPressed(KEY_L)) { lights[0].enabled = !lights[0].enabled; UpdateLightValues(shader, lights[0]);}
//              
//              // update the light shader with the camera view position
//              SetShaderValue(shader, shader.locs[SHADER_LOC_VECTOR_VIEW], &camera.position.x, SHADER_UNIFORM_VEC3);
//      
//              frameTime += GetFrameTime();
//              int pSteps = 0;
//              physTime = GetTime(); 
//              
//              while (frameTime > physSlice) {
//                  // check for collisions
//                  // TODO use 2nd param data to pass custom structure with
//                  // world and space ID's to avoid use of globals...
//                  dSpaceCollide(space, 0, &nearCallback);
//                  
//                  // step the world
//                  dWorldQuickStep(world, physSlice);  // NB fixed time step is important
//                  dJointGroupEmpty(contactgroup);
//                  
//                  frameTime -= physSlice;
//                  pSteps++;
//                  if (pSteps > maxPsteps) {
//                      frameTime = 0;
//                      break;      
//                  }
//              }
//              
//              physTime = GetTime() - physTime;    
//      
//              
//      
//              //----------------------------------------------------------------------------------
//              // Draw
//              //----------------------------------------------------------------------------------
//           
//              BeginDrawing();
//      
//              ClearBackground(BLACK);
//      
//              BeginMode3D(camera);
//                  DrawModel(ground,(Vector3){0,0,0},1,WHITE);
//                  
//                  // NB normally you wouldn't be drawing the collision meshes
//                  // instead you'd iterrate all the bodies get a user data pointer
//                  // from the body you'd previously set and use that to look up
//                  // what you are rendering oriented and positioned as per the
//                  // body
//                  drawAllSpaceGeoms(space);        
//                  DrawGrid(100, 1.0f);
//      
//              EndMode3D();
//      
//              //DrawFPS(10, 10); // can't see it in lime green half the time!!
//      
//              //if (pSteps > maxPsteps) DrawText("WARNING CPU overloaded lagging real time", 10, 0, 20, RED);
//              //DrawText(TextFormat("%2i FPS", GetFPS()), 10, 20, 20, WHITE);
//              //DrawText(FormatText("accel %4.4f",accel), 10, 40, 20, WHITE);
//              //DrawText(FormatText("steer %4.4f",steer), 10, 60, 20, WHITE);
//              //if (!antiSway) DrawText("Anti sway bars OFF", 10, 80, 20, RED);
//              //DrawText(FormatText("debug %4.4f %4.4f %4.4f",debug.x,debug.y,debug.z), 10, 100, 20, WHITE);
//              //DrawText(FormatText("Phys steps per frame %i",pSteps), 10, 120, 20, WHITE);
//              //DrawText(FormatText("Phys time per frame %i",physTime), 10, 140, 20, WHITE);
//              //DrawText(FormatText("total time per frame %i",frameTime), 10, 160, 20, WHITE);
//              //DrawText(FormatText("objects %i",numObj), 10, 180, 20, WHITE);
//      
//          
//              //DrawText(FormatText("roll %.4f",fabs(roll)), 10, 200, 20, WHITE);
//              //
//              //const double* v = dBodyGetLinearVel(car->bodies[0]);
//              //float vel = Vector3Length((Vector3){v[0],v[1],v[2]}) * 2.23693629f;
//              //DrawText(FormatText("mph %.4f",vel), 10, 220, 20, WHITE);
//      //printf("%i %i\n",pSteps, numObj);
//      
//              //EndDrawing();
//      
//          }
//              //----------------------------------------------------------------------------------
//      
//      
//          ////--------------------------------------------------------------------------------------
//          //// De-Initialization
//          ////--------------------------------------------------------------------------------------
//          //UnloadModel(box);
//          //UnloadModel(ball);
//          //UnloadModel(cylinder);
//          //UnloadModel(ground);
//          //UnloadTexture(drumTx);
//          //UnloadTexture(earthTx);
//          //UnloadTexture(crateTx);
//          //UnloadTexture(grassTx);
//          //UnloadShader(shader);
//          
//          //RL_FREE(car);
//          //
//          //RL_FREE(groundInd);
//          //dGeomTriMeshDataDestroy(triData);
//      
//          //dJointGroupEmpty(contactgroup);
//          //dJointGroupDestroy(contactgroup);
//          //dSpaceDestroy(space);
//          //dWorldDestroy(world);
//          //dCloseODE();
//      
//          //CloseWindow();              // Close window and OpenGL context
//          //--------------------------------------------------------------------------------------
//      
//      
//          
//          return 0;
//      }
//      
