/*	---------------------------------------------------------
	File.......: WDO_SQLITE3.prg
	Description: Conexi�n a Bases de Datos Sqlite3
				  Version for Uhttpd2	
	Author.....: Carles Aubia Floresvi
	Date:......: 18/12/2023
	Updated:...: 18/12/2023
	--------------------------------------------------------- */ 	
#include 'hbclass.ch'
#include "error.ch"
#include "FileIO.ch"
#include "lib\sqlite3\hbsqlite3.ch"

#define VERSION_WDO_SQLITE3					'1.0'

#xcommand TRY  => BEGIN SEQUENCE WITH {| oErr | Break( oErr ) }
#xcommand CATCH [<!oErr!>] => RECOVER [USING <oErr>] <-oErr->
#xcommand FINALLY => ALWAYS

CLASS WDO_Sqlite3 //FROM WDO

	DATA cFile
	DATA db
      
	METHOD New( cFile, lCreate )
	
	METHOD IsTable( cTable )	
	METHOD Query( cSql )
	METHOD Exec( cSql )	
	
	METHOD Prepare( cSql )
	
	METHOD Version()						INLINE VERSION_WDO_SQLITE3
	METHOD VersionName()					INLINE 'WDO_SQLITE3 ' + VERSION_WDO_SQLITE3	
 
ENDCLASS

METHOD New( cFile, lCreate ) CLASS WDO_Sqlite3

	hb_default( @cFile, '' )
	hb_default( @lCreate, .T. )
	
	::cFile := cFile 
	
	::db := sqlite3_open( cFile, lCreate )

    IF sqlite3_errcode( ::db ) != SQLITE_OK
		raiseError( sqlite3_errmsg( ::db ) )
    ENDIF		

RETU Self

METHOD IsTable( cTable ) CLASS WDO_Sqlite3

	local lExist := .f.
	local Stmt, cSql, o

	hb_default( cTable, '' )	

	cSql := 'PRAGMA table_info( ' + cTable + ' )'			
	stmt := sqlite3_prepare( ::db, cSql )    
	
	try 			
		lExist := sqlite3_step( stmt ) == SQLITE_ROW
	catch o 
		? 'Error: ' + o:description
	end 	
	
    sqlite3_finalize( stmt )

RETU lExist

// ---------------------------------------------

METHOD Query( cSql ) CLASS WDO_Sqlite3

	local aRows 	:= {}
	local o	
	
	hb_default( @cSql, '' )

	try 
		aRows	:= sqlite3_get_table( ::db, cSql )		
	catch o 
		? 'Error: ' + o:description	
	end 	

retu WDO_Sqlite3_RS():New( aRows )

// ---------------------------------------------

METHOD Prepare( cSql ) CLASS WDO_Sqlite3

	local aRows 	:= {}
	local o, pStmt
	
	hb_default( @cSql, '' )

	try 
		pStmt := sqlite3_prepare( ::db, cSql )	

		if Empty( pStmt )
			? "Can't prepare statement : ", cSql
			raiseError(  "Can't prepare statement : " +  cSql )
		endif
		
	catch o 
		? 'Error: ' + o:description	
	end 	

retu WDO_Sqlite3_Stmt():New( ::db, pStmt, cSql )



METHOD Exec( cSql ) CLASS WDO_Sqlite3

	local lOk := .f.
	local o
	
	try 
		lOk := sqlite3_exec( ::db, cSql ) == SQLITE_OK
	catch o 
		? 'Error ' + o:description
	end 
	
RETU lOk 

//	--------------------------------------------------

CREATE CLASS WDO_Sqlite3_RS //FROM WDO_Sqlite3

	
	DATA aCols  			INIT {}
	DATA aRows  			INIT {}
	DATA nRows  			INIT 0
	DATA nCols  			INIT 0     
	DATA nPos  				INIT 0   
	DATA lAssociative		INIT .f.
	
	METHOD New( aTable )	
	
	METHOD Headers()		INLINE ::aCols
	METHOD FetchAll()	
	METHOD Count() 		INLINE ::nRows
	METHOD FCount() 		INLINE ::nCols
	METHOD GoTo( n )		INLINE if( n > 0 .and. n <= ::nRows , ::nPos := n, nil )
	METHOD Row()			
	METHOD View( )			
	
 
ENDCLASS

METHOD New( aRows ) CLASS WDO_Sqlite3_RS
	
	hb_default( @aRows, {} )
	
	::nRows := len( aRows )

	if ::nRows > 0
		::nCols := len( aRows[1] )			
		::aCols := aRows[1]		
		::nPos 	:= 1
	endif
	
	::aRows := hb_ADel( aRows, 1, .T. )
	::nRows := len( aRows )
	
	if ::nRows > 0
		::lAssociative	 := valtype( aRows[1] ) == 'H'
	else
		::lAssociative	 := .f.
	endif
	

RETU SELF

METHOD Row( lAssociative ) CLASS WDO_Sqlite3_RS

	local hReg, nJ

	hb_default( @lAssociative, .f. )
	
	if lAssociative 
	
		hReg := {=>}
		
		for nJ := 1 to ::nCols
			hReg[ ::aCols[nJ] ] := ::aRows[::nPos][nJ]
		next	
		
		retu hReg 
		
	else
	
		retu ::aRows[::nPos]
	
	endif
	

RETU nil 

METHOD FetchAll( lAssociative ) CLASS WDO_Sqlite3_RS

	local hReg := {=>}
	local aRows := {}
	local nI, nJ

	hb_default( @lAssociative, .f. )
	
	if lAssociative 

		for nI := 1 to ::nRows
	
			hReg := {=>}			
			
			for nJ := 1 to ::nCols						
				hReg[ ::aCols[nJ] ] := ::aRows[nI][nJ]
			next
		
			Aadd( aRows, hReg )
		next 
		
		retu aRows		
	else 	
		retu ::aRows 
	endif 	
	
RETU nil 

METHOD View() CLASS WDO_Sqlite3_RS
	
	LOCAL cHtml 	:= ''
	LOCAL n, j
	
	if empty( ::nCols )
		retu ''
	endif
	
	//cHtml := '<h3>View table</h3>'		
	
	cHtml += '<style>'
	cHtml += '#mytable tr:hover {background-color: #ddd;}'
	cHtml += '#mytable tr:nth-child(even){background-color: #e0e6ff;}'
	cHtml += '#mytable { font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;border-collapse: collapse; width: 100%; }'
	cHtml += '#mytable thead { background-color: #425ecf;color: white;}'
	cHtml += '</style>'
	cHtml += '<table id="mytable" border="1" cellpadding="3" >'
	
	cHtml += '<thead><tr>'
	
	FOR n := 1 TO ::nCols
	
		cHtml += '<td>' + ::aCols[n] + '</td>'
		
	NEXT
	
	cHtml += '</tr></thead>'		
	
	cHtml += '<tbody>'
	
	//? cHtml 
	
	FOR n := 1 to ::nRows
	
		cHtml += '<tr>'
		
		FOR j := 1 to ::nCols
		
			if ::lAssociative
				cHtml += '<td>' + UValtochar( HB_HValueAt( ::aRows[n], j ) ) + '</td>'
			else
				cHtml += '<td>' + UValtochar( ::aRows[n][j] ) + '</td>'
			endif
		
		NEXT
		
		cHtml += '</tr>'
		
		//?? cHtml
	
	NEXT
	
	cHtml += '</tbody></table><hr>'
	//?? '</tbody></table><hr>'

RETU cHtml

//	--------------------------------------------------

CREATE CLASS WDO_Sqlite3_Stmt

	DATA db 
	DATA pStmt
	DATA cSql 
	DATA aBinds
	
	METHOD New( db, pStmt, cSql  )					
	METHOD Bind( cKey, uValue )					
	METHOD Exec()					
 
ENDCLASS

METHOD New( db, pStmt, cSql ) CLASS WDO_Sqlite3_Stmt

	::db 	:= db
	::pStmt := pStmt
	::cSql 	:= cSql 
	::aBinds := {}

retu Self

METHOD Bind( cKey, uValue ) CLASS WDO_Sqlite3_Stmt	
	
	hb_default( @cKey, '' )
	
	aadd( ::aBinds, { cKey, uValue, -1 } )

RETU nil 

METHOD Exec() CLASS WDO_Sqlite3_Stmt

	local nI, cKey, nPos, uValue, cType, lOk, lExec
	local lError := .f.
	
	for nI := 1 to len( ::aBinds )
		
		cKey := ::aBinds[nI][1]
		nPos := At( cKey, ::cSql )							
		
		if nPos == 0
			lError := .t.
		endif
		
		::aBinds[nI][3] := nPos				
	next
	
	//	Sort by key pos 
	
	::aBinds := ASort( ::aBinds,,, {|x,y| x[3] < y[3] } )


	if !lError
		
		for nI := 1 to len( ::aBinds )		
		
			uValue := ::aBinds[nI][2]
			
			cType := valtype( uValue )
			
			//? nI, ::aBinds[nI][1], cType
			
			//try
			
				do case
					case cType == 'C' ; lOk := sqlite3_bind_text( ::pStmt, nI, uValue ) == SQLITE_OK
					case cType == 'N' ; lOk := sqlite3_bind_int ( ::pStmt, nI, uValue ) == SQLITE_OK
					case cType == 'D' ; lOk := sqlite3_bind_text ( ::pStmt, nI, DToS( uValue ) ) == SQLITE_OK
					case cType == 'B' ; lOk := sqlite3_bind_blob( ::pStmt, nI, @uValue ) == SQLITE_OK
					otherwise			
						lOk := sqlite3_bind_text( ::pStmt, nI, hb_CStr( uValue ) ) == SQLITE_OK			
				endcase
			
			//catch o 
			//	? 'Error ' + o:description
			//end 
			
			
		next				
		
		lExec := sqlite3_step( ::pStmt ) == SQLITE_DONE
		
		//?? lExec
		
		//? 'Reset...'
		//sqlite3_reset( ::pStmt )
		
		// 'Clear...'
	    sqlite3_clear_bindings( ::pStmt )
        sqlite3_finalize( ::pStmt )	

	else
	
		? 'Error binds...'

	endif

retu nil 

function raiseError( cErrMsg )

   LOCAL oErr
   //_d( cErrMsg )
   //retu nil
? 'Din s Error...'
   oErr := ErrorNew()
   oErr:severity := ES_ERROR
   oErr:genCode := EG_OPEN
   oErr:subSystem := "HDBCSQLT"
   oErr:SubCode := 1000
   oErr:Description := cErrMsg

   Eval( ErrorBlock(), oErr )
? 'Fora Error...'
RETURN nil