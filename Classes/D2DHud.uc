//================================================================
// DoubleDimension.D2DHud
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class D2DHud extends CRZHud;

var Texture2D CrosshairTex;
var float CrosshairSize;

event PostRender()
{
	local D2DPlayerController PC;
	local float CrosshairClamp;

	if ( HudMovie != None && HudMovie.Crosshair_MC != None )
		HudMovie.Crosshair_MC.SetVisible(false);

	Super.PostRender();

	PC = D2DPlayerController(PlayerOwner);
	if ( PC != None )
	{
		// clamp crosshair around center, allowed area depends on screen size
		CrosshairClamp = 0.20*Min(Canvas.ClipX, Canvas.ClipY);
		if ( VSize(PC.CrosshairPos) > CrosshairClamp )
			PC.CrosshairPos = CrosshairClamp*Normal(PC.CrosshairPos);

		Canvas.SetPos(Canvas.ClipX/2 + PC.CrosshairPos.X - CrosshairSize/2, Canvas.ClipY/2 + PC.CrosshairPos.Y - CrosshairSize/2);
		Canvas.SetDrawColor(255,255,255,255);
		Canvas.DrawTile(CrosshairTex, CrosshairSize, CrosshairSize, 0, 0, CrosshairTex.SizeX, CrosshairTex.SizeY);
	}
}

defaultproperties
{
	//HUDClass=class'D2DHudMovie'

	// flare dot
	//CrosshairTex=Texture2D'EngineVolumetrics.LightBeam.Materials.T_EV_LightBeam_Falloff_02'
	// some kind of reticle
	//CrosshairTex=Texture2D'EditorMaterials.TargetIcon'
	// circle
	CrosshairTex=Texture2D'CastleHUD.HUD_TouchToMove'
	// harder flare dot
	//CrosshairTex=Texture2D'Envy_Effects.flares.Materials.T_EFX_Flare_Round_Hard_01'

	CrosshairSize=16
}
