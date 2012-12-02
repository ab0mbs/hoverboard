
// includes
include( "shared.lua" );

// rendergroup
ENT.RenderGroup = RENDERGROUP_BOTH;

// materials
local glow = Material( "modulus_hoverboard/glow" );
local trail = Material( "modulus_hoverboard/trail" );

// effects
local Effects = {};


/*------------------------------------
	LoadEffects
------------------------------------*/
local function LoadEffects( )

	// find all the effects
	local effectfiles = file.FindInLua( "entities/modulus_hoverboard/effects/*.lua" );
	
	// load
	for _, filename in pairs( effectfiles ) do

		local old_effect = EFFECT;
		
		// setup the effect object
		EFFECT = {};
		
		// new
		function EFFECT:new( )
		
			local obj = {};
			setmetatable( obj, self );
			self.__index = self;
			
			return obj;
		
		end
		
		// load
		include( string.format( "effects/%s", filename ) );
		
		// store
		local _, _, effectname = string.find( filename, "([%w_]*)\.lua" );
		Effects[ effectname ] = EFFECT;
		
		// restore
		EFFECT = old_effect;

	end

end


/*------------------------------------
	Initialize
------------------------------------*/
function ENT:Initialize( )

	// hover sound
	self.HoverSoundFile = "weapons/gauss/chargeloop.wav";
	self.HoverSound = CreateSound( self.Entity, self.HoverSoundFile );
	self.HoverSoundPlaying = false;
	
	// grind soud
	self.GrindSoundFile = "physics/metal/metal_grenade_scrape_smooth_loop1.wav";
	self.GrindSound = CreateSound( self.Entity, self.GrindSoundFile );
	self.GrindSoundPlaying = false;
	self.GrindSoundTime = 0;
	
	// boost sound
	self.BoostOffSoundFile = "npc/scanner/scanner_nearmiss1.wav";
	self.BoostOnSoundFile = "npc/scanner/scanner_nearmiss2.wav";
	self.BoostSoundFile = "ambient/levels/labs/teleport_rings_loop2.wav";
	self.BoostSound = CreateSound( self.Entity, self.BoostSoundFile );
	self:SetNetworkedVarProxy( "Boosting", self.BoostStateChanged );
	
	// effects list
	self.Effects = {};
	self.EffectsInitailized = false;

	// setup
	self:SetShouldDrawInViewMode( true );
	self:SetRenderBounds( Vector( -24, -8, -16 ), Vector( 24, 8, 16 ) );

end


/*------------------------------------
	BoostStateChanged
------------------------------------*/
function ENT:BoostStateChanged( name, oldvalue, newvalue )

	// check value
	if ( oldvalue == newvalue ) then
	
		// prevent spamming sounds
		return newvalue;
		
	end

	// handle sounds
	if ( newvalue ) then

		// start sounds
		self.BoostSound:Play();
		self:EmitSound( self.BoostOnSoundFile );

	else

		// stop sounds
		self.BoostSound:Stop();
		self:EmitSound( self.BoostOffSoundFile );

	end

	return newvalue;

end


/*------------------------------------
	OnRemove
------------------------------------*/
function ENT:OnRemove( )

	// stop sounds
	self.HoverSound:Stop();
	self.GrindSound:Stop();
	self.BoostSound:Stop();

end


/*------------------------------------
	DrawTranslucent
------------------------------------*/
function ENT:DrawTranslucent( )

	// draw opaque
	self:Draw();

end


/*------------------------------------
	PlayerBindPress
------------------------------------*/
local function PlayerBindPress( pl, bind, pressed )

	// get the scripted vehicle
	local board = pl:GetScriptedVehicle();

	// make sure they are using the hoverboard
	if ( !ValidEntity( board ) || board:GetClass() != "modulus_hoverboard" ) then

		// if not, exit
		return;

	end
	
	// list to block
	local blocked = {
	
		"phys_swap",
		"slot",
		"invnext",
		"invprev",
		"lastinv",
		"gmod_tool"
		
	};
	
	// loop
	for _, block in pairs( blocked ) do
	
		// found?
		if ( bind:find( block ) ) then
		
			// block
			return true;
			
		end
		
	end
	
end
hook.Add( "PlayerBindPress", "Hoverboard_PlayerBindPress", PlayerBindPress );


/*------------------------------------
	HUDPaint
------------------------------------*/
local function HUDPaint( )

	// check developer
	if ( GetConVarNumber( "cl_hoverboard_developer" ) == 1 ) then
	
		// trace
		local tr = LocalPlayer():GetEyeTrace();
		
		// check for board
		if ( ValidEntity( tr.Entity ) && tr.Entity:GetClass() == "modulus_hoverboard" ) then
		
			// get coordinates
			local pos = tr.Entity:WorldToLocal( tr.HitPos );
			
			// build string
			local text = ("Coords: %s"):format( tostring( pos ) );
			
			// draw text
			draw.SimpleText(
				text,
				"ScoreboardText",
				( ScrW() * 0.5 ),
				( ScrH() * 0.5 ) + 100,
				Color( 255, 255, 255, 255),
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_CENTER
			);
		
		end
	
	end
	
end
hook.Add( "HUDPaint", "Hoverboard_HUDPaint", HUDPaint );


/*------------------------------------
	Think
------------------------------------*/
function ENT:Think( )

	// check grind time
	if ( self:GetNetworkedFloat( "GrindSoundTime" ) > CurTime() ) then

		// not playing
		if ( !self.GrindSoundPlaying ) then

			// play it
			self.GrindSound:Play();
			self.GrindSoundPlaying = true;

		end

	else

		// still playing
		if ( self.GrindSoundPlaying ) then

			// stop
			self.GrindSound:Stop();
			self.GrindSoundPlaying = false;

		end

	end
	

	// check sound is playing
	if ( !self.HoverSoundPlaying && !self:IsGrinding() ) then

		// setup sound
		self.HoverSound:SetSoundLevel( 60 );
		self.HoverSound:Play();
		self.HoverSoundPlaying = true;

	elseif( self.HoverSoundPlaying && self:IsGrinding() ) then
	
		// stop playing
		self.HoverSound:Stop();
		self.HoverSoundPlaying = false;
		
	else

		// current speed
		local speed = self:GetBoardVelocity();

		// fractional speed
		speed = speed / 700;

		// calculate speed sound
		local soundspeed = math.Clamp( 80 + ( speed * 55 ), 80, 160 );

		// update
		self.HoverSound:ChangePitch( soundspeed );

	end
	

	// check sound
	if ( self.HoverSoundPlaying && self:GetUp().z < 0.33 ) then

		// stop sound
		self.HoverSound:Stop();
		self.HoverSoundPlaying = false;

	end
	
	// received my effects?
	if ( !self.EffectsInitailized && self:GetEffectCount() != false ) then
	
		// all done?
		local done = true;
		
		// initialize each effect
		for i = 1, self:GetEffectCount() do
		
			// was this effect initialized?
			if( !self.Effects[ i ] ) then
			
				// have all the attributes of it?
				if( !self:GetNetworkedVar( "Effect" .. i, false ) ||
					!self:GetNetworkedVar( "EffectPos" .. i, false ) ||
					!self:GetNetworkedVar( "EffectNormal" .. i, false ) ||
					!self:GetNetworkedVar( "EffectScale" .. i, false ) ) then
					
					// not done, this effect isn't here yet
					done = false;
					
				else
		
					// get the effect name
					local effectname = self:GetNetworkedString( "Effect" .. i );
					
					// load a new effect
					local effect = Effects[ effectname ]:new();
					
					// init
					effect.Board = self;
					effect:Init(
						self:GetNetworkedVector( "EffectPos" .. i ),
						self:GetNetworkedVector( "EffectNormal" .. i ),
						self:GetNetworkedFloat( "EffectScale" .. i )
						
					);
					
					// add
					self.Effects[ i ] = effect;
					
				end
				
			end
		
		end
		
		// say we inited the effects
		self.EffectsInitailized = done;

	end
	
	// run effect think
	for _, effect in pairs( self.Effects ) do
	
		// call
		effect:Think();
	
	end

	// think
	self:NextThink( UnPredictedCurTime() );
	return true;

end


/*------------------------------------
	Draw
------------------------------------*/
function ENT:Draw( )

	// render model
	self:DrawModel();

	// run effect render
	for _, effect in pairs( self.Effects ) do
	
		// call
		effect:Render();
	
	end
	
	// render thrusters
	if( GetConVarNumber( "cl_hoverboard_developer" ) == 1 ) then

		// for each hover point
		for i = 1, #self.ThrusterPoints do

			//local point = phys:LocalToWorld( self.ThrusterPoints[ i ].Pos );
			local point = self:GetThruster( i );

			local tracelen = self.Entity:GetHoverHeight() - ( self.ThrusterPoints[ i ].Diff or 0 );

			// trace for solid
			local trace = {
				start = point,
				endpos = point - Vector( 0, 0, tracelen ),
				mask = MASK_NPCWORLDSTATIC

			};
			local tr = util.TraceLine( trace );

			// color
			local color = Color( 128, 255, 128, 255 );
			if( tr.Hit ) then

				color = Color( 255, 128, 128, 255 );

			end
			
			local scale = ( self.ThrusterPoints[ i ].Spring || 1 ) * 0.5;
			local sprite = 16 * scale;
			local beam = 4 * scale;
			
			// render
			cam.IgnoreZ( true );
			render.SetMaterial( glow );
			render.DrawSprite( point, sprite, sprite, color );
			render.DrawSprite( tr.HitPos, sprite, sprite, color );
			render.SetMaterial( trail );
			render.DrawBeam( point, tr.HitPos, beam, 0, 1, color );
			cam.IgnoreZ( false );

		end

	end

end

// load effects
LoadEffects();

