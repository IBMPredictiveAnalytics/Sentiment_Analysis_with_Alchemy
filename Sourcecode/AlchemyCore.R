#predefined for node
sFunctionName <- "GetTextSentiment"

# Install function for packages    
packages <- function(x){
  x <- as.character(match.call()[[2]])
  if (!require(x,character.only=TRUE)){
    install.packages(pkgs=x,repos="http://cran.r-project.org")
    require(x,character.only=TRUE)
  }
}
packages(httr)
packages(XML)
packages(RCurl)
packages(plyr)

#ui-input
sFeatureColumns <- "%%input_column%%"
sSourceType <- %%input_is_url%%
sApiKey <- "%%input_api_key%%"

#pre-defined
sBaseUrl <-  "http://gateway-a.watsonplatform.net/calls/"

#utinity
safeJsonValueFetch <- function(jsonObject){
	if(is.null(jsonObject)) return(NA)
	else return(jsonObject)
}

#Generate Url 
generateAlchemyUrl <- function(sBaseUrl, sFunctionName, sSourceType, sApiKey, sContext){
	if (sSourceType == "url"){
		sUrl <- paste(sBaseUrl, "url/URL" , sFunctionName, "?",
			"apikey=",sApiKey,"&url=", sContext, "&outputMode=json", sep='')
	}else if(sSourceType == "html"){
		sUrl <- paste(sBaseUrl, "html/HTML" , sFunctionName, "?",
			"apikey=",sApiKey,"&html=", sContext, "&outputMode=json", sep='')		
	}else if(sSourceType == "text"){
		sUrl <- paste(sBaseUrl, "text/Text" , sFunctionName, "?",
			"apikey=",sApiKey,"&text=", sContext, "&outputMode=json", sep='')	
	}
	sUrl <- paste(sUrl, "&sentiment=1", sep='')
	return(sUrl)
}


#Retrive data from rest api
retriveFromAlchemy <- function(sContent, sSourceType, sFunctionName, funProcessResult){
	sUrl <- generateAlchemyUrl(sBaseUrl,
		sFunctionName,
		sSourceType,
		sApiKey,
		curlEscape(sContent))
	rHttpResult <- POST(sUrl)
	stop_for_status(rHttpResult)
	return(funProcessResult(sContent, rHttpResult))
}

generateProcessFunction <- function(sFunctionName){
	if(sFunctionName == "GetTextSentiment"){
		return(processTextSentiment)
	}else if(sFunctionName == "GetRankedNamedEntities"){
		return(processRankedNamedEntities)
	}
}
processTextSentiment <- function(sContent, httpResult){
	result <- content(httpResult)$docSentiment
	#result$content <- sContent
	result <- list(
		score=safeJsonValueFetch(result$score), 
		type=safeJsonValueFetch(result$type))
	return(result)	
}

processRankedNamedEntities <- function(sContent, httpResult){
	entitiesResult <- content(httpResult)$entities
	processEntities <- function(entities){	
		return(list(
			text=safeJsonValueFetch(entities$text), 
			type=safeJsonValueFetch(entities$type), 
			relevance=safeJsonValueFetch(entities$relevance),
			count=safeJsonValueFetch(entities$count),
			sentiment.type=safeJsonValueFetch(entities$sentiment$type),
			sentiment.score=safeJsonValueFetch(entities$sentiment$score),
			url=sContent)) }
	result <- ldply (lapply(entitiesResult,processEntities), data.frame)
	return(result)
}


print("source type is:")
print(sSourceType)
print("function name is:")
print(sFunctionName)
#fetch modeler data
textData <- modelerData[,sFeatureColumns]
resultData <- lapply(textData, FUN=retriveFromAlchemy, 
	sSourceType=sSourceType, sFunctionName=sFunctionName,
	funProcessResult=generateProcessFunction(sFunctionName))
resultData <- ldply (resultData, data.frame)
print(resultData)

if(sFunctionName == "GetTextSentiment"){
	modelerData <- cbind(resultData,modelerData)
	varScore <- c(fieldName= "score" ,fieldLabel="",fieldStorage="real",fieldMeasure="",fieldFormat="",  fieldRole="")
	varType <- c(fieldName= "type" ,fieldLabel="",fieldStorage="string",fieldMeasure="",fieldFormat="",  fieldRole="")
	modelerDataModel <- data.frame(varScore,varType, modelerDataModel)
}else if(sFunctionName == "GetRankedNamedEntities"){
	modelerData <- resultData #have joined when process data
	varText <- c(fieldName= "text" ,fieldLabel="",fieldStorage="string",fieldMeasure="",fieldFormat="",  fieldRole="")
	varType <- c(fieldName= "type" ,fieldLabel="",fieldStorage="string",fieldMeasure="",fieldFormat="",  fieldRole="")
	varRelevance <- c(fieldName= "relevance" ,fieldLabel="",fieldStorage="real",fieldMeasure="",fieldFormat="",  fieldRole="")
	varCount <- c(fieldName= "count" ,fieldLabel="",fieldStorage="real",fieldMeasure="",fieldFormat="",  fieldRole="")
	varSentimentType <- c(fieldName= "sentiment.type" ,fieldLabel="",fieldStorage="string",fieldMeasure="",fieldFormat="",  fieldRole="")
	varSentimentScore <- c(fieldName= "sentiment.score" ,fieldLabel="",fieldStorage="real",fieldMeasure="",fieldFormat="",  fieldRole="")
	valContent <- c(fieldName= "content" ,fieldLabel="",fieldStorage="string",fieldMeasure="",fieldFormat="",  fieldRole="")
	modelerDataModel <- data.frame(varText, varType, varRelevance, varCount, varSentimentType, varSentimentScore, valContent)	
}

