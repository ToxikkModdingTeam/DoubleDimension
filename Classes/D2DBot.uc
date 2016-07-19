//================================================================
// DoubleDimension.D2DBot
// ----------------
// Stop bots from firing/tracking outer screen
// - override native LineOfSightTo and CanSee with custom functions
// - copy all code to replace function calls
// ----------------
// by Chatouille
//================================================================
class D2DBot extends CRZBot;

var float MaxAttackDist;


// Native "override"
function bool MyLineOfSightTo(Actor Other, optional vector chkLocation, optional bool bTryAlternateTargetLoc)
{
	if ( VSize(Other.Location - Pawn.Location) > MaxAttackDist )
	{
		bEnemyIsVisible = false;
		return false;
	}
	return LineOfSightTo(Other, chkLocation, bTryAlternateTargetLoc);
}

function bool MyCanSee(Pawn Other)
{
	if ( VSize(Other.Location - Pawn.Location) > MaxAttackDist )
		return false;
	return CanSee(Other);
}


//================================================
// Copy of CRZBot
//================================================

function FightEnemy(bool bCanCharge, float EnemyStrength)
{
	local vector X,Y,Z;
	local float enemyDist;
	local float AdjustedCombatStyle;
	local bool bFarAway, bOldForcedCharge;

 	if ( (Squad == None) || (Enemy == None) || (Pawn == None) )
		`log("HERE 3 Squad "$Squad$" Enemy "$Enemy$" pawn "$Pawn);

	//if(Pawn.IsInvisible())
	//	return;

	if ( Vehicle(Pawn) != None )
	{
		VehicleFightEnemy(bCanCharge, EnemyStrength);
		return;
	}
	if ( Pawn.IsInPain() && FindInventoryGoal(0.0) )
	{
	        GoalString = "Fallback out of pain volume " $ RouteGoal $ " hidden " $ RouteGoal.bHidden;
	        GotoState('Fallback');
	        return;
	}

	if ( (Enemy == FailedHuntEnemy) && (WorldInfo.TimeSeconds == FailedHuntTime) )
	{
		GoalString = "FAILED HUNT - HANG OUT";
		if ( MyLineOfSightTo(Enemy) )
			bCanCharge = false;
		else if ( FindInventoryGoal(0) )
		{
			SetAttractionState();
			return;
		}
		else
		{
			WanderOrCamp();
			return;
		}
	}
////magically generating the agression of the bot
	bOldForcedCharge = bMustCharge;
	bMustCharge = false;
	enemyDist = VSize(Pawn.Location - Enemy.Location);
	AdjustedCombatStyle = CombatStyle + UTWeapon(Pawn.Weapon).SuggestAttackStyle();
	Aggression = 1.5 * FRand() - 0.8 + 2 * AdjustedCombatStyle - 0.5 * EnemyStrength
				+ FRand() * (Normal(Enemy.Velocity - Pawn.Velocity) Dot Normal(Enemy.Location - Pawn.Location));
	if ( UTWeapon(Enemy.Weapon) != None )
		Aggression += 2 * UTWeapon(Enemy.Weapon).SuggestDefenseStyle();
	if ( enemyDist > MAXSTAKEOUTDIST )
		Aggression += 0.5;
	if (Squad != None)
	{
		UTSquadAI(Squad).ModifyAggression(self, Aggression);
	}
	if ( (Pawn.Physics == PHYS_Walking) || (Pawn.Physics == PHYS_Falling) )
	{
		if (Pawn.Location.Z > Enemy.Location.Z + TACTICALHEIGHTADVANTAGE)
			Aggression = FMax(0.0, Aggression - 1.0 + AdjustedCombatStyle);
		else if ( (Skill < 4) && (enemyDist > 0.65 * MAXSTAKEOUTDIST) )
		{
			bFarAway = true;
			Aggression += 0.5;
		}
		else if (Pawn.Location.Z < Enemy.Location.Z - Pawn.GetCollisionHeight()) // below enemy
			Aggression += CombatStyle;
	}

	//if we cant attack him
	if (!Pawn.CanAttack(Enemy)) 
	{
		if ( UTSquadAI(Squad).MustKeepEnemy(Enemy) )//if the flagcarrier shouldn't get lost
		{
			GoalString = "Hunt priority enemy";
			GotoState('Hunting');
			return;
		}
		if ( !bCanCharge )
		{
			GoalString = "Stake Out - no charge";
			DoStakeOut();
		}
		else if ( UTSquadAI(Squad).IsDefending(self) && LostContact(4) && ClearShot(LastSeenPos, false) )
		{
			GoalString = "Stake Out "$LastSeenPos;
			DoStakeOut();
		}
		else if ( (((Aggression < 1) && !LostContact(3+2*FRand())) || IsSniping()) && CanStakeOut() )
		{
			GoalString = "Stake Out2";
			DoStakeOut();
		}
		else if ( Skill + Tactics >= 3.5 + FRand() && !LostContact(1) && VSize(Enemy.Location - Pawn.Location) < MAXSTAKEOUTDIST &&
			Pawn.Weapon != None && Pawn.Weapon.AIRating > 0.5 && !Pawn.Weapon.bMeleeWeapon &&
			FRand() < 0.75 && !MyLineOfSightTo(Enemy) && !Enemy.LineOfSightTo(Pawn) &&
			(Squad == None || !UTSquadAI(Squad).HasOtherVisibleEnemy(self)) )
		{
			GoalString = "Stake Out 3";
			DoStakeOut();
		}
		else
		{
			BotGoInStealth(true);

			GoalString = "Hunt";
			GotoState('Hunting');
		}
		return;
	}

	// see enemy - decide whether to charge it or strafe around/stand and fire
	BlockedPath = None;
	Focus = Enemy;

	if( Pawn.Weapon.bMeleeWeapon || (bCanCharge && bOldForcedCharge) )
	{
		GoalString = "Charge";
		DoCharge();
		return;
	}
	if ( Pawn.RecommendLongRangedAttack() )
	{
		GoalString = "Long Ranged Attack";
		DoRangedAttackOn(Enemy);
		return;
	}

	if ( bCanCharge && (Skill < 5) && bFarAway && (Aggression > 1) && (FRand() < 0.5) )
	{
		BotGoInStealth(true);//almost never been called

		GoalString = "Charge closer";
		DoCharge();
		return;
	}

	if ( UTWeapon(Pawn.Weapon).RecommendRangedAttack() || IsSniping() || ((FRand() > 0.17 * (skill + Tactics - 1)) && !DefendMelee(enemyDist)) )
	{
		GoalString = "Ranged Attack";
		DoRangedAttackOn(Enemy);
		return;
	}

	if ( bCanCharge )
	{
		if ( Aggression > 1 )
		{
			GoalString = "Charge 2";
			DoCharge();
			return;
		}
	}
	GoalString = "Do tactical move";
	if ( !UTWeapon(Pawn.Weapon).bRecommendSplashDamage && (FRand() < 0.7) && (3*Jumpiness + FRand()*Skill > 3) )
	{
		GetAxes(Pawn.Rotation,X,Y,Z);
		GoalString = "Try to Duck ";
		if ( FRand() < 0.5 )
		{
			Y *= -1;
			TryToDuck(Y, true);
		}
		else
			TryToDuck(Y, false);
	}
	DoTacticalMove();
}


//================================================
// Copy of UTBot
//================================================

function EnemyJustTeleported()
{
	local EnemyPosition NewPosition;

	MyLineOfSightTo(Enemy);
	SavedPositions.Remove(0,SavedPositions.Length);
	NewPosition.Position = Enemy.GetTargetLocation();
	NewPosition.Velocity = Enemy.Velocity;
	NewPosition.Time = WorldInfo.TimeSeconds;
	SavedPositions[0] = NewPosition;
}

function FearThisSpot(UTAvoidMarker aSpot)
{
	local int i;

	if ( (Pawn == None) || (Skill < 1 + 4.5*FRand()) )
		return;
	if ( !MyLineOfSightTo(aSpot) )
		return;
	for ( i=0; i<2; i++ )
		if ( (FearSpots[i] == None) || FearSpots[i].bDeleteMe )
		{
			FearSpots[i] = aSpot;
			return;
		}
	for ( i=0; i<2; i++ )
		if ( VSize(Pawn.Location - FearSpots[i].Location) > VSize(Pawn.Location - aSpot.Location) )
		{
			FearSpots[i] = aSpot;
			return;
		}
}

function bool ShouldFireAgain()
{
	local UTWeapon UTWeap;
	local float LandTime, ProjTime, TargetGravityZ;
	local vector HitLocation, HitNormal, TargetLoc;

	if (ScriptedTarget != None)
	{
		return true;
	}
	// re-eval weapon if switching to non-Pawn target
	if (Focus != LastFireTarget && Pawn(Focus) == None)
	{
		return false;
	}
	UTWeap = UTWeapon(Pawn.Weapon);
	if (UTWeap != None)
	{
		if ( WorldInfo.TimeSeconds - LastCanAttackCheckTime > 1.0 )
		{
			LastCanAttackCheckTime = WorldInfo.TimeSeconds;
			if (!CanAttack(Focus))
			{
				return false;
			}
		}
		if (UTWeap.bFastRepeater)
		{
			return true;
		}
		else if (UTWeap.bLockedAimWhileFiring && !Focus.IsStationary())
		{
			return false;
		}
	}

	if (Pawn.Weapon == None || !Pawn.Weapon.bMeleeWeapon)
	{
		if (Pawn.FireOnRelease())
		{
			return (FRand() < 0.8 || (Skill > 1.0 + 3.0 * FRand() && UTWeap != None && UTWeap.IsFullyCharged() && MyLineOfSightTo(Focus)));
		}
		else if (UTWeap != None && Focus == Enemy)
		{
			if (UTWeap.bInstantHit)
			{
				// sometimes delay a little to throw opponent dodges off
				if (VSize(Enemy.Velocity) > Enemy.GroundSpeed && FRand() < 0.4 && Skill + Tactics + ReactionTime > 2.0 + 4.0 * FRand())
				{
					return false;
				}
			}
			// if target is falling, wait until it's close enough to ground that we can target at feet and hit
			else if (UTWeap.bRecommendSplashDamage && Focus.Physics == PHYS_Falling && Skill + Accuracy + Tactics > 2.0 + 2.0 * FRand())
			{
				if (UTWeap.CurrentFireMode < UTWeap.WeaponProjectiles.length && UTWeap.WeaponProjectiles[UTWeap.CurrentFireMode] != None)
				{
					// approximate landing Z by just tracing down with world trace
					if (Trace(HitLocation, HitNormal, Focus.Location - vect(0,0,10000), Focus.Location, false, Pawn(Focus).GetCollisionExtent()) != None)
					{
						TargetLoc = Focus.Location;
						TargetLoc.Z = HitLocation.Z;
						// get time for target to land
						TargetGravityZ = Focus.GetGravityZ();
						LandTime = (-Focus.Velocity.Z - Sqrt(Square(Focus.Velocity.Z) - (2.0 * TargetGravityZ * (Focus.Location.Z - TargetLoc.Z)))) / TargetGravityZ;
						ProjTime = UTWeap.WeaponProjectiles[UTWeap.CurrentFireMode].static.StaticGetTimeToLocation(TargetLoc, UTWeap.GetPhysicalFireStartLoc(), self);
						if (LandTime + 0.1 > ProjTime)
						{
							if (LandTime - UTWeap.GetFireInterval(UTWeap.CurrentFireMode) > ProjTime)
							{
								// target will take so long to land that we can fire a shot now
								// and still have time to shoot the ground later
								return true;
							}
							else
							{
								// delay until about to land
								SetTimer(LandTime - ProjTime, true);
								bResetCombatTimer = true;
								return false;
							}
						}
					}
				}
			}
		}

		if (FRand() < 0.8)
		{
			return true;
		}
	}

	if ( Pawn(Focus) != None )
		return ( (Pawn.bStationary || Pawn(Focus).bStationary) && (Pawn(Focus).Health > 0) );

	return IsShootingObjective();
}

event HearNoise(float Loudness, Actor NoiseMaker, optional Name NoiseType )
{
	if ( NoiseMaker.Instigator.IsInvisible() )
	{
		// only react to invisible player noise if its a pickup or a projectile explosion and can see the instigator
		if ( (Skill < 3)
			|| ((PickupFactory(NoiseMaker) != None) && (Projectile(Noisemaker) != None))
			|| ((vector(Rotation) dot Normal(NoiseMaker.Instigator.Location - Pawn.Location)) < 0.7)
			|| !MyLineOfSightTo(NoiseMaker.Instigator) )
		{
			return;
		}
	}

	if ( UTSquadAI(Squad).SetEnemy(self, NoiseMaker.Instigator))
	{
		WhatToDoNext();
	}
}

event NotifyMissedJump()
{
	local NavigationPoint N;
	local actor OldMoveTarget;
	local vector Loc2D, NavLoc2D;
	local float BestDist, NewDist;

	OldMoveTarget = MoveTarget;
	MoveTarget = None;

	if ( MoveTarget == None )
	{
		// find an acceptable path
		Loc2D = Pawn.Location;
		Loc2D.Z = 0;
		foreach WorldInfo.AllNavigationPoints(class'NavigationPoint', N)
		{
			if ( N.Location.Z < Pawn.Location.Z )
			{
				NavLoc2D = N.Location;
				NavLoc2D.Z = 0;
				NewDist = VSize(NavLoc2D - Loc2D);
				if ( (NewDist <= Pawn.Location.Z - N.Location.Z)
					&& ((MoveTarget == None) || (BestDist > NewDist))  && MyLineOfSightTo(N) )
				{
					MoveTarget = N;
					BestDist = NewDist;
				}
			}
		}
		if ( MoveTarget == None )
		{
			MoveTarget = OldMoveTarget;
			return;
		}
	}

	MoveTimer = 1.0;
}

protected event ExecuteWhatToDoNext()
{
	local float StartleRadius, StartleHeight;

	if (Pawn == None)
	{
		// pawn got destroyed between WhatToDoNext() and now - abort
		return;
	}
	bHasFired = false;
	GoalString = "WhatToDoNext at "$WorldInfo.TimeSeconds;
	// if we don't have a squad, try to find one
	//@fixme FIXME: doesn't work for FFA gametypes
	if (Squad == None && PlayerReplicationInfo != None && UTTeamInfo(PlayerReplicationInfo.Team) != None)
	{
		UTTeamInfo(PlayerReplicationInfo.Team).SetBotOrders(self);
	}
	SwitchToBestWeapon();

	if (Pawn.Physics == PHYS_None)
		Pawn.SetMovementPhysics();
	if ( (Pawn.Physics == PHYS_Falling) && DoWaitForLanding() )
		return;
	if ( (StartleActor != None) && !StartleActor.bDeleteMe )
	{
		StartleActor.GetBoundingCylinder(StartleRadius, StartleHeight);
		if ( VSize(StartleActor.Location - Pawn.Location) < StartleRadius  )
		{
			Startle(StartleActor);
			return;
		}
	}
	bIgnoreEnemyChange = true;
	if ( (Enemy != None) && ((Enemy.Health <= 0) || (Enemy.Controller == None)) )
		LoseEnemy();
	if ( Enemy == None )
		UTSquadAI(Squad).FindNewEnemyFor(self,false);
	else if ( !UTSquadAI(Squad).MustKeepEnemy(Enemy) && !MyLineOfSightTo(Enemy) )
	{
		// decide if should lose enemy
		if ( UTSquadAI(Squad).IsDefending(self) )
		{
			if ( LostContact(4) )
				LoseEnemy();
		}
		else if ( LostContact(7) )
			LoseEnemy();
	}

	bIgnoreEnemyChange = false;
	if ( AssignSquadResponsibility() )
	{
		return;
	}
	if ( ShouldDefendPosition() )
	{
		return;
	}
	if ( Enemy != None )
		ChooseAttackMode();
	else
	{
		if (Pawn.FindAnchorFailedTime == WorldInfo.TimeSeconds)
		{
			// we failed the above actions because we couldn't find an anchor.
			GoalString = "No anchor" @ WorldInfo.TimeSeconds;
			if (Pawn.LastValidAnchorTime > 5.0)
			{
				if (bSoaking)
				{
					SoakStop("NO PATH AVAILABLE!!!");
				}
				if ( (NumRandomJumps > 4) || PhysicsVolume.bWaterVolume )
				{
					// can't suicide during physics tick, delay it
					Pawn.SetTimer(0.01, false, 'Suicide');
					return;
				}
				else
				{
					// jump
					NumRandomJumps++;
					if (!Pawn.IsA('Vehicle') && Pawn.Physics != PHYS_Falling && Pawn.DoJump(false))
					{
						Pawn.SetPhysics(PHYS_Falling);
						Pawn.Velocity = 0.5 * Pawn.GroundSpeed * VRand();
						Pawn.Velocity.Z = Pawn.JumpZ;
					}
				}
			}
		}

		GoalString @= "- Wander or Camp at" @ WorldInfo.TimeSeconds;
		bShortCamp = UTPlayerReplicationInfo(PlayerReplicationInfo).bHasFlag;
		WanderOrCamp();
	}
}

function VehicleFightEnemy(bool bCanCharge, float EnemyStrength)
{
	local UTVehicle V;

	V = UTVehicle(Pawn);
	if (V != None && V.bShouldLeaveForCombat)
	{
		LeaveVehicle(true);
		return;
	}
	if (Pawn.bStationary || (UTWeaponPawn(Pawn) != None) || V.bKeyVehicle )
	{
		if ( !MyLineOfSightTo(Enemy) )
		{
			GoalString = "Stake Out";
			DoStakeOut();
		}
		else
		{
			DoRangedAttackOn(Enemy);
		}
		return;
	}

	if ( !bFrustrated && Pawn.HasRangedAttack() && Pawn.TooCloseToAttack(Enemy) )
	{
		GoalString = "Retreat";
		DoRetreat();
		return;
	}
	if ( (Enemy == FailedHuntEnemy && WorldInfo.TimeSeconds == FailedHuntTime) || V.bKeyVehicle )
	{
		GoalString = "FAILED HUNT - HANG OUT";
		if ( Pawn.HasRangedAttack() && MyLineOfSightTo(Enemy) )
			DoRangedAttackOn(Enemy);
		else
			WanderOrCamp();
		return;
	}
	if ( !MyLineOfSightTo(Enemy) )
	{
		if ( UTSquadAI(Squad).MustKeepEnemy(Enemy) )
		{
			GoalString = "Hunt priority enemy";
			GotoState('Hunting');
			return;
		}
		if ( !bCanCharge || (UTSquadAI(Squad).IsDefending(self) && LostContact(4)) )
		{
			GoalString = "Stake Out";
			DoStakeOut();
		}
		else if ( ((Aggression < 1) && !LostContact(3+2*FRand()) || IsSniping()) && CanStakeOut() )
		{
			GoalString = "Stake Out2";
			DoStakeOut();
		}
		else
		{
			GoalString = "Hunt";
			GotoState('Hunting');
		}
		return;
	}

	BlockedPath = None;
	Focus = Enemy;

	if ( V.RecommendCharge(self, Enemy) )
	{
		GoalString = "Charge";
		DoCharge();
		return;
	}

	if ( Pawn.bCanFly && !Enemy.bCanFly && (Pawn.Weapon == None || VSize(Pawn.Location - Enemy.Location) < Pawn.Weapon.MaxRange()) &&
		(FRand() < 0.17 * (skill + Tactics - 1)) )
	{
		GoalString = "Do tactical move";
		DoTacticalMove();
		return;
	}

	if ( Pawn.RecommendLongRangedAttack() )
	{
		GoalString = "Long Ranged Attack";
		DoRangedAttackOn(Enemy);
		return;
	}
	GoalString = "Charge";
	DoCharge();
}

function ClearPathFor(Controller C)
{
	if ( Vehicle(Pawn) != None )
		return;
	if ( AdjustAround(C.Pawn) )
		return;
	if ( Enemy != None )
	{
		if ( MyLineOfSightTo(Enemy) && Pawn.bCanStrafe )
		{
			GotoState('TacticalMove');
			return;
		}
	}
	else if ( Stopped() && !Pawn.bStationary )
		MoveAwayFrom(C);
}

function DelayedInstantWarning()
{
	local vector X,Y,Z, Dir;

	if ( Pawn == None || InstantWarningShooter == None || InstantWarningShooter.bDeleteMe ||
		InstantWarningShooter.Controller == None )
	{
		return;
	}
	if ( Enemy == None )
	{
		if ( Squad != None )
		{
			UTSquadAI(Squad).SetEnemy(self, InstantWarningShooter);
		}
		return;
	}

	GetAxes(Pawn.Rotation, X,Y,Z);
	X.Z = 0;
	Dir = InstantWarningShooter.Location - Pawn.Location;
	Dir.Z = 0;
	Dir = Normal(Dir);

	// make sure still looking at shooter
	if ((Dir Dot Normal(X)) < 0.7 || !MyLineOfSightTo(InstantWarningShooter))
	{
		return;
	}

	// decide which way to duck
	if (!TryDuckTowardsMoveTarget(Dir, Y))
	{
		if (FRand() < 0.5)
		{
			Y *= -1;
			TryToDuck(Y, true);
		}
		else
		{
			TryToDuck(Y, false);
		}
	}
}

function bool ShouldStrafeTo(Actor WayPoint)
{
	local NavigationPoint N;

	if ( (UTVehicle(Pawn) != None) && !UTVehicle(Pawn).bFollowLookDir )
		return true;

	if ( (Skill + StrafingAbility < 3) && !UTPlayerReplicationInfo(PlayerReplicationInfo).bHasFlag )
		return false;

	if ( WayPoint == Enemy )
	{
		if ( Pawn.Weapon != None && Pawn.Weapon.bMeleeWeapon )
			return false;
		return ( Skill + StrafingAbility > 5 * FRand() - 1 );
	}
	else if ( PickupFactory(WayPoint) == None )
	{
		N = NavigationPoint(WayPoint);
		if ( (N == None) || N.bNeverUseStrafing )
			return false;

		if ( N.FearCost > 200 )
			return true;
		if ( N.bAlwaysUseStrafing && (FRand() < 0.8) )
			return true;
	}
	if ( (Pawn(WayPoint) != None) || ((UTSquadAI(Squad).SquadLeader != None) && (WayPoint == UTSquadAI(Squad).SquadLeader.MoveTarget)) )
		return ( Skill + StrafingAbility > 5 * FRand() - 1 );

	if ( Skill + StrafingAbility < 6 * FRand() - 1 )
		return false;

	if ( !bFinalStretch && Enemy == None )
		return ( FRand() < 0.4 );

	if ( (WorldInfo.TimeSeconds - LastUnderFire < 2) )
		return true;
	if ( (Enemy != None) && MyLineOfSightTo(Enemy) )
		return ( FRand() < 0.85 );
	return ( FRand() < 0.6 );
}

function ForceGiveWeapon()
{
    local Vector TossVel, LeaderVel;
	local Pawn LeaderPawn;

	LeaderPawn = UTSquadAI(Squad).SquadLeader.Pawn;
	if ( (Pawn == None) || (Pawn.Weapon == None) || (LeaderPawn == None) || !MyLineOfSightTo(LeaderPawn) )
	return;

    if ( Pawn.CanThrowWeapon() )
    {
		TossVel = Vector(Pawn.Rotation);
		TossVel.Z = 0;
		TossVel = Normal(TossVel);
		LeaderVel = Normal(LeaderPawn.Location - Pawn.Location);
		if ( (TossVel Dot LeaderVel) > 0.7 )
				TossVel = LeaderVel;
		TossVel = TossVel * ((Pawn.Velocity Dot TossVel) + 500) + Vect(0,0,200);
		Pawn.TossInventory(Pawn.Weapon, TossVel);
		SwitchToBestWeapon();
    }
}

function DoRetreat()
{
	if ( UTSquadAI(Squad).PickRetreatDestination(self) )
	{
		GotoState('Retreating');
		return;
	}

	// if nothing, then tactical move
	if ( MyLineOfSightTo(Enemy) )
	{
		GoalString= "No retreat because frustrated";
		bFrustrated = true;
		if ( Pawn.Weapon != None && Pawn.Weapon.bMeleeWeapon )
			GotoState('Charging');
		else if ( Vehicle(Pawn) != None )
			GotoState('VehicleCharging');
		else
			DoTacticalMove();
		return;
	}
	GoalString = "Stakeout because no retreat dest";
	DoStakeOut();
}

state TacticalMove
{
TacticalTick:
	Sleep(0.02);
Begin:
	if ( Enemy == None )
	{
		sleep(0.01);
		Goto('FinishedStrafe');
	}
	if (Pawn.Physics == PHYS_Falling)
	{
		Focus = Enemy;
		SetDestinationPosition( Enemy.Location );
		WaitForLanding();
	}
	if ( Enemy == None )
		Goto('FinishedStrafe');
	PickDestination();

DoMove:
	if ( FocusOnLeader(false) )
		MoveTo(GetDestinationPosition(), Focus);
	else if ( !Pawn.bCanStrafe )
	{
		StopFiring();
		MoveTo(GetDestinationPosition());
	}
	else
	{
DoStrafeMove:
		MoveTo(GetDestinationPosition(), Enemy);
	}
	if ( bForcedDirection && (WorldInfo.TimeSeconds - StartTacticalTime < 0.2) )
	{
		if ( !Pawn.HasRangedAttack() || Skill > 2 + 3 * FRand() )
		{
			bMustCharge = true;
			LatentWhatToDoNext();
		}
		GoalString = "RangedAttack from failed tactical";
		DoRangedAttackOn(Enemy);
	}
	if ( (Enemy == None) || MyLineOfSightTo(Enemy) || !FastTrace(Enemy.Location, LastSeeingPos) || (Pawn.Weapon != None && Pawn.Weapon.bMeleeWeapon) )
		Goto('FinishedStrafe');

RecoverEnemy:
	GoalString = "Recover Enemy";
	HidingSpot = Pawn.Location;
	StopFiring();
	Sleep(0.1 + 0.2 * FRand());
	SetDestinationPosition( LastSeeingPos + 4 * Pawn.GetCollisionRadius() * Normal(LastSeeingPos - Pawn.Location) );
	MoveTo(GetDestinationPosition(), Enemy);

	if (FireWeaponAt(Enemy))
	{
		Pawn.Acceleration = vect(0,0,0);
		if (Pawn.Weapon != None && UTWeapon(Pawn.Weapon).GetDamageRadius() > 0)
		{
			StopFiring();
			Sleep(0.05);
		}
		else
			Sleep(0.1 + 0.3 * FRand() + 0.06 * (7 - FMin(7,Skill)));
		if ( (FRand() + 0.3 > Aggression) )
		{
			Enable('EnemyNotVisible');
			SetDestinationPosition( HidingSpot + 4 * Pawn.GetCollisionRadius() * Normal(HidingSpot - Pawn.Location) );
			Goto('DoMove');
		}
	}
FinishedStrafe:
	LatentWhatToDoNext();
	if ( bSoaking )
		SoakStop("STUCK IN TACTICAL MOVE!");
}

state StakeOut
{
ignores EnemyNotVisible;

	function FindNewStakeOutDir()
	{
		local NavigationPoint N, Best;
		local vector Dir, EnemyDir;
		local float Dist, BestVal, Val;

		EnemyDir = Normal(Enemy.Location - Pawn.Location);
		foreach WorldInfo.AllNavigationPoints(class'NavigationPoint', N)
		{
			Dir = N.Location - Pawn.Location;
			Dist = VSize(Dir);
			if ( (Dist < MAXSTAKEOUTDIST) && (Dist > MINSTRAFEDIST) )
			{
				Val = (EnemyDir Dot Dir/Dist);
				if ( WorldInfo.Game.bTeamgame && PlayerReplicationInfo.Team != None && PlayerReplicationInfo.Team.Size > 1 )
					Val += FRand();
				if ( (Val > BestVal) && MyLineOfSightTo(N) )
				{
					BestVal = Val;
					Best = N;
				}
			}
		}
		if ( Best != None )
			SetFocalPoint( Best.Location + 0.5 * Pawn.GetCollisionHeight() * vect(0,0,1) );
	}
}

state RangedAttack
{
ignores SeePlayer, HearNoise, Bump;

Begin:
	bHasFired = false;
	if ( (Pawn.Weapon != None) && Pawn.Weapon.bMeleeWeapon )
		SwitchToBestWeapon();
	GoalString = GoalString@"Ranged attack";
	Sleep(0.0);
	if ( (Focus == None) || Focus.bDeleteMe )
		LatentWhatToDoNext();
	if ( Enemy != None )
		CheckIfShouldCrouch(Pawn.Location,Enemy.Location, 1);
	if ( Pawn.NeedToTurn(GetFocalPoint()) )
	{
		FinishRotation();
	}
	bHasFired = true;
	if ( Focus == Enemy )
		TimedFireWeaponAtEnemy();
	else
		FireWeaponAt(Focus);
	Sleep(0.1);
	if ( ((Pawn.Weapon != None) && Pawn.Weapon.bMeleeWeapon) || (Focus == None) || ((Focus != Enemy) && (UTGameObjective(Focus) == None) && (Enemy != None) && MyLineOfSightTo(Enemy)) )
		LatentWhatToDoNext();
	if ( Enemy != None )
		CheckIfShouldCrouch(Pawn.Location,Enemy.Location, 1);
	if (FindStrafeDest())
	{
		GoalString = GoalString $ ", strafe to" @ MoveTarget;
		MoveToward(MoveTarget, Focus,, true, false);
		StopMovement();
	}
	else
	{
		Sleep(FMax(Pawn.RangedAttackTime(),0.2 + (0.5 + 0.5 * FRand()) * 0.4 * (7 - Skill)));
	}
	LatentWhatToDoNext();
	if ( bSoaking )
		SoakStop("STUCK IN RANGEDATTACK!");
}

state FindAir
{
ignores SeePlayer, HearNoise, Bump;

	function Timer()
	{
		if ( (Enemy != None) && MyLineOfSightTo(Enemy) )
			TimedFireWeaponAtEnemy();
		else
			SetCombatTimer();
	}
}

state Hunting
{
ignores EnemyNotVisible;

AdjustFromWall:
	MoveTo(GetDestinationPosition(), MoveTarget);

Begin:
	WaitForLanding();
	if ( MyCanSee(Enemy) )
		SeePlayer(Enemy);
	PickDestination();
SpecialNavig:
	if (MoveTarget == None)
		MoveTo(GetDestinationPosition());
	else
		MoveToward(MoveTarget,FaceActor(10),,(FRand() < 0.75) && ShouldStrafeTo(MoveTarget));

	LatentWhatToDoNext();
	if ( bSoaking )
		SoakStop("STUCK IN HUNTING!");
}


defaultproperties
{
	MaxAttackDist=1050
}
