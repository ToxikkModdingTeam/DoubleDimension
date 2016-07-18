//================================================================
// DoubleDimension.D2DPlayerController
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class D2DPlayerController extends CRZPlayerController;

var Vector CrosshairPos;

function UpdateRotation(float dt)
{
	local Vector WeapCenterOffset, Rot2D;
	local Rotator TargetRot;

	ViewShake(dt);

	// Update crosshair pos
	CrosshairPos.X += (PlayerInput.aTurn - 0.5) / PlayerInput.MouseSensitivity;
	CrosshairPos.Y -= (PlayerInput.bInvertMouse ? -1 : 1) * (PlayerInput.aLookUp - 0.5) / PlayerInput.MouseSensitivity;
	CrosshairPos.Z = 0;

	// Get Pawn-To-Crosshair vector
	if ( Pawn != None )
	{
		WeapCenterOffset = CenterOffsetForWeapon((Pawn != None && Pawn.Weapon != None) ? Pawn.Weapon.Class : None);
		WeapCenterOffset.Y = -WeapCenterOffset.Y;   //invert because screen Y-axis is downwards

		if ( CrosshairPos.X < 0 )
			WeapCenterOffset.X *= -1;

		if ( Pawn.bIsCrouched ) //TODO: better handling for crouching, hardcode values in CenterOffsetForWeapon
			WeapCenterOffset.Y *= 0.5;

		Rot2D = Normal(CrosshairPos - WeapCenterOffset);    // this gives us approximate Weapon-To-Crosshair 2D vector
	}
	else
		Rot2D = Normal(CrosshairPos);

	// Convert to 3D Rotation
	TargetRot = Rot2DToRotation(Rot2D);

	//???
	//ProcessViewRotation(dt, ViewRot, DeltaRot);

	// Will orient Pawn's pitch in standalone/client
	SetRotation(TargetRot);

	if ( Pawn != None )
	{
		//???
		Pawn.SetDesiredRotation(Rotation);

		// Orients the pawn left or right
		Pawn.FaceRotation(Rotation, dt);

		// Will orient Pawn's pitch and weaponfire in multiplayer
		Pawn.SetRemoteViewPitch(Rotation.Pitch);


		// We want to aim at crosshair, but this is complex
		// because the first start location is the tip of the gun
		// and it rotates around with us.
		// At this point, we rotated along the Pawn-To-Crosshair vector

		//PROBLEM: We are not YET rotated... only next Tick or something it seems...
		// We'll stick to an approximate rotation, and then bias the firing in GetAdjustedAimFor()
/*
		// Get the fire start location with the current rotation
		if ( UTPawn(Pawn) != None && UTPawn(Pawn).CurrentWeaponAttachment != None )
			PawnToWeap = UTPawn(Pawn).CurrentWeaponAttachment.GetEffectLocation() - Pawn.Location;
		else
			PawnToWeap = Pawn.GetWeaponStartTraceLocation(Pawn.Weapon) - Pawn.Location;

		// Project to screen vector
		PawnToWeap.X = PawnToWeap.Y;
		PawnToWeap.Y = -PawnToWeap.Z;   // on-screen Y axis is inverted
		PawnToWeap.Z = 0;

		// Rotate again along the WeaponFireStart-To-Crosshair vector
		Rot2D = Normal(CrosshairPos - PawnToWeap);
		TargetRot = Rot2DToRotation(Rot2D);
		SetRotation(TargetRot);
*/
	}
}


// For a better Pawn-To-Crosshair vector alignment
function Vector CenterOffsetForWeapon(class<Weapon> WeapClass)
{
	Switch(WeapClass)
	{
		case class'CRZWeap_Impactor':       return Vect(0,8,0);
		case class'CRZWeap_PistolAW29':     return Vect(0,16,0);
		case class'CRZWeap_ShotgunSG12':    return Vect(0,20,0);
		case class'CRZWeap_PulseRifle':     return Vect(0,20,0);
		case class'D2DWeap_SniperRifle':    return Vect(0,20,0);
		case class'CRZWeap_ScionRifle':     return Vect(0,20,0);
		case class'CRZWeap_FlameThrower':   return Vect(0,16,0);
		case class'CRZWeap_RocketLauncher': return Vect(0,24,0);
		case class'CRZWeap_Hellraiser':     return Vect(0,20,0);
	}
	return Vect(0,20,0);
}


function Rotator Rot2DToRotation(Vector Rot2D)
{
	local Rotator Rot;

	if ( Rot2D.X < 0 )
		Rot.Yaw = -16384;
	else
		Rot.Yaw = 16384;

	Rot.Pitch = -Asin(Rot2D.Y) * RadToUnrRot;

	Rot.Roll = 0;

	return Rot;
}


// Trace direction for weapons
//NOTE: This is only for standalone. In multiplayer, Pawn rotation and RemoteViewPitch are used instead (see Pawn.GetAdjustedAimFor)
function Rotator GetAdjustedAimFor(Weapon W, Vector StartFireLoc)
{
	return Rotation;

	// Our approximated rotation is actually BETTER than the "exact" calculation below WTF??

	/*
	local Vector PawnToWeap, Rot2D;
	local Rotator TargetRot;

	// Get the fire start location
	if ( UTPawn(Pawn) != None && UTPawn(Pawn).CurrentWeaponAttachment != None )
		PawnToWeap = UTPawn(Pawn).CurrentWeaponAttachment.GetEffectLocation() - Pawn.Location;
	else
		PawnToWeap = Pawn.GetWeaponStartTraceLocation(Pawn.Weapon) - Pawn.Location;

	// Project to screen vector
	PawnToWeap.X = PawnToWeap.Y;
	PawnToWeap.Y = -PawnToWeap.Z;   // on-screen Y axis is inverted
	PawnToWeap.Z = 0;

	// Don't bias firing if crosshair is too close to center, it looks bullshit
	if ( VSize(CrosshairPos) < 2.0*VSize(PawnToWeap) )
		return Rotation;

	// Get WeaponStartFire-To-Crosshair vector
	Rot2D = Normal(CrosshairPos - PawnToWeap);

	// Convert to 3D Rotation
	TargetRot = Rot2DToRotation(Rot2D);

	return TargetRot;
	*/
}


state PlayerWalking
{
	function PlayerMove(float dt)
	{
		local Vector MoveAxis, NewAccel;
		local eDoubleClickDir DoubleClickMove;
		local Rotator OldRot;
		local bool bSaveJump;

		if ( Pawn == None )
		{
			GotoState('Dead');
			return;
		}

		MoveAxis = Vect(0,1,0);

		// Update acceleration
		NewAccel = PlayerInput.aStrafe*MoveAxis;
		NewAccel.Z = 0;
		NewAccel = Pawn.AccelRate*Normal(NewAccel);

		if ( IsLocalPlayerController() )
			AdjustPlayerWalkingMoveAccel(NewAccel);

		// Update rotation
		OldRot = Rotation;
		UpdateRotation(dt);

		// Handle jumping (?)
		bDoubleJump = false;
		if ( bPressedJump && Pawn.CannotJumpNow() )
		{
			bSaveJump = true;
			bPressedJump = false;
		}
		else
			bSaveJump = false;

		// Handle dodging (D2DPawn will fix directions)
		DoubleClickMove = PlayerInput.CheckForDoubleClickMove(dt/WorldInfo.TimeDilation);

		// save and replicate this move
		if ( Role < ROLE_Authority )
			ReplicateMove(dt, NewAccel, DoubleClickMove, OldRot-Rotation);
		else
			ProcessMove(dt, NewAccel, DoubleClickMove, OldRot-Rotation);

		bPressedJump = bSaveJump;
	}
}


//CRZ code completely removes PC Camera support, try to restore it...
simulated event GetPlayerViewPoint(out Vector out_Location, out Rotator out_Rotation)
{
	if ( !bBehindView )
		SetBehindView(true);

	Super(PlayerController).GetPlayerViewPoint(out_Location, out_Rotation);
}


state Spectating
{
	exec function BehindView() {}
}

simulated function SmoothCameraZoom(float TargetZoom, float Duration)
{
	local D2DCamera Cam;

	Cam = D2DCamera(PlayerCamera);
	if ( Cam != None )
	{
		Cam.PreviousZoom = Cam.CurrentZoom;
		Cam.TargetZoom = TargetZoom;
		Cam.TargetZoomTotalDur = Duration;
		Cam.TargetZoomRemDur = Duration;
	}
}

simulated function SetCameraZoom(float TargetZoom)
{
	local D2DCamera Cam;

	Cam = D2DCamera(PlayerCamera);
	if ( Cam != None )
	{
		Cam.CurrentZoom = TargetZoom;
		Cam.TargetZoom = TargetZoom;
		Cam.TargetZoomTotalDur = 0;
		Cam.TargetZoomRemDur = 0;
	}
}


defaultproperties
{
	CameraClass=class'D2DCamera'
	bForceBehindview=true
	CrosshairPos=(X=0,Y=0)
}
