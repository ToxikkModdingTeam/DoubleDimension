//================================================================
// package.D2DWeap_SniperRifle
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class D2DWeap_SniperRifle extends CRZWeap_SniperRifle;

var float ZoomMult;
var float ZoomDuration;

var bool bZooming;

simulated function GFxMoviePlayer CreateScope()
{
	return None;
}

simulated state WeaponFiring
{
	simulated event Tick(float dt)
	{
		Super(CRZWeapon).Tick(dt);
	}
}

// Sound is called right before firing - the bZooming var has not changed yet
simulated function PlayFiringSound()
{
	if ( CurrentFireMode == 1 && WorldInfo.NetMode != NM_DedicatedServer )
	{
		if ( bZooming )
			WeaponPlaySound(WeaponFireSnd[2]);  // disabling zoom
		else
			WeaponPlaySound(WeaponFireSnd[1]);  // enabling zoom
	}
	else
		Super.PlayFiringSound();
}

// Custom zoom
simulated function CustomFire()
{
	local D2DPlayerController PC;

	if ( Instigator != None )
	{
		PC = D2DPlayerController(Instigator.Controller);
		if ( PC != None )
		{
			bZooming = !bZooming;
			PC.SmoothCameraZoom(bZooming ? ZoomMult : 1.0, ZoomDuration);
		}
	}
}

simulated function EZoomState GetZoomedState()
{
	return ZST_NotZoomed;
}

simulated state WeaponPuttingDown
{
	simulated function BeginState(Name PrevStateName)
	{
		if ( bZooming )
			CustomFire();

		Super.BeginState(PrevStateName);
	}
}

reliable client function ClientWeaponThrown()
{
	if ( bZooming )
		CustomFire();

	Super.ClientWeaponThrown();
}

simulated event Destroyed()
{
	if ( bZooming )
		CustomFire();

	Super.Destroyed();
}

defaultproperties
{
	bZoomedFireMode[1]=0
	WeaponFireTypes(1)=EWFT_Custom
	FireInterval(1)=0.33

	ZoomMult=1.5
	ZoomDuration=0.8

	// enable zoom sound
	WeaponFireSnd(1)=SoundCue'Snd_Pickups.Steroids.A_Powerup_Steroids_WarningCue'
	// disable zoom sound
	WeaponFireSnd(2)=SoundCue'Snd_Pickups.Steroids.A_Powerup_Steroids_WarningCue'
}
