
// download files
AddCSLuaFile( 'cl_init.lua' );
AddCSLuaFile( 'shared.lua' );

// shared file
include( 'shared.lua' );


/*------------------------------------
	Initialize
------------------------------------*/
function ENT:Initialize( )

	// setup SENT
	self:DrawShadow( false );
	self:SetModel( self.Model );
	self:SetMoveType( MOVETYPE_NONE );
	self:SetSolid( SOLID_NONE );
	self:SetCollisionBounds( Vector( 0, 0, 0 ), Vector( 0, 0, 0 ) );
	
end


/*------------------------------------
	UpdateTransmitState
------------------------------------*/
function ENT:UpdateTransmitState( )

	return TRANSMIT_ALWAYS;
	
end

/*------------------------------------
	SetPlayer
------------------------------------*/
function ENT:SetPlayer( pl )

	// store player
	self.Entity:SetNetworkedEntity( "Player", pl );
	self.Player = pl;
	
	if ( ValidEntity( pl ) && pl:IsPlayer() ) then
	
		// set model
		self.Model = pl:GetModel();
		util.PrecacheModel( self.Model ); // just to be safe
		self.Entity:SetModel( self.Model );
		
	end
	
	// make sure these stick
	self:SetMoveType( MOVETYPE_NONE );
	self:SetSolid( SOLID_NONE );
	self:SetCollisionBounds( Vector( 0, 0, 0 ), Vector( 0, 0, 0 ) );
	
	// think fast
	self.Entity:NextThink( CurTime() );
	
end


/*------------------------------------
	SetBoard
------------------------------------*/
function ENT:SetBoard( ent )

	// store board
	self:SetOwner( ent );
	self.Entity:SetNetworkedEntity( "Board", ent );
	self.Board = ent;
	
	// think fast
	self.Entity:NextThink( CurTime() );
	
end


/*------------------------------------
	Think
------------------------------------*/
function ENT:Think( )

	// get player
	local pl = self.Entity:GetNetworkedEntity( "Player" );
	
	// think fast
	self.Entity:NextThink( CurTime() + 0.2 );
	
	return true;
	
end
