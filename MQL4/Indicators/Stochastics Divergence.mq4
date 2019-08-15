//+------------------------------------------------------------------+
//|                                       Stochastics Divergence.mq4 |
//|                                                  The Lazy Trader |
//|                                   http://www.the-lazy-trader.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2012, The lazy trader"
#property link      "the-lazy-trader.com"
//----
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_color1 Green
#property indicator_color2 Red
#property indicator_color3 LightSeaGreen
#property indicator_color4 Orange
#property indicator_level1 20
#property indicator_level2 80
#property indicator_minimum 0
#property indicator_maximum 100

//----
#define arrowsDisplacement 0.0003
//---- input parameters
extern string StochasticSettings = "*** Stochastics Settings ***";
extern int    kPeriod = 8;
extern int    dPeriod = 3;
extern int    slowing = 3;
extern string IndicatorSettings = "*** Indicator Settings ***";
extern bool   drawIndicatorTrendLines = true;
extern bool   drawPriceTrendLines = true;
extern bool   displayAlert = true;
extern bool   DisplayClassicalDivergences = true;
extern bool   DisplayHiddenDivergences = true;
//---- buffers
double bullishDivergence[];
double bearishDivergence[];
double mainLine[];
double signalLine[];
double divergencesType[];
double divergencesStochasticsDiff[];
double divergencesPriceDiff[];

//----
static datetime lastAlertTime;
static string   indicatorName;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   SetIndexStyle(0, DRAW_ARROW);
   SetIndexStyle(1, DRAW_ARROW);
   SetIndexStyle(2, DRAW_LINE);
   SetIndexStyle(3, DRAW_LINE);

//----   
   SetIndexBuffer(0, bullishDivergence);
   SetIndexBuffer(1, bearishDivergence);
   SetIndexBuffer(2, mainLine);
   SetIndexBuffer(3, signalLine);   
   
   SetIndexBuffer(4, divergencesType);   
   SetIndexBuffer(5, divergencesStochasticsDiff);   
   SetIndexBuffer(6, divergencesPriceDiff);   
//----   
   SetIndexArrow(0, 233);
   SetIndexArrow(1, 234);
//----
   indicatorName = "Stochastics_Divergence_(" + kPeriod + ", " + dPeriod + ", " + slowing + ")";
   SetIndexDrawBegin(3, kPeriod);
   IndicatorDigits(Digits + 2);
   IndicatorShortName(indicatorName);

   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
    for(int i = ObjectsTotal() - 1; i >= 0; i--)
    {
        string label = ObjectName(i);
        if(StringSubstr(label, 0, 26) != "Stochastics_DivergenceLine")
            continue;
        ObjectDelete(label);   
    }
     
    return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{
   int countedBars = IndicatorCounted();
   if (countedBars < 0)
       countedBars = 0;
   CalculateIndicator(countedBars);   
   return(0);
}



void CalculateIndicator(int countedBars)
{
    for(int i = Bars - countedBars; i >= 0; i--)
    {
        CalculateStochastics(i);
        CatchBullishDivergence(i + 2);
        CatchBearishDivergence(i + 2);
    }              
}



void CalculateStochastics(int i)
{
    mainLine[i] = iStochastic(NULL, 0, kPeriod, dPeriod, slowing, MODE_SMA, 0, MODE_MAIN, i);
    signalLine[i] = iStochastic(NULL, 0, kPeriod, dPeriod, slowing, MODE_SMA, 0, MODE_SIGNAL, i);         
}



void CatchBullishDivergence(int shift)
{
    if(IsIndicatorTrough(shift) == false)
        return;  
        
    int currentTrough = shift;
    int lastTrough = GetIndicatorLastTrough(shift);

    //--CLASSIC DIVERGENCE--//
    if (DisplayClassicalDivergences == true)
    {
        if(mainLine[currentTrough] > mainLine[lastTrough] && Low[currentTrough] < Low[lastTrough])
        {
            bullishDivergence[currentTrough] = mainLine[currentTrough] - arrowsDisplacement;
       
            divergencesType[currentTrough] = 1; //"Classic Bullish";
            divergencesStochasticsDiff[currentTrough] = MathAbs(mainLine[currentTrough] - mainLine[lastTrough]);
            divergencesPriceDiff[currentTrough] = MathAbs(Low[currentTrough] - Low[lastTrough]);
        
            if(drawPriceTrendLines == true)
                DrawPriceTrendLine(Time[currentTrough], Time[lastTrough], 
                                   Low[currentTrough], 
                                   Low[lastTrough], Green, STYLE_SOLID);
       
            if(drawIndicatorTrendLines == true)
                DrawIndicatorTrendLine(Time[currentTrough], 
                                       Time[lastTrough], 
                                       mainLine[currentTrough],
                                       mainLine[lastTrough], 
                                       Green, STYLE_SOLID);
                                       
                                       
       
            if(displayAlert == true)
                DisplayAlert("Classical Stochastics bullish divergence on: ", currentTrough);  
        }
    }
   //-----HIDDEN DIVERGENCE--//
   if (DisplayHiddenDivergences == true)
   {
       if (mainLine[currentTrough] < mainLine[lastTrough] && Low[currentTrough] > Low[lastTrough])
       {
           bullishDivergence[currentTrough] = mainLine[currentTrough] - arrowsDisplacement;
           
           divergencesType[currentTrough] = 2; //"Hidden Bullish";
           divergencesStochasticsDiff[currentTrough] = MathAbs(mainLine[currentTrough] - mainLine[lastTrough]);
           divergencesPriceDiff[currentTrough] = MathAbs(Low[currentTrough] - Low[lastTrough]);
               
           if(drawPriceTrendLines == true)
               DrawPriceTrendLine(Time[currentTrough], Time[lastTrough], 
                                  Low[currentTrough], 
                                  Low[lastTrough], Green, STYLE_DOT);

           if(drawIndicatorTrendLines == true)                            
               DrawIndicatorTrendLine(Time[currentTrough], 
                                      Time[lastTrough], 
                                      mainLine[currentTrough],
                                      mainLine[lastTrough], 
                                      Green, STYLE_DOT);

           if(displayAlert == true)
               DisplayAlert("Hidden Stochastics bullish divergence on: ", currentTrough);   
        } 
    }     
}



void CatchBearishDivergence(int shift)
{
    if(IsIndicatorPeak(shift) == false)
        return;
    int currentPeak = shift;
    int lastPeak = GetIndicatorLastPeak(shift);

    //-- CLASSIC DIVERGENCE --//
    if (DisplayClassicalDivergences == true)
    {
        if(mainLine[currentPeak] < mainLine[lastPeak] && High[currentPeak] > High[lastPeak])
        {
            bearishDivergence[currentPeak] = mainLine[currentPeak] + arrowsDisplacement;
        
            divergencesType[currentPeak] = 3; //"Classic Bearish";
            divergencesStochasticsDiff[currentPeak] = MathAbs(mainLine[currentPeak] - mainLine[lastPeak]);
            divergencesPriceDiff[currentPeak] = MathAbs(Low[currentPeak] - Low[lastPeak]);
      
            if(drawPriceTrendLines == true)
                DrawPriceTrendLine(Time[currentPeak], Time[lastPeak], 
                                   High[currentPeak], 
                                   High[lastPeak], Red, STYLE_SOLID);
                            
           if(drawIndicatorTrendLines == true)
               DrawIndicatorTrendLine(Time[currentPeak], Time[lastPeak], 
                                      mainLine[currentPeak],
                                      mainLine[lastPeak], Red, STYLE_SOLID);

           if(displayAlert == true)
               DisplayAlert("Classical Stochastics bearish divergence on: ", currentPeak);  
         }
     }
     
     //----HIDDEN DIVERGENCE----//
     if (DisplayHiddenDivergences == true)
     {
         if(mainLine[currentPeak] > mainLine[lastPeak] && High[currentPeak] < High[lastPeak])
         {
              bearishDivergence[currentPeak] = mainLine[currentPeak] + arrowsDisplacement;
              
              divergencesType[currentPeak] = 4;//"Hidden Bearish";
              divergencesStochasticsDiff[currentPeak] = MathAbs(mainLine[currentPeak] - mainLine[lastPeak]);
              divergencesPriceDiff[currentPeak] = MathAbs(Low[currentPeak] - Low[lastPeak]);
        
              if(drawPriceTrendLines == true)
                  DrawPriceTrendLine(Time[currentPeak], Time[lastPeak], 
                                     High[currentPeak], 
                                     High[lastPeak], Red, STYLE_DOT);
       
              if(drawIndicatorTrendLines == true)
                  DrawIndicatorTrendLine(Time[currentPeak], Time[lastPeak], 
                                         mainLine[currentPeak],
                                         mainLine[lastPeak], Red, STYLE_DOT);
   
              if(displayAlert == true)
                  DisplayAlert("Hidden Stochastics bearish divergence on: ", currentPeak);   
         }   
     }
}



bool IsIndicatorPeak(int shift)
{
    if(mainLine[shift] >= mainLine[shift+1] && mainLine[shift] > mainLine[shift+2] && mainLine[shift] > mainLine[shift-1])
        return(true);
    else 
        return(false);
}



bool IsIndicatorTrough(int shift)
{
    if(mainLine[shift] <= mainLine[shift+1] && mainLine[shift] < mainLine[shift+2] && mainLine[shift] < mainLine[shift-1])
        return(true);
    else 
        return(false);
}



int GetIndicatorLastPeak(int shift)
{
    for(int i = shift + 5; i < Bars; i++)
     {
       if(mainLine[i] >= mainLine[i+1] && mainLine[i] >= mainLine[i+2] &&
          mainLine[i] >= mainLine[i-1] && mainLine[i] >= mainLine[i-2])
         {
             return(i);
         }
     }
     return(-1);
}



int GetIndicatorLastTrough(int shift)
{
    for(int i = shift + 5; i < Bars; i++)
      {
        if(mainLine[i] <= mainLine[i+1] && mainLine[i] <= mainLine[i+2] &&
           mainLine[i] <= mainLine[i-1] && mainLine[i] <= mainLine[i-2])
          {
              return(i);
              
          }
      }
    return(-1);
}



void DisplayAlert(string message, int shift)
{
    if(shift <= 2 && Time[shift] != lastAlertTime)
    {
        lastAlertTime = Time[shift];
        Alert(message, Symbol(), " , ", Period(), " minutes chart");
    }
}



void DrawPriceTrendLine(datetime x1, datetime x2, double y1, double y2, color lineColor, double style)
{
    string label = "Stochastics_DivergenceLine_v1# " + DoubleToStr(x1, 0);
    ObjectDelete(label);
    ObjectCreate(label, OBJ_TREND, 0, x1, y1, x2, y2, 0, 0);
    ObjectSet(label, OBJPROP_RAY, 0);
    ObjectSet(label, OBJPROP_COLOR, lineColor);
    ObjectSet(label, OBJPROP_STYLE, style);
}



void DrawIndicatorTrendLine(datetime x1, datetime x2, double y1, double y2, color lineColor, double style)
{
    int indicatorWindow = WindowFind(indicatorName);
    if(indicatorWindow < 0)
        return;
    string label = "Stochastics_DivergenceLine_v1$# " + DoubleToStr(x1, 0);
    ObjectDelete(label);
    ObjectCreate(label, OBJ_TREND, indicatorWindow, x1, y1, x2, y2, 0, 0);
    ObjectSet(label, OBJPROP_RAY, 0);
    ObjectSet(label, OBJPROP_COLOR, lineColor);
    ObjectSet(label, OBJPROP_STYLE, style);
}