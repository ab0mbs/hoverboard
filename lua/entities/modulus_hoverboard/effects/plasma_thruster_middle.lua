
// materials
local plasma = Material( "effects/strider_muzzle" );
local refract = Material( "sprites/heatwave" );

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
	local anchor = self.Board:LocalToWorld( self.Position );

	// shift the anchor pos
	local normal = self.Board:LocalToWorldAngles( self.Normal ):Forward();
	anchor = anchor + normal * 2.5;
	
	// draw bottom
	render.SetMaterial( refract );
	render.DrawSprite(
		anchor,
		4 * math.Rand( 1, 1.5 ), 4 * math.Rand( 1, 1.5 ),
		Color( 128, 200, 255, 255 )

	);

	// scroll speed;
	local scroll = UnPredictedCurTime() * -20;

	// draw
 	render.SetMaterial( plasma );

 	// 1
 	scroll = scroll * 0.9;
 	render.StartBeam( 3 );
 		render.AddBeam( anchor, 3, scroll, Color( 0, 255, 255, 255) );
 		render.AddBeam( anchor + normal * 8, 3, scroll + 0.01, Color( 255, 255, 255, 255) );
 		render.AddBeam( anchor + normal * 12, 3, scroll + 0.02, Color( 0, 255, 255, 0) );
 	render.EndBeam();

 	// 2
 	scroll = scroll * 0.9;
 	render.StartBeam( 3 );
 		render.AddBeam( anchor, 3, scroll, Color( 0, 255, 255, 255) );
 		render.AddBeam( anchor + normal * 3, 3, scroll + 0.01, Color( 255, 255, 255, 255) );
 		render.AddBeam( anchor + normal * 6, 3, scroll + 0.02, Color( 0, 255, 255, 0) );
 	render.EndBeam();

 	// 3
 	scroll = scroll * 0.9;
 	render.StartBeam( 3 );
 		render.AddBeam( anchor, 3, scroll, Color( 0, 255, 255, 255) );
 		render.AddBeam( anchor + normal * 3, 3, scroll + 0.01, Color( 255, 255, 255, 255) );
 		render.AddBeam( anchor + normal * 6, 3, scroll + 0.02, Color( 0, 255, 255, 0) );
 	render.EndBeam();

end
