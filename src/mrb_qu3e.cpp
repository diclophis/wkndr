///   //
///   
///   #include "../qu3e/src/q3.h"
///   
///   
///   struct Demo
///   {
///   	virtual ~Demo( ) {}
///   
///   	virtual void Init( ) {};
///   	//virtual void Update( ) {};
///   	//virtual void Shutdown( ) {};
///   
///   	//virtual void Render( q3Render *debugDrawer ) { (void)debugDrawer; }
///   	//virtual void KeyDown( unsigned char key ) { (void)key; }
///   	//virtual void KeyUp( unsigned char key ) { (void)key; }
///   	//virtual void LeftClick( i32 x, i32 y ) { (void)x; (void)y; }
///   };
///   
///   // Is frame by frame stepping enabled?
///   extern bool paused;
///   
///   // Can the simulation take a step, while paused is enabled?
///   extern bool singleStep;
///   
///   // Globals for running the scene
///   extern float dt;
///   extern q3Scene scene;
///   
///   //int InitApp( int argc, char** argv );
///   
///   // Globals for maintaining a list of demos
///   extern i32 demoCount;
///   extern i32 currentDemo;
///   
///   //#define Q3_DEMO_MAX_COUNT 64
///   //extern Demo* demos[ Q3_DEMO_MAX_COUNT ];
///   
///   
///   struct DropBoxes : public Demo
///   {
///   	virtual void Init( )
///   	{
///   		acc = 0;
///   
///   		// Create the floor
///   		q3BodyDef bodyDef;
///   		//bodyDef.axis.Set( q3RandomFloat( -1.0f, 1.0f ), q3RandomFloat( -1.0f, 1.0f ), q3RandomFloat( -1.0f, 1.0f ) );
///   		//bodyDef.angle = q3PI * q3RandomFloat( -1.0f, 1.0f );
///   		q3Body* body = scene.CreateBody( bodyDef );
///   
///   		q3BoxDef boxDef;
///   		boxDef.SetRestitution( 0 );
///   		q3Transform tx;
///   		q3Identity( tx );
///   		boxDef.Set( tx, q3Vec3( 50.0f, 1.0f, 50.0f ) );
///   		body->AddBox( boxDef );
///   
///   		// Create boxes
///   		//for ( i32 i = 0; i < 10; ++i )
///   		//{
///   		//	bodyDef.position.Set( 0.0f, 1.2f * (i + 1), -0.0f );
///   		//	//bodyDef.axis.Set( 0.0f, 1.0f, 0.0f );
///   		//	//bodyDef.angle = q3PI * q3RandomFloat( -1.0f, 1.0f );
///   		//	//bodyDef.angularVelocity.Set( 3.0f, 3.0f, 3.0f );
///   		//	//bodyDef.linearVelocity.Set( 2.0f, 0.0f, 0.0f );
///   		//	bodyDef.bodyType = eDynamicBody;
///   		//	body = scene.CreateBody( bodyDef );
///   		//	boxDef.Set( tx, q3Vec3( 1.0f, 1.0f, 1.0f ) );
///   		//	body->AddBox( boxDef );
///   		//}
///   	}
///   
///   	virtual void Update( )
///   	{
///   		acc += dt;
///   
///   		if ( acc > 1.0f )
///   		{
///   			acc = 0;
///   
///   			q3BodyDef bodyDef;
///   			bodyDef.position.Set( 0.0f, 3.0f, 0.0f );
///   			bodyDef.axis.Set( q3RandomFloat( -1.0f, 1.0f ), q3RandomFloat( -1.0f, 1.0f ), q3RandomFloat( -1.0f, 1.0f ) );
///   			bodyDef.angle = q3PI * q3RandomFloat( -1.0f, 1.0f );
///   			bodyDef.bodyType = eDynamicBody;
///   			bodyDef.angularVelocity.Set( q3RandomFloat( 1.0f, 3.0f ), q3RandomFloat( 1.0f, 3.0f ), q3RandomFloat( 1.0f, 3.0f ) );
///   			bodyDef.angularVelocity *= q3Sign( q3RandomFloat( -1.0f, 1.0f ) );
///   			bodyDef.linearVelocity.Set( q3RandomFloat( 1.0f, 3.0f ), q3RandomFloat( 1.0f, 3.0f ), q3RandomFloat( 1.0f, 3.0f ) );
///   			bodyDef.linearVelocity *= q3Sign( q3RandomFloat( -1.0f, 1.0f ) );
///   			q3Body* body = scene.CreateBody( bodyDef );
///   
///   			q3Transform tx;
///   			q3Identity( tx );
///   			q3BoxDef boxDef;
///   			boxDef.Set( tx, q3Vec3( 1.0f, 1.0f, 1.0f ) );
///   			body->AddBox( boxDef );
///   		}
///   	}
///   
///   	virtual void Shutdown( )
///   	{
///   		scene.RemoveAllBodies( );
///   	}
///   
///   	float acc;
///   };
