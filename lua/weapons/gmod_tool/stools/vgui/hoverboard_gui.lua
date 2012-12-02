
/*------------------------------------
	Init
------------------------------------*/
function PANEL:Init( )

	// height
	self:SetTall( 1000 );

	// stuff
	self.AttributePoints = 5;
	self.Attributes = {};

	// model select
	self.BoardSelect = vgui.Create( "PropSelect", self );
	self.BoardSelect:SetConVar( "hoverboard_model" );
	self.BoardSelect.Label:SetText( "Select Model" );
	
	// points
	self.PointsText = vgui.Create( "DLabel", self );
	self.PointsText:SetText( "Attribute Points: 0" );
	self.PointsText:SizeToContents();
	
	// add attributes
	self:AddAttribute( "Speed" );
	self:AddAttribute( "Jump" );
	self:AddAttribute( "Turn" );
	self:AddAttribute( "Flip" );
	self:AddAttribute( "Twist" );
	
	// trail
	self.TrailLabel = vgui.Create( "DLabel", self );
	self.TrailLabel:SetText( "Trail Color" );
	self.TrailLabel:SizeToContents();
	
	self.TrailColor = vgui.Create( "CtrlColor", self );
	self.TrailColor:SetConVarR( "hoverboard_trail_r" );
	self.TrailColor:SetConVarG( "hoverboard_trail_g" );
	self.TrailColor:SetConVarB( "hoverboard_trail_b" );
	
	// boost
	self.BoostLabel = vgui.Create( "DLabel", self );
	self.BoostLabel:SetText( "Boost Color" );
	self.BoostLabel:SizeToContents();
	
	self.BoostColor = vgui.Create( "CtrlColor", self );
	self.BoostColor:SetConVarR( "hoverboard_boost_r" );
	self.BoostColor:SetConVarG( "hoverboard_boost_g" );
	self.BoostColor:SetConVarB( "hoverboard_boost_b" );
	
	// recharge
	self.RechargeLabel = vgui.Create( "DLabel", self );
	self.RechargeLabel:SetText( "Recharge Color" );
	self.RechargeLabel:SizeToContents();
	
	self.RechargeColor = vgui.Create( "CtrlColor", self );
	self.RechargeColor:SetConVarR( "hoverboard_recharge_r" );
	self.RechargeColor:SetConVarG( "hoverboard_recharge_g" );
	self.RechargeColor:SetConVarB( "hoverboard_recharge_b" );
	
	// trail size
	self.TrailSize = vgui.Create( "DNumSlider", self );
	self.TrailSize:SetText( "Trail Size" );
	self.TrailSize:SetMin( 0 );
	self.TrailSize:SetMax( 10 );
	self.TrailSize:SetDecimals( 0 );
	self.TrailSize:SetConVar( "hoverboard_trail_size" );
	
	// hover height
	self.HoverHeight = vgui.Create( "DNumSlider", self );
	self.HoverHeight:SetText( "Hover Height" );
	self.HoverHeight:SetMin( 36 );
	self.HoverHeight:SetMax( 100 );
	self.HoverHeight:SetDecimals( 0 );
	self.HoverHeight:SetConVar( "hoverboard_height" );
	
	// view distance
	self.ViewDistance = vgui.Create( "DNumSlider", self );
	self.ViewDistance:SetText( "View Distance" );
	self.ViewDistance:SetMin( 64 );
	self.ViewDistance:SetMax( 256 );
	self.ViewDistance:SetDecimals( 0 );
	self.ViewDistance:SetConVar( "hoverboard_viewdist" );
	
	// mouse control
	self.MouseControl = vgui.Create( "DCheckBoxLabel", self );
	self.MouseControl:SetText( "Mouse Control" );
	self.MouseControl:SetConVar( "hoverboard_mousecontrol" );
	self.MouseControl:SizeToContents();
	
	// boost shake
	self.BoostShake = vgui.Create( "DCheckBoxLabel", self );
	self.BoostShake:SetText( "Boost Shake" );
	self.BoostShake:SetConVar( "hoverboard_boostshake" );
	self.BoostShake:SizeToContents();
	
end


/*------------------------------------
	PerformLayout
------------------------------------*/
function PANEL:PerformLayout( )
	
	// starting positions
	local vspacing = 10;
	local ypos = 0;
	
	// model select
	self.BoardSelect:SetPos( 0, ypos );
	self.BoardSelect:SetSize( self:GetWide(), 165 );
	ypos = self.BoardSelect.Y + self.BoardSelect:GetTall() + vspacing;
	
	// points remaining
	self.PointsText:SetPos( 0, ypos );
	ypos = self.PointsText.Y + self.PointsText:GetTall() + vspacing;
	
	// attributes
	for _, panel in pairs( self.Attributes ) do
	
		// size & position
		panel:SetPos( 0, ypos );
		panel:SetSize( self:GetWide(), panel:GetTall() );
		ypos = panel.Y + panel:GetTall() + vspacing;
		
	end
	
	// trail color
	self.TrailLabel:SetPos( 0, ypos );
	ypos = self.TrailLabel.Y + self.TrailLabel:GetTall() + 2;
	
	self.TrailColor:SetPos( 0, ypos );
	self.TrailColor:SetSize( self:GetWide(), self.TrailColor:GetTall() );
	ypos = self.TrailColor.Y + self.TrailColor:GetTall() + vspacing;
	
	// boost color
	self.BoostLabel:SetPos( 0, ypos );
	ypos = self.BoostLabel.Y + self.BoostLabel:GetTall() + 2;
	
	self.BoostColor:SetPos( 0, ypos );
	self.BoostColor:SetSize( self:GetWide(), self.BoostColor:GetTall() );
	ypos = self.BoostColor.Y + self.BoostColor:GetTall() + vspacing;
	
	// recharge color
	self.RechargeLabel:SetPos( 0, ypos );
	ypos = self.RechargeLabel.Y + self.RechargeLabel:GetTall() + 2;
	
	self.RechargeColor:SetPos( 0, ypos );
	self.RechargeColor:SetSize( self:GetWide(), self.RechargeColor:GetTall() );
	ypos = self.RechargeColor.Y + self.RechargeColor:GetTall() + 4;
	
	// trail size
	self.TrailSize:SetPos( 0, ypos );
	self.TrailSize:SetSize( self:GetWide(), self.TrailSize:GetTall() );
	ypos = self.TrailSize.Y + self.TrailSize:GetTall() + vspacing;
	
	// hover height
	self.HoverHeight:SetPos( 0, ypos );
	self.HoverHeight:SetSize( self:GetWide(), self.HoverHeight:GetTall() );
	ypos = self.HoverHeight.Y + self.HoverHeight:GetTall() + vspacing;
	
	// view distance
	self.ViewDistance:SetPos( 0, ypos );
	self.ViewDistance:SetSize( self:GetWide(), self.ViewDistance:GetTall() );
	ypos = self.ViewDistance.Y + self.ViewDistance:GetTall() + vspacing;
	
	// mouse controls
	self.MouseControl:SetPos( 0, ypos );
	ypos = self.MouseControl.Y + self.MouseControl:GetTall() + vspacing;
	
	// boost shake
	self.BoostShake:SetPos( 0, ypos );
	ypos = self.BoostShake.Y + self.BoostShake:GetTall() + vspacing;
	
	// update text
	self:UpdatePoints();

end


/*------------------------------------
	Think
------------------------------------*/
function PANEL:Think( )

	// get points
	local points = GetGlobalInt( "HoverPoints" );
	
	// check for change
	if ( points != self.AttributePoints ) then
	
		// clamp
		points = math.Clamp( tonumber( points ), 5, 50 );
		
		// reset each panel
		for name, panel in pairs( self.Attributes ) do
		
			panel:SetValue( 0 );
			panel:ValueChanged( 0 );
			panel:PerformLayout();
		
		end
		
		// save points
		self.AttributePoints = points;
		
		// update text
		self:UpdatePoints();
	
	end
	
	// check table
	if ( self.HoverboardTable ) then
	
		// get selected
		local selected = GetConVarString( self.BoardSelect:ConVar() );
		
		// check if selection changed
		if ( selected != self.LastSelectedBoard ) then
		
			// save
			self.LastSelectedBoard = selected;
			
			// loop attributes
			for name, panel in pairs( self.Attributes ) do
			
				// reset
				panel:SetText( name );
				panel.Label:SetTextColor( panel.OldFontColor );
			
			end
			
			// loop boards
			for _, board in pairs( self.HoverboardTable ) do
			
				// match model
				if ( selected:lower() == board[ 'model' ]:lower() ) then
				
					// loop bonuses
					for k, v in pairs( board[ 'bonus' ] ) do
						
						// loop attributes
						for name, panel in pairs( self.Attributes ) do
						
							// match name
							if ( panel.Attribute == k:lower() ) then
							
								// change color
								panel:SetText( ("%s +%d"):format( name, tonumber( v ) ) );
								panel.Label:SetTextColor( Color( 255, 100, 100, 255 ) );
							
							end
							
						end
			
					end
					
					// done
					break;
				
				end
				
			end
			
		end
	
	end
		
end


/*------------------------------------
	PopulateBoards
------------------------------------*/
function PANEL:PopulateBoards( tbl )

	// loop boards
	for _, board in pairs( tbl ) do
	
		// add model
		self.BoardSelect:AddModel( board[ 'model' ] );
		
		// change text
		self.BoardSelect.Controls[ #self.BoardSelect.Controls ]:SetToolTip( board[ 'name' ] or "Unknown" );
	
	end
	
	// save
	self.HoverboardTable = tbl;

end


/*------------------------------------
	GetUsedPoints
------------------------------------*/
function PANEL:GetUsedPoints( ignore )

	// reset count
	local count = 0;

	// loop attributes
	for _, panel in pairs( self.Attributes ) do
	
		// check ignore
		if ( panel != ignore ) then
		
			// count
			count = count + panel:GetValue();
		
		end
	
	end
	
	// return
	return count;
	
end


/*------------------------------------
	UpdatePoints
------------------------------------*/
function PANEL:UpdatePoints( )

	// update label
	self.PointsText:SetText( ("Attribute Points: %d/%s"):format( self.AttributePoints - self:GetUsedPoints(), self.AttributePoints ) );
	self.PointsText:SizeToContents();
	
end


/*------------------------------------
	AddAttribute
------------------------------------*/
function PANEL:AddAttribute( name )

	// create & setup
	local panel = vgui.Create( "DNumSlider", self );
	panel:SetText( name );
	panel:SetMin( 0 );
	panel:SetMax( 10 );
	panel:SetDecimals( 0 );
	panel:SetConVar( ("hoverboard_%s"):format( name:lower() ) );
	panel.Attribute = name:lower();
	panel.OnValueChanged = function( slider, val )
	
		// clamp it
		val = math.Clamp( tonumber( val ), 0, 10 );
	
		// get used
		local count = self:GetUsedPoints( slider );
		
		// make sure we dont go over limit
		if ( count + val > self.AttributePoints ) then
		
			// new value
			val = self.AttributePoints - count;
		
			// update
			slider:SetValue( val )
			slider:ValueChanged( val );
			slider:PerformLayout();
			
		end
		
		// update text
		self:UpdatePoints();
		
	end
	
	// save font color
	panel.OldFontColor = panel.Label:GetTextColor();
	
	// store
	self.Attributes[ name ] = panel;

end
