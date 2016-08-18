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

input int StopLoss = 10;
input int PadAmount = 1;
input int TrailStop = 1;
input int TakeProfitFactor = 3;

double LotSize = 0.1;
double pt;
double StopLevel;
double TS;
int TakeProfit = StopLoss * TakeProfitFactor;

static int SELL = -1;
static int BUY = 1;

////////////////////////////////
// Todo List:
// BreakEven checken

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   if(Digits==3 || Digits==5) pt=10*Point;   else   pt=Point;

   StopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL);
   TS = (MathMax(StopLevel, TrailStop*10))/10;

   Shift = TS + PadAmount;

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

void ModifyOrders(){
   for (int o=OrdersTotal()-1; o >=0; o--) {
      if (OrderSelect(o, SELECT_BY_POS, MODE_TRADES))
      if (OrderMagicNumber() == MAGICMA)
      if (OrderSymbol() == Symbol())
      if (OrderType() == OP_BUY){
         if (OrderOpenPrice() < Bid - Shift){
            bool success = false;
            if (OrderStopLoss() < Bid - Shift)
            {
               double _sl = ND(Bid - (TS*pt));
               Print("Try to change SL to: "+ (string)_sl + " Bid: "+ (string)Bid);
               success = OrderModify(OrderTicket(), OrderOpenPrice(), _sl, OrderTakeProfit(), 0, clrMintCream);
               if (!success){
                  int lErr = GetLastError();
                  Print("OrderModify LastError: "+(string)lErr);
                  ResetLastError();
               } else {
                  Print("Bid: "+(string)Bid+" - Shift: "+ (string)Shift + " = _sl:  "+ (string)_sl +" Orders Open: "+ (string)OrdersTotal() + " Orders Saved:"+ (string)(OrdersSaved+1));
               }
            }
         } 
      } else if (OrderType() == OP_SELL){
         if (OrderOpenPrice() > Ask + Shift){
            bool success = false;
            if (OrderStopLoss() > Ask + Shift)
            {
               double _sl = ND(Ask + (TS*pt));
               Print("Try to change SL to: "+ (string)_sl + " Ask: "+(string)Ask);
               success = OrderModify(OrderTicket(), OrderOpenPrice(), _sl, OrderTakeProfit(), 0, clrMintCream);
               if (!success){
                  int lErr = GetLastError();
                  Print("OrderModify LastError: "+(string)lErr);
                  ResetLastError();
               } else {
                  Print("Ask: "+(string)Ask+" + Shift: "+ (string)Shift + " = _sl:  "+ (string)_sl +" Orders Open: "+ (string)OrdersTotal() + " Orders Saved:"+ (string)(OrdersSaved+1));
               }
            }
         }
      }
   }
}

int IndicateTrade()
{
   datetime dt = TimeCurrent();
   if (TimeMinute(dt) == 0 && allowBUYTrade){
      allowBUYTrade = false;
      return BUY;
   }

   if (TimeMinute(dt) == 5) allowBUYTrade = true;

   if (TimeMinute(dt) == 30 && allowSELLTrade) {
      allowSELLTrade = false;
      return SELL;
   }

   if (TimeMinute(dt) == 35) allowSELLTrade = true;

   return 0;
}
  
/* int IndicateTrade()
{
   double previousFast = iMA(NULL,0,FastMa,FastMaShift, FastMaMethod, FastMaAppliedTo, 2);
   double currentFast = iMA(NULL,0,FastMa,FastMaShift, FastMaMethod, FastMaAppliedTo, 1);
   double previousSlow = iMA(NULL,0,SlowMa,SlowMaShift, SlowMaMethod, SlowMaAppliedTo, 2);
   double currentSlow = iMA(NULL,0,SlowMa,SlowMaShift, SlowMaMethod, SlowMaAppliedTo, 1);
   
   if (previousFast<previousSlow && currentFast>currentSlow){
      
      if (CurrentCandlesSinceLastMaSwap > MinCandlesBeforeTradeSignal) {
         CurrentCandlesSinceLastMaSwap = 0; // reset
         return BUY;
      }
      CurrentCandlesSinceLastMaSwap = 0; // reset
   }
   
   if (previousFast>previousSlow && currentFast<currentSlow) {
      if (CurrentCandlesSinceLastMaSwap > MinCandlesBeforeTradeSignal) {
         CurrentCandlesSinceLastMaSwap = 0; // reset
         return SELL;
      }
      CurrentCandlesSinceLastMaSwap = 0; // reset
   }
   CurrentCandlesSinceLastMaSwap++;
      
   return 0;
}*/

int returnRequestedOrderCount(int orderType){
   int c = 0;
   for (int o=OrdersTotal()-1; o >=0; o--) {
      if (OrderSelect(o, SELECT_BY_POS, MODE_TRADES))
      if (OrderMagicNumber() == MAGICMA)
      if (OrderSymbol() == Symbol())
      if (OrderType() == orderType){
         c++;
      }
   }
   return c;
}
  
int OrderEntry(int trade){
//   if (trade == BUY){
   if (trade == BUY && returnRequestedOrderCount(OP_BUY) < MaxBuyOrders){
      int ticket = OrderSend(Symbol(), OP_BUY, LotSize, Ask, 3, 0, 0, NULL, MAGICMA, 0, clrGreen);
      int lErr = GetLastError();
      Print("OrderBUY ticket: "+(string)ticket+ " LastError: "+(string)lErr);
      ResetLastError();
      
      if (ticket>0) {
         double _sl = ND(Ask-(StopLoss*pt));
         double _tp = ND(Ask+(TakeProfit*pt));
         Print("Try to modify BUY StopLoss to:" + (string)_sl + " modify TakeProfit to: "+ (string)_tp);
         bool success = OrderModify(ticket, OrderOpenPrice(), _sl, _tp, 0, clrYellow);
         if (!success){
            lErr = GetLastError();
            Print("OrderModify LastError: "+(string)lErr);
            ResetLastError();
         }
      }
   }
   
//   if (trade == SELL) {
   if (trade == SELL && returnRequestedOrderCount(OP_SELL) < MaxSellOrders) {
      int ticket = OrderSend(Symbol(), OP_SELL, LotSize, Bid, 3, 0, 0, NULL, MAGICMA, 0, clrBlue);
      int lErr = GetLastError();
      Print("OrderSELL ticket: "+(string)ticket+ " LastError: "+(string)lErr);
      ResetLastError();
      
      if (ticket>0) {
         double _sl = ND(Bid+(StopLoss*pt));
         double _tp = ND(Bid-(TakeProfit*pt));
//         double _tp = 0;
         Print("Try to modify SELL StopLoss to:" + (string)_sl + " modify TakeProfit to: "+ (string)_tp);
         bool success = OrderModify(ticket, OrderOpenPrice(), _sl, _tp, 0, clrYellow);
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
   Comment("LotSize is: " + (string) LotSize + "\n"+
           "Orders Open: "+ (string) OrdersTotal() + " / Orders Max: " + (string)(MaxBuyOrders + MaxSellOrders) +"\n"+
           "Orders Saved: "+ (string) OrdersSaved + "\n"+
           "Orders History: "+ (string) OrdersHistoryTotal() + "\n"+
           "Account free margin: "+ (string)AccountFreeMargin() + "\n"+
           "AccountBalance: "+ (string)AccountBalance() + "\n"+
           "AccountEquity: "+ (string)AccountEquity() + "\n"+
           "AccountCredit: "+ (string)AccountCredit() + "\n"+
           "AccountMargin: "+ (string)AccountMargin() + "\n"+
           "CurrentCandlesSinceLastMaSwap: " + (string)CurrentCandlesSinceLastMaSwap );
  
//---
   if (IsNewCandle()){
      if (AccountFreeMargin() > MinFreeMargin){
         int ret = OrderEntry(IndicateTrade());
      }
      ModifyOrders();
   }

  }
//+------------------------------------------------------------------+
