captions<-list()
tables<-list()
lstAppendixes<-list()
lstAppendixes$captions<-list()
lstAppendixes$tables<-list()
rm(captions)
rm(tables)

lstAppendixes$intNextAppendixNumber<-1


lstAppendixes$addTable<-function(myTable, myAppendixNumber){
  lstAppendixes$tables[[myAppendixNumber]]<<-myTable
}

lstAppendixes$addCaption<-function(myCaption, myAppendixNumber){
  lstAppendixes$captions[[myAppendixNumber]]<<-paste("Appendix - ", myAppendixNumber, ".  ", myCaption, sep="")
  print(lstAppendixes$captions[[myAppendixNumber]])
}

lstAppendixes$addAppendix<-function(myCaption, myTable, myAppendixNumber=lstAppendixes$intNextAppendixNumber) {
  lstAppendixes$addCaption(myCaption, myAppendixNumber)
  lstAppendixes$addTable(myTable, myAppendixNumber)
  lstAppendixes$intNextAppendixNumber<<-lstAppendixes$intNextAppendixNumber + 1
}

lstAppendixes$printAppendixes<-function(){
  for(i in 1:(length(lstAppendixes$captions))) {
    cat(lstAppendixes$captions[[i]])
    print(lstAppendixes$tables[[i]])
  }
}
  
