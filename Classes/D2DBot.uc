//================================================================
// DoubleDimension.D2DBot
// ----------------
// Ugly ass hack to stop bots from firing/tracking outer screen
// ----------------
// by Chatouille
//================================================================
class D2DBot extends CRZBot;

var float MaxAttackDist;

// Not working in the real environment, cannot override the final native method
//TODO: copy parts of code calling that method, and call my method instead
function bool LineOfSightTo(Actor Other, optional vector chkLocation, optional bool bTryAlternateTargetLoc)
{
	if ( VSize(Other.Location - Pawn.Location) > MaxAttackDist )
		return false;

	return Super.LineOfSightTo(Other, chkLocation, bTryAlternateTargetLoc);
}

defaultproperties
{
	MaxAttackDist=1050
}
