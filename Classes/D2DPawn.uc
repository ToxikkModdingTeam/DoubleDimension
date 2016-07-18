//================================================================
// DoubleDimension.D2DPawn
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class D2DPawn extends CRZPawn;


function bool Dodge(EDoubleClickDir DoubleClickMove)
{
	// PLAYER: dodge left/right becomes forward/backwards
	if ( PlayerController(Controller) != None )
	{
		if ( DoubleClickMove == DCLICK_Back || DoubleClickMove == DCLICK_Forward )
			return false;

		if ( DoubleClickMove == DCLICK_Left )
			return Super.Dodge(Rotation.Yaw < 0 ? DCLICK_Forward : DCLICK_Back);

		if ( DoubleClickMove == DCLICK_Right )
			return Super.Dodge(Rotation.Yaw < 0 ? DCLICK_Back : DCLICK_Forward);
	}

	// BOT: no strafe dodges, only forward/backwards
	else
	{
		if ( DoubleClickMove == DCLICK_Left || DoubleClickMove == DCLICK_Right )
			return false;
	}

	return Super.Dodge(DoubleClickMove);
}


defaultproperties
{
	// AI
	bCanStrafe=false
	//HearingThreshold=2800
	//Alertness=0
	SightRadius=950
	PeripheralVision=-1
	ControllerClass=class'D2DBot'
}
