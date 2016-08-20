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

input int iStopLoss = 100;
input int iPadAmount = 40;
input int iTrailStop = 40;
input int iiTakeProfitFactor = 3;

int iTS;
double dShift;
string sIndicatorName = "RandomTime";
double LotSize = 0.1;
int iTakeProfit = iStopLoss * iiTakeProfitFactor;

static int SELL = -1;
static int BUY = 1;

////////////////////////////////
// Todo List:
// BreakEven checken
// getCorrectOrderPair (from video)

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   if(!(Digits==3 || Digits==5)){
      Alert("This Broker onle trades "+ Digits +" Digits!");
      return(INIT_FAILED);
   }

   iTS = MathMax(MarketInfo(Symbol(), MODE_STOPLEVEL), iTrailStop);

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

void ModifyOrders(){
   for (int o=OrdersTotal()-1; o >=0; o--) {
      if (OrderSelect(o, SELECT_BY_POS, MODE_TRADES))
      if (OrderMagicNumber() == MAGICMA)
      if (OrderSymbol() == Symbol())
      if (OrderType() == OP_BUY){
         if (OrderOpenPrice() < Bid - dShift){
            bool success = false;
            if (OrderiStopLoss() < Bid - dShift)
            {
               double _sl = ND(Bid - (iTS*Points));
               Print("Try to change SL to: "+ (string)_sl + " Bid: "+ (string)Bid);
               success = OrderModify(OrderTicket(), OrderOpenPrice(), _sl, OrderiTakeProfit(), 0, clrMintCream);
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
            if (OrderiStopLoss() > Ask + dShift)
            {
               double _sl = ND(Ask + (iTS*Point));
               Print("Try to change SL to: "+ (string)_sl + " Ask: "+(string)Ask);
               success = OrderModify(OrderTicket(), OrderOpenPrice(), _sl, OrderiTakeProfit(), 0, clrMintCream);
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
   return (int) iCustom(NULL, 0, sIndicatorName, PRICE_CLOSE,0);
}


int OrderEntry(int trade){
   if (trade == BUY){
      int ticket = OrderSend(Symbol(), OP_BUY, LotSize, Ask, 3, 0, 0, NULL, MAGICMA, 0, clrGreen);
      int lErr = GetLastError();
      Print("OrderBUY ticket: "+(string)ticket+ " LastError: "+(string)lErr);
      ResetLastError();

      if (ticket>0) {
         double _sl = ND(Ask-(iStopLoss*Point));
         double _tp = ND(Ask+(iTakeProfit*Point));
         Print("Try to modify BUY iStopLoss to:" + (string)_sl + " modify iTakeProfit to: "+ (string)_tp);
         bool success = OrderModify(ticket, OrderOpenPrice(), _sl, _tp, 0, clrYellow);
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
         double _sl = ND(Bid+(iStopLoss*Point));
         double _tp = ND(Bid-(iTakeProfit*Point));
//         double _tp = 0;
         Print("Try to modify SELL iStopLoss to:" + (string)_sl + " modify iTakeProfit to: "+ (string)_tp);
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

//---
   if (IsNewCandle()){
      int ret = OrderEntry(IndicateTrade());
      ModifyOrders();
   }

  }
//+------------------------------------------------------------------+
