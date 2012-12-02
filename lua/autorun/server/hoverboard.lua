
// hoverboard limit
CreateConVar( "sbox_maxhoverboards", 1, { FCVAR_NOTIFY, FCVAR_ARCHIVE } );
CreateConVar( "sv_hoverboard_adminonly", 0, { FCVAR_NOTIFY, FCVAR_ARCHIVE } );
CreateConVar( "sv_hoverboard_cansteal", 0, { FCVAR_NOTIFY, FCVAR_ARCHIVE } );
CreateConVar( "sv_hoverboard_canshare", 1, { FCVAR_NOTIFY, FCVAR_ARCHIVE } );
local points = CreateConVar( "sv_hoverboard_points", 45, { FCVAR_NOTIFY, FCVAR_ARCHIVE } );
timer.Create( "HoverPointsThink", 1, 0, function() SetGlobalInt( "HoverPoints", points:GetInt() ); end );

// downloads
resource.AddFile( "data/hoverboards.txt" );
resource.AddFile( "materials/modulus_hoverboard/glow.vmt" );
resource.AddFile( "materials/modulus_hoverboard/trail.vmt" );
resource.AddFile( "materials/modulus_hoverboard/deathicon.vmt" );
resource.AddFile( "materials/modulus_hoverboard/deathicon.vtf" );
