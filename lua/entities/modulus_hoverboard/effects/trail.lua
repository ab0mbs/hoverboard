
// materials
local glow = Material( "modulus_hoverboard/glow" );
local trail = Material( "modulus_hoverboard/trail" );

/*------------------------------------
	RemapValClamped
------------------------------------*/
function EFFECT:RemapValClamped( value, a, b, c, d )

	// clamp to 0/1
	local v = math.Clamp(
		( value - a ) / ( b - a ),
		0, 1

	);

	// remap
	return c + ( d - c ) * v;

end

/*------------------------------------
	Init
------------------------------------*/
function EFFECT:Init( pos, normal, scale )

	// pos and scale are the only things that interest us
	self.Position = pos;

	// trail points
	self.Points = {};
	self.NextPoint = UnPredictedCurTime() + 0.05;

end

/*------------------------------------
	Think
------------------------------------*/
function EFFECT:Think( )

	// time to update?
	if ( self.NextPoint > UnPredictedCurTime() || self.Board:GetBoardVelocity() < 150 || self.Board:IsGrinding() ) then

		return;

	end

	// add new trail points
	self.Points[ #self.Points + 1 ] = {
		Position = self.Board:LocalToWorld( self.Position ),
		DieTime = UnPredictedCurTime() + 0.5,

	};

	// destroy dead trail segments
	for i = #self.Points, 1, -1 do

		// die?
		if ( self.Points[ i ].DieTime <= UnPredictedCurTime() ) then

			table.remove( self.Points, i );

		end

	end

	// next update
	self.NextPoint = UnPredictedCurTime() + 0.05;

end

/*------------------------------------
	Render
------------------------------------*/
function EFFECT:Render( )

	local count = #self.Points;
	
	// not enough points to draw the trail
	if( count <= 1 || self.Board:IsGrinding() ) then

		return;
	
	end
	
	// alpha
	local alpha = self:RemapValClamped( self.Board:GetBoardVelocity(), 150, 1000, 0, 255 );
	
	// get trail color
	local color_vec = self.Board:GetTrailColor();
	local color = Color(
		color_vec.x,
		color_vec.y,
		color_vec.z,
		255
		
	);
	
	// get recharge color
	local recharge_color_vec = self.Board:GetTrailRechargeColor();
	local recharge_color = Color(
		recharge_color_vec.x,
		recharge_color_vec.y,
		recharge_color_vec.z,
		255
		
	);

	// get boost color
	local boost_color_vec = self.Board:GetTrailBoostColor();
	local boost_color = Color(
		boost_color_vec.x,
		boost_color_vec.y,
		boost_color_vec.z,
		255
		
	);
	
	// boosting?
	if ( self.Board:IsBoosting() ) then
		
		// boost percent
		local percent = ( 100 - self.Board:Boost() ) / 100;
		
		// lerp
		color = Color(
			Lerp( percent, boost_color.r, recharge_color.r ),
			Lerp( percent, boost_color.g, recharge_color.g ),
			Lerp( percent, boost_color.b, recharge_color.b ),
			255
		
		);

	elseif ( !self.Board:IsBoosting() && self.Board:Boost() < 100 ) then

		// boost percent
		local percent = self.Board:Boost() / 100;
		
		// lerp
		color = Color(
			Lerp( percent, recharge_color.r, color.r ),
			Lerp( percent, recharge_color.g, color.g ),
			Lerp( percent, recharge_color.b, color.b ),
			255
		
		);

	end
	
	// anchor pos
	local anchor = self.Board:LocalToWorld( self.Position );
	
	// render the sprites
	render.SetMaterial( glow );
	render.DrawSprite(
		anchor,
		24 * self.Board:GetTrailScale(), 24 * self.Board:GetTrailScale(),
		Color( color.r, color.g, color.b, alpha * 0.5 )

	);
	render.DrawSprite(
		anchor,
		math.Rand( 8, 10 ) * self.Board:GetTrailScale(), math.Rand( 8, 10 ) * self.Board:GetTrailScale(),
		Color( color.r, color.g, color.b, alpha )

	);
	
	// left trail
	render.SetMaterial( trail );
	render.StartBeam( count + 1 );

	// segments
	for i = 1, count do

		local seg = self.Points[ i ];

		// coord
		local coord = ( 1 / count ) * ( i - 1 );

		// calculate alpha
		local percent = math.Clamp( ( seg.DieTime - UnPredictedCurTime() ) / 0.5, 0, 1 );

		// point
		render.AddBeam(
			seg.Position,
			12 * self.Board:GetTrailScale(),
			coord,
			Color( color.r, color.g, color.b, alpha * percent )

		);

	end

	// start point
	render.AddBeam(
		anchor,
		12 * self.Board:GetTrailScale(),
		1,
		Color( color.r, color.g, color.b, alpha )

	);

	// finihs
	render.EndBeam();

end
