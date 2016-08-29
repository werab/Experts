//+------------------------------------------------------------------+
//|                                        MyFirstExpertsAdvisor.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define MAGICMA  3443

input int iPadAmount = 40;
input int iTrailStop = 40;
input int iSLPeriodLookback = 180; // periods
input int iMaxTickDistance = 1000;

int iSLTimeFrame = PERIOD_D1;
int iDropGrothLookback = 5;

int iTS;
double dShift;
//string sIndicatorName = "RandomTime";
string sIndicatorName = "EURUSDmicroIndicator_01";
//string sIndicatorName = "RandomTimeWithTrend";
double LotSize = 0.1;
bool bOrderPerDay = false;

static int MAX_SL_SAFETY = 5000;

static int SELL = -1;
static int BUY = 1;

////////////////////////////////
// Todo List:
//
// indicator:
//  - moving average
//  - find large changes last days


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   if(!(Digits==3 || Digits==5)){
      Alert("This Broker only trades "+ (string)Digits +" Digits!");
      return(INIT_FAILED);
   }

   iTS = (int)MathMax(MarketInfo(Symbol(), MODE_STOPLEVEL), iTrailStop);

   dShift = (iTS + iPadAmount)*Point;

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {


  }

bool IsNewCandle(){
   static int BarsOnChard = 0;
   if (Bars == BarsOnChard)
      return false;
   BarsOnChard = Bars;
   return true;
}

double ND(double val)
{
   return(NormalizeDouble(val, Digits));
}

int OpenOrderThisPair(string pair){
   int total = 0;
   for (int i=OrdersTotal()-1; i>=0; i--){
      bool ret = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if(ret && OrderSymbol() == pair) total++;
   }
   return (total);
}

double getBuySL(){
  int val_index = iLowest(NULL,iSLTimeFrame,MODE_LOW,iSLPeriodLookback,0);
  if(val_index != -1) {
     return ND(Low[val_index]-(iPadAmount*Point));
  }

  return ND(Bid - (MAX_SL_SAFETY * Point));
}

double getSellSL(){
  int val_index = iHighest(NULL,iSLTimeFrame,MODE_HIGH,iSLPeriodLookback,0);
  if(val_index != -1) {
     return ND(High[val_index]+(iPadAmount*Point));
  }

  return ND(Ask + (MAX_SL_SAFETY * Point));
}

bool noLargeDropOrGroth(){
  int high_idx = iHighest(NULL,iSLTimeFrame,MODE_HIGH,iDropGrothLookback,0);
  int low_idx = iLowest(NULL,iSLTimeFrame,MODE_LOW,iDropGrothLookback,0);

  if (high_idx != -1 && low_idx != -1)
    if (High[high_idx] - Low[low_idx] < iMaxTickDistance*Point)
      return true;

  return false;
}

void ModifyOrders(){
   for (int o=OrdersTotal()-1; o >=0; o--) {
      if (OrderSelect(o, SELECT_BY_POS, MODE_TRADES))
      if (OrderMagicNumber() == MAGICMA)
      if (OrderSymbol() == Symbol())
      if (OrderType() == OP_BUY){
         if (OrderOpenPrice() < Bid - dShift){
            bool success = false;
            if (OrderStopLoss() < Bid - dShift)
            {
               double _sl = ND(Bid - (iTS*Point));
               Print("Try to change SL to: "+ (string)_sl + " Bid: "+ (string)Bid);
               success = OrderModify(OrderTicket(), OrderOpenPrice(), _sl, OrderTakeProfit(), 0, clrMintCream);
               if (!success){
                  int lErr = GetLastError();
                  Print("OrderModify LastError: "+(string)lErr);
                  ResetLastError();
               }
            }
         }
      } else if (OrderType() == OP_SELL){
         if (OrderOpenPrice() > Ask + dShift){
            bool success = false;
            if (OrderStopLoss() > Ask + dShift)
            {
               double _sl = ND(Ask + (iTS*Point));
               Print("Try to change SL to: "+ (string)_sl + " Ask: "+(string)Ask);
               success = OrderModify(OrderTicket(), OrderOpenPrice(), _sl, OrderTakeProfit(), 0, clrMintCream);
               if (!success){
                  int lErr = GetLastError();
                  Print("OrderModify LastError: "+(string)lErr);
                  ResetLastError();
               }
            }
         }
      }
   }
}

int IndicateTrade()
{
   return (int)iCustom(NULL, PERIOD_D1, sIndicatorName, PRICE_CLOSE,0);
}


int OrderEntry(int trade){
   if (trade == BUY){
      int ticket = OrderSend(Symbol(), OP_BUY, LotSize, Ask, 3, 0, 0, NULL, MAGICMA, 0, clrGreen);
      int lErr = GetLastError();
      Print("OrderBUY ticket: "+(string)ticket+ " LastError: "+(string)lErr);
      ResetLastError();

      if (ticket>0) {
         double _sl = getBuySL();
         Print("Try to modify BUY StopLoss to:" + (string)_sl);
         bool success = OrderModify(ticket, OrderOpenPrice(), _sl, 0, 0, clrGreen);
         if (!success){
            lErr = GetLastError();
            Print("OrderModify LastError: "+(string)lErr);
            ResetLastError();
         }
      }
   }

   if (trade == SELL) {
      int ticket = OrderSend(Symbol(), OP_SELL, LotSize, Bid, 3, 0, 0, NULL, MAGICMA, 0, clrBlue);
      int lErr = GetLastError();
      Print("OrderSELL ticket: "+(string)ticket+ " LastError: "+(string)lErr);
      ResetLastError();

      if (ticket>0) {
         double _sl = getSellSL();
         Print("Try to modify SELL StopLoss to:" + (string)_sl);
         bool success = OrderModify(ticket, OrderOpenPrice(), _sl, 0, 0, clrBlue);
         if (!success){
            lErr = GetLastError();
            Print("OrderModify LastError: "+(string)lErr);
            ResetLastError();
         }
      }
   }

   return -1;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

//---
   if (IsNewCandle()) bOrderPerDay = true;

//      if (noLargeDropOrGroth()){
   int trade = IndicateTrade();
   if (trade != 0 && bOrderPerDay){
      int ret = OrderEntry(trade);
      bOrderPerDay = false;
   }
//      }
      ModifyOrders();
//   }

  }
//+------------------------------------------------------------------+
