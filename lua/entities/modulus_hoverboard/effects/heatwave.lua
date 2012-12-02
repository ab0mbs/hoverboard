
// materials
local glow = Material( "modulus_hoverboard/glow" );

/*------------------------------------
	Init
------------------------------------*/
function EFFECT:Init( pos, normal, scale )

	// pos and scale are the only things that interest us
	self.Position = pos;
	self.Scale = scale;
	self.Normal = normal:Angle();
	
	// create an emitter
	self.Emitter = ParticleEmitter( self.Board:GetPos() );

end

/*------------------------------------
	ShouldRender
------------------------------------*/
function EFFECT:ShouldRender( )

	if( self.Board:IsGrinding() || self.Board:GetUp().z < 0.33 ) then
	
		return false;
	
	end
	
	return true;

end

/*------------------------------------
	Think
------------------------------------*/
function EFFECT:Think( )

	// time to update?
	if( !self:ShouldRender() ) then

		return;

	end
	
	// emit particles
	local particle = self.Emitter:Add( "sprites/heatwave", self.Board:LocalToWorld( self.Position ) );
		particle:SetDieTime( math.Rand( 0.05, 0.15 ) );
		particle:SetColor( 255, 255, 255 );
		particle:SetStartSize( 8 * self.Scale );
		particle:SetEndSize( math.Rand( 4, 8 ) * self.Scale );
		particle:SetStartAlpha( 255 );
		particle:SetEndAlpha( 255 );
		particle:SetVelocity( self.Board:WorldToLocalAngles( self.Normal ):Forward() * math.Rand( 50, 150 ) + VectorRand() * math.Rand( 10, 25 ) );
		particle:SetRollDelta( math.Rand( -2, 2 ) );
		particle:SetCollide( true );
		particle:SetBounce( 0.2 );

end

/*------------------------------------
	Render
------------------------------------*/
function EFFECT:Render( )

	// time to update?
	if( !self:ShouldRender() ) then

		return;

	end

	// anchor pos
	local timer = math.max( 0, math.sin( UnPredictedCurTime() ) );
	local timer2 = math.max( 0, math.sin( UnPredictedCurTime() * 2 ) );
	local anchor = self.Board:LocalToWorld( self.Position );
	
	// render the sprites
	render.SetMaterial( glow );
	render.DrawSprite(
		anchor,
		48 * self.Scale, 48 * self.Scale,
		Color( 255, 128, 0, 60 )

	);
	render.DrawSprite(
		anchor,
		48 * timer, 48 * timer,
		Color( 255, 128, 0, 20 )

	);
	render.DrawSprite(
		anchor,
		32 * timer2, 32 * timer2,
		Color( 255, 128, 0, 20 )

	);

end
