
// info
ENT.Type 		= "vehicle";
ENT.Base 		= "base_anim";
ENT.PrintName 		= "Hoverboard";
ENT.Author 		= "% Software";
ENT.Information 	= "UT Hoverboard";
ENT.Category 		= "% Software";
ENT.Spawnable 		= false;
ENT.AdminSpawnable 	= false;

// thrusters
ENT.ThrusterPoints = {
	{ Pos = Vector( -46, 0, 0 ), Diff = 24, Spring = 3 },

	{ Pos = Vector( -24, 13, 24 ) },
	{ Pos = Vector( 24, 13, 24 ) },
	{ Pos = Vector( -24, -13, 24 ) },
	{ Pos = Vector( 24, -13, 24 ) },
	//Vector( 0, 32, 24 ),
	//Vector( 0, -32, 24 ),
	//Vector( 12, 18, 24 ),
	//Vector( 12, -08, 24 ),
	//Vector( -12, 08, 24 ),
	//Vector( -12, -08, 24 ),
	//Vector( 0, 0, 24 ),

};

// network vars
AccessorFuncNW( ENT, "effects", "EffectCount", false );
AccessorFuncNW( ENT, "boardvelocity", "BoardVelocity", 0, FORCE_NUMBER );
AccessorFuncNW( ENT, "rotation", "BoardRotation", 0, FORCE_NUMBER );
AccessorFuncNW( ENT, "hoverheight", "HoverHeight", 0, FORCE_NUMBER );
AccessorFuncNW( ENT, "viewdistance", "ViewDistance", 0, FORCE_NUMBER );
AccessorFuncNW( ENT, "boostshake", "BoostShake", 1, FORCE_NUMBER );
AccessorFuncNW( ENT, "trailscale", "TrailScale", 1, FORCE_NUMBER );
AccessorFuncNW( ENT, "trailcolor", "TrailColor", Vector( 128, 128, 255 ) );
AccessorFuncNW( ENT, "trailboostcolor", "TrailBoostColor", Vector( 255, 128, 128 ) );
AccessorFuncNW( ENT, "trailrechargecolor", "TrailRechargeColor", Vector( 255, 255, 128 ) );

/*------------------------------------
	GetDriver
------------------------------------*/
function ENT:GetDriver( )

	//return self:GetNetworkedEntity( "Driver", NULL );
	return self:GetOwner();

end


/*------------------------------------
	CalcView
------------------------------------*/
function ENT:CalcView( pl, origin, angles, fov )

	// get ent
	local viewentity = ( SERVER ) && pl:GetViewEntity() || GetViewEntity();

	// check
	if ( !ValidEntity( viewentity ) || viewentity:GetClass() != "modulus_hoverboard" ) then
	
		return;
	
	end

	local ang = pl:GetAimVector();
	//local ang = aim:Angle():Right() * -1;
	
	local pos = self.Entity:GetPos() + Vector( 0, 0, 64 ) - ( ang * self.Entity:GetViewDistance() );
	local speed = self.Entity:GetVelocity():Length() - 500;

	// shake their view
	if ( self:IsBoosting() && speed > 0 && self.Entity:GetBoostShake() == 1 ) then

		local power = 14 * ( speed / 700 );

		local x = math.Rand( -power, power ) * 0.1;
		local y = math.Rand( -power, power ) * 0.1;
		local z = math.Rand( -power, power ) * 0.1;

		pos = pos + Vector( x, y, z );

	end

	// the direction to face
	local face = ( ( self.Entity:GetPos() + Vector( 0, 0, 40 ) ) - pos ):Angle();
	
	// get the proper force to apply
	face:RotateAroundAxis( Vector( 0, 0, 1 ), self.Entity:GetBoardRotation() );

	// trace to keep it out of the walls
	local trace = {
		start = self.Entity:GetPos() + Vector( 0, 0, 64 ),
		endpos = self.Entity:GetPos() + Vector( 0, 0, 64 ) + face:Forward() * ( self.Entity:GetViewDistance() * -1 );
		mask = MASK_NPCWORLDSTATIC,

	};
	local tr = util.TraceLine( trace );

	// setup view
	local view = {
		origin = tr.HitPos + tr.HitNormal,
		angles = face,
		fov = 90,

	};

	return view;

end


/*------------------------------------
	Move
------------------------------------*/
local function Move( pl, mv )

	// get the scripted vehicle
	local board = pl:GetScriptedVehicle();

	// make sure they are using the hoverboard
	if ( !ValidEntity( board ) || board:GetClass() != "modulus_hoverboard" ) then

		// if not, exit
		return;

	end

	// set their origin
	mv:SetOrigin( board:GetPos() );

	// prevent their movement
	return true;

end
hook.Add( "Move", "Hoverboard_Move", Move );


/*------------------------------------
	IsGrinding
------------------------------------*/
function ENT:IsGrinding( )

	return self.Entity:GetNWBool( "Grinding" );

end

/*------------------------------------
	Boost
------------------------------------*/
function ENT:Boost( )

	return self.Entity:GetNWInt( "Boost" );

end

/*------------------------------------
	IsBoosting
------------------------------------*/
function ENT:IsBoosting( )

	return self.Entity:GetNWBool( "Boosting" );

end

/*------------------------------------
	GetThruster
------------------------------------*/
function ENT:GetThruster( index )

	local pos = self:LocalToWorld( self.ThrusterPoints[ index ].Pos );

	// get distance and dir
	local dist = ( self:GetPos() - pos ):Length();
	local dir = ( pos - self:GetPos() ):Normalize();

	// rotate
	dir = dir:Angle();
	dir:RotateAroundAxis( self:GetUp(), self:GetBoardRotation() );
	dir = dir:Forward();

	// return
	return self:GetPos() + dir * dist;

end


/*------------------------------------
	UpdateAnimation
------------------------------------*/
local function UpdateAnimation( pl )

	// get the scripted vehicle
	local board = pl:GetScriptedVehicle();

	// make sure they are using the hoverboard
	if ( !ValidEntity( board ) || board:GetClass() != "modulus_hoverboard" ) then

		// if not, exit
		return;

	end

	// copy pose parameters
	local pose_params = { "head_pitch", "head_yaw", "body_yaw", "aim_yaw", "aim_pitch" };
	for _, param in pairs( pose_params ) do

		if ( ValidEntity( board.Avatar ) ) then

			local val = pl:GetPoseParameter( param );
			board.Avatar:SetPoseParameter( param, val );

		end

	end

end
hook.Add( "UpdateAnimation", "Hoverboard_UpdateAnimation", UpdateAnimation );
