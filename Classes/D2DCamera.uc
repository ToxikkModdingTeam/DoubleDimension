//================================================================
// DoubleDimension.D2DCamera
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class D2DCamera extends Camera;

var Vector CameraOffset;

var float CurrentZoom;

// animating CurrentZoom smoothly
var float PreviousZoom;
var float TargetZoom;
var float TargetZoomRemDur;
var float TargetZoomTotalDur;


// Updates the camera's view target. Called once per tick
function UpdateViewTarget(out TViewTarget OutVT, float dt)
{
	if (PendingViewTarget.Target != None && OutVT == ViewTarget && BlendParams.bLockOutgoing)
		return;

	AnimateZoom(dt);

	// Add the camera offset to the target's location to get the location of the camera
	OutVT.POV.Location = OutVT.Target.Location + CameraOffset;

	// Make the camera point towards the target's location
	OutVT.POV.Rotation = Rotator(OutVT.Target.Location - OutVT.POV.Location);

	bConstrainAspectRatio = true;
	ConstrainedAspectRatio = AspectRatio16x9;
	OutVT.AspectRatio = ConstrainedAspectRatio;
}

function AnimateZoom(float dt)
{
	local float pct_time;
	local float pct_val;

	if ( CurrentZoom == TargetZoom )
		return;

	if ( dt >= TargetZoomRemDur )
		CurrentZoom = TargetZoom;
	else
	{
		TargetZoomRemDur -= dt;
		pct_time = 1.0 - TargetZoomRemDur/TargetZoomTotalDur;
		pct_val = Sin( Sin(pct_time * Pi / 2.0) * Pi / 2.0);
		CurrentZoom = PreviousZoom + pct_val*(TargetZoom-PreviousZoom);
	}

	CameraOffset = CurrentZoom * default.CameraOffset;
}

defaultproperties
{
	CameraOffset=(X=-1000,Y=0,Z=0)
	CurrentZoom=1.0
	TargetZoom=1.0

	// setting FreeCam style will prevent weaponfire from using camera for tracing (see Pawn.GetBaseAimRotation)
	CameraStyle=FreeCam
}
