<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
				xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
				xmlns:ho="http://www.kith.no/xmlstds/HelseOpplysningerArbeidsuforhet/2013-10-01"
				xmlns:fk1="http://www.kith.no/xmlstds/felleskomponent1"
				xmlns:kith="http://www.kith.no/xmlstds"
				xmlns:msxsl="urn:schemas-microsoft-com:xslt"
				xmlns:exslt="http://exslt.org/common"
				xmlns:ldtxt="http://nav.no/dokument/ekstern/sykmelding/dynamiskregelsett/SM2013Ledetekst/v1"
				exclude-result-prefixes="xsl soap ho fk1 kith msxsl exslt">
	
	<xsl:output method="html" indent="yes" omit-xml-declaration="yes" encoding="UTF-8" doctype-system="about:legacy-compat" />

	<!-- Load inn alle ledetekstene fra egen fil -->
	<xsl:variable name="ledetekster" select="document('SM2013Ledetekst_v1_3.xml')/*" />
	<xsl:variable name="default_option_text_true" select="'Ja'" />
	<xsl:variable name="default_option_text_false" select="'Nei'" />
	<xsl:variable name="default_option_text_empty" select="' '" />

	<!-- Check digit reference for Code39 standard -->
	<xsl:variable name="code39_check_digits" select="'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%'" />

	<!-- -->
	<xsl:variable name="printout_parameter" select="//Utskriftsparameter" />
	<xsl:variable name="section_nav_copy" select="'A'" />
	<xsl:variable name="section_patient_copy" select="'B'" />
	<xsl:variable name="section_employer_copy" select="'C'" />
	<xsl:variable name="section_claim_document" select="'D'" />
	<xsl:variable name="section_documentation" select="'V'" />
	<xsl:variable name="sections_to_be_printed">
		<!-- 
			1 = Kun del A  - for NAV
			2 = Del B,C,D + veiledningstekst (V) - Normalt for EPJ
			3 = Del B,C,D (uten veiledning)
			4 = ABCDV - alle deler
		-->
		<xsl:choose>
			<xsl:when test="$printout_parameter = 1">
				<xsl:value-of select="$section_nav_copy" />
			</xsl:when>
			<xsl:when test="$printout_parameter = 2">
				<xsl:value-of select="concat($section_patient_copy, $section_employer_copy, $section_claim_document, $section_documentation)" />
			</xsl:when>
			<xsl:when test="$printout_parameter = 3">
				<xsl:value-of select="concat($section_patient_copy, $section_employer_copy, $section_claim_document)" />
			</xsl:when>
			<xsl:when test="$printout_parameter = 4">
				<xsl:value-of select="concat($section_nav_copy, $section_patient_copy, $section_employer_copy, $section_claim_document, $section_documentation)" />
			</xsl:when>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="ingen_arbeidsgiver" select="string(//Content/ho:HelseOpplysningerArbeidsuforhet/ho:Arbeidsgiver/ho:HarArbeidsgiver/@DN)" />
	<xsl:template match="/">
		<html>
			<head>
				<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
				<xsl:element name="meta">
					<xsl:attribute name="charset">UTF-8</xsl:attribute>
				</xsl:element>
				<xsl:element name="link">
					<xsl:attribute name="rel">stylesheet</xsl:attribute>
					<xsl:attribute name="href">blankett-hybrid.css</xsl:attribute>
					<xsl:attribute name="type">text/css</xsl:attribute>
				</xsl:element>
			</head>
			<body>
				<xsl:if test="contains($sections_to_be_printed, $section_nav_copy)">
					<xsl:apply-templates select="//Content">
						<xsl:with-param name="section" select="$section_nav_copy" />
					</xsl:apply-templates>
				</xsl:if>
				<xsl:if test="contains($sections_to_be_printed, $section_patient_copy)">
					<xsl:apply-templates select="//Content">
						<xsl:with-param name="section" select="$section_patient_copy" />
					</xsl:apply-templates>
				</xsl:if>
				<xsl:if test="contains($sections_to_be_printed, $section_employer_copy) and $ingen_arbeidsgiver != 'Ingen arbeidsgiver' ">
					<xsl:apply-templates select="//Content">
						<xsl:with-param name="section" select="$section_employer_copy" />
					</xsl:apply-templates>
				</xsl:if>
				<xsl:if test="contains($sections_to_be_printed, $section_claim_document)">
					<xsl:apply-templates select="//Content">
						<xsl:with-param name="section" select="$section_claim_document" />
					</xsl:apply-templates>
		    		<xsl:call-template name="veiledning_egenerklaering" />
				</xsl:if>
				<xsl:if test="contains($sections_to_be_printed, $section_documentation)">
            		<xsl:call-template name="veiledning" />
				</xsl:if>				
			</body>
		</html>
	</xsl:template>

	<xsl:template match="Content">
		<xsl:param name="section" />
		<xsl:variable name="skjermes_for_pasient" select="string(ho:HelseOpplysningerArbeidsuforhet/ho:MedisinskVurdering/ho:SkjermesForPasient)" />
		<section>
            <header>
            	<xsl:apply-templates select="." mode="section_header">
            		<xsl:with-param name="section" select="$section" />
            	</xsl:apply-templates>
            </header>
            <table class="section">
                <thead>
                	<xsl:apply-templates select="." mode="section_table_header" />
                </thead>
                <tbody>
                    <tr>
                        <td>
                        	<xsl:if test="$section = $section_employer_copy">
                        		<xsl:apply-templates select="ho:HelseOpplysningerArbeidsuforhet" mode="employer_summary" />
                        	</xsl:if>
                        	<xsl:apply-templates select="ho:HelseOpplysningerArbeidsuforhet/ho:SyketilfelleStartDato" />
                        	<xsl:apply-templates select="ho:HelseOpplysningerArbeidsuforhet/ho:Pasient" />
                        	<xsl:apply-templates select="ho:HelseOpplysningerArbeidsuforhet/ho:Arbeidsgiver" />
                        	<xsl:if test="$section = $section_nav_copy or ($section = $section_patient_copy and $skjermes_for_pasient != 'true')">
	                        	<xsl:apply-templates select="ho:HelseOpplysningerArbeidsuforhet/ho:MedisinskVurdering">
	                        		<xsl:with-param name="section" select="$section" />
	                        	</xsl:apply-templates>
	                        </xsl:if>
                        	<xsl:apply-templates select="ho:HelseOpplysningerArbeidsuforhet/ho:Aktivitet">
                    			<xsl:with-param name="section" select="$section" />
                    			<xsl:with-param name="skjermes_for_pasient" select="$skjermes_for_pasient" />
                        	</xsl:apply-templates>
                        	<xsl:apply-templates select="ho:HelseOpplysningerArbeidsuforhet/ho:Prognose">
                        		<xsl:with-param name="section" select="$section" />
                        		<xsl:with-param name="skjermes_for_pasient" select="$skjermes_for_pasient" />
                        	</xsl:apply-templates>
                        	<xsl:if test="$section = $section_nav_copy or ($section = $section_patient_copy and $skjermes_for_pasient != 'true')">  
                        		<xsl:apply-templates select="ho:HelseOpplysningerArbeidsuforhet/ho:UtdypendeOpplysninger" />
                        	</xsl:if>
                        	<!--xsl:if test="$section != $section_claim_document">
                        		<xsl:apply-templates select="ho:HelseOpplysningerArbeidsuforhet/ho:Tiltak">
                        			<xsl:with-param name="section" select="$section" />
                        			<xsl:with-param name="skjermes_for_pasient" select="$skjermes_for_pasient" />
                        		</xsl:apply-templates>
                        	</xsl:if-->
                        	<xsl:if test="$section = $section_nav_copy or ($section = $section_patient_copy and $skjermes_for_pasient != 'true')">
                        		<xsl:apply-templates select="ho:HelseOpplysningerArbeidsuforhet/ho:MeldingTilNav" />
                        	</xsl:if>
                        	<xsl:if test="$section != $section_claim_document">
                        		<xsl:apply-templates select="ho:HelseOpplysningerArbeidsuforhet/ho:MeldingTilArbeidsgiver" />
	                        	<!--xsl:apply-templates select="ho:HelseOpplysningerArbeidsuforhet/ho:Oppfolgingsplan" /-->
                        	</xsl:if>
                        	<xsl:if test="$section = $section_nav_copy or $section = $section_employer_copy or ($section = $section_patient_copy and $skjermes_for_pasient != 'true')">
                        		<xsl:apply-templates select="ho:HelseOpplysningerArbeidsuforhet/ho:KontaktMedPasient" >
									<xsl:with-param name="section" select="$section" />
								</xsl:apply-templates>
                        	</xsl:if>
                        	<xsl:apply-templates select="ho:HelseOpplysningerArbeidsuforhet" mode="behandler_bekreftelse">
                        		<xsl:with-param name="section" select="$section" />
                        	</xsl:apply-templates>
				        	<xsl:if test="$section = $section_claim_document">
				        		<xsl:call-template name="egenerklaering" />
				        	</xsl:if>
				        	<xsl:if test="$section = $section_employer_copy">
				        		<xsl:call-template name="employer_orientation" />
				        	</xsl:if>
                        </td>
                    </tr>
                </tbody>
                <tfoot>
                	<tr>
                		<td class="barcode">
                			<xsl:call-template name="generate_strekkode_3">
                				<xsl:with-param name="section" select="$section" />
                			</xsl:call-template>
                		</td>
                	</tr>
                </tfoot>
            </table>
        </section>
    </xsl:template>

    <xsl:template match="ho:Pasient">
        <table>
            <thead>
                <tr>
                    <th>
                    	<xsl:call-template name="ledetekst_ref">
                			<xsl:with-param name="id" select="'PasientOpplysninger'" />
                		</xsl:call-template>
                    </th>
                    <th colspan="2">
                    	<xsl:call-template name="ledetekst_tekst">
                			<xsl:with-param name="id" select="'PasientOpplysninger'" />
                		</xsl:call-template>
                    </th>
                </tr>
            </thead>
            <tbody>
            	<tr>
            		<th>
						<xsl:call-template name="ledetekst_ref">
							<xsl:with-param name="id" select="'PasientNavn'" />
						</xsl:call-template>
            		</th>
            		<th>
						<xsl:call-template name="ledetekst_tekst">
							<xsl:with-param name="id" select="'PasientNavn'" />
						</xsl:call-template>
            		</th>
            		<td>
        				<xsl:apply-templates select="ho:Navn" mode="patient"/>
            		</td>
            	</tr>

            	<!--xsl:call-template name="write_standard_table_row">
            		<xsl:with-param name="ledetekst_id" select="'PasientTelefon'" />
            		<xsl:with-param name="value">
            			<xsl:for-each select="ho:KontaktInfo/fk1:TeleAddress">
            				<xsl:if test="position() > 1">
            					<xsl:value-of select="', '" />
            				</xsl:if>
            				<xsl:value-of select="substring-after(./@V, 'tel:')" />
            			</xsl:for-each>
            		</xsl:with-param>
					<xsl:with-param name="remove_space" select="'true'" />
            	</xsl:call-template>
            	<xsl:call-template name="write_standard_table_row">
            		<xsl:with-param name="ledetekst_id" select="'NavnFastlege'" />
            		<xsl:with-param name="value" select="ho:NavnFastlege" />
					<xsl:with-param name="remove_space" select="'true'" />
            	</xsl:call-template>
            	<xsl:call-template name="write_standard_table_row">
            		<xsl:with-param name="ledetekst_id" select="'NAVKontor'" />
            		<xsl:with-param name="value" select="ho:NAVKontor" />
					<xsl:with-param name="remove_space" select="'true'" />
            	</xsl:call-template!-->
            </tbody>
        </table>
    </xsl:template>

    <xsl:template match="ho:Arbeidsgiver">
        <table>
            <thead>
                <tr>
                    <th>
                    	<xsl:call-template name="ledetekst_ref">
                			<xsl:with-param name="id" select="'Arbeidsgiver'" />
                		</xsl:call-template>
                    </th>
                    <th colspan="2">
                    	<xsl:call-template name="ledetekst_tekst">
                			<xsl:with-param name="id" select="'Arbeidsgiver'" />
                		</xsl:call-template>
                    </th>
                </tr>
            </thead>
            <tbody>
            	<xsl:call-template name="write_standard_table_row">
            		<xsl:with-param name="ledetekst_id" select="'HarArbeidsgiver'" />
            		<xsl:with-param name="value" select="ho:HarArbeidsgiver/@DN" />
					<xsl:with-param name="remove_space" select="'true'" />
            	</xsl:call-template>
            	<xsl:call-template name="write_standard_table_row">
            		<xsl:with-param name="ledetekst_id" select="'NavnArbeidsgiver'" />
            		<xsl:with-param name="value" select="ho:NavnArbeidsgiver" />
					<xsl:with-param name="remove_space" select="'true'" />
            	</xsl:call-template>
            	<xsl:call-template name="write_standard_table_row">
            		<xsl:with-param name="ledetekst_id" select="'Yrkesbetegnelse'" />
            		<xsl:with-param name="value" select="ho:Yrkesbetegnelse" />
					<xsl:with-param name="remove_space" select="'true'" />
            	</xsl:call-template>
            	<xsl:call-template name="write_standard_table_row">
            		<xsl:with-param name="ledetekst_id" select="'Stillingsprosent'" />
            		<xsl:with-param name="value" select="ho:Stillingsprosent" />
					<xsl:with-param name="remove_space" select="'true'" />
            	</xsl:call-template>
            </tbody>
        </table>		
    </xsl:template>

    <xsl:template match="ho:MedisinskVurdering">
    	<xsl:param name="section" />
        <table>
            <thead>
                <tr>
                    <th>
                    	<xsl:call-template name="ledetekst_ref">
                			<xsl:with-param name="id" select="'MedisinskVurdering'" />
                		</xsl:call-template>
                    </th>
                    <th colspan="4">
                    	<xsl:call-template name="ledetekst_tekst">
                			<xsl:with-param name="id" select="'MedisinskVurdering'" />
                		</xsl:call-template>
                    </th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <th>
                    	<xsl:call-template name="ledetekst_ref">
                			<xsl:with-param name="id" select="'HovedDiagnose'" />
                		</xsl:call-template>
                    </th>
                    <th>
                    	<xsl:call-template name="ledetekst_tekst">
                			<xsl:with-param name="id" select="'HovedDiagnose'" />
                		</xsl:call-template>
                    </th>
                    <th>
                    	<xsl:call-template name="ledetekst_concatenated">
                    		<xsl:with-param name="id" select="'HovedDiagnosesystemS'" />
                		</xsl:call-template>
                    </th>
                    <th>
                    	<xsl:call-template name="ledetekst_concatenated">
                    		<xsl:with-param name="id" select="'HovedDiagnosekodeV'" />
                		</xsl:call-template>
                    </th>
                    <th>
                    	<xsl:call-template name="ledetekst_concatenated">
                    		<xsl:with-param name="id" select="'HovedDiagnoseTekst'" />
                		</xsl:call-template>
                    </th>
                </tr>
                <xsl:call-template name="print_diagnose_table_row">
                	<xsl:with-param name="diagnose_node" select="ho:HovedDiagnose/ho:Diagnosekode" />
                </xsl:call-template>
                <xsl:if test="ho:BiDiagnoser">
	                <tr>
	                    <th>
	                    	<xsl:call-template name="ledetekst_ref">
	                			<xsl:with-param name="id" select="'Bidiagnoser'" />
	                		</xsl:call-template>
	                    </th>
	                    <th>
	                    	<xsl:call-template name="ledetekst_tekst">
	                			<xsl:with-param name="id" select="'Bidiagnoser'" />
	                		</xsl:call-template>
	                    </th>
	                    <th>
	                    	<xsl:call-template name="ledetekst_concatenated">
	                    		<xsl:with-param name="id" select="'BiDiagnosesystemS'" />
	                		</xsl:call-template>
	                    </th>
	                    <th>
	                    	<xsl:call-template name="ledetekst_concatenated">
	                    		<xsl:with-param name="id" select="'BiDiagnosekodeV'" />
	                		</xsl:call-template>
	                    </th>
	                    <th>
	                    	<xsl:call-template name="ledetekst_concatenated">
	                    		<xsl:with-param name="id" select="'BiDiagnoseTekst'" />
	                		</xsl:call-template>
	                    </th>
	                </tr>
	                <xsl:for-each select="ho:BiDiagnoser/ho:Diagnosekode">
	                	<xsl:call-template name="print_diagnose_table_row">
	                		<xsl:with-param name="diagnose_node" select="." />
	                	</xsl:call-template>
	                </xsl:for-each>
                </xsl:if>
                <xsl:if test="ho:AnnenFraversArsak">
	                <tr>
	                    <th>
	                    	<xsl:call-template name="ledetekst_ref">
	                			<xsl:with-param name="id" select="'AnnenFraversArsak'" />
	                		</xsl:call-template>
	                    </th>
	                    <th colspan="4">
	                    	<xsl:call-template name="ledetekst_tekst">
	                			<xsl:with-param name="id" select="'AnnenFraversArsak'" />
	                		</xsl:call-template>
	                    </th>
	                </tr>
	            	<xsl:call-template name="write_standard_table_row">
	            		<xsl:with-param name="ledetekst_id" select="'AnnenFraverArsakskode'" />
	            		<xsl:with-param name="value" select="ho:AnnenFraversArsak/ho:Arsakskode/@DN" />
	            		<xsl:with-param name="colspan_third_col" select="3" />
						<xsl:with-param name="remove_space" select="'true'" />
	            	</xsl:call-template>
	            	<xsl:call-template name="write_standard_table_row">
	            		<xsl:with-param name="ledetekst_id" select="'AnnenFraverArsakBeskriv'" />
	            		<xsl:with-param name="value" select="ho:AnnenFraversArsak/ho:Beskriv" />
	            		<xsl:with-param name="colspan_third_col" select="3" />
						<xsl:with-param name="remove_space" select="'true'" />
	            	</xsl:call-template>                	
                </xsl:if>
                <xsl:if test="ho:Svangerskap = 'true'">
                	<xsl:call-template name="write_standard_table_row">
                		<xsl:with-param name="ledetekst_id" select="'Svangerskap'" />
                		<xsl:with-param name="value" select="$default_option_text_true" />
                		<xsl:with-param name="colspan_third_col" select="3" />
						<xsl:with-param name="remove_space" select="'true'" />
                	</xsl:call-template>
                </xsl:if>
                <xsl:if test="ho:Yrkesskade = 'true'">
                	<xsl:call-template name="write_standard_table_row">
                		<xsl:with-param name="ledetekst_id" select="'Yrkesskade'" />
                		<xsl:with-param name="value" select="$default_option_text_true" />
                		<xsl:with-param name="colspan_third_col" select="3" />            			
						<xsl:with-param name="remove_space" select="'true'" />
                	</xsl:call-template>
                	<xsl:call-template name="write_standard_table_row">
                		<xsl:with-param name="ledetekst_id" select="'YrkesskadeDato'" />
                		<xsl:with-param name="value">
                			<xsl:call-template name="formater_dato">
                				<xsl:with-param name="dato" select="ho:YrkesskadeDato" />
                			</xsl:call-template>
                		</xsl:with-param>
                		<xsl:with-param name="colspan_third_col" select="3" />            			
						<xsl:with-param name="remove_space" select="'true'" />
                	</xsl:call-template>
                </xsl:if>
            </tbody>
    	</table>   
    </xsl:template>

    <xsl:template match ="ho:Aktivitet">
		<xsl:param name="section" />
		<xsl:param name="skjermes_for_pasient" />
	    <table>
	        <thead>
	            <tr>
	                <th>
	                	<xsl:call-template name="ledetekst_ref">
	                		<xsl:with-param name="id" select="'Aktivitet'" />
	                	</xsl:call-template>
	                </th>
	                <th colspan="3">
	                	<xsl:call-template name="ledetekst_tekst">
	                		<xsl:with-param name="id" select="'Aktivitet'" />
	                	</xsl:call-template>
	                </th>
	            </tr>
	        </thead>
	        <tbody>
	        	<xsl:apply-templates select="ho:Periode">
	        		<xsl:sort select="ho:PeriodeFOMDato" />
	        		<xsl:with-param name="section" select="$section" />
	        		<xsl:with-param name="skjermes_for_pasient" select="$skjermes_for_pasient" />
	        	</xsl:apply-templates>
			</tbody>
		</table>
	</xsl:template>

	<xsl:template match="ho:Periode">
		<xsl:param name="section" />
		<xsl:param name="skjermes_for_pasient" />
		<xsl:choose>
			<xsl:when test="ho:AvventendeSykmelding">
		        <tr>
		            <th>
		            	<xsl:call-template name="ledetekst_ref">
		            		<xsl:with-param name="id" select="'AvventendeSykmelding'" />
		            	</xsl:call-template>
		            </th>
		            <th>
		            	<xsl:call-template name="ledetekst_tekst">
		            		<xsl:with-param name="id" select="'AvventendeSykmelding'" />
		            	</xsl:call-template>
		            </th>
		            <th>
		            	<xsl:call-template name="ledetekst_concatenated">
		            		<xsl:with-param name="id" select="'AvventendePeriodeFOMDato'" />
		            	</xsl:call-template>
		            </th>
		            <th>
		            	<xsl:call-template name="ledetekst_concatenated">
		            		<xsl:with-param name="id" select="'AvventendePeriodeTOMDato'" />
		            	</xsl:call-template>
					</th>
		        </tr>
		        <xsl:apply-templates select="." mode="date_row" />
		        <xsl:call-template name="write_standard_table_row">
		        	<xsl:with-param name="ledetekst_id" select="'AvventendeSykmeldingInnspillTilArbeidsgiver'" />
		        	<xsl:with-param name="value" select="ho:AvventendeSykmelding/ho:InnspillTilArbeidsgiver" />
		        	<xsl:with-param name="colspan_third_col" select="2" />
					<xsl:with-param name="remove_space" select="'true'" />
		        </xsl:call-template>
			</xsl:when>
			<xsl:when test="ho:GradertSykmelding">
		        <tr>
		            <th>
		            	<xsl:call-template name="ledetekst_ref">
		            		<xsl:with-param name="id" select="'GradertSykmelding'" />
		            	</xsl:call-template>
		            </th>
		            <th>
		            	<xsl:call-template name="ledetekst_tekst">
		            		<xsl:with-param name="id" select="'GradertSykmelding'" />
		            	</xsl:call-template>
		            </th>
		            <th>
		            	<xsl:call-template name="ledetekst_concatenated">
		            		<xsl:with-param name="id" select="'GradertPeriodeFOMDato'" />
		            	</xsl:call-template>
		            </th>
		            <th>
		            	<xsl:call-template name="ledetekst_concatenated">
		            		<xsl:with-param name="id" select="'GradertPeriodeTOMDato'" />
		            	</xsl:call-template>
					</th>
		        </tr>
		        <xsl:apply-templates select="." mode="date_row" />
		        <xsl:call-template name="write_standard_table_row">
		        	<xsl:with-param name="ledetekst_id" select="'Sykmeldingsgrad'" />
		        	<xsl:with-param name="value" select="ho:GradertSykmelding/ho:Sykmeldingsgrad" />
		        	<xsl:with-param name="colspan_third_col" select="2" />
					<xsl:with-param name="remove_space" select="'true'" />
		        </xsl:call-template>
		        <xsl:if test="ho:GradertSykmelding/ho:Reisetilskudd = 'true'">
			        <xsl:call-template name="write_standard_table_row">
			        	<xsl:with-param name="ledetekst_id" select="'GradertSykmeldingReisetilskudd'" />
			        	<xsl:with-param name="value" select="$default_option_text_true" />
			        	<xsl:with-param name="colspan_third_col" select="2" />
						<xsl:with-param name="remove_space" select="'true'" />
			        </xsl:call-template>
		        </xsl:if>
			</xsl:when>
			<xsl:when test="ho:AktivitetIkkeMulig">
		        <tr>
		            <th>
		            	<xsl:call-template name="ledetekst_ref">
		            		<xsl:with-param name="id" select="'AktivitetIkkeMulig'" />
		            	</xsl:call-template>
		            </th>
		            <th>
		            	<xsl:call-template name="ledetekst_tekst">
		            		<xsl:with-param name="id" select="'AktivitetIkkeMulig'" />
		            	</xsl:call-template>
		            </th>
		            <th>
		            	<xsl:call-template name="ledetekst_concatenated">
		            		<xsl:with-param name="id" select="'IkkeMuligPeriodeFOMDato'" />
		            	</xsl:call-template>
		            </th>
		            <th>
		            	<xsl:call-template name="ledetekst_concatenated">
		            		<xsl:with-param name="id" select="'IkkeMuligPeriodeTOMDato'" />
		            	</xsl:call-template>
					</th>
		        </tr>

		        <xsl:apply-templates select="." mode="date_row" />
		         <xsl:if test="$section = $section_nav_copy or ($section = $section_patient_copy and $skjermes_for_pasient != 'true')">
                    <xsl:apply-templates select="ho:AktivitetIkkeMulig/ho:MedisinskeArsaker" />
                    <xsl:apply-templates select="ho:AktivitetIkkeMulig/ho:Arbeidsplassen" />
		        </xsl:if>
		       
			</xsl:when>
			<xsl:when test="ho:Behandlingsdager">
		        <tr>
		            <th>
		            	<xsl:call-template name="ledetekst_ref">
		            		<xsl:with-param name="id" select="'Behandlingsdager'" />
		            	</xsl:call-template>
		            </th>
		            <th>
		            	<xsl:call-template name="ledetekst_tekst">
		            		<xsl:with-param name="id" select="'Behandlingsdager'" />
		            	</xsl:call-template>
		            </th>
		            <th>
		            	<xsl:call-template name="ledetekst_concatenated">
		            		<xsl:with-param name="id" select="'BehandlingPeriodeFOMDato'" />
		            	</xsl:call-template>
		            </th>
		            <th>
		            	<xsl:call-template name="ledetekst_concatenated">
		            		<xsl:with-param name="id" select="'BehandlingPeriodeTOMDato'" />
		            	</xsl:call-template>
					</th>
		        </tr>
		        <xsl:apply-templates select="." mode="date_row" />
		        <xsl:call-template name="write_standard_table_row">
		        	<xsl:with-param name="ledetekst_id" select="'AntallBehandlingsdagerUke'" />
		        	<xsl:with-param name="value" select="ho:Behandlingsdager/ho:AntallBehandlingsdagerUke" />
		        	<xsl:with-param name="colspan_third_col" select="2" />
					<xsl:with-param name="remove_space" select="'true'" />
		        </xsl:call-template>
			</xsl:when>
			<xsl:when test="ho:Reisetilskudd">
		        <tr>
		            <th>
		            	<xsl:call-template name="ledetekst_ref">
		            		<xsl:with-param name="id" select="'Reisetilskudd'" />
		            	</xsl:call-template>
		            </th>
		            <th>
		            	<xsl:call-template name="ledetekst_tekst">
		            		<xsl:with-param name="id" select="'Reisetilskudd'" />
		            	</xsl:call-template>
		            </th>
		            <th>
		            	<xsl:call-template name="ledetekst_concatenated">
		            		<xsl:with-param name="id" select="'IkkeMuligPeriodeFOMDato'" />
		            	</xsl:call-template>
		            </th>
		            <th>
		            	<xsl:call-template name="ledetekst_concatenated">
		            		<xsl:with-param name="id" select="'IkkeMuligPeriodeTOMDato'" />
		            	</xsl:call-template>
					</th>
		        </tr>
		        <xsl:apply-templates select="." mode="date_row" />			
			</xsl:when>

			<xsl:otherwise>
		        <tr>
		            <th>
		            	<xsl:call-template name="ledetekst_ref">
		            		<xsl:with-param name="id" select="'AktivitetIkkeMulig'" />
		            	</xsl:call-template>
		            </th>
		            <th>
		            	<xsl:call-template name="ledetekst_tekst">
		            		<xsl:with-param name="id" select="'AktivitetIkkeMulig'" />
		            	</xsl:call-template>
		            </th>
		            <th>
		            	<xsl:call-template name="ledetekst_concatenated">
		            		<xsl:with-param name="id" select="'IkkeMuligPeriodeFOMDato'" />
		            	</xsl:call-template>
		            </th>
		            <th>
		            	<xsl:call-template name="ledetekst_concatenated">
		            		<xsl:with-param name="id" select="'IkkeMuligPeriodeTOMDato'" />
		            	</xsl:call-template>
					</th>
		        </tr>
		        <xsl:apply-templates select="." mode="date_row" />			
			</xsl:otherwise>
		</xsl:choose>
    </xsl:template>

	<xsl:template match="ho:Periode" mode="employer_summary">
		<xsl:choose>
			<xsl:when test="ho:AvventendeSykmelding">
		        <tr>
		            <th>
		            	<xsl:call-template name="ledetekst_tekst">
		            		<xsl:with-param name="id" select="'AvventendeSykmelding'" />
		            	</xsl:call-template>
		            </th>
		            <xsl:apply-templates select="." mode="employer_summary_period"/>
		        </tr>
			</xsl:when>
			<xsl:when test="ho:GradertSykmelding">
		        <tr>
		            <th>
		            	<xsl:call-template name="ledetekst_tekst">
		            		<xsl:with-param name="id" select="'GradertSykmelding'" />
		            	</xsl:call-template>
		            </th>
		            <xsl:apply-templates select="." mode="employer_summary_period"/>
		        </tr>
			</xsl:when>
			<xsl:when test="ho:AktivitetIkkeMulig">
		        <tr>
		            <th>
		            	<xsl:call-template name="ledetekst_tekst">
		            		<xsl:with-param name="id" select="'AktivitetIkkeMulig'" />
		            	</xsl:call-template>
		            </th>
		            <xsl:apply-templates select="." mode="employer_summary_period"/>
		        </tr>
			</xsl:when>
			<xsl:when test="ho:Behandlingsdager">
		        <tr>
		            <th>
		            	<xsl:call-template name="ledetekst_tekst">
		            		<xsl:with-param name="id" select="'Behandlingsdager'" />
		            	</xsl:call-template>
		            </th>
		            <xsl:apply-templates select="." mode="employer_summary_period"/>
		        </tr>
			</xsl:when>
			<xsl:when test="ho:Reisetilskudd">
		        <tr>
		            <th>
		            	<xsl:call-template name="ledetekst_tekst">
		            		<xsl:with-param name="id" select="'Reisetilskudd'" />
		            	</xsl:call-template>
		            </th>
		            <xsl:apply-templates select="." mode="employer_summary_period"/>
		        </tr>
			</xsl:when>
			<xsl:otherwise>
		        <tr>
		            <th>
		            	<xsl:call-template name="ledetekst_tekst">
		            		<xsl:with-param name="id" select="'AktivitetIkkeMulig'" />
		            	</xsl:call-template>
		            </th>
		            <xsl:apply-templates select="." mode="employer_summary_period"/>
		        </tr>
			</xsl:otherwise>
		</xsl:choose>
    </xsl:template>

    <xsl:template match="ho:Periode" mode="employer_summary_period">
    	<td>
    		<xsl:call-template name="formater_dato">
    			<xsl:with-param name="dato" select="ho:PeriodeFOMDato" />
    		</xsl:call-template>
    		<xsl:value-of select="' - '" />
    		<xsl:call-template name="formater_dato">
    			<xsl:with-param name="dato" select="ho:PeriodeTOMDato" />
    		</xsl:call-template>    		
    	</td>
    </xsl:template>

    <xsl:template match="ho:Periode" mode="date_row">
        <tr>
            <td colspan="2"></td>
            <td>
            	<xsl:call-template name="formater_dato">
            		<xsl:with-param name="dato" select="ho:PeriodeFOMDato" />
            	</xsl:call-template>
            </td>
            <td>
            	<xsl:call-template name="formater_dato">
            		<xsl:with-param name="dato" select="ho:PeriodeTOMDato" />
            	</xsl:call-template>
            </td>
        </tr>
    </xsl:template>

    <xsl:template match="ho:MedisinskeArsaker">
    	                <tr>
	                    <th>
	                    	<xsl:call-template name="ledetekst_ref">
	                			<xsl:with-param name="id" select="'AktivitetIkkeMuligMedisinskeArsaker'" />
	                		</xsl:call-template>
	                    </th>
	                    <th colspan="4">
	                    	<xsl:call-template name="ledetekst_tekst">
	                			<xsl:with-param name="id" select="'AktivitetIkkeMuligMedisinskeArsaker'" />
	                		</xsl:call-template>
	                    </th>
	                </tr>
        <xsl:call-template name="write_standard_table_row">
            <xsl:with-param name="ledetekst_id" select="'AktivitetIkkeMuligMedisinskeArsaker'" />
            <xsl:with-param name="value" select="''" />
            <xsl:with-param name="colspan_third_col" select="2" />
			<xsl:with-param name="remove_space" select="'true'" />
        </xsl:call-template>
        <xsl:call-template name="write_standard_table_row">
            <xsl:with-param name="ledetekst_id" select="'AktivitetIkkeMuligMedisinskeArsakerArsakskode'" />
            <xsl:with-param name="value" select="ho:Arsakskode/@DN" />
            <xsl:with-param name="colspan_third_col" select="2" />
			<xsl:with-param name="remove_space" select="'true'" />
        </xsl:call-template>
        <xsl:call-template name="write_standard_table_row">
            <xsl:with-param name="ledetekst_id" select="'AktivitetIkkeMuligMedisinskeArsakerBeskriv'" />
            <xsl:with-param name="value" select="ho:Beskriv" />
            <xsl:with-param name="colspan_third_col" select="2" />
			<xsl:with-param name="remove_space" select="'true'" />
        </xsl:call-template>                    
    </xsl:template>
    
     <xsl:template match="ho:Arbeidsplassen">
    	                <tr>
	                    <th>
	                    	<xsl:call-template name="ledetekst_ref">
	                			<xsl:with-param name="id" select="'AktivitetIkkeMuligArbeidsplassen'" />
	                		</xsl:call-template>
	                    </th>
	                    <th colspan="4">
	                    	<xsl:call-template name="ledetekst_tekst">
	                			<xsl:with-param name="id" select="'AktivitetIkkeMuligArbeidsplassen'" />
	                		</xsl:call-template>
	                    </th>
	                </tr>
        <xsl:call-template name="write_standard_table_row">
            <xsl:with-param name="ledetekst_id" select="'AktivitetIkkeMuligArbeidsplassen'" />
            <xsl:with-param name="value" select="''" />
            <xsl:with-param name="colspan_third_col" select="2" />
			<xsl:with-param name="remove_space" select="'true'" />
        </xsl:call-template>
        <xsl:call-template name="write_standard_table_row">
            <xsl:with-param name="ledetekst_id" select="'AktivitetIkkeMuligArbeidplassenArsakskode'" />
            <xsl:with-param name="value" select="ho:Arsakskode/@DN" />
            <xsl:with-param name="colspan_third_col" select="2" />
			<xsl:with-param name="remove_space" select="'true'" />
        </xsl:call-template>
        <xsl:call-template name="write_standard_table_row">
            <xsl:with-param name="ledetekst_id" select="'AktivitetIkkeMuligArbeidsplassenBeskriv'" />
            <xsl:with-param name="value" select="ho:Beskriv" />
            <xsl:with-param name="colspan_third_col" select="2" />
			<xsl:with-param name="remove_space" select="'true'" />
        </xsl:call-template>                    
    </xsl:template>

    <xsl:template match="ho:Prognose">
    	<xsl:param name="section" />
    	<xsl:param name="skjermes_for_pasient" />
	    <table>
	        <thead>
	            <tr>
	                <th>
	                	<xsl:call-template name="ledetekst_ref">
	                		<xsl:with-param name="id" select="'Prognose'" />
	                	</xsl:call-template>
	                </th>
	                <th colspan="3">
	                	<xsl:call-template name="ledetekst_tekst">
	                		<xsl:with-param name="id" select="'Prognose'" />
	                	</xsl:call-template>
	                </th>
	            </tr>
	        </thead>
	        <tbody>
				<xsl:if test="ho:ArbeidsforEtterEndtPeriode = 'true'">
					<xsl:call-template name="write_standard_table_row">
						<xsl:with-param name="ledetekst_id" select="'ArbeidsforEtterEndtPeriode'" />
						<xsl:with-param name="value" select="$default_option_text_true" />
						<xsl:with-param name="remove_space" select="'true'" />
					</xsl:call-template>
				</xsl:if>
	        	<xsl:if test="ho:BeskrivHensynArbeidsplassen and ho:ArbeidsforEtterEndtPeriode = 'true' and $section != $section_claim_document">
	        		<xsl:call-template name="write_standard_table_row">
        				<xsl:with-param name="ledetekst_id" select="'BeskrivHensynArbeidsplassen'" />
        				<xsl:with-param name="value" select="ho:BeskrivHensynArbeidsplassen" />
						<xsl:with-param name="remove_space" select="'true'" />
	        		</xsl:call-template>
	        	</xsl:if>
	        	<!--xsl:if test="ho:ErIArbeid and ($section = $section_nav_copy or ($section = $section_patient_copy and $skjermes_for_pasient != 'true'))">
					<xsl:if test="ho:ErIArbeid/ho:VurderingDato != '' or ho:ErIArbeid/ho:EgetArbeidPaSikt = 'true'">
						<xsl:call-template name="write_standard_table_row">
							<xsl:with-param name="ledetekst_id" select="'EgetArbeidPaSikt'" />
							<xsl:with-param name="value">
								<xsl:choose>
									<xsl:when test="ho:ErIArbeid/ho:EgetArbeidPaSikt = 'true'">
										<xsl:value-of select="$default_option_text_true" />
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="$default_option_text_empty" />
									</xsl:otherwise>
								</xsl:choose>
							</xsl:with-param>
							<xsl:with-param name="remove_space" select="'false'" />
						</xsl:call-template>
					</xsl:if>
					<xsl:if test="ho:ErIArbeid/ho:ArbeidFraDato != '' and ho:ErIArbeid/ho:EgetArbeidPaSikt = 'true'">
						<xsl:call-template name="write_standard_table_row">
							<xsl:with-param name="ledetekst_id" select="'ArbeidFraDato'" />
							<xsl:with-param name="value">
								<xsl:call-template name="formater_dato">
									<xsl:with-param name="dato" select="ho:ErIArbeid/ho:ArbeidFraDato" />
								</xsl:call-template>
							</xsl:with-param>
							<xsl:with-param name="remove_space" select="'true'" />
						</xsl:call-template>
					</xsl:if>
					<xsl:if test="ho:ErIArbeid/ho:VurderingDato != '' or ho:ErIArbeid/ho:AnnetArbeidPaSikt = 'true'">
						<xsl:call-template name="write_standard_table_row">
							<xsl:with-param name="ledetekst_id" select="'AnnetArbeidPaSikt'" />
							<xsl:with-param name="value">
								<xsl:choose>
									<xsl:when test="ho:ErIArbeid/ho:AnnetArbeidPaSikt = 'true'">
										<xsl:value-of select="$default_option_text_true" />
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="$default_option_text_empty" />
									</xsl:otherwise>
								</xsl:choose>
							</xsl:with-param>
							<xsl:with-param name="remove_space" select="'false'" />
						</xsl:call-template>
					</xsl:if>
					<xsl:if test="ho:ErIArbeid/ho:VurderingDato != ''">
						<xsl:if test="$section = $section_nav_copy or ($section = $section_patient_copy and $skjermes_for_pasient != 'true')">
							<xsl:call-template name="write_standard_table_row">
								<xsl:with-param name="ledetekst_id" select="'ErIArbeidVurderingDato'" />
								<xsl:with-param name="value">
									<xsl:call-template name="formater_dato">
										<xsl:with-param name="dato" select="ho:ErIArbeid/ho:VurderingDato" />
									</xsl:call-template>
								</xsl:with-param>
								<xsl:with-param name="remove_space" select="'true'" />
							</xsl:call-template>
						</xsl:if>
					</xsl:if>
	        	</xsl:if>
                <xsl:if test="ho:ErIkkeIArbeid and ($section = $section_nav_copy or ($section = $section_patient_copy and $skjermes_for_pasient != 'true'))">
                    <xsl:if test="ho:ErIkkeIArbeid/ho:VurderingDato != '' or ho:ErIkkeIArbeid/ho:ArbeidsforPaSikt = 'true'">
						<xsl:call-template name="write_standard_table_row">
							<xsl:with-param name="ledetekst_id" select="'ArbeidsforPaSikt'" />
							<xsl:with-param name="value">
								<xsl:choose>
									<xsl:when test="ho:ErIkkeIArbeid/ho:ArbeidsforPaSikt = 'true'">
										<xsl:value-of select="$default_option_text_true" />
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="$default_option_text_empty" />
									</xsl:otherwise>
								</xsl:choose>
							</xsl:with-param>
							<xsl:with-param name="remove_space" select="'false'" />
						</xsl:call-template>
					</xsl:if>
					<xsl:if test="ho:ErIkkeIArbeid/ho:ArbeidsforFraDato != '' and ho:ErIkkeIArbeid/ho:ArbeidsforPaSikt = 'true'">
						<xsl:call-template name="write_standard_table_row">
							<xsl:with-param name="ledetekst_id" select="'ArbeidsforFraDato'" />
							<xsl:with-param name="value">
								<xsl:call-template name="formater_dato">
									<xsl:with-param name="dato" select="ho:ErIkkeIArbeid/ho:ArbeidsforFraDato" />
								</xsl:call-template>
							</xsl:with-param>
							<xsl:with-param name="remove_space" select="'true'" />
						</xsl:call-template>
					</xsl:if>
					<xsl:if test="ho:ErIkkeIArbeid/ho:VurderingDato != ''">
						<xsl:call-template name="write_standard_table_row">
							<xsl:with-param name="ledetekst_id" select="'ErIkkeIArbeidVurderingDato'" />
							<xsl:with-param name="value">
								<xsl:call-template name="formater_dato">
									<xsl:with-param name="dato" select="ho:ErIkkeIArbeid/ho:VurderingDato" />
								</xsl:call-template>
							</xsl:with-param>
							<xsl:with-param name="remove_space" select="'true'" />
						</xsl:call-template>
					</xsl:if>
                </xsl:if-->
	        </tbody>
        </table>    	
    </xsl:template>

    <xsl:template match="ho:UtdypendeOpplysninger">
	    <table>
	        <thead>
	            <tr>
	                <th>
	                	<xsl:call-template name="ledetekst_ref">
	                		<xsl:with-param name="id" select="'UtdypendeOpplysninger'" />
	                	</xsl:call-template>
	                </th>
	                <th colspan="2">
	                	<xsl:call-template name="ledetekst_tekst">
	                		<xsl:with-param name="id" select="'UtdypendeOpplysninger'" />
	                	</xsl:call-template>
	                </th>
	            </tr>
	        </thead>
	        <tbody>
	        	<xsl:apply-templates select="ho:SpmGruppe" />
	        </tbody>
        </table>    	
    </xsl:template>

    <xsl:template match="ho:SpmGruppe">
    	<tr>
    		<th>
    			<xsl:value-of select="ho:SpmGruppeId" />
    		</th>
    		<th colspan="2">
    			<xsl:value-of select="ho:SpmGruppeTekst" />
    		</th>
    	</tr>
    	<xsl:apply-templates select="ho:SpmSvar">
    		<xsl:sort select="ho:SpmId" />
    	</xsl:apply-templates>
    </xsl:template>

    <xsl:template match="ho:SpmSvar">
    	<tr>
    		<th>
    			<xsl:value-of select="ho:SpmId" />
    		</th>
    		<th>
    			<xsl:value-of select="ho:SpmTekst" />
    		</th>
    		<td>
    			<xsl:value-of select="ho:SvarTekst" />
    		</td>
    	</tr>
    </xsl:template>

    <!--xsl:template match="ho:Tiltak">
    	<xsl:param name="skjermes_for_pasient" />
    	<xsl:param name="section" />
	    <table>
	        <thead>
	            <tr>
	                <th>
	                	<xsl:call-template name="ledetekst_ref">
	                		<xsl:with-param name="id" select="'Tiltak'" />
	                	</xsl:call-template>
	                </th>
	                <th colspan="2">
	                	<xsl:call-template name="ledetekst_tekst">
	                		<xsl:with-param name="id" select="'Tiltak'" />
	                	</xsl:call-template>
	                </th>
	            </tr>
	        </thead>
	        <tbody>
	        	<xsl:if test="ho:TiltakArbeidsplassen">
	        		<xsl:call-template name="write_standard_table_row">
	        			<xsl:with-param name="ledetekst_id" select="'TiltakArbeidsplassen'" />
	        			<xsl:with-param name="value" select="ho:TiltakArbeidsplassen" />
						<xsl:with-param name="remove_space" select="'true'" />
	        		</xsl:call-template>
	        	</xsl:if>
	        	<xsl:if test="ho:TiltakNAV and ($section = $section_nav_copy or ($section = $section_patient_copy and $skjermes_for_pasient != 'true'))">
	        		<xsl:call-template name="write_standard_table_row">
	        			<xsl:with-param name="ledetekst_id" select="'TiltakNAV'" />
	        			<xsl:with-param name="value" select="ho:TiltakNAV" />
						<xsl:with-param name="remove_space" select="'true'" />
	        		</xsl:call-template>
	        	</xsl:if>
	        	<xsl:if test="ho:AndreTiltak and ($section = $section_nav_copy or ($section = $section_patient_copy and $skjermes_for_pasient != 'true'))">
	        		<xsl:call-template name="write_standard_table_row">
	        			<xsl:with-param name="ledetekst_id" select="'AndreTiltak'" />
	        			<xsl:with-param name="value" select="ho:AndreTiltak" />
						<xsl:with-param name="remove_space" select="'true'" />
	        		</xsl:call-template>
	        	</xsl:if>
	        </tbody>
        </table> 		
    </xsl:template-->

    <!--xsl:template match="ho:Oppfolgingsplan">
	    <table>
	        <thead>
	            <tr>
	                <th>
	                	<xsl:call-template name="ledetekst_ref">
	                		<xsl:with-param name="id" select="'Oppfolgingsplan'" />
	                	</xsl:call-template>
	                </th>
	                <th colspan="2">
	                	<xsl:call-template name="ledetekst_tekst">
	                		<xsl:with-param name="id" select="'Oppfolgingsplan'" />
	                	</xsl:call-template>
	                </th>
	            </tr>
	        </thead>
	        <tbody>
				<xsl:if test="ho:MottattOppfolgingsplan = 'true'">
					<xsl:call-template name="write_standard_table_row">
						<xsl:with-param name="ledetekst_id" select="'MottattOppfolgingsplan'" />
						<xsl:with-param name="value" select="$default_option_text_true" />
						<xsl:with-param name="remove_space" select="'true'" />
					</xsl:call-template>
				</xsl:if>
				<xsl:if test="ho:InnkaltDialogmote1 = 'true'">
					<xsl:call-template name="write_standard_table_row">
						<xsl:with-param name="ledetekst_id" select="'InnkaltDialogmote1'" />
						<xsl:with-param name="value" select="$default_option_text_true" />
						<xsl:with-param name="remove_space" select="'true'" />
					</xsl:call-template>
				</xsl:if>
				<xsl:if test="ho:DeltattDialogmote1 = 'true'">
					<xsl:call-template name="write_standard_table_row">
						<xsl:with-param name="ledetekst_id" select="'DeltattDialogmote1'" />
						<xsl:with-param name="value" select="$default_option_text_true" />
						<xsl:with-param name="remove_space" select="'true'" />
					</xsl:call-template>
				</xsl:if>
	        	<xsl:if test="ho:DeltattDialogmote1 != 'true'">
	        		<xsl:call-template name="write_standard_table_row">
	        			<xsl:with-param name="ledetekst_id" select="'ArsakIkkeDeltatt'" />
	        			<xsl:with-param name="value" select="ho:ArsakIkkeDeltatt" />
						<xsl:with-param name="remove_space" select="'true'" />
	        		</xsl:call-template>
	        	</xsl:if>
	        </tbody>
        </table> 		
    </xsl:template-->

    <xsl:template match="ho:MeldingTilNav">
	    <table>
	        <thead>
	            <tr>
	                <th>
	                	<xsl:call-template name="ledetekst_ref">
	                		<xsl:with-param name="id" select="'MeldingTilNav'" />
	                	</xsl:call-template>
	                </th>
	                <th colspan="2">
	                	<xsl:call-template name="ledetekst_tekst">
	                		<xsl:with-param name="id" select="'MeldingTilNav'" />
	                	</xsl:call-template>
	                </th>
	            </tr>
	        </thead>
	        <tbody>
				<!--xsl:if test="ho:BistandNAVUmiddelbart = 'true'">
					<xsl:call-template name="write_standard_table_row">
						<xsl:with-param name="ledetekst_id" select="'BistandNAVUmiddelbart'" />
						<xsl:with-param name="value" select="$default_option_text_true" />
						<xsl:with-param name="remove_space" select="'true'" />
					</xsl:call-template>
				</xsl:if-->
        		<xsl:call-template name="write_standard_table_row">
        			<xsl:with-param name="ledetekst_id" select="'BeskrivBistandNAV'" />
        			<xsl:with-param name="value" select="ho:BeskrivBistandNAV" />
					<xsl:with-param name="remove_space" select="'true'" />
        		</xsl:call-template>
        	</tbody>
        </table>
    </xsl:template>

	<xsl:template match="ho:MeldingTilArbeidsgiver">
	    <table>
	        <thead>
	            <tr>
	                <th>
	                	<xsl:call-template name="ledetekst_ref">
	                		<xsl:with-param name="id" select="'MeldingTilArbeidsgiver'" />
	                	</xsl:call-template>
	                </th>
	                <th colspan="2">
	                	<xsl:call-template name="ledetekst_tekst">
	                		<xsl:with-param name="id" select="'MeldingTilArbeidsgiver'" />
	                	</xsl:call-template>
	                </th>
	            </tr>
	        </thead>
	        <tbody>
        		<xsl:call-template name="write_standard_table_row">
        			<xsl:with-param name="ledetekst_id" select="'BeskrivMeldingTilArbeidsgiver'" />
        			<xsl:with-param name="value" select="." />
					<xsl:with-param name="remove_space" select="'true'" />
        		</xsl:call-template>
        	</tbody>
        </table>
	</xsl:template>

	<xsl:template match="ho:KontaktMedPasient">
	  	<xsl:param name="section" />
		<xsl:if test="ho:KontaktDato or ho:BegrunnIkkeKontakt">
		    <table>
		        <thead>
		            <tr>
		                <th>
		                	<xsl:call-template name="ledetekst_ref">
		                		<xsl:with-param name="id" select="'KontaktMedPasient'" />
		                	</xsl:call-template>
		                </th>
		                <th colspan="3">
		                	<xsl:call-template name="ledetekst_tekst">
		                		<xsl:with-param name="id" select="'KontaktMedPasient'" />
		                	</xsl:call-template>
		                </th>
		            </tr>
		        </thead>
		        <tbody>
		        	<xsl:if test="ho:KontaktDato">
		        		<xsl:call-template name="write_standard_table_row">
		        			<xsl:with-param name="ledetekst_id" select="'KontaktDato'" />
		        			<xsl:with-param name="value" select="ho:KontaktDato" />
							<xsl:with-param name="remove_space" select="'true'" />
		        		</xsl:call-template>
		        	</xsl:if>
		        	<xsl:if test="ho:BegrunnIkkeKontakt and $section != $section_employer_copy" >
		        		<xsl:call-template name="write_standard_table_row">
		        			<xsl:with-param name="ledetekst_id" select="'BegrunnIkkeKontakt'" />
		        			<xsl:with-param name="value" select="ho:BegrunnIkkeKontakt" />
							<xsl:with-param name="remove_space" select="'true'" />
		        		</xsl:call-template>
		        	</xsl:if>
		        </tbody>
		    </table>
		</xsl:if>
	</xsl:template>

    <xsl:template match="ho:HelseOpplysningerArbeidsuforhet" mode="behandler_bekreftelse">
    	<xsl:param name="section" />
    	<xsl:variable name="behandler_adresse">
    		<xsl:apply-templates select="ho:Behandler/ho:Adresse" />
    	</xsl:variable>
	    <table>
	        <thead>
	            <tr>
	                <th>
	                	<xsl:call-template name="ledetekst_ref">
	                		<xsl:with-param name="id" select="'Bekreftelse'" />
	                	</xsl:call-template>
	                </th>
	                <th colspan="3">
	                	<xsl:call-template name="ledetekst_tekst">
	                		<xsl:with-param name="id" select="'Bekreftelse'" />
	                	</xsl:call-template>
	                </th>
	            </tr>
	        </thead>
	        <tbody>
	        	<tr>
	        		<th>
	        			<xsl:call-template name="ledetekst_ref">
	        				<xsl:with-param name="id" select="'BehandletDato'" />
	        			</xsl:call-template>
	        		</th>
	        		<th>
	        			<xsl:call-template name="ledetekst_tekst">
	        				<xsl:with-param name="id" select="'BehandletDato'" />
	        			</xsl:call-template>
	        		</th>
	        		<td>
	        			<xsl:call-template name="formater_dato">
	        				<xsl:with-param name="dato" select="ho:KontaktMedPasient/ho:BehandletDato" />
	        			</xsl:call-template>
	        		</td>
	        	</tr>
	        	<xsl:call-template name="write_standard_table_row">
	        		<xsl:with-param name="ledetekst_id" select="'BehandlerNavn'" />
	        		<xsl:with-param name="value">
	        			<xsl:apply-templates select="ho:Behandler/ho:Navn" />
	        		</xsl:with-param>
					<xsl:with-param name="remove_space" select="'true'" />
	        	</xsl:call-template>
	        	<xsl:if test="$section != $section_claim_document">
		        	<xsl:call-template name="write_standard_table_row">
		        		<xsl:with-param name="ledetekst_id" select="'HPRnummer'" />
		        		<xsl:with-param name="value" select="ho:Behandler/ho:Id[fk1:TypeId/@V='HPR']/fk1:Id" />
						<xsl:with-param name="remove_space" select="'true'" />
		        	</xsl:call-template>
        		</xsl:if>
            	<xsl:call-template name="write_standard_table_row">
            		<xsl:with-param name="ledetekst_id" select="'Telefon'" />
            		<xsl:with-param name="value">
            			<xsl:for-each select="ho:Behandler/ho:KontaktInfo/fk1:TeleAddress">
            				<xsl:if test="position() > 1">
            					<xsl:value-of select="', '" />
            				</xsl:if>
            				<xsl:value-of select="substring-after(./@V, 'tel:')" />
            			</xsl:for-each>
            		</xsl:with-param>
					<xsl:with-param name="remove_space" select="'true'" />
            	</xsl:call-template>
	        	<xsl:if test="$section != $section_claim_document">
		        	<xsl:call-template name="write_standard_table_row">
		        		<xsl:with-param name="ledetekst_id" select="'Adresse'" />
		        		<xsl:with-param name="value" select="$behandler_adresse" />
						<xsl:with-param name="remove_space" select="'true'" />
		        	</xsl:call-template>
		        </xsl:if>
	        </tbody>
        </table>    	
    </xsl:template>

    <xsl:template match="ho:Adresse">
		<xsl:if test="fk1:StreetAdr">
			<xsl:value-of select="fk1:StreetAdr" />
		</xsl:if>
		<xsl:value-of select="concat(', ', fk1:PostalCode, ' ', fk1:City)" />
		<xsl:if test="fk1:Postbox">
			<xsl:value-of select="concat(', ', fk1:Postbox)" />
		</xsl:if>
    </xsl:template>

    <xsl:template match="Content" mode="section_table_header">
        <tr>
            <th>
                <section class="ssn">
                    <div class="form_owner">
                    	<xsl:call-template name="ledetekst_tekst">
                    		<xsl:with-param name="id" select="'Overskrift'" />
                		</xsl:call-template>
                    </div>
                    <div class="subject_ssn">
                        <span class="label">F.nr.</span>
                        <span class="ssn">
                        	<xsl:value-of select="concat(' ',ho:HelseOpplysningerArbeidsuforhet/ho:Pasient/ho:Fodselsnummer/fk1:Id)" />
                        </span>
                    </div>
                </section>
            </th>
        </tr>    	
    </xsl:template>

    <xsl:template match="Content" mode="section_header">
    	<xsl:param name="section" />
        <section class="machine_readable_header">
            <div class="section_letter">
            	<xsl:value-of select="$section" />
            </div>
            <div class="barcode">*NEW*</div>
            <div class="barcode">
            	<xsl:call-template name="generate_strekkode_2">
            		<xsl:with-param name="section_letter" select="$section" />
            		<xsl:with-param name="patient_ssn" select="ho:HelseOpplysningerArbeidsuforhet/ho:Pasient/ho:Fodselsnummer/fk1:Id" />
        		</xsl:call-template>
            </div>
        </section>
        <section class="form_heading">
            <table>
                <tr>
                    <th class="title">
                        <h1>
                        	<xsl:call-template name="ledetekst_tekst">
                        		<xsl:with-param name="id" select="'Tittel'" />
                        	</xsl:call-template>
                        </h1>
                    </th>
                    <th class="recipient">
                        <h2>
                    		<xsl:call-template name="ledetekst_tekst">
                    			<xsl:with-param name="id">
                    				<xsl:value-of select="concat($section,'_overskrift')" />
                    			</xsl:with-param>
                    		</xsl:call-template>
                        </h2>
                        <p>
                    		<xsl:call-template name="ledetekst_tekst">
                    			<xsl:with-param name="id">
                    				<xsl:value-of select="$section" />
                    			</xsl:with-param>
                    		</xsl:call-template>
                        </p>
                    </th>
                </tr>
            </table>
        </section>
    </xsl:template>

    <xsl:template name="egenerklaering">
        <section id="egenerklaering">
            <div class="form_image">
                <img src="egenerklaring_sykmelding.png" />
            </div>
        </section>    	
    </xsl:template>

    <xsl:template match="ho:HelseOpplysningerArbeidsuforhet" mode="employer_summary">
    	<section class="employer_summary">
    		<dl>
    			<dt>Arbeidstaker</dt>
    			<dd><xsl:apply-templates select="ho:Pasient/ho:Navn" /></dd>
			</dl>

			<h3>
				<xsl:call-template name="ledetekst_tekst">
					<xsl:with-param name="id" select="'Aktivitet'" />
				</xsl:call-template>
			</h3>
			<table>
				<tbody>
					<xsl:apply-templates select="ho:Aktivitet/ho:Periode" mode="employer_summary">
						<xsl:sort select="ho:PeriodeFOMDato" />
					</xsl:apply-templates>
				</tbody>
			</table>

			<xsl:choose>
				<xsl:when test="ho:Aktivitet//ho:InnspillTilArbeidsgiver or ho:MeldingTilArbeidsgiver">
					<h3>Informasjon til arbeidsgiver fra sykmelder</h3>
					<h4>
						<xsl:call-template name="ledetekst_tekst">
							<xsl:with-param name="id" select="'BeskrivMeldingTilArbeidsgiver'" />
						</xsl:call-template>
					</h4>
					<ul>
						<xsl:for-each select="ho:Aktivitet//ho:InnspillTilArbeidsgiver">
							<li><xsl:value-of select="." /></li>
						</xsl:for-each>
					</ul>

					<!--h4>
						<xsl:call-template name="ledetekst_tekst">
							<xsl:with-param name="id" select="'Tiltak'" />
						</xsl:call-template>
					</h4-->
					<!--p>
						<xsl:value-of select="ho:Tiltak/ho:TiltakArbeidsplassen" />
					</p-->

					<h4>
						<xsl:call-template name="ledetekst_tekst">
							<xsl:with-param name="id" select="'MeldingTilArbeidsgiver'" />
						</xsl:call-template>
					</h4>
					<p>
						<xsl:value-of select="ho:MeldingTilArbeidsgiver" />
					</p>
				</xsl:when>
				<xsl:otherwise>
					<p class="default-message">
						<b>Ved utfylling av sykmelding kan sykmelder komme med innspill til arbeidsgiver. I dette tilfellet er det ikke gitt innspill.</b>
					</p>
				</xsl:otherwise>
			</xsl:choose>

			<p>
				<i>Merk: Medisinske opplysninger fremkommer ikke i arbeidsgivers eksemplar</i>
			</p>
    	</section>
    </xsl:template>

    <xsl:template name="veiledning_egenerklaering">
    	<section class="guide">
	        <h1>Om utfylling av egenerklæring</h1>
	        <p><b>13.2</b> Oppgi første fraværsdag, enten den dagen sykmeldingen gjelder fra eller fra første dag forut hvor det er benyttet egenmelding.</p>
	        <p><b>13.5</b> Dersom du er sykmeldt fra flere arbeidsforhold, må det skrives ut en sykmelding og leveres et sykepengekrav for hvert arbeidsforhold.</p>
	        <h2>Hvem skal kravblanketten sendes til</h2>
	        <p>Betaler arbeidsgiveren din lønn under sykdom, skal du sende kravblanketten dit. Hvis ikke, skal du sende kravet til NAV Forvaltning i ditt fylke (se nav.no/sykepenger for adresse).</p>
	        <h2>Frist for å sette frem krav</h2>
	        <p>Krav om sykepenger må som hovedregel fremsettes innen tre måneder.</p>
	        <p>For mer informasjon se nav.no, eller ta kontakt med NAV.</p>
    	</section>
    </xsl:template>

    <xsl:template name="veiledning">
        <section class="guide">
            <h1>Om sykmelding &#8211; Rettigheter og plikter</h1>
            <p>Sykmelding er aktuell når det er medisinske grunner som hindrer at du kan være i arbeid, men ofte er det mulig å være på jobb hvis det blir tilrettelagt. Før du blir sykmeldt, skal derfor din lege/sykmelder vurdere om det medisinsk sett er mulig å være helt eller delvis i arbeid.</p>
            <p>Arbeidsgiver har plikt til å tilrettelegge arbeidet så langt det er mulig, og du har plikt til å bidra til å finne løsninger som hindrer unødig sykefravær.</p>
            <p>Noen oppfølgingspunkter er lovfestede:</p>
            <ul>
                <li>Innen <b>4 ukers sykmelding</b> skal oppfølgingsplan være utarbeidet av arbeidsgiver og deg, og kopi av denne skal sendes til lege/sykmelder.</li>
                <li>Innen <b>7 ukers sykmelding</b> skal arbeidsgiver ha innkalt deg til dialogmøte.</li>
                <li>Innen <b>8 ukers sykmelding</b> må du være i aktivitet tilknyttet arbeidsgiver, hvis det ikke kan dokumenteres at helsen eller arbeidssituasjonen gjør det umulig.</li>
                <li>Innen <b>6 måneders sykmelding</b> innkaller NAV til dialogmøte.</li>
            </ul>
            <p>Hvis du er sykmeldt uten å ha tilknytning til en arbeidsgiver, er det NAV-kontoret som skal gi veiledning og oppfølging.</p>
            <h2>Vær også klar over at</h2>
            <ul>
                <li>rett til sykepenger forutsetter at du har inntektstap på grunn av egen sykdom. Sosiale eller økonomiske problemer gir ikke rett til sykepenger.</li>
                <li>sykepenger utbetales i maksimum 52 uker, også for gradert (delvis) sykmelding.</li>
                <li>det gis bare feriepenger for de første 48 sykepengedagene i opptjeningsåret.</li>
            </ul>
            <h3>Du kan miste retten til sykepenger</h3>
            <ul>
                <li>hvis du uten rimelig grunn nekter å opplyse om egen funksjonsevne eller nekter å ta imot tilbud om behandling og/eller tilrettelegging.</li>
                <li>hvis du ikke medvirker til utarbeiding og gjennomføring av oppfølgingsplaner eller ikke deltar i dialogmøter</li>
                <li>hvis du ikke er i aktivitet på arbeidsplassen etter 8 ukers sykmelding og dette ikke skyldes dokumenterte medisinske eller arbeidsmessige forhold.</li>
            </ul>
            <h2>Klage</h2>
            <p>Dersom du ønsker å klage på vedtak om sykepenger, må dette skje innen seks uker etter at du mottok vedtaket (avslaget). Klagen sendes til NAV.</p>
            <p>For mer informasjon se nav.no, eller ta kontakt med NAV.</p>
        </section>    	
    </xsl:template>

    <xsl:template name="employer_orientation">
    	<section class="guide">
    		<h2>Orientering til arbeidsgiver angående refusjon fra folketrygden</h2>
    		<p>Arbeidsgiver som betaler lønn under sykdom utover arbeidsgiverperioden, kan kreve sykepengene refundert fra folketrygden, se folketrygdloven § 22-3. Slik refusjon betinger at retten til sykepenger er oppfylt. Hvis arbeidsgiver er i tvil om dette, bør NAV kontaktes. Når NAV skal refundere (utbetale) sykepengene, må kravblanketten oversendes, ferdig utfylt av den sykmeldte, fra arbeidsgiveren til NAV Forvaltning i arbeidstakerens bostedsfylke innen tre måneder. Se nav.no/sykepenger for adresser. Det kan ikke gjøres unntak fra denne fristen, se folketrygdloven § 22-13 femte og sjette ledd. Hvis NAV godkjenner kravet om refusjon av sykepenger, vil sykepengene bli utbetalt til arbeidsgivers konto. For mer informasjon se nav.no
			</p>
    	</section>
    </xsl:template>

    <xsl:template match="ho:Navn">
    	<xsl:value-of select="ho:Fornavn" />
    	<xsl:if test="ho:Mellomnavn">
    		<xsl:value-of select="concat(' ', ho:Mellomnavn)" />
    	</xsl:if>
		<xsl:value-of select="concat(' ', ho:Etternavn)" />    	
    </xsl:template>

    <xsl:template match="ho:Navn" mode="patient">
		<xsl:value-of select="concat(ho:Etternavn, ', ')" />
    	<xsl:value-of select="ho:Fornavn" />
    	<xsl:if test="ho:Mellomnavn">
    		<xsl:value-of select="concat(' ', ho:Mellomnavn)" />
    	</xsl:if>
    </xsl:template>

    <xsl:template match="ho:SyketilfelleStartDato">
        <table>
            <tbody>
            	<xsl:call-template name="write_standard_table_row">
            		<xsl:with-param name="ledetekst_id" select="'SyketilfelleStartDato'" />
            		<xsl:with-param name="value">
                    	<xsl:call-template name="formater_dato">
                    		<xsl:with-param name="dato" select="." />
						</xsl:call-template>
					</xsl:with-param>
					<xsl:with-param name="remove_space" select="'true'" />
        		</xsl:call-template>
            </tbody>
        </table>
    </xsl:template>

    <xsl:template name="print_diagnose_table_row">
    	<xsl:param name="diagnose_node" />
        <tr>
            <td colspan="2"></td>
            <td>
            	<xsl:call-template name="konverter_diagnosekode">
            		<xsl:with-param name="kode" select="$diagnose_node/@S" />
            	</xsl:call-template>
            </td>
            <td>
    			<xsl:value-of select="$diagnose_node/@V" />
            </td>
            <td>
        		<xsl:value-of select="$diagnose_node/@DN" />
            </td>
        </tr>    	
    </xsl:template>

	<xsl:template name="write_standard_table_row">
		<xsl:param name="ledetekst_id" />
		<xsl:param name="value" />
		<xsl:param name="colspan_third_col" />
		<xsl:param name="remove_space" />
		<xsl:if test="$remove_space = 'false' or translate($value, ' ', '')">
			<tr>
				<th>
					<xsl:call-template name="ledetekst_ref">
						<xsl:with-param name="id" select="$ledetekst_id" />
					</xsl:call-template>
				</th>
				<th>
					<xsl:call-template name="ledetekst_tekst">
						<xsl:with-param name="id" select="$ledetekst_id" />
					</xsl:call-template>
				</th>
				<td>
					<xsl:if test="$colspan_third_col">
						<xsl:attribute name="colspan">
							<xsl:value-of select="$colspan_third_col" />
						</xsl:attribute>
					</xsl:if>
					<xsl:value-of select="$value" />
				</td>
			</tr>
		</xsl:if>
	</xsl:template>

	<!-- template for å få tekst til en gitt ledetekst-id -->
	<xsl:template name="ledetekst_tekst">
		<xsl:param name="id"/>
		<xsl:choose>
			<xsl:when test="function-available('msxsl:node-set')">
					<xsl:value-of select="msxsl:node-set($ledetekster)/ldtxt:Ledetekst[@Id=$id]/ldtxt:Tekst"/>
			</xsl:when>
			<xsl:when test="function-available('exslt:node-set')">
				<xsl:value-of select="exslt:node-set($ledetekster)/ldtxt:Ledetekst[@Id=$id]/ldtxt:Tekst"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- template for å få referanse til en gitt ledetekst-id -->
	<xsl:template name="ledetekst_ref">
		<xsl:param name="id"/>
		<xsl:choose>
			<xsl:when test="function-available('msxsl:node-set')"><xsl:value-of select="msxsl:node-set($ledetekster)/ldtxt:Ledetekst[@Id=$id]/ldtxt:Referanse"/></xsl:when>
			<xsl:when test="function-available('exslt:node-set')"><xsl:value-of select="exslt:node-set($ledetekster)/ldtxt:Ledetekst[@Id=$id]/ldtxt:Referanse"/></xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- template som konkatenerer referanse og ledetekst -->
	<xsl:template name="ledetekst_concatenated">
		<xsl:param name="id" />
		<xsl:call-template name="ledetekst_ref">
			<xsl:with-param name="id" select="$id" />
		</xsl:call-template>
		<xsl:value-of select="' '" />
		<xsl:call-template name="ledetekst_tekst">
			<xsl:with-param name="id" select="$id" />
		</xsl:call-template>
	</xsl:template>

	<!-- konverter kodesystem for diagnoser til tekstkoder -->
	<xsl:template name="konverter_diagnosekode">
		<xsl:param name="kode"/>
		<xsl:variable name="lengde"><xsl:value-of select="string-length($kode)"/></xsl:variable>
		<xsl:variable name="sluttsiffer"><xsl:value-of select="substring($kode, $lengde - 3, 4)"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$sluttsiffer='7170'"><xsl:value-of select="'ICPC-2'"/></xsl:when>
			<xsl:when test="$sluttsiffer='7110'"><xsl:value-of select="'ICD-10'"/></xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- konverter date-element til norsk format -->
	<xsl:template name="formater_dato">
		<xsl:param name="dato"/>
		<xsl:value-of select="concat(substring($dato, 9, 2), '.', substring($dato, 6, 2), '.', substring($dato, 1, 4))"/>
	</xsl:template>

	<xsl:template name="generate_strekkode_2">
		<xsl:param name="section_letter" />
		<xsl:param name="patient_ssn" />
		<xsl:variable name="strekkode_raw_values">
			<xsl:value-of select="$patient_ssn" />
			<xsl:choose>
				<xsl:when test="$section_letter = 'A'">
					<xsl:value-of select="900011" />
					<xsl:value-of select="1411" />
				</xsl:when>
				<xsl:when test="$section_letter = 'B'">
					<xsl:value-of select="900012" />
					<xsl:value-of select="2222" />
				</xsl:when>
				<xsl:when test="$section_letter = 'C'">
					<xsl:value-of select="900013" />
					<xsl:value-of select="3333" />
				</xsl:when>
				<xsl:when test="$section_letter = 'D'">
					<xsl:value-of select="900014" />
					<xsl:value-of select="1412" />
				</xsl:when>
			</xsl:choose>
		</xsl:variable>

		<xsl:value-of select="'*'" />
		<xsl:value-of select="$strekkode_raw_values" />
		<xsl:call-template name="generate_mod43_check_digit">
			<xsl:with-param name="raw_value" select="$strekkode_raw_values" />
		</xsl:call-template>
		<xsl:value-of select="'*'" />
	</xsl:template>

	<xsl:template name="generate_strekkode_3">
		<xsl:param name="section" />
		<xsl:variable name="main_diagnose_code">
			<!-- only included for sections A and B, padded with zeroes for other sections -->
			<xsl:choose>
				<xsl:when test="$section = 'A' or $section = 'B'">
					<xsl:value-of select="ho:HelseOpplysningerArbeidsuforhet/ho:MedisinskVurdering/ho:HovedDiagnose/ho:Diagnosekode/@V" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'000'" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="period_from_date">
			<xsl:call-template name="formater_dato">
				<xsl:with-param name="dato" select="ho:HelseOpplysningerArbeidsuforhet/ho:Aktivitet/ho:Periode/ho:PeriodeFOMDato" />
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="period_to_date">
			<xsl:call-template name="formater_dato">
				<xsl:with-param name="dato" select="ho:HelseOpplysningerArbeidsuforhet/ho:Aktivitet/ho:Periode/ho:PeriodeTOMDato" />
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="document_id_timestamp" select="substring(ho:HelseOpplysningerArbeidsuforhet/ho:Strekkode, 14, 12)" />
		<xsl:variable name="strekkode_concatenated_values">
			<!-- write document timestamp as ddMMyyhhmm -->
			<xsl:value-of select="substring($document_id_timestamp, 1, 4)" />
			<xsl:value-of select="substring($document_id_timestamp, 7, 6)" />
			<!-- write diagnose code verbatim -->
			<xsl:value-of select="$main_diagnose_code" />
			<!-- write period start date as ddMMyy -->
			<xsl:value-of select="substring($period_from_date, 1, 2)" />
			<xsl:value-of select="substring($period_from_date, 4, 2)" />
			<xsl:value-of select="substring($period_from_date, 9, 2)" />
			<!-- write period end date as ddMMyy -->
			<xsl:value-of select="substring($period_to_date, 1, 2)" />
			<xsl:value-of select="substring($period_to_date, 4, 2)" />
			<xsl:value-of select="substring($period_to_date, 9, 2)" />
		</xsl:variable>

		<xsl:value-of select="'*'" />
		<xsl:value-of select="'00'" /> <!-- Subject -->
		<xsl:value-of select="'0'" /> <!-- Logic -->
		<xsl:value-of select="$strekkode_concatenated_values" />
		<xsl:value-of select="'00'" /><!-- placeholder for page numbers (which can't be generated correctly) -->
		<xsl:call-template name="generate_mod43_check_digit">
			<xsl:with-param name="raw_value" select="$strekkode_concatenated_values" />
		</xsl:call-template>
		<xsl:value-of select="'*'" />
	</xsl:template>

	<xsl:template name="generate_mod43_check_digit">
		<xsl:param name="raw_value" select="''" />
		<xsl:param name="sum" select="0" />
		<xsl:choose>
			<xsl:when test="string-length($raw_value) &gt; 0">
				<xsl:variable name="character" select="translate(substring($raw_value, 1, 1), 'abcdefghijklmnopqrstuvwzyx', 'ABCDEFGHIJKLMNOPQRSTUVWZYX')" />
				<xsl:variable name="char_reference_value" select="string-length(substring-before($code39_check_digits, $character))" />
				<xsl:call-template name="generate_mod43_check_digit">
					<xsl:with-param name="raw_value" select="substring($raw_value, 2)" />
					<xsl:with-param name="sum" select="$sum + $char_reference_value" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="substring($code39_check_digits, ($sum mod 43) + 1, 1)" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>