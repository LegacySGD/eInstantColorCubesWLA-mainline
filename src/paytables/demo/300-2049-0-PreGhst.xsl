<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, convertedPrizeValues, prizeNames)
					{
						var scenario = getScenario(jsonContext);
						var board = getOutcomeData(scenario, 0);
						var coords = getOutcomeData(scenario, 1);
						var nameAndCollectList = (prizeNames.substring(1)).split(',');
						var prizeValues = (convertedPrizeValues.substring(1)).split('|');
						var boardWidth = 7;
						var boardHeight = 7;

						var prizeNamesList = [];
						var collectionsList = [];
						var instantWinPrizes = [];
						for(var i = 0; i < nameAndCollectList.length; ++i)
						{
							var desc = nameAndCollectList[i];
							if(desc[0] != 'I')
							{
								prizeNamesList.push(desc[desc.length - 1]);
								collectionsList.push(desc.slice(0,desc.length - 1));
							}
							else
							{
								prizeNamesList.push(desc[desc.length - 1]);
								collectionsList.push(1);
							}
						}

						
						registerDebugText("Prize Names: " + prizeNamesList);
						registerDebugText("Collection Counts: " + collectionsList);
						registerDebugText("Instant Wins: " + instantWinPrizes);
						
						// visible board
						var visibleBoard = [];
						for(var x = 0; x < boardWidth; ++x)
						{
							visibleBoard.push("");
							for(var y = 0; y < boardHeight; ++y)
							{
								visibleBoard[x] += board[x][y];
							}
						}
						
						// Checking Cells 2D arrays
						var checkedCells = [[],[],[],[],[],[],[]];
						for(var i = 0; i < 7; ++i)
						{
							for(var j = 0; j < 7; ++j)
							{
								checkedCells[i][j] = false;
							}
						}
						
						var prizeTotals = [];
						for(var i = 0; i < prizeNamesList.length; ++i)
						{
							prizeTotals.push(0);
						}
						
						//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////			
						// Print Translation Table to !DEBUG
						var index = 1;
						//registerDebugText("Translation Table");
						while(index < translations.item(0).getChildNodes().getLength())
						{
							var childNode = translations.item(0).getChildNodes().item(index);
							//registerDebugText(childNode.getAttribute("key") + ": " +  childNode.getAttribute("value"));
							index += 2;
						}
						/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						
						// Output winning numbers table.
						var r = [];
						r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
						
						var MatchedCells = [];
						var MatchedValues = [];
						var MatchedValuesTranslated = [];
						for(var i = 0; i < coords.length; ++i)
						//for(var i = 0; i < 2; ++i)
						{
							// Present Board
							/*registerDebugText("CURRENT BOARD---------------------------------------------------------------------------------------------------------------------");
							for(var y = visibleBoard.length - 1; y >= 0 ; y--)
							{
								var boardRow = [];
								for(var x = 0; x < visibleBoard[y].length; ++x)
								{
		 							boardRow.push(getTranslationByName(visibleBoard[y][x], translations));
								}
								registerDebugText("Row " + (y+1) + ": " + boardRow);
								boardRow = [];
							}
							registerDebugText("--------------------------------------------------------------------------------------------------------------------------------");*/
							
							var yLoc = coords[i][0] - 1;
							var xLoc = coords[i][1] - 1;
							var checkValue = visibleBoard[xLoc][yLoc];
							registerDebugText("Turn " + (i+1) + ": (" + xLoc + ", " + yLoc + ")");
							registerDebugText("Cube at Location (" + xLoc + ", " + yLoc + "): " + getTranslationByName(checkValue, translations));
						
							if(checkValue == "X")
							{
								getCubesAroundCenter(xLoc, yLoc, MatchedCells);
							}
							else
							{
								getCubeAdjacentLocation(checkValue, xLoc, yLoc, board, boardWidth, boardHeight, checkedCells, MatchedCells);
							}
							registerDebugText("Matched Cell Locations: " + MatchedCells);
							
							var stringRemove = "";
							for(var j = 0; j < MatchedCells.length; ++j)
							{
								var MatchedCellX = Number(MatchedCells[j][0]);
								var MatchedCellY = Number(MatchedCells[j][1]);
								stringRemove = board[MatchedCellX];
								
								stringRemove = board[MatchedCellX].substring(0, MatchedCellY) + "Z";
								stringRemove = stringRemove.concat(board[MatchedCellX].substring(MatchedCellY + 1));
								
								/*registerDebugText("MatchedCell X Index: " + MatchedCellX);
								registerDebugText("MatchedCell Y Index: " + MatchedCellY);
								registerDebugText("String BEFORE Replacement: " + board[MatchedCellX]);
								registerDebugText("String AFTER Replacement: " + stringRemove);
								registerDebugText("Board Length: " + board.length);
								registerDebugText("Board Element[" + MatchedCellX + "] Length: " + board[MatchedCellX].length);
								registerDebugText("Board Element[" + MatchedCellX + "] Expected Length: " + stringRemove.length);*/
								
								board[MatchedCellX] = stringRemove;
								stringRemove = "";
								
								//registerDebugText("Board Element[" + MatchedCellX + "] AFTER Length: " + board[MatchedCellX].length);
								
								MatchedValues.push(visibleBoard[MatchedCellX][MatchedCellY]);
								MatchedValuesTranslated.push(getTranslationByName(visibleBoard[MatchedCellX][MatchedCellY], translations));
								visibleBoard[MatchedCellX][MatchedCellY] = getTranslationByName("youMatched", translations) + ": " + getTranslationByName(visibleBoard[MatchedCellX][MatchedCellY], translations)
							}
							
							for(var index = 0; index < board.length; ++index)
							{
								registerDebugText("Board Row [" + index + "] BEFORE: " + board[index]);
								board[index] = board[index].replace(/Z/g, "");
								registerDebugText("Board Row [" + index + "] AFTER: " + board[index]);
							}	
							
							registerDebugText("Matched Cells: " + MatchedCells);
							registerDebugText("Matched Values: " + MatchedValues);
							registerDebugText("Matched Translations: " + MatchedValuesTranslated);
							
							for(var prize = 0; prize < prizeNamesList.length; ++prize)
							{
								registerDebugText(getTranslationByName(prizeNamesList[prize], translations) + ": " + countMatched(prizeNamesList[prize], MatchedValues));
							}							 
							
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							
							r.push('<tr><td>');
	 						r.push(getTranslationByName("turn", translations) + " #" + (i+1));
	 						r.push('</td></tr>');
	 						
							// Show Old Board with Matched Symbols
							//registerDebugText("BEFORE:");
							/*for(var y = visibleBoard.length - 1; y >= 0 ; y--)
							{
								r.push('<tr>');
								//registerDebugText("Row " + j + ": " + visibleBoard[y]);
								for(var x = 0; x < visibleBoard[y].length; ++x)
								{
									var boardItem = visibleBoard[y][x];
									r.push('<td class="tablebody">');
									if(visibleBoard[y][x].length == 1)
									{
										boardItem = getTranslationByName(visibleBoard[y][x], translations);
									}
	 								r.push(boardItem);
		 							r.push('</td>');
		 							boardItem = "";
								}
								r.push('</tr>');
							}*/
							
							r.push('<tr>');
							r.push('<td class="tablehead">');
	 						r.push(getTranslationByName("cubeColor", translations));
	 						r.push('</td>');
	 						r.push('<td class="tablehead">');
	 						r.push(getTranslationByName("numberCollected", translations));
	 						r.push('</td>');
	 						r.push('<td class="tablehead">');
	 						r.push(getTranslationByName("cumulativeTotal", translations));
	 						r.push('</td>');
	 						r.push('<td class="tablehead">');
	 						r.push(getTranslationByName("prize", translations));
	 						r.push('</td>');
	 						r.push('</tr>');
	 						
	 						r.push('<tr>');
	 						for(var prize = 0; prize < prizeNamesList.length; ++prize)
							{
								var numCollected = countMatched(prizeNamesList[prize], MatchedValues);
								
								prizeTotals[prize] += numCollected;
							
								r.push('<tr>');
								
								r.push('<td class="tablebody">');
								if(isNaN(prizeNamesList[prize]))
								{
									r.push(getTranslationByName(prizeNamesList[prize], translations));
								}
								else
								{
									r.push(getTranslationByName(prizeNamesList[prize], translations) + " (" + getTranslationByName("instantWin", translations) + ")");
								}
								r.push('</td>');
								
								r.push('<td class="tablebody">');
								if(numCollected > 0)
								{
									r.push(numCollected);
								}
								r.push('</td>');
								
								r.push('<td class="tablebody">');
								if(collectionsList[prize] > 1)
								{
									r.push(prizeTotals[prize] + "/" + collectionsList[prize]);
								}
								r.push('</td>');
								
								r.push('<td class="tablebody">');
								if(prizeTotals[prize] >= collectionsList[prize] && numCollected > 0)
								{
									r.push(prizeValues[prize]);
								}
								r.push('</td>');
								
								r.push('</tr>');
							}	
							r.push('</tr>');
							r.push('</table>');
							
							// Reset Board
							visibleBoard = [[],[],[],[],[],[],[]];
							for(var x = 0; x < boardWidth; ++x)
							{
								for(var y = 0; y < boardHeight; ++y)
								{
									//registerDebugText("Board Item[" + y + "][" + x + "]: " + board[y][x]);
									if(typeof board[y][x] != 'undefined')
									{
										visibleBoard[x][y] = board[x][y];
									}
									else
									{
										registerDebugText("Board Item[" + y + "][" + x + "] is undefined");
									}
									
								}
							}
							
							MatchedCells = [];
							MatchedValues = [];
							MatchedValuesTranslated = [];
							
							// Reset All Checked Cells
							for(var j = 0; j < 7; ++j)
							{
								for(var k = 0; k < 7; ++k)
								{
									checkedCells[j][k] = false;
								}
							}
						}
						
						r.push('</table>');
						
						
						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
							{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
								r.push('</td>');
								r.push('</tr>');
							}
							r.push('</table>');
						}

						return r.join('');
					}
					
					
					/////////////////////////
					// Color Cubes Logic
					
					function getCubeAdjacentLocation(checkValue, xLoc, yLoc, board, width, height, checkedCells, matchedCells)
					{
						var minX = 0;
						var minY = 0;
						var maxX = width - 1;
						var maxY = height - 1;
						//registerDebugText("(" + xLoc + ", " + yLoc + ")");
						if(xLoc > maxX || xLoc < minX || yLoc > maxY || yLoc < minY)
						{
							//registerDebugText("OUT OF BOUNDS");
							return;
						}
						
						if(checkedCells[xLoc][yLoc] == false)
						{
							if(board[xLoc][yLoc] == checkValue)
							{
								//registerDebugText("Value '" + checkValue + "' FOUND....Checking Adjacencies....");
								matchedCells.push(xLoc + "" + yLoc);
								checkedCells[xLoc][yLoc] = true;
							
								// Check Left
								//registerDebugText("(" + xLoc + ", " + yLoc + ")...Checking LEFT....");
								getCubeAdjacentLocation(checkValue, xLoc - 1, yLoc, board, width, height, checkedCells, matchedCells);
								
								//Check Top
								//registerDebugText("(" + xLoc + ", " + yLoc + ")...Checking TOP....");
								getCubeAdjacentLocation(checkValue, xLoc, yLoc + 1, board, width, height, checkedCells, matchedCells);
								
								// Check Right
								//registerDebugText("(" + xLoc + ", " + yLoc + ")...Checking RIGHT....");
								getCubeAdjacentLocation(checkValue, xLoc + 1, yLoc, board, width, height, checkedCells, matchedCells);
								
								// Check Bottom
								//registerDebugText("(" + xLoc + ", " + yLoc + ")...Checking BOTTOM....");
								getCubeAdjacentLocation(checkValue, xLoc, yLoc - 1, board, width, height, checkedCells, matchedCells);
							}
							else
							{
								//registerDebugText("Value '" + checkValue + "' NOT FOUND!!! END CYCLE!!!");
							}
							checkedCells[xLoc][yLoc] = true;
						}
						else
						{
							//registerDebugText("ALREADY CHECKED!!!");
						}
					}
					
					function getCubesAroundCenter(xLoc, yLoc, matchedCells)
					{
						// Center
						matchedCells.push(xLoc + "" + yLoc);
						
						// Top
						matchedCells.push(xLoc + "" + (yLoc+1));
						
						// Bottom
						matchedCells.push(xLoc + "" + (yLoc-1));
						
						// Left
						matchedCells.push((xLoc-1) + "" + yLoc);
						
						// Top Left
						matchedCells.push((xLoc-1) + "" + (yLoc+1));
						
						// Bottom Left
						matchedCells.push((xLoc-1) + "" + (yLoc-1));
						
						// Right
						matchedCells.push((xLoc+1) + "" + yLoc);
						
						// Top Right
						matchedCells.push((xLoc+1) + "" + (yLoc+1));
						
						// Bottom Right
						matchedCells.push((xLoc+1) + "" + (yLoc-1));
					}
					
					function countMatched(matchValue, checkArray)
					{
						var count = 0;
						for(var i = 0; i < checkArray.length; ++i)
						{
							if(matchValue == checkArray[i])
							{
								count++;
							}
						}
						return count;
					}

					/////////////////
					
					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}
					
					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					// Input: "23,9,31|8:E,35:E,4:D,13:D,37:G,..."
					// Output: ["23", "9", "31"]
					function getWinningNumbers(scenario)
					{
						var numsData = scenario.split("|")[0];
						return numsData.split(",");
					}
					
					// Input: e.g. "FBBEFFAAF,F2BEEEDDBDDAC,FFAXDCECDEDABEEF,EAABC1CAAEDDB,ABFCBABCCBFCCXDC,EBXAAAFFCEBBF,DEDDADF3ECC|24,63,36,63,11,27,45,32,44"
					// Output: e.g ["FBBEFFAAF", "F2BEEEDDBDDAC", "FFAXDCECDEDABEEF", "EAABC1CAAEDDB", ...] or ["24", "63", "36", "11",...]
					function getOutcomeData(scenario, index)
					{
						var outcomeData = scenario.split("|")[index];
						var outcomePairs = outcomeData.split(",");
						var result = [];
						for(var i = 0; i < outcomePairs.length; ++i)
						{
							result.push(outcomePairs[i]);
						}
						return result;
					}
					
					function filterCollectables(scenario)
					{
						var simpleCollections = scenario.split("|")[1];
						
						return simpleCollections;			
					}
					
					function countPrizeCollections(prizeName, scenario)
					{
						//registerDebugText("Checking for prize in scenario: " + prizeName);
						var count = 0;
						for(var char = 0; char < scenario.length; ++char)
						{
							if(prizeName == scenario[char])
							{
								count++;
							}
						}
						
						return count;
					}

					// Input: List of winning numbers and the number to check
					// Output: true is number is contained within winning numbers or false if not
					function checkMatch(winningNums, boardNum)
					{
						for(var i = 0; i < winningNums.length; ++i)
						{
							if(winningNums[i] == boardNum)
							{
								return true;
							}
						}
						
						return false;
					}
					
					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						var prizes = prizeNames.split(",");
						
						for(var i = 0; i < prizes.length; ++i)
						{
							if(prizes[i] == currPrize)
							{
								return i;
							}
						}
						
						return -1;
					}
					
					//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeTables, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeTableStrings = prizeTables.split("|");
						
						
						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeTableStrings[i];
							}
						}
						
						return "";
					}
					
					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}
					
					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>
				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
