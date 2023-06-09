/*	---------------------------------------------------------
	File.......: WDO_ADO.prg
	Description: Conexi�n ADO
				  Version for Uhttpd2	
	Author.....: Carles Aubia Floresvi
	Date:......: 26/07/2019
	Updated:...: 17/03/2023	
	--------------------------------------------------------- */ 
#include 'hbclass.ch'
#include "adodef.ch"

#define CRLF 		'<br>'

#define VERSION_WDO_ADO					'1.0'	

#xcommand ? [<explist,...>] => UWrite( '<br>' [,<explist>] )
#xcommand TRY  => BEGIN SEQUENCE WITH {| oErr | Break( oErr ) }
#xcommand CATCH [<!oErr!>] => RECOVER [USING <oErr>] <-oErr->
#xcommand FINALLY => ALWAYS
#xtranslate Throw( <oErr> ) => ( Eval( ErrorBlock(), <oErr> ), Break( <oErr> )

	
	
CLASS WDO_ADO FROM WDO

	DATA cServer	
	DATA cUserName
	DATA cPassword 
	DATA cDatabase 

	DATA oCn 	
	DATA lInit									INIT .F.
	DATA lConnect								INIT .F.
	DATA lShowError							INIT .F.
	DATA cError									INIT ''

	
	METHOD New() 								CONSTRUCTOR
	METHOD Open() 
	
	METHOD Query( cSql ) 																
	METHOD Close()	
	
							
	
	METHOD Version()						INLINE VERSION_WDO_ADO
	METHOD VersionName()					INLINE 'WDO_MYSQL ' + VERSION_WDO_ADO
					
	
	DESTRUCTOR  Exit()	

ENDCLASS

METHOD New( cServer, cUsername, cPassword, cDatabase, lAutoOpen ) CLASS WDO_ADO

	
    LOCAL bErrorHandler 	:= {|oError| Break(oError) }
	LOCAL bLastHandler 	:= ErrorBlock(bErrorHandler)
	LOCAL oError	

	__defaultNIL( @lAutoOpen, .F. )
	
	IF Valtype( cServer ) == 'H' 
	
		::cServer		:= HB_HGetDef( cServer, 'server' ) 
		::cUserName	:= HB_HGetDef( cServer, 'user' ) 
		::cPassword 	:= HB_HGetDef( cServer, 'pwd' ) 
		::cDatabase 	:= HB_HGetDef( cServer, 'db' ) 
		
		IF Valtype( cUserName ) == 'L'
			lAutoOpen := cUserName
		ENDIF	
	
	ELSE 

		hb_default( @cServer, '' )
		hb_default( @cUserName, '' )
		hb_default( @cPassword, '' )
		hb_default( @cDatabase, '' )
		hb_default( @lAutoOpen, .T. )
	
		::cServer		:= cServer
		::cUserName		:= cUserName
		::cPassword 	:= cPassword
		::cDatabase 	:= cDatabase
		
	ENDIF
	
	BEGIN SEQUENCE		
	
		::oCn 		:= win_oleCreateObject( "ADODB.Connection" )
		::lInit 	:= .T.
		
	RECOVER USING oError	
	
		::cError := 'Error ADODB'
		
		IF ::lShowError
			? ::cError 
		ENDIF
		
		RETU NIL
		
	END SEQUENCE		
	
	ErrorBlock(bLastHandler) // Restore handler 
	
	IF lAutoOpen
		::Open()
	ENDIF	
		
RETU SELF


METHOD Open() CLASS WDO_ADO

    LOCAL bErrorHandler 	:= { |oError | ADOErrorHandler(oError) }
	LOCAL bLastHandler 	:= ErrorBlock(bErrorHandler)
	LOCAL oError 
	LOCAL cStr  			:= 	"Provider=SQLOLEDB;" + ;
								"Data Source="     + ::cServer 		+ ";" + ;
								"Initial Catalog=" + ::cDatabase   	+ ";" + ;
								"User ID="         + ::cUserName   	+ ";" + ;
								"Password="        + ::cPassword   	+ ";"
				
	IF ::lConnect 
		RETU .T.
	ENDIF
						

	BEGIN SEQUENCE		
	
		WITH OBJECT ::oCn
			:ConnectionString := cStr
			:CursorLocation   := adUseClient
			:Open()
		END	
		
	RECOVER USING oError	

		::cError := oError:description

		IF ::lShowError
			? ::cError 
		ENDIF		
		
		RETU .F.
		
	END SEQUENCE		
	
	ErrorBlock(bLastHandler) // Restore handler    	

	::lConnect := .T.	
					
RETU .T.

STATIC FUNCTION ADOErrorHandler( oError )

	BREAK oError
	
RETU NIL


METHOD Query( cSql, nMaxRecords ) CLASS WDO_ADO

	LOCAL oRs


	oRs   := TOleAuto():new( "ADODB.RecordSet" )

	WITH OBJECT oRs
	
		:ActiveConnection    := ::oCn      
		:Source              := cSql
		:LockType            := adLockOptimistic
		:CursorLocation      := adUseClient            // adUseClient
		:CacheSize           := 100
		:CursorType          := adOpenStatic //nCursorType  // adOpenDynamic

		if HB_IsNumeric( nMaxRecords )
			:MaxRecords       := nMaxRecords
		endif
    

      TRY

		:Open()	 		 

      CATCH

      END
      
   END

RETU RecordSet():New( oRs	, ::oCn )

METHOD Close() CLASS WDO_ADO

    IF ValType( ::oCn ) == "O"

		IF ::oCn:State > 0
			::oCn:Close()
		ENDIF
		
		::oCn := NIL
		::lConnect := .F.

	ENDIF

RETU NIL



METHOD Exit() CLASS WDO_ADO

	//? "ADO free Connection"
	::Close()
	
RETU NIL


//	---------------------------------------------------------------	//


CLASS RecordSet

	DATA oCn 	
	DATA oRs 	
	DATA hRow								INIT 	{=>}
	DATA nFields							INIT 0
	DATA lAssociative 						INIT .T.
	DATA aStruct 
	DATA cError 							INIT ''
	
	METHOD New( oRs, oCn ) 						CONSTRUCTOR
							
	METHOD Count()							INLINE ::oRs:RecordCount()										
	METHOD FCount()						INLINE ::nFields								
	METHOD Next()							INLINE ( ::oRs:MoveNext(), !::oRs:Eof() )	
	METHOD FieldName( n )					INLINE ::oRs:Fields( n - 1 ):Name 	//HB_HKeyAt( ::hRow, n )								
	METHOD FieldGet( n )					INLINE ::oRs:Fields( n - 1 ):Value	//HB_HValueAt( ::hRow, n )								
	METHOD FieldPos( cFieldName ) 	
	METHOD FieldPut( nPos, uValue ) 	
	METHOD Eof()							INLINE ::oRs:Eof							
	//METHOD Append()						INLINE ::oRs:AddNew()
	METHOD Append()						
	METHOD Recno()							INLINE ::oRs:BookMark

	METHOD Save()							

	METHOD Row( lAssociative )							
	METHOD GetFields()							
	
	METHOD FetchAll( lAssociative )

	METHOD Close()							INLINE ( ::oRs:Close(), ::oRs := NIL )

ENDCLASS

METHOD New( oRs, oCn ) CLASS RecordSet		

	::oCn := oCn
	::oRs := oRs
	
	::nFields 	:= ::oRs:Fields:Count()	
	::aStruct 	:= FWAdoStruct( oRs )
	
	

RETU SELF

METHOD FieldPos( cField ) CLASS RecordSet

	LOCAL nPos := Ascan( ::aStruct, {|aItem| upper(aItem[1]) == upper(cField) } )

RETU nPos 

METHOD FieldPut( nPos, uValue ) CLASS RecordSet

	::oRs:Fields( nPos - 1 ):Value := uValue

RETU nil

METHOD Row( lAssociative ) CLASS RecordSet

	LOCAL nI, oField
	
	__defaultNIL( @lAssociative, ::lAssociative )	

	IF lAssociative 
		::hRow := {=>}			
	ELSE
		::hRow := {}
	ENDIF


	
	FOR nI := 1 TO ::nFields
	
		oField := ::oRs:Fields( nI - 1 )
	
		IF lAssociative 

			::hRow[ oField:Name ] :=  oField:Value
			
		ELSE
		
			Aadd( ::hRow, oField:Value )
		
		ENDIF
		
	NEXT	

RETU ::hRow

METHOD FetchAll( lAssociative ) CLASS RecordSet

	LOCAL aData := {}
	local n := 0
	
	__defaultNIL( @lAssociative, ::lAssociative )	

	WHILE ! ::oRs:Eof

		Aadd( aData, ::Row( lAssociative ) )
		
		::Next()		
	
	END	
	
RETU aData

METHOD GetFields() CLASS RecordSet

	LOCAL aFields := {}
	LOCAL n
	
	FOR n := 1 To len( ::aStruct )
		Aadd( aFields, ::aStruct[n][1] )
	Next	

RETU aFields

METHOD Append() CLASS RecordSet

	LOCAL n
	LOCAL cType, uValue

	::oRs:AddNew()

	FOR n := 1 To len( ::aStruct )	
	
		IF ::aStruct[n][6]		//	RW
		
			cType := ::aStruct[n][2]
		
			DO CASE
				CASE cType == 'C'; uValue := ''
				CASE cType == 'N'; uValue := '0'
				CASE cType == 'D'; uValue := '2000-01-01'
				CASE cType == 'L'; uValue := '0'
				CASE cType == 'M'; uValue := ''
				OTHERWISE
					uValue := ''				
			ENDCASE
			
			::FieldPut( n, uValue )
		
		ENDIF
		
	Next

	::oRs:Update()

RETU nil


METHOD Save( hData ) CLASS RecordSet

	LOCAL lSave 		:= .T.
	LOCAL nI 
	LOCAL aItem, aInfo, cField, uValue, cType, nLen, nPos 
	LOCAL bError   	
	LOCAL oError
	local nErr, oErr	
	
	IF Valtype( hData ) == 'H'
	
		bError   	:= Errorblock({ |o| Break(o) })
		
		FOR nI := 1 TO len( hData )

			//	Buscamos si el campo existe en la Estructura
			
				aItem 	:= HB_HPairAt( hData, nI )
				cField 	:= aItem[1]
				uValue 	:= aItem[2]
				
				nPos := Ascan( ::aStruct, {|aStr| upper(aStr[1]) == cField } )
				
				IF nPos > 0
				
					aInfo 	:= ::aStruct[ nPos ]
					cType 	:= aInfo[2]
					nLen 	:= aInfo[3]
					
					IF cType <> '+'  //	Lo mismo que cField == 'ID'
				
						//	Chequeamos los campos que hemos de convertir formato (MS SERVER)
						
						DO CASE
							CASE cType == 'C'
							CASE cType == 'N'
							
								uValue := IF( empty( uValue ), '0', uValue )
								
							CASE cType == 'D'
							
								uValue := IF( empty( uValue ), '00-01-01', uValue )
								
							CASE cType == 'L'
							
								uValue := IF ( uValue == 'yes', '1', '0' )
						
						ENDCASE	
						
							BEGIN SEQUENCE          

							
								::FieldPut( ::FieldPos( cField ), uValue )

								
							RECOVER USING oError	

								 if ( nErr := ::oCn:Errors:Count ) > 0
								 
									::cError := 'Field: ' + cField + ', Value: ' + uValue + CRLF 
																
									oErr  := ::oCn:Errors( nErr - 1 )
								
									::cError +=  HB_OEMTOANSI( oErr:Description )+ CRLF 
									::cError +=  oErr:Source + CRLF 
									::cError +=  ::oCn:Provider 																																
								endif      
								
								lSave := .F.
								
								EXIT
								
							END SEQUENCE

					
					ENDIF
					
				ENDIF		
		
		NEXT
		
		ErrorBlock( bError ) 	

		IF lSave
			::oRs:Update()
		ENDIF
		
	ELSE
	
		::oRs:Update()
	
	ENDIF
	

RETU lSave


//	-----------------------------------------------------------------------------	//
//	FIVEWIN ADO FUNCTIONS
//	-----------------------------------------------------------------------------	//

//----------------------------------------------------------------------------//

function FWAdoStruct( oRs )

   local aStruct  := {}
   local n

   for n := 1 to oRs:Fields:Count()
      AAdd( aStruct, FWAdoFieldStruct( oRs, n ) )
   next

return aStruct

//----------------------------------------------------------------------------//

function FWAdoFieldStruct( oRs, n ) // ( oRs, nFld ) where nFld is 1 based
                                    // ( oRs, oField ) or ( oRs, cFldName )
                                    // ( oField )

   local oField, nType, uval
   local cType := 'C', nLen := 10, nDec := 0, lRW := .t.  // default

   if n == nil
      oField      := oRs
      oRs         := nil
   elseif ValType( n ) == 'O'
      oField      := n
   else
      if ValType( n ) == 'N'
         n--
      endif
      TRY
         oField      := oRs:Fields( n )
      CATCH
      END
   endif
   if oField == nil
      return nil
   endif

   nType       := oField:Type

   if nType == adBoolean
      cType    := 'L'
      nLen     := 1
   elseif AScan( { adDate, adDBDate, adDBTime, adDBTimeStamp }, nType ) > 0
      cType    := 'D'
      nLen     := 8
      if oRs != nil .and. ! oRs:Eof() .and. ValType( uVal := oField:Value ) == 'T' 
	  //	CAF
      //if oRs != nil .and. ! oRs:Eof() .and. ValType( uVal := oField:Value ) == 'T' .and. ;
      //      FW_TIMEPART( uVal ) >= 1.0
         cType := 'T'
      endif
      if ( oRs == nil .or. oRs:Eof() ) .and. nType == adDBTimeStamp
         cType := 'T'
      endif
   elseif AScan( { adTinyInt, adSmallInt, adInteger, adBigInt, ;
                  adUnsignedTinyInt, adUnsignedSmallInt, adUnsignedInt, ;
                  adUnsignedBigInt }, nType ) > 0
      cType    := 'N'
      nLen     := oField:Precision + 1  // added 1 for - symbol
      if oField:Properties( "ISAUTOINCREMENT" ):Value == .t.
         cType := '+'
         lRW   := .f.
      endif
   elseif AScan( { adSingle, adDouble }, nType ) > 0
      cType    := 'N'
      if oField:Precision == 0 .or. oField:Precision > 255
         nLen  := 19
      else
         nLen     := Min( 19, oField:Precision + 2 )
      endif
      if oField:NumericScale == 0
         nDec     := Set( _SET_DECIMALS )
      else
         nDec     := Min( nLen - 2, oField:NumericScale )
      endif
   elseif nType == adCurrency
      cType    := 'N'      // 'Y'
      nLen     := 19
      nDec     := 2
   elseif AScan( { adDecimal, adNumeric, adVarNumeric }, nType ) > 0
      cType    := 'N'
      nLen     := Min( 19, oField:Precision + 2 )
      if oField:NumericScale > 0 .and. oField:NumericScale < nLen
         nDec  := oField:NumericScale
      endif
   elseif AScan( { adBSTR, adChar, adVarChar, adLongVarChar, adWChar, adVarWChar, adLongVarWChar }, nType ) > 0
      nLen     := oField:DefinedSize
      if nType != adChar .and. nType != adWChar .and. ( nLen <= 0 .or. nLen > nFWAdoMemoSizeThreshold )
         cType := 'M'
         nLen  := 10
      endif
   elseif AScan( { adBinary, adVarBinary, adLongVarBinary }, nType ) > 0
      nLen     := oField:DefinedSize
      if nType != adBinary .and. nLen > nFWAdoMemoSizeThreshold
         cType := 'm'
         nLen  := 10
      endif
   elseif AScan( { adChapter, adPropVariant }, nType ) > 0
      cType    := 'O'
      lRW      := .f.
   elseif nType == adGUID
      cType    := 'C'
      nLen     := 36
      lRW      := .f.
   else
      lRW      := .f.
   endif
   
   //	CAF
   //if lAnd( oField:Attributes, 0x72100 ) .or. ! lAnd( oField:Attributes, 8 )
   //   lRW      := .f.
   //endif

return { oField:Name, cType, nLen, nDec, nType, lRW }


