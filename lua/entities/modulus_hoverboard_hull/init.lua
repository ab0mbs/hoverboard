
// client files
AddCSLuaFile( "cl_init.lua" );
AddCSLuaFile( "shared.lua" );

// includes
include( "shared.lua" );

/*------------------------------------
	Precache
------------------------------------*/
function ENT:Precache( )

	util.PrecacheModel( "models/modulus/player_hull.mdl" );
	util.PrecacheSound( "Player.FallDamage" );

end


/*------------------------------------
	UpdateTransmitState
------------------------------------*/
function ENT:UpdateTransmitState( )

	return TRANSMIT_ALWAYS;
	
end

/*------------------------------------
	CanTool
------------------------------------*/
function ENT:CanTool( pl, trace, mode )

	return false;

end

/*------------------------------------
	Initialize
------------------------------------*/
function ENT:Initialize( )

	// precache
	self:Precache();

	// setup
	self:SetModel( "models/modulus/player_hull.mdl" );
	self:PhysicsInit( SOLID_VPHYSICS );
	self:SetMoveType( MOVETYPE_VPHYSICS );
	self:SetNoDraw( true );
	self:DrawShadow( false );

	// player
	self.Player = NULL;

end


/*------------------------------------
	SetPlayer
------------------------------------*/
function ENT:SetPlayer( pl )

	self.Player = pl;

end


/*------------------------------------
	Think
------------------------------------*/
function ENT:Think( )

	// get physics
	local phys = self:GetPhysicsObject();
	
	// validate
	if ( ValidEntity( phys ) ) then
	
		// check
		if ( phys:IsPenetrating() ) then
		
			// the board we belong to
			local board = self:GetOwner();
			
			// boot
			board:SetDriver( NULL );
			
			// damage
			local damage = self.Player:Health() * 0.9;
		
			// inflict damage to our player
			board:HurtDriver( damage );
		
			// sound
			self.Player:EmitSound( "Player.FallDamage" );
		
		end
	
	end
	
	// think
	self:NextThink( CurTime() + 0.3 );
	return true;

end


/*------------------------------------
	PhysicsCollide
------------------------------------*/
function ENT:PhysicsCollide( data, phys )

	// no player?
	if( !ValidEntity( self.Player ) || !ValidEntity( self:GetOwner() ) ) then

		return;

	end
	
	// the board we belong to
	local board = self:GetOwner();
	
	// is the board upside down?
	if( board:GetUp().z < 0.33 ) then
	
		board:SetDriver( NULL );
	
	end
	
	// timing
	if( data.DeltaTime < 0.2 ) then
	
		return;
	
	end

	// get speed
	local lastvelocity = data.OurOldVelocity;
	local velocity = phys:GetVelocity();
	local speed = velocity:Length();
	local lastspeed = lastvelocity:Length();
	local diff = math.abs( lastspeed - speed );

	// have enough speed?
	if( diff < 40 ) then
	
		return;

	end

	// calculate damage
	local damage = math.Clamp( diff * 0.025, 0, 100 );

	// inflict damage to our player
	board:HurtDriver( damage );

	// sound
	self.Player:EmitSound( "Player.FallDamage" );

	// decal
	util.Decal( "Blood", data.HitPos - data.HitNormal * 2, data.HitPos + data.HitNormal * 2 );

	// blood
	for i = 1, 3 do

		local effect = EffectData();
			effect:SetOrigin( data.HitPos + data.HitNormal * 2 + VectorRand() * math.Rand( 8, 16 ) );
		util.Effect( "BloodImpact", effect, true, true );

	end

end
