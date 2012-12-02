
// client files
AddCSLuaFile( "cl_init.lua" );
AddCSLuaFile( "shared.lua" );

// includes
include( "shared.lua" );

// accessor functions
AccessorFunc( ENT, "pitchspeed", "PitchSpeed", FORCE_NUMBER );
AccessorFunc( ENT, "yawspeed", "YawSpeed", FORCE_NUMBER );
AccessorFunc( ENT, "turnspeed", "TurnSpeed", FORCE_NUMBER );
AccessorFunc( ENT, "rollspeed", "RollSpeed", FORCE_NUMBER );
AccessorFunc( ENT, "jumppower", "JumpPower", FORCE_NUMBER );
AccessorFunc( ENT, "speed", "Speed", FORCE_NUMBER );
AccessorFunc( ENT, "boosterspeed", "BoostMultiplier", FORCE_NUMBER );
AccessorFunc( ENT, "dampingfactor", "DampingFactor", FORCE_NUMBER );
AccessorFunc( ENT, "spring", "Spring", FORCE_NUMBER );

/*------------------------------------
	Precache
------------------------------------*/
function ENT:Precache( )

	// sound files
	self.MountSoundFile = "buttons/button9.wav";
	self.UnMountSoundFile = "buttons/button19.wav";
	self.JumpSoundFile = "weapons/airboat/airboat_gun_energy1.wav";

	// preache
	util.PrecacheSound( self.MountSoundFile );
	util.PrecacheSound( self.UnMountSoundFile );
	util.PrecacheSound( self.JumpSoundFile );

end

/*------------------------------------
	UpdateTransmitState
------------------------------------*/
function ENT:UpdateTransmitState( )

	return TRANSMIT_ALWAYS;
	
end

/*------------------------------------
	Initialize
------------------------------------*/
function ENT:Initialize( )

	// precache
	self:Precache();

	// init
	self:PhysicsInit( SOLID_VPHYSICS );
	self:SetMoveType( MOVETYPE_VPHYSICS );
	self:SetUseType( ONOFF_USE );

	// defaults
	self.WaterContacts = 0;
	self.Contacts = 0;
	self.MouseControl = 1;
	self.CanPitch = false;
	self:SetBoost( 100 );
	self.NextBoostThink = 0;
	self:SetDampingFactor( 2 );
	self:SetSpeed( 20 );
	self:SetYawSpeed( 25 );
	self:SetTurnSpeed( 25 );
	self:SetPitchSpeed( 25 );
	self:SetRollSpeed( 20 );
	self:SetJumpPower( 250 );
	self:SetBoostMultiplier( 1.5 );
	self:SetSpring( 0.21 );
	self:SetHoverHeight( 72 );
	self:SetViewDistance( 128 );
	self:SetBoosting( false );
	self.PlayerMountedTime = 0;

	// allow grabbing
	self.PhysgunDisabled = false;

	// create avatar
	self.Avatar = ents.Create( "modulus_hoverboard_avatar" );
	self.Avatar:SetParent( self.Entity );
	self.Avatar:Spawn();
	self.Avatar:SetBoard( self.Entity );
	self:SetNWEntity( "Avatar", self.Avatar );
	self:SetAvatarPosition( Vector( 0, 0, 3 ) );

	// hull
	self.Hull = NULL;

	// set mass
	local boardphys = self:GetPhysicsObject();
	if ( ValidEntity( boardphys ) ) then

		boardphys:SetMass( 750 );

	end

	// start motioncontroller
	self:StartMotionController();

end

/*------------------------------------
	SetAvatarPosition
------------------------------------*/
function ENT:SetAvatarPosition( pos )

	self.Avatar:SetLocalPos( pos );
	self.Avatar:SetLocalAngles( Angle( 0, 160 + self:GetBoardRotation(), 0 ) );

end

/*------------------------------------
	OnRemove
------------------------------------*/
function ENT:OnRemove( )

	// remove any driver
	self:SetDriver( NULL );

	// stop controller
	self:StopMotionController();

end


/*------------------------------------
	SetControls
------------------------------------*/
function ENT:SetControls( num )

	self.MouseControl = num;

end


/*------------------------------------
	SetDriver
------------------------------------*/
function ENT:SetDriver( pl )

	// set avatar model
	self.Avatar:SetPlayer( pl );

	local driver = self:GetDriver();
	if( ValidEntity( driver ) ) then

		// check if we should boot the driver
		if ( ( pl == NULL || pl == nil ) || GetConVarNumber( "sv_hoverboard_cansteal" ) == 1 ) then
		
			// clear it's scripted vehicle
			driver:SetScriptedVehicle( NULL );
	
			// unmount
			self:UnMount( driver );
	
			// restore movetype
			driver:SetMoveType( driver.OldMoveType );
			driver:DrawWorldModel( true );
			driver:SetNoDraw( false );
	
			// enable physgun again
			self.PhysgunDisabled = false;
	
			// grinding off
			self:SetGrinding( false );
	
			// boost off
			self:SetBoosting( false );
			
			if ( self.OldWeapon && driver:HasWeapon( self.OldWeapon ) ) then
			
				driver:SelectWeapon( self.OldWeapon );
			
			end
			
		else
		
			return;
			
		end

	end
	
	// stuff
	self.PlayerMountedTime = 0;
	self.OldWeapon = nil;

	// init
	if( ValidEntity( pl ) ) then
	
		// can we get on it?
		if ( GetConVarNumber( "sv_hoverboard_canshare" ) < 1 ) then
		
			if ( pl:UniqueID() != self.Creator ) then
			
				return;
			
			end
		
		end
	
		// stuff
		self.PlayerMountedTime = CurTime();

		// create a hull if it doesn't exist
		if( !ValidEntity( self.Hull ) ) then

			// phys
			local boardphys = self:GetPhysicsObject();
			if ( ValidEntity( boardphys ) ) then

				// make
				self.Hull = ents.Create( "modulus_hoverboard_hull" );
					self.Hull:SetAngles( boardphys:GetAngle() );
					self.Hull:SetPos( boardphys:GetPos() );
				self.Hull:Spawn();
				self.Hull:SetPlayer( pl );
				self.Hull:SetOwner( self );

				// weld
				constraint.Weld( self.Hull, self, 0, 0, 0, true, true );

			end

		// simply update the driver
		else

			self.Hull:SetPlayer( pl );

		end
		
		local weapon = pl:GetActiveWeapon();
		
		if ( ValidEntity( weapon ) ) then
		
			self.OldWeapon = weapon:GetClass();
			
		end
		
		// switch weapon
		pl:SelectWeapon( "weapon_crowbar" );

		// don't allow us to mount if we already have a scripted vehicle
		if( ValidEntity( pl:GetScriptedVehicle() ) ) then

			return;

		end

		// set scripted vehicle
		pl:SetScriptedVehicle( self );

		// store our old movetype and prevent us from moving
		pl.OldMoveType = pl:GetMoveType();
		pl:SetMoveType( MOVETYPE_NOCLIP );

		// mount
		self:Mount( pl );

		// should we set the clientside vehicle?
		/*
		
		//this was disabled... the last update broke this
		
		if( !SinglePlayer() ) then

			pl:SetClientsideVehicle( self );

		end
		*/
		
		// set board velocity (allows for a running start)
		local phys = self:GetPhysicsObject();
		if( ValidEntity( phys ) ) then
		
			local angles = self:GetAngles();
			angles:RotateAroundAxis( angles:Up(), self:GetBoardRotation() + 180 );
			local forward = angles:Forward();
			local velocity = forward:DotProduct( pl:GetVelocity() ) * forward;
		
			phys:SetVelocity( velocity );
		
		end

		// disable physgun
		self.PhysgunDisabled = true;
		
		pl:DrawWorldModel( false );
		pl:SetNoDraw( true );
		
	// a player is getting off, destroy the hull
	else

		// destroy
		SafeRemoveEntity( self.Hull );

	end

	// set new driver
	self:SetNetworkedEntity( "Driver", pl );
	self:SetOwner( pl );

end


/*------------------------------------
	HurtDriver
------------------------------------*/
function ENT:HurtDriver( damage )

	// get driver
	local driver = self:GetDriver();
	
	// validate
	if ( !ValidEntity( driver ) ) then
	
		return;
		
	// check time
	elseif ( self.PlayerMountedTime == 0 || CurTime() - self.PlayerMountedTime < 1 ) then
	
		return;
		
	end
	
	// inflict damage to our player
	driver:TakeDamage( damage, self.Entity );

end


/*------------------------------------
	SetBoost
------------------------------------*/
function ENT:SetBoost( int )

	// set flag
	self:SetNWInt( "Boost", int );

end


/*------------------------------------
	SetBoosting
------------------------------------*/
function ENT:SetBoosting( bool )

	// set flag
	self:SetNWBool( "Boosting", bool );

end


/*------------------------------------
	Upright
------------------------------------*/
function ENT:IsUpright( physobj )

	// get our physics object
	local phys = phys || self:GetPhysicsObject();

	// validate the physics object
	if ( !ValidEntity( phys ) ) then

		// its not valid, leave
		return;

	end

	// get the upward angle
	local up = phys:GetAngle():Up();

	// return bool
	return ( up.z >= 0.33 );

end


/*------------------------------------
	OnTakeDamage
------------------------------------*/
function ENT:OnTakeDamage( dmginfo )

	// pass to physics as forces
	self:TakePhysicsDamage( dmginfo );

end


/*------------------------------------
	SetPlayerAnimation
------------------------------------*/
local function SetPlayerAnimation( pl, anim )

	// get the scripted vehicle
	local board = pl:GetScriptedVehicle();

	// make sure they are using the hoverboard
	if ( !ValidEntity( board ) || board:GetClass() != "modulus_hoverboard" ) then

		// if not, exit
		return;

	end

	// select animation
	local seq = "idle_slam";

	if ( board:IsGrinding() ) then

		seq = "cidle_melee";

	elseif ( pl.IsTurning ) then

		seq = "idle_grenade";

	end

	// get the pose sequence
	seq = pl:LookupSequence( seq );

	// run the animation
	pl:SetPlaybackRate( 1.0 );
	pl:ResetSequence( seq );
	pl:SetCycle( 0 );

	// animate the avatar
	board.Avatar:SetPlaybackRate( 1.0 );
	board.Avatar:ResetSequence( seq );
	board.Avatar:SetCycle( 0 );

	// override
	return true;

end
hook.Add( "SetPlayerAnimation", "Hoverboard_SetPlayerAnimation", SetPlayerAnimation );


/*------------------------------------
	Think
------------------------------------*/
function ENT:Think( )

	// stay wake
	local phys = self:GetPhysicsObject();
	if( ValidEntity( phys ) ) then

		phys:Wake();

	end

	// get driver
	local driver = self:GetDriver();

	// validate driver
	if( ValidEntity( driver ) ) then
	
		driver:DrawWorldModel( false );
		driver:SetNoDraw( true );
		
		// view entity is the driver?
		if( driver:GetViewEntity() == driver ) then
		
			driver:SetViewEntity( self );
		
		end

		// make sure driver is still around
		if ( self:WaterLevel() > 0 || !driver:Alive() || !driver:IsConnected() ) then

			// give 'em the boot
			self:SetDriver( NULL );

		// make sure board is upright
		/*elseif ( self:GetUp().z < -0.85 ) then

			// check if board is on ground
			if ( self.Contacts > 0 || self:OnGround() ) then

				// give 'em the boot
				//self:SetDriver( NULL );

			end*/

		else

			// get weapon
			local weap = driver:GetActiveWeapon();

			// validate
			if ( ValidEntity( weap ) ) then

				// disable attack
				weap:SetNextPrimaryFire( CurTime() + 1 );
				weap:SetNextSecondaryFire( CurTime() + 1 );

			end
			
		end

		// maintain the animation
		if ( driver:Alive() && driver:IsConnected() ) then

			// change the animation
			SetPlayerAnimation( driver );

		end

	elseif( self.DriverWeapon != nil ) then

		// no driver, no weapon
		self.DriverWeapon = nil;

	end

	// boost thinking
	if ( CurTime() >= self.NextBoostThink ) then

		// set next think
		self.NextBoostThink = CurTime() + 0.1;

		// boosting
		if ( self:IsBoosting() ) then

			// consume boost
			self:SetBoost( math.Clamp( self:Boost() - 1, 0, 100 ) );

			// boost done
			if ( self:Boost() == 0 ) then

				// reset
				self:SetBoosting( false );

			end

		else

			// hold current boost
			local oldboost = self:Boost();

			// recharge boost
			self:SetBoost( math.Clamp( self:Boost() + 1, 0, 100 ) );

			// boost has recharged
			//if ( self:Boost() == 100 && oldboost < 100 ) then

				// err, wtf was yous thinking? thar be nothing here!

			//end

		end

	end

	// think
	self:NextThink( CurTime() );
	return true;

end


/*------------------------------------
	ApplyForwardForce
------------------------------------*/
function ENT:ApplyForwardForce( phys, force, mass )

	// get the proper force to apply
	local ang = phys:GetAngle();
	ang:RotateAroundAxis( phys:GetAngle():Up(), self:GetBoardRotation() );
	ang = ang:Forward();

	// calculate
	return phys:CalculateForceOffset(
		ang * force * mass,
		phys:GetPos() + phys:GetAngle():Up() * 8

	);

end


/*------------------------------------
	ApplyForwardForce
------------------------------------*/
function ENT:ApplySideForce( phys, force, mass )

	// get the proper force to apply
	local ang = phys:GetAngle();
	ang:RotateAroundAxis( phys:GetAngle():Up(), self:GetBoardRotation() );
	ang = ang:Right();

	// calculate
	return phys:CalculateForceOffset(
		ang * force * mass,
		phys:GetPos() + phys:GetAngle():Up() * 8

	);

end


/*------------------------------------
	ApplyRotateForce
------------------------------------*/
function ENT:ApplyRotateForce( phys, force, mass )

	// two forces each at opposite ends of the board
	local _, force1 = phys:CalculateForceOffset(
		phys:GetAngle():Right() * force * mass,
		phys:GetPos() + phys:GetAngle():Forward() * -24 + phys:GetAngle():Up() * 1.36

	);
	local _, force2 = phys:CalculateForceOffset(
		phys:GetAngle():Right() * -force * mass,
		phys:GetPos() + phys:GetAngle():Forward() * 24 + phys:GetAngle():Up() * 1.36

	);

	return force1 + force2;

end


/*------------------------------------
	ApplyPitchForce
------------------------------------*/
function ENT:ApplyPitchForce( phys, force, mass )

	// get the proper force to apply
	local ang = phys:GetAngle();
	ang:RotateAroundAxis( phys:GetAngle():Up(), self:GetBoardRotation() );
	ang = ang:Forward();

	// two forces each at opposite ends of the board
	local _, force1 = phys:CalculateForceOffset(
		phys:GetAngle():Up() * force * mass,
		phys:GetPos() + ang * -24 + phys:GetAngle():Up() * 1.36

	);
	local _, force2 = phys:CalculateForceOffset(
		phys:GetAngle():Up() * -force * mass,
		phys:GetPos() + ang * 24 + phys:GetAngle():Up() * 1.36

	);

	return force1 + force2;

end


/*------------------------------------
	ApplyRollForce
------------------------------------*/
function ENT:ApplyRollForce( phys, force, mass )

	// get the proper force to apply
	local ang = phys:GetAngle();
	ang:RotateAroundAxis( phys:GetAngle():Up(), self:GetBoardRotation() );

	// two forces each at opposite ends of the board
	local _, force1 = phys:CalculateForceOffset(
		ang:Up() * force * mass,
		phys:GetPos() + ang:Right() * -24

	);
	local _, force2 = phys:CalculateForceOffset(
		ang:Up() * -force * mass,
		phys:GetPos() + ang:Right() * 24

	);

	return force1 + force2;

end


/*------------------------------------
	SetGrinding
------------------------------------*/
function ENT:SetGrinding( bool )

	// physics object
	local phys = self:GetPhysicsObject();

	// validate
	if ( ValidEntity( phys ) ) then

		if ( bool ) then

			// sliding
			phys:SetMaterial( "ice" );

		else

			// friction
			phys:SetMaterial( "metal" );

		end

	end

	// update
	self:SetNWBool( "Grinding", bool );

end


/*------------------------------------
	PhysicsCollide
------------------------------------*/
function ENT:PhysicsCollide( data, physobj )

	// get speed
	local velocity = self:GetVelocity();
	local speed = velocity:Length();

	// minimum speed
	if ( speed < 150 ) then

		return;

	end

	// check entity
	if ( !data.HitEntity || data.HitEntity == NULL || self:WaterLevel() > 0 ) then

		return;

	end

	// make sure its world
	if ( data.HitEntity == GetWorldEntity() || data.HitEntity:GetSolid( ) != SOLID_NONE ) then

		// create effect
		local effectdata = EffectData();
 			effectdata:SetOrigin( data.HitPos );
 			effectdata:SetNormal( data.HitNormal );
 			effectdata:SetMagnitude( 1.5 );
 			effectdata:SetScale( 0.1 );
 			effectdata:SetRadius( 12 );

 		// dispatch
		util.Effect( "sparks", effectdata, true, true );

		// grinding sound
		self:SetNetworkedFloat( "GrindSoundTime", CurTime() + 0.2 );

	end

end

/*------------------------------------
	PhysicsSimulate
------------------------------------*/
function ENT:PhysicsSimulate( phys, deltatime )

	// reset contact points
	self.Contacts = 0;
	self.WaterContacts = 0;

	// we spaz out if we hover when we're physgunned.
	if ( self.Entity:IsPlayerHolding() || self:WaterLevel() > 0 ) then

		// go ahead and update next use
		self.NextUse = CurTime() + 1;

		return SIM_NOTHING;

	end

	local driver		= self:GetDriver();
	local thrusters		= 5;					// 5 is the magic number (#self.ThrusterPoints)
	local thruster_mass	= phys:GetMass() / thrusters;	// spread the mass evenly over all thrusters
	local hoverheight 	= math.Clamp( self:GetHoverHeight(), 36, 100 );
	local massscale	= ( phys:GetMass() / 150 );

	// force accumulators
	local angular		= Vector( 0, 0, 0 );
	local linear		= Vector( 0, 0, 0 );

	// hover spring power
	local spring_power	= self:GetSpring();

	// damping
	local angle_velocity	= phys:GetAngleVelocity();
	local velocity		= phys:GetVelocity();
	local hover_damping	= Vector( 0, 0, ( velocity.z * -4.8 ) / thrusters ) * self:GetDampingFactor();
	local angular_damping	= angle_velocity * ( -6.4 / thrusters ) * self:GetDampingFactor();
	local friction		= velocity * ( -3.6 / thrusters );

	// friction shouldn't affect gravity
	friction.z = 0;

	// update board velocity
	self:SetBoardVelocity( velocity:Length() );

	// for each hover point
	for i = 1, thrusters do

		local point = self:GetThruster( i );
		local tracelen = hoverheight - ( self.ThrusterPoints[ i ].Diff or 0 );

		// trace
		local trace = {
			start = point,
			endpos = point - Vector( 0, 0, tracelen ),
			filter = { self.Entity, driver, self.Hull },
			mask = bit.bor(MASK_SOLID,MASK_WATER),

		};
		local tr = util.TraceLine( trace );

		// did we hit water?
		if ( tr.MatType == MAT_SLOSH ) then

			self.WaterContacts = self.WaterContacts + 1;

		end

		// should we apply forces to this thruster?
		if ( tr.Fraction < 1 && tr.Fraction > 0 ) then

			// increment contacts
			self.Contacts = self.Contacts + 1;

			// calculate force and compression
			local compression = tracelen * ( 1 - tr.Fraction );
			local force = ( spring_power * ( self.ThrusterPoints[ i ].Spring or 1 ) ) * compression;

			// calculate angular
			local forcelinear, forceangular = phys:CalculateForceOffset(
				Vector( 0, 0, force * thruster_mass ),
				point

			);

			// accumulate
			angular = angular + forceangular + angular_damping;
			linear = linear + forcelinear + hover_damping;

		// is the contact fully inside a wall?
		elseif ( tr.Fraction == 0 ) then

			// increment contacts
			self.Contacts = self.Contacts + 1;

		end

	end

	// don't apply the forces if we're not upright. ( we can flip upside down whilst in the air )
	if ( self.Contacts > 0 && !self:IsUpright( phys ) ) then

		return SIM_NOTHING;

	elseif ( self:IsGrinding() ) then

		self.CanPitch = true;

	elseif ( self.Contacts >= 1 ) then

		self.CanPitch = false;

	end

	// movement
	if ( ValidEntity( driver ) ) then

		local forward = phys:GetAngle():Forward();
		local driver_forward = driver:GetAimVector();
		local right = phys:GetAngle():Right();
		local up = phys:GetAngle():Up();
			forward.z = 0;
			right.z = 0;

		// speeds
		local forward_speed = self:GetSpeed();
		local rotation_speed = self:GetTurnSpeed();
		local yaw_speed = self:GetYawSpeed();
		local pitch_speed = self:GetPitchSpeed();
		local roll_speed = self:GetRollSpeed();
		local jump_power = self:GetJumpPower();
		
		// flag as not turning
		driver.IsTurning = false;

		// do rotational movement if we're on the ground.
		if ( self.Contacts >= 1  ) then

			local speed;

			// they use the mouse to control the board, figure out rotation force
			if ( self.MouseControl == 1 ) then

				// get angles
				local ang1 = phys:GetAngle();
				local ang2 = driver:GetAimVector():Angle();

				// get the difference between the 2 and normalize it
				local diff = ( math.NormalizeAngle( ang1.y - ang2.y ) );
				// calculate the delta
				local delta = ( diff > 0 ) && 1 || -1;
				// calculate the speed
				speed = math.Clamp( ( 180 * delta ) - diff, -rotation_speed, rotation_speed );

				// we are turning.
				if ( ( diff > 0 && diff < 150 ) || ( diff < 0 && diff > -150 ) ) then

					driver.IsTurning = true;

				end
				
				if ( !driver:KeyDown( IN_FORWARD ) && !driver:KeyDown( IN_FORWARD ) ) then
				
					// rotate left
					if( driver:KeyDown( IN_MOVELEFT ) ) then
	
						local forcel, forcea = self:ApplySideForce( phys, ( forward_speed * 0.5 ), thruster_mass );
							angular = angular + forcea;
							linear = linear + forcel + friction;
	
					end
	
					// rotate right
					if( driver:KeyDown( IN_MOVERIGHT ) ) then
	
						local forcel, forcea = self:ApplySideForce( phys, ( forward_speed * 0.5 ) * -1, thruster_mass );
							angular = angular + forcea;
							linear = linear + forcel + friction;
	
					end
					
				end

			else

				// rotate left
				if( driver:KeyDown( IN_MOVELEFT ) ) then

					speed = rotation_speed;
					driver.IsTurning = true;

				end

				// rotate right
				if( driver:KeyDown( IN_MOVERIGHT ) ) then

					speed = -rotation_speed;
					driver.IsTurning = true;

				end

			end
			
			// apply force
			local forcelinear, forceangular = phys:CalculateForceOffset(
				right * speed * thruster_mass,
				phys:GetPos() + forward * -24 + up * 8

			);
			angular = angular + forceangular;

		else

			// no more turning!
			driver.IsTurning = true;

		end

		// boosting
		if ( self:IsBoosting() ) then

			forward_speed = forward_speed * 1.5;

		end

		// move forward
		if ( driver:KeyDown( IN_FORWARD ) && self.Contacts >= 1 ) then

			local forcel, forcea = self:ApplyForwardForce( phys, -forward_speed, thruster_mass );
				angular = angular + forcea;
				linear = linear + forcel + friction;

		end

		// move backward
		if ( driver:KeyDown( IN_BACK ) && self.Contacts >= 1 ) then

			local forcel, forcea = self:ApplyForwardForce( phys, forward_speed, thruster_mass );
				angular = angular + forcea;
				linear = linear + forcel + friction;

		end

		// grind?
		if( driver:KeyDown( IN_DUCK ) || driver:KeyDown( IN_ATTACK2 ) ) then

			// grinding destroys all forces
			angular = Vector( 0, 0, 0 );
			linear = Vector( 0, 0, 0 );

			// update grinding
			if ( !self:IsGrinding() ) then

				self:SetGrinding( true );

			end

		else

			// update grinding
			if ( self:IsGrinding() ) then

				self:SetGrinding( false );

			end

		end

		// aerial control
		if ( self.Contacts == 0 || self:IsGrinding() ) then
		
			// rolling
			if( driver:KeyDown( IN_ATTACK ) ) then

				// rotate left
				if( driver:KeyDown( IN_MOVELEFT ) ) then
	
					local force = self:ApplyRollForce( phys, roll_speed, thruster_mass );
						angular = angular + force;
	
				end
	
				// rotate right
				if( driver:KeyDown( IN_MOVERIGHT ) ) then
	
					local force = self:ApplyRollForce( phys, -roll_speed, thruster_mass );
						angular = angular + force;
	
				end
				
			// yaw
			else
			
				// rotate left
				if( driver:KeyDown( IN_MOVELEFT ) ) then
	
					local force = self:ApplyRotateForce( phys, yaw_speed, thruster_mass );
						angular = angular + force;
	
				end
	
				// rotate right
				if( driver:KeyDown( IN_MOVERIGHT ) ) then
	
					local force = self:ApplyRotateForce( phys, -yaw_speed, thruster_mass );
						angular = angular + force;
	
				end
			
			end

			// pitch forward
			if( driver:KeyDown( IN_FORWARD ) && self.CanPitch ) then

				local force = self:ApplyPitchForce( phys, -pitch_speed, thruster_mass );
					angular = angular + force;

			end

			// pitch back
			if( driver:KeyDown( IN_BACK ) && self.CanPitch ) then

				local force = self:ApplyPitchForce( phys, pitch_speed, thruster_mass );
					angular = angular + force;

			end

		end

		// jump is handled via keypress since it was unresponsive here.
		if( self.Jumped ) then

			// current speed
			local speed = velocity:Length();

			// fractional speed
			speed = speed / 575;

			// calculate speed sound
			jump_power = math.Clamp( jump_power * speed, 170, 300 ) / 5;

			// stopped jump
			self.Jumped = false;

			// jump
			self:EmitSound( self.JumpSoundFile );

			// apply a jump force to each thruster
			for i = 1, thrusters do

				local point = self:GetThruster( i );
				local speed = velocity:Length();

				// shift the jump point based on speed
				point = point + ( forward * ( speed * 0.01 ) );

				// apply force
				local forcelinear, forceangular = phys:CalculateForceOffset( Vector( 0, 0, jump_power ) * thruster_mass, point );
					angular = angular + forceangular + angular_damping;
					linear = linear + forcelinear + friction;

			end

		end

	end

	// apply friction
	linear = linear + ( friction * deltatime * ( self:IsGrinding() && 10 || 400 ) * ( ( 1 / thrusters ) * self.Contacts ) );

	// damping
	angular = angular + angular_damping * deltatime * 750;

	// simuluate
	return angular, linear, SIM_GLOBAL_ACCELERATION;

end


/*------------------------------------
	KeyPress
------------------------------------*/
local function KeyPress( pl, in_key )

	// get the scripted vehicle
	local board = pl:GetScriptedVehicle();

	// make sure they are using the hoverboard
	if ( !ValidEntity( board ) || board:GetClass() != "modulus_hoverboard" ) then

		// if not, exit
		return;

	end

	// check if they are pressing the use key
	if ( in_key == IN_USE ) then

		// remove them from board
		board:SetDriver( NULL );
		
		// get physics
		local phys = board:GetPhysicsObject();
		
		// validate
		if ( ValidEntity( phys ) ) then
		
			// get angle
			local ang = board:GetAngles();
			ang.r = 0;
			ang:RotateAroundAxis( Vector( 0, 0, 1 ), board:GetBoardRotation() + 180 );
		
			// kick forward (prevents players from getting stuck in board)
			phys:ApplyForceCenter( ang:Forward() * phys:GetMass() * 500 );
			
		end

		// delay next use
		board.NextUse = CurTime() + 1;

	end

	// jump
	if ( in_key == IN_JUMP && board.Contacts >= 3 && board.WaterContacts < 2 ) then

		board.Jumped = true;

	end

	// boost
	if ( in_key == IN_SPEED && !board:IsBoosting() && board:Boost() == 100 ) then

		// turn on boost
		board:SetBoosting( true );

	end

end
hook.Add( "KeyPress", "Hoverboard_KeyPress", KeyPress );


/*------------------------------------
	Use
------------------------------------*/
function ENT:Use( activator, caller )

	// validate the activator and make sure its a player
	if ( !ValidEntity( activator ) || !activator:IsPlayer() ) then

		// wtf activated us?
		return;

	end

	// make sure we are upright and not under water
	if ( !self:IsUpright() || self:WaterLevel() > 0 ) then

		// nope!
		return;

	end

	// default next use delay
	self.NextUse = self.NextUse or 0;

	// make sure its time to be used
	if ( CurTime() < self.NextUse ) then

		// not time yet
		return;

	end

	// delay the next use
	self.NextUse = CurTime() + 1;

	// set the driver
	self:SetDriver( activator );

end


/*------------------------------------
	Mount
------------------------------------*/
function ENT:Mount( pl )

	// sound
	self:EmitSound( self.MountSoundFile );
	
	// set player angle
	local ang = self:GetAngles();
	ang.r = 0;
	ang:RotateAroundAxis( Vector( 0, 0, 1 ), 180 );
	pl:SetAngles( ang );
	pl:SetEyeAngles( ang );

end


/*------------------------------------
	UnMount
------------------------------------*/
function ENT:UnMount( pl )

	// sound
	self:EmitSound( self.UnMountSoundFile );
	
	// set player angle
	local ang = self:GetAngles();
	ang.r = 0;
	ang:RotateAroundAxis( Vector( 0, 0, 1 ), self:GetBoardRotation() + 180 );
	pl:SetAngles( ang );
	pl:SetEyeAngles( ang );

end


/*------------------------------------
	EntityTakeDamage
------------------------------------*/
local function EntityTakeDamage( ent, inflictor, attacker, amount, dmginfo )

	// get attacker
	local attacker = dmginfo:GetAttacker();
	
	// make sure its a hoverboard
	if ( ValidEntity( attacker ) ) then
	
		local driver;
	
		if ( attacker:GetClass() == "modulus_hoverboard" ) then
	
			// get driver
			driver = attacker:GetDriver();
			
		elseif ( attacker:GetClass() == "modulus_hoverboard_hull" ) then
		
			// get driver
			driver = attacker:GetOwner():GetDriver();
			
		end
	
		// validate
		if ( ValidEntity( driver ) ) then
		
			// change attacker
			dmginfo:SetAttacker( driver );
		
		end
	
	end

end
hook.Add( "EntityTakeDamage", "Hoverboard_EntityTakeDamage", EntityTakeDamage );


/*------------------------------------
	AddEffect
------------------------------------*/
function ENT:AddEffect( effect, pos, normal, scale )

	// increment effect count
	local index = self:GetEffectCount();
	if( !index ) then
	
		index = 1;
	
	else
	
		index = index + 1;
	
	end
	self:SetEffectCount( index );
	
	// add new effect
	self:SetNetworkedString( "Effect" .. index, effect );
	self:SetNetworkedVector( "EffectPos" .. index, pos || Vector( 0, 0, 0 ) );
	self:SetNetworkedVector( "EffectNormal" .. index, normal || Vector( 0, 0, 1 ) );
	self:SetNetworkedFloat( "EffectScale" .. index, scale || 1 );

end


// send effects to client
local effectfiles = file.FindInLua( "entities/modulus_hoverboard/effects/*.lua" );
for _, filename in pairs( effectfiles ) do

	AddCSLuaFile( string.format( "effects/%s", filename ) );

end
