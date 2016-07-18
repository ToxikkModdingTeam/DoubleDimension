//================================================================
// DoubleDimension.D2DGame
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class D2DGame extends CRZBloodLust;


// Remove momentum along X axis
//NOTE: kind of useless now we stuck everything between two blocking volumes ^^
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
	Acronym="2D"
	MapPrefixes(0)="D2D"
	PlayerControllerClass=class'D2DPlayerController'
	DefaultPawnClass=class'D2DPawn'
	HUDType=class'D2DHud'
	BotClass=class'D2DBot'
}
