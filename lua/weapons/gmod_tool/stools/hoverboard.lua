
// basic
TOOL.Category		= "Modulus";
TOOL.Name			= "#Hoverboard";
TOOL.Command		= nil;
TOOL.ConfigName		= nil;

// hoverboards info
local HoverboardTypes = util.KeyValuesToTable(file.Read("data/hoverboards.txt", "game"));

// client stuff
if ( CLIENT ) then

	// create language shit
	language.Add( "Tool.hoverboard.name", "Hoverboard" );
	language.Add( "Tool.hoverboard.desc", "Spawn a customized hoverboard" );
	language.Add( "Tool.hoverboard.0", "Left click to spawn a hoverboard. Right click to spawn & mount a hoverboard." );
	language.Add( "Undone.hoverboard", "Undone Hoverboard" );
	language.Add( "SBoxLimit.hoverboards", "You've reached the Hoverboard limit!" )
	
	// register gui
	local pnldef_Hoverboard = vgui.RegisterFile( "vgui/hoverboard_gui.lua" );
	
	/*------------------------------------
		BuildCPanel
	------------------------------------*/
	function TOOL.BuildCPanel( cp )
	
		// create
		local panel = vgui.CreateFromTable( pnldef_Hoverboard );
		cp:AddPanel( panel );
		panel:PopulateBoards( HoverboardTypes );
		
	end

else

	// include vgui
	AddCSLuaFile( "vgui/hoverboard_gui.lua" );

end

// loop board types
for _, hbt in pairs( HoverboardTypes ) do

	// add to list
	list.Set( "HoverboardModels", hbt[ 'model' ], {} );
	
	if ( SERVER ) then
	
		// send model
		resource.AddFile( hbt[ 'model' ] );
		
		// send other files
		if ( hbt[ 'files' ] ) then
		
			for __, f in pairs( hbt[ 'files' ] ) do
			
				resource.AddFile( f );
			
			end
		
		end
		
	end
	
	// precache
	util.PrecacheModel( hbt[ 'model' ] );

end

// convars
TOOL.ClientConVar[ 'model' ] = "models/UT3/hoverboard.mdl";
TOOL.ClientConVar[ 'mousecontrol' ] = 1;
TOOL.ClientConVar[ 'boostshake' ] = 1;
TOOL.ClientConVar[ 'height' ] = 72;
TOOL.ClientConVar[ 'viewdist' ] = 128;
TOOL.ClientConVar[ 'trail_size' ] = 5;
TOOL.ClientConVar[ 'trail_r' ] = 128;
TOOL.ClientConVar[ 'trail_g' ] = 128;
TOOL.ClientConVar[ 'trail_b' ] = 255;
TOOL.ClientConVar[ 'boost_r' ] = 128;
TOOL.ClientConVar[ 'boost_g' ] = 128;
TOOL.ClientConVar[ 'boost_b' ] = 255;
TOOL.ClientConVar[ 'recharge_r' ] = 128;
TOOL.ClientConVar[ 'recharge_g' ] = 128;
TOOL.ClientConVar[ 'recharge_b' ] = 255;
TOOL.ClientConVar[ 'speed' ] = 1;
TOOL.ClientConVar[ 'jump' ] = 1;
TOOL.ClientConVar[ 'turn' ] = 1;
TOOL.ClientConVar[ 'flip' ] = 1;
TOOL.ClientConVar[ 'twist' ] = 1;


/*------------------------------------
	LeftClick
------------------------------------*/
function TOOL:LeftClick( trace )

	// do shit
	local result, hoverboard = self:CreateBoard( trace );
	
	// done
	return result;

end


/*------------------------------------
	RightClick
------------------------------------*/
function TOOL:RightClick( trace )

	// do shit
	local result, hoverboard = self:CreateBoard( trace );
	
	// client result
	if ( CLIENT ) then
	
		return result;
		
	end
	
	// validate board
	if ( ValidEntity( hoverboard ) ) then
	
		// owner
		local pl = self:GetOwner();
	
		// check distance
		local dist = ( hoverboard:GetPos() - pl:GetPos() ):Length();
		
		// make sure its relatively close?
		if ( dist <= 256 ) then
		
			// had to delay it to avoid errors
			timer.Simple( 0.25, function( h, p )
			
				// validate
				if ( ValidEntity( h ) && ValidEntity( p ) ) then
				
					// bam!
					h:SetDriver( p );
					
				end
				
			end, hoverboard, pl );
		
		end
	
	end
	
	return result;

end


/*------------------------------------
	CreateBoard
------------------------------------*/
function TOOL:CreateBoard( trace )

	// get owner
	local pl = self:GetOwner();

	// client is done
	if ( CLIENT ) then
	
		return true;
		
	end
	
	// admin only check
	if ( GetConVarNumber( "sv_hoverboard_adminonly" ) > 0 && !( pl:IsAdmin() || pl:IsSuperAdmin() ) ) then
	
		return false;
		
	end
	
	// get values
	local model = self:GetClientInfo( "model" );
	local mcontrol = self:GetClientNumber( "mousecontrol" );
	local shake = self:GetClientNumber( "boostshake" );
	local trailsize = math.Clamp( self:GetClientNumber( "trail_size" ), 0, 10 );
	local height = math.Clamp( self:GetClientNumber( "height" ), 36, 100 );
	local viewdist = math.Clamp( self:GetClientNumber( "viewdist" ), 64, 256 );
	local trail = Vector( self:GetClientNumber( "trail_r" ), self:GetClientNumber( "trail_g" ), self:GetClientNumber( "trail_b" ) );
	local boost = Vector( self:GetClientNumber( "boost_r" ), self:GetClientNumber( "boost_g" ), self:GetClientNumber( "boost_b" ) );
	local recharge = Vector( self:GetClientNumber( "recharge_r" ), self:GetClientNumber( "recharge_g" ), self:GetClientNumber( "recharge_b" ) );
	
	// get attributes
	local attributes = {
		[ 'speed' ] = math.Clamp( self:GetClientNumber( "speed" ), 0, 10 ),
		[ 'jump' ] = math.Clamp( self:GetClientNumber( "jump" ), 0, 10 ),
		[ 'turn' ] = math.Clamp( self:GetClientNumber( "turn" ), 0, 10 ),
		[ 'flip' ] = math.Clamp( self:GetClientNumber( "flip" ), 0, 10 ),
		[ 'twist' ] = math.Clamp( self:GetClientNumber( "twist" ), 0, 10 )
	};
	
	// set angle
	local ang = pl:GetAngles();
	ang.p = 0;
	ang.y = ang.y + 180;
	
	// position
	local pos = trace.HitPos + trace.HitNormal * 32
	
	// create hoverboard
	local hoverboard = MakeHoverboard( pl, model, ang, pos, mcontrol, shake, height, viewdist, trailsize, trail, boost, recharge, attributes );
	
	// validate
	if ( !hoverboard ) then
	
		return false;
		
	end
	
	// create undo
	undo.Create( "Hoverboard" );
		undo.AddEntity( hoverboard );
		undo.SetPlayer( pl );
	undo.Finish();
	
	// all done
	return true, hoverboard;

end

/*------------------------------------
	Reload
------------------------------------*/
function TOOL:Reload( trace )

end


/*------------------------------------
	Think
------------------------------------*/
function TOOL:Think( )

end


if ( SERVER ) then

	function MakeHoverboard( pl, model, ang, pos, mcontrol, shake, height, viewdist, trailsize, trail, boost, recharge, attributes )
	
		// check limit	
		if ( !pl:CheckLimit( "hoverboards" ) ) then
		
			return false;
			
		end
		
		// create
		local hoverboard = ents.Create( "modulus_hoverboard" );
		
		// validate
		if ( !hoverboard:IsValid() ) then
		
			return false;
			
		end
		
		// storage
		local boardinfo;
		
		// loop boards
		for _, board in pairs( HoverboardTypes ) do
		
			// find selected
			if ( board[ 'model' ]:lower() == model:lower() ) then
			
				// save
				boardinfo = board;
				break;
			
			end
			
		end
		
		// validate
		if ( !boardinfo ) then
		
			return false;
			
		end
		
		// just incase
		util.PrecacheModel( model );
		
		// setup
		hoverboard:SetModel( model );
		hoverboard:SetAngles( ang );
		hoverboard:SetPos( pos );
		
		// default rotation
		hoverboard:SetBoardRotation( 0 );
		
		// check rotation
		if ( boardinfo[ 'rotation' ] ) then
		
			// get value
			local rot = tonumber( boardinfo[ 'rotation' ] );
		
			// update
			hoverboard:SetBoardRotation( tonumber( boardinfo[ 'rotation' ] ) );
			
			// change angles
			ang.y = ang.y - rot;
			hoverboard:SetAngles( ang );
			
		end
		
		// spawn
		hoverboard:Spawn();
		hoverboard:Activate();
		
		// default position
		hoverboard:SetAvatarPosition( Vector( 0, 0, 0 ) );
		
		// check position
		if ( boardinfo[ 'driver' ] ) then
		
			// get position
			local x, y, z = unpack( string.Explode( " ", boardinfo[ 'driver' ] ) );
			local pos = Vector( tonumber( x or 0 ), tonumber( y or 0 ), tonumber( z or 0 ) );
			
			// update
			hoverboard:SetAvatarPosition( pos );
		
		end
		
		// loop info
		for k, v in pairs( boardinfo ) do
		
			// check for effects
			if ( k:sub( 1, 7 ):lower() == "effect_" && type( boardinfo[ k ] == "table" ) ) then
			
				// get effect table
				local effect = boardinfo[ k ];
				
				// get position
				local x, y, z = unpack( string.Explode( " ", effect[ 'position' ] ) );
				local pos = Vector( tonumber( x or 0 ), tonumber( y or 0 ), tonumber( z or 0 ) );
				
				// get name
				local name = effect[ 'effect' ] or "trail";
				
				// get normal
				local normal;
				if ( effect[ 'normal' ] ) then
				
					local x, y, z = unpack( string.Explode( " ", effect[ 'normal' ] or "" ) );
					normal = Vector( tonumber( x or 0 ), tonumber( y or 0 ), tonumber( z or 0 ) );
					
				end
				
				// get scale
				local scale = effect[ 'scale' ] or 1;
				
				// add it
				hoverboard:AddEffect( name, pos, normal, scale );
			
			end
		
		end
		
		// controls
		hoverboard:SetControls( math.Clamp( tonumber( mcontrol ), 0, 1 ) );
		
		// boost shake
		hoverboard:SetBoostShake( math.Clamp( tonumber( shake ), 0, 1 ) );
		
		// hover height
		hoverboard:SetHoverHeight( math.Clamp( tonumber( height ), 36, 100 ) );
		
		// view distance
		hoverboard:SetViewDistance( math.Clamp( tonumber( viewdist ), 64, 256 ) );
		
		// spring
		hoverboard:SetSpring( 0.21 * ( ( 72 / height ) * ( 72 / height ) ) );
		
		// trail info
		trailsize = math.Clamp( trailsize, 0, 10 ) * 0.3;
		hoverboard:SetTrailScale( trailsize );
		hoverboard:SetTrailColor( trail );
		hoverboard:SetTrailBoostColor( boost );
		hoverboard:SetTrailRechargeColor( recharge );
		
		// make sure no one is hacking the console vars
		local count = 0;
		local points = GetGlobalInt( "HoverPoints" );
		
		// loop
		for k, v in pairs( attributes ) do
		
			// available points
			local remaining = points - count;
			
			// clamp
			v = math.Clamp( v, 0, math.min( 10, remaining ) );
			
			// update
			attributes[ k ] = v;
			
			// increment count
			count = count + v;
		
		end
		
		// find bonuses
		for k, v in pairs( boardinfo[ 'bonus' ] or {} ) do
		
			// check bonus
			if ( attributes[ k ] ) then
			
				// add it
				attributes[ k ] = attributes[ k ] + tonumber( v );
				
			end
		
		end
		
		// attributes
		local speed = ( attributes[ 'speed' ] * 0.1 ) * 20;
		hoverboard:SetSpeed( speed );
		local jump = ( attributes[ 'jump' ] * 0.1 ) * 250;
		hoverboard:SetJumpPower( jump );
		local turn = ( attributes[ 'turn' ] * 0.1 ) * 25;
		hoverboard:SetTurnSpeed( turn );
		local flip = ( attributes[ 'flip' ] * 0.1 ) * 25;
		hoverboard:SetPitchSpeed( flip );
		local twist = ( attributes[ 'twist' ] * 0.1 ) * 25;
		hoverboard:SetYawSpeed( twist );
		local roll = ( ( flip + twist * 0.5 ) / 50 ) * 22;
		hoverboard:SetRollSpeed( roll );
		
		// all done
		DoPropSpawnedEffect( hoverboard );
		pl:AddCount( "hoverboards", hoverboard );
		
		// store
		hoverboard.Creator = pl:UniqueID();
		
		// return
		return hoverboard;
		
	end
	
end
