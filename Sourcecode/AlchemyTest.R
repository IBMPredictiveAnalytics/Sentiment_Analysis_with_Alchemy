sFeatureColumns <- "text"
sSourceType <- "text"
sApiKey <- "159fa5a9b1c09a70340058b3968016bc0d0a0298"


#fake data for test
textData <- c("hello can you believe i hate iphones so much, it's expensive but it's not awesome",
	"Could you please take a look this performance issue?",
	"We have only less than 3 days to go before close of the 2016 Global Integrity Survey on this Sunday night. So far we have only achieved 20% response. ")
modelerData <- data.frame(text=textData)
textData <- modelerData[,sFeatureColumns]
sFunctionName <- "GetTextSentiment"
resultData <- lapply(textData, FUN=retriveFromAlchemy, 
	sSourceType="text", sFunctionName=sFunctionName,
	funProcessResult=generateProcessFunction(sFunctionName))
resultData <- ldply (resultData, data.frame)

sFunctionName <- "GetRankedNamedEntities"
resultData <- lapply(textData, FUN=retriveFromAlchemy, 
	sSourceType="text", sFunctionName=sFunctionName,
	funProcessResult=generateProcessFunction(sFunctionName))
resultData <- ldply (resultData, data.frame)

urlData <- c(
    "http://www.dailymail.co.uk/sciencetech/article-2355833/Apples-iPhone-5-hated-handset--majority-people-love-Samsung-Galaxy-S4-study-finds.html",
	"http://www.washingtonpost.com/blogs/capital-weather-gang/wp/2013/08/14/d-c-area-forecast-ultra-nice-weather-dominates-next-few-days/"
	)
modelerData <- data.frame(text=urlData)
urlData <- modelerData[,sFeatureColumns]
sFunctionName <- "GetRankedNamedEntities"
resultData <- lapply(urlData, FUN=retriveFromAlchemy, 
	sSourceType="url", sFunctionName=sFunctionName,
	funProcessResult=generateProcessFunction(sFunctionName))
resultData <- ldply (resultData, data.frame)

sFunctionName <- "GetTextSentiment"
resultData <- lapply(urlData, FUN=retriveFromAlchemy, 
	sSourceType="url", sFunctionName=sFunctionName,
	funProcessResult=generateProcessFunction(sFunctionName))
resultData <- ldply (resultData, data.frame)