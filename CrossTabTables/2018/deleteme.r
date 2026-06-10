go<-function(mySurveyObject, myVariables, myPopMargins){
  #myVariables<-enquo(myVariables)

  t_rake<-rake(design=mySurveyObject,
               sample.margins=myVariables,
               population.margins=myPopMargins)
  return(t_rake)
}


mySurveyObject=svyObject
myVariables="E3"
myPopMargins=ageDist
go(svyObject, list(~E3), list(ageDist))
