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
input int rangeStart = 1300;
input int rangeDuration=500;
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
      low(999999),
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

   trade.SetExpertMagicNumber(magicNumber);

   if(_UninitReason==REASON_PARAMETERS) {
      CalculateRange();
   }
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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


   if(lastTick.time >= range.startTime && lastTick.time < range.endTime) {
      range.f_entry = true;

      if(lastTick.ask > range.high) {
         range.high = lastTick.ask;
         DrawObjects();
      }

      if(lastTick.bid < range.low) {
         range.low = lastTick.bid;
         DrawObjects();
      }
   }

   if(lastTick.time >= range.closeTime) {
      if(!ClosePosition()) {
         return;
      }
   }

   if(((rangeClose >=0 && lastTick.time >= range.closeTime
        || (range.f_high_breakout && range.f_low_breakout)
        ||(range.endTime==0)
        ||(range.endTime!=0 && lastTick.time>range.endTime && !range.f_entry))
       && countOpenPosition()==0)) {

      CalculateRange();
   }

   CheckBreakout();
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

   //high
   ObjectDelete(NULL,"range high");
   if(range.high>0) {
      ObjectCreate(NULL,"range high",OBJ_TREND,0,range.startTime,range.high,range.endTime,range.high);
      ObjectSetString(NULL,"range high",OBJPROP_TOOLTIP,"high of the range \n"+DoubleToString(range.high,_Digits));
      ObjectSetInteger(NULL,"range high",OBJPROP_COLOR,clrBlue);
      ObjectSetInteger(NULL,"range high",OBJPROP_WIDTH,2);
      ObjectSetInteger(NULL,"range high",OBJPROP_BACK,true);

      ObjectCreate(NULL,"range high ",OBJ_TREND,0,range.endTime,range.high,range.closeTime,range.high);
      ObjectSetString(NULL,"range high ",OBJPROP_TOOLTIP,"high of the range \n"+DoubleToString(range.high,_Digits));
      ObjectSetInteger(NULL,"range high ",OBJPROP_COLOR,clrBlue);
      ObjectSetInteger(NULL,"range high ",OBJPROP_STYLE,STYLE_DOT);
      ObjectSetInteger(NULL,"range high ",OBJPROP_BACK,true);
   }

   //low
   ObjectDelete(NULL,"range low");
   if(range.low<999999) {
      ObjectCreate(NULL,"range low",OBJ_TREND,0,range.startTime,range.low,range.endTime,range.low);
      ObjectSetString(NULL,"range low",OBJPROP_TOOLTIP,"low of the range \n"+DoubleToString(range.low,_Digits));
      ObjectSetInteger(NULL,"range low",OBJPROP_COLOR,clrBlue);
      ObjectSetInteger(NULL,"range low",OBJPROP_WIDTH,2);
      ObjectSetInteger(NULL,"range low",OBJPROP_BACK,true);

      ObjectCreate(NULL,"range low ",OBJ_TREND,0,range.endTime,range.low,range.closeTime,range.low);
      ObjectSetString(NULL,"range low ",OBJPROP_TOOLTIP,"high of the range \n"+DoubleToString(range.high,_Digits));
      ObjectSetInteger(NULL,"range low ",OBJPROP_COLOR,clrBlue);
      ObjectSetInteger(NULL,"range low ",OBJPROP_STYLE,STYLE_DOT);
      ObjectSetInteger(NULL,"range low ",OBJPROP_BACK,true);
   }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void CheckBreakout()
{
   if(lastTick.time >= range.endTime && range.endTime>0 && range.f_entry) {

      if(!range.f_high_breakout && lastTick.ask >= range.high) {
         range.f_high_breakout = true;

         trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,lot,lastTick.ask,0,0,"BUY");
      }

      if(!range.f_low_breakout && lastTick.bid <= range.low) {
         range.f_low_breakout=true;

         trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,lot,lastTick.bid,0,0,"SELL");
      }

   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ClosePosition()
{

   int total = PositionsTotal();
   for(int i=total; i>0; i--) {
      if(total != PositionsTotal()) {
         total = PositionsTotal();
         i = total;
         continue;
      }

      ulong ticket = PositionGetTicket(i);
      if(ticket<=0) {
         Print("Faild to get position ticket");
         return false;
      }
      if(!PositionSelectByTicket(ticket)) {
         Print("Failed to get position ticket");
         return false;
      }
      long magicnumber;
      if(!PositionGetInteger(POSITION_MAGIC,magicnumber)) {
         Print("Failed to get position magicnumber");
         return false;
      }
      if(magicnumber == magicNumber) {
         trade.PositionClose(ticket);
         if(trade.ResultRetcode() != TRADE_RETCODE_DONE) {
            Print("Failed to close position. result: " + (string)trade.ResultRetcode()+":"+trade.ResultRetcodeDescription());
            return false;
         }
      }
   }
   return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int countOpenPosition()
{
   int counter = 0;
   int total = PositionsTotal();
   for(int i=total;i>0;i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)){Print("Failed to select position by ticket");return -1;}
      ulong magicnumber;
      if(!PositionGetInteger(POSITION_MAGIC,magicnumber))
        {Print("Failed to get position magicnumber");return -1;}
      if(magicNumber == magicnumber)
        {
         counter++;
        }
     }

   return counter;
}
//+------------------------------------------------------------------+
