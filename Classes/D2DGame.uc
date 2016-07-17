//================================================================
// DoubleDimension.D2DGame
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class D2DGame extends CRZBloodLust;


// Remove momentum along X axis
//TODO: see about removing the "random momentum" when pawns touch each other
function ReduceDamage(out int Damage, Pawn injured, Controller InstigatedBy, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
	Momentum.X = 0;
	Super.ReduceDamage(Damage, injured, instigatedBy, HitLocation, Momentum, DamageType, DamageCauser);
}


// Replace standard sniper with ours, custom zoom
function bool CheckRelevance(Actor Other)
{
	local CRZWeaponPickupFactory PF;

	if ( !Super.CheckRelevance(Other) )
		return false;

	PF = CRZWeaponPickupFactory(Other);
	if ( PF != None && PF.WeaponPickupClass == class'CRZWeap_SniperRifle' )
	{
		PF.WeaponPickupClass = class'D2DWeap_SniperRifle';
		PF.InitializePickup();
	}

	return true;
}


defaultproperties
{
	Acronym="TT"
	MapPrefixes(0)="TT"
	PlayerControllerClass=class'D2DPlayerController'
	DefaultPawnClass=class'D2DPawn'
	HUDType=class'D2DHud'
}
