/*	---------------------------------------------------------
	File.......: WDO.prg
	Description: Base WDO. Conexión a Bases de Datos. 
				  Version for Uhttpd2
	Author.....: Carles Aubia Floresvi
	Date:......: 26/07/2019
	Updated:...: 17/03/2023
	--------------------------------------------------------- */
#include 'hbclass.ch'

#xcommand ? [<explist,...>] => UWrite( '<br>' [,<explist>] )
#xcommand ?? [<explist,...>] => UWrite( [<explist>] )
	
#define WDO_VERSION 		'2.0'

thread static hPool 

CLASS WDO	

	DATA cError 								INIT ''
	DATA bError 								
	
	CLASSDATA lShowError						INIT .t.
	CLASSDATA lLog								INIT .f.
	
	METHOD VersionName()						INLINE 'WDO UHttpd2'
	METHOD Version()							INLINE WDO_VERSION
	
	METHOD SetError( cError )		
	METHOD View( aSt, aData ) 
	
ENDCLASS


METHOD SetError( cError ) CLASS WDO

	::cError := cError

	IF ::lShowError				

		IF Valtype( ::bError ) == 'B'

			//if Eval( ::bError, ::cError )			
			Eval( ::bError, ::cError )			
	
			//endif
			
		ELSE		
			? '<h3><b>Error</b>', ::cError, '</b></h3>'
		ENDIF
			
	ENDIF
	
RETU NIL

//	------------------------------------------------------- //


METHOD View( aSt, aData ) CLASS WDO

	LOCAL nFields 	:= len( aSt )
	LOCAL cHtml 	:= ''
	LOCAL n, j, nLen
	
	cHtml := '<h3>View table</h3>'	
	
	cHtml += '<style>'
	cHtml += '#mytable tr:hover {background-color: #ddd;}'
	cHtml += '#mytable tr:nth-child(even){background-color: #e0e6ff;}'
	cHtml += '#mytable { font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;border-collapse: collapse; width: 100%; }'
	cHtml += '#mytable thead { background-color: #425ecf;color: white;}'
	cHtml += '</style>'
	cHtml += '<table id="mytable" border="1" cellpadding="3" >'
	
	cHtml += '<thead><tr>'
	
	FOR n := 1 TO nFields
	
		cHtml += '<td>' + aSt[n][1] + '</td>'
		
	NEXT
	
	cHtml += '</tr></thead>'
	
	nLen := len( aData )
	
	cHtml += '<tbody>'
	
	? cHtml 
	
	FOR n := 1 to nLen 
	
		cHtml := '<tr>'
		
		FOR j := 1 to nFields

			cHtml += '<td>' + UValtochar( aData[n][j] ) + '</td>'
		
		NEXT
		
		cHtml += '</tr>'
		
		?? cHtml
	
	NEXT
	
	?? '</tbody></table><hr>'

RETU NIL

//	------------------------------------------------------- //


function WDO_Version() ; retu WDO_VERSION


function WDO_Pool( cName, bInit )
	local h

	hb_default( @cName, '' )	
	
	if empty( cName )
		retu nil
	endif	

	if hPool == nil 	

		if valtype( bInit ) == 'B'
		
			hPool := {=>}
		
			hPool[ cName ] := { 'id' => hb_threadId(),;
								 'pool' => eval( bInit ) }			
				

			retu hPool[ cName ][ 'pool' ]
		else
			retu nil		
		endif 
	
	endif

	if valtype( hPool ) == 'H' .and. HB_HHasKey( hPool, cName )
			h := hPool[ cName ]
			if valtype( h ) == 'H' .and. HB_HHasKey( h, 'id' ) .and. h[ 'id' ] == hb_threadId()
	
				retu h[ 'pool' ]
			endif
	
	endif	
	
retu nil 
