//+------------------------------------------------------------------+
//|                                                    RangeFinder.mq5 |
//|                                               Houtan Alinaghi |
//|                                          https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Houtan Alinaghi"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>;
CTrade trade;



input double lot=0.01;
input long magicNumber=1234;
input int rangeStart = 600; 
input int rangeDuration=120;
input int rangeClose=1200;

struct RANGE_STRUCT {
   datetime startTime;
   datetime endTime;
   datetime closeTime;
   double high;
   double low;
   bool f_entry;
   bool f_high_breakout;
   bool f_low_breakout;

   RANGE_STRUCT() :
      startTime(0),
      endTime(0),
      closeTime(0),
      high(0),
      low(99999),
      f_entry(false),
      f_high_breakout(false),
      f_low_breakout(false)
   {};
};

RANGE_STRUCT range;
MqlTick prevTick,lastTick;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{

   if(_UninitReason==REASON_PARAMETERS)
     {
      CalculateRange();
     }
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(NULL,"range");  
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   prevTick = lastTick;
   SymbolInfoTick(_Symbol,lastTick);

   if(rangeClose >=0 && lastTick.time >= range.closeTime
      || (range.f_high_breakout && range.f_low_breakout)
      ||(range.endTime==0)
      ||(range.endTime!=0 && lastTick.time>range.endTime && !range.f_entry)) {
      CalculateRange();
   }
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateRange()
{
   range.startTime = 0;
   range.endTime = 0;
   range.closeTime = 0;
   range.high = 0.0;
   range.low = 999999;
   range.f_entry = false;
   range.f_high_breakout = false;
   range.f_low_breakout=false;

   int timeCycle = 86400;
   range.startTime = (lastTick.time - (lastTick.time % timeCycle)) + rangeStart*60;
   for(int i=0; i<8; i++) {
      MqlDateTime tmp;
      TimeToStruct(range.startTime,tmp);
      int dow = tmp.day_of_week;
      if(lastTick.time>=range.startTime || dow==6 || dow==0) {
         range.startTime += timeCycle;
      }
   }

   range.endTime = range.startTime + rangeDuration*60;
   for(int i=0; i<2; i++) {
      MqlDateTime tmp;
      TimeToStruct(range.endTime,tmp);
      int dow = tmp.day_of_week;
      if(dow==6 || dow==0) {
         range.endTime += timeCycle;
      }
   }

   range.closeTime = (range.endTime - (range.endTime % timeCycle)) + rangeClose * 60;
   for(int i=0; i<3; i++) {
      MqlDateTime tmp;
      TimeToStruct(range.closeTime,tmp);
      int dow = tmp.day_of_week;
      if(range.closeTime<=range.endTime || dow==6 || dow==0) {
         range.closeTime += timeCycle;
      }
   }

   DrawObjects();
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawObjects()
{
   //start time
   ObjectDelete(NULL,"range start");
   if(range.startTime>0) {
      ObjectCreate(NULL,"range start",OBJ_VLINE,0,range.startTime,0);
      ObjectSetString(NULL,"range start",OBJPROP_TOOLTIP,"start of the range \n"+TimeToString(range.startTime,TIME_DATE|TIME_MINUTES));
      ObjectSetInteger(NULL,"range start",OBJPROP_COLOR,clrBlue);
      ObjectSetInteger(NULL,"range start",OBJPROP_WIDTH,2);
      ObjectSetInteger(NULL,"range start",OBJPROP_BACK,true);
   }

   //end time
   ObjectDelete(NULL,"range end");
   if(range.endTime>0) {
      ObjectCreate(NULL,"range end",OBJ_VLINE,0,range.endTime,0);
      ObjectSetString(NULL,"range end",OBJPROP_TOOLTIP,"end of the range \n"+TimeToString(range.endTime,TIME_DATE|TIME_MINUTES));
      ObjectSetInteger(NULL,"range end",OBJPROP_COLOR,clrDarkBlue);
      ObjectSetInteger(NULL,"range end",OBJPROP_WIDTH,2);
      ObjectSetInteger(NULL,"range end",OBJPROP_BACK,true);
   }

   //close start
   ObjectDelete(NULL,"range close");
   if(range.closeTime>0) {
      ObjectCreate(NULL,"range close",OBJ_VLINE,0,range.closeTime,0);
      ObjectSetString(NULL,"range close",OBJPROP_TOOLTIP,"close of the range \n"+TimeToString(range.closeTime,TIME_DATE|TIME_MINUTES));
      ObjectSetInteger(NULL,"range close",OBJPROP_COLOR,clrRed);
      ObjectSetInteger(NULL,"range close",OBJPROP_WIDTH,2);
      ObjectSetInteger(NULL,"range close",OBJPROP_BACK,true);
   }
}
//+------------------------------------------------------------------+
