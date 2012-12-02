
// shared file
include( 'shared.lua' );


/*------------------------------------
	Initialize
------------------------------------*/
function ENT:Initialize( )
	
end


/*------------------------------------
	Draw
------------------------------------*/
function ENT:Draw( )
	
	if ( !ValidEntity( self.Board ) || !ValidEntity( self.Board:GetDriver() ) ) then
	
		return;
		
	end
	
	// draw
	self:DrawModel();
	
end


/*------------------------------------
	DrawTranslucent
------------------------------------*/
function ENT:DrawTranslucent( )

	// draw opaque
	self:Draw();

end


/*------------------------------------
	Think
------------------------------------*/
function ENT:Think( )

	// update player
	local pl = self.Entity:GetNetworkedEntity( "Player" );
	self.Player = pl;
	
	// update board
	local board = self:GetOwner();
	//local board = self.Entity:GetNetworkedEntity( "Board" );
	self.Board = board;
	
	// think fast
	self.Entity:NextThink( CurTime() + 0.1 );
	
	return true;
	
end
