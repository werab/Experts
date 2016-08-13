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

input int StopLoss = 100;

input int FastMa = 5;
input int FastMaShift = 0;
input int FastMaMethod = 0;
input int FastMaAppliedTo = 0;
input int SlowMa = 21;
input int SlowMaShift = 0;
input int SlowMaMethod = 0;
input int SlowMaAppliedTo = 0;

input int TPBuffer = 20;
input int MinSLAdjust = 10;

input double LotSize = 0.1;

double pt;
double lot;

// statistics
int OrdersSaved = 0;

static int SELL = -1;
static int BUY = 1;

double CorrectLots(double thelot) {
   double maxlots=MarketInfo(Symbol(),MODE_MAXLOT);
   double minlot=MarketInfo(Symbol(),MODE_MINLOT);
   double lstep=MarketInfo(Symbol(),MODE_LOTSTEP);
   double lots=lstep*NormalizeDouble(thelot/lstep,0);
   lots=MathMax(MathMin(maxlots,lots),minlot);
   return (lots);
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   lot = CorrectLots(LotSize);
      
   if(Digits==3 || Digits==5) pt=10*Point;   else   pt=Point;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }

bool IsNewCandle(){
   static int BarsOnChard = 0;
   if (Bars == BarsOnChard)
      return false;
   BarsOnChard = Bars;
   return true;
}
  
void ModifyOrders(){
   for (int o=OrdersTotal()-1; o >=0; o--) {
      if (OrderSelect(o, SELECT_BY_POS, MODE_TRADES))
      if (OrderMagicNumber() == MAGICMA)
      if (OrderSymbol() == Symbol())
      if (OrderType() == OP_BUY){
         if (OrderOpenPrice() < Bid - (TPBuffer*pt)){
            bool success = false;
            if (OrderStopLoss() < Bid - (TPBuffer*pt))
            {
               success = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - (NormalizeDouble(TPBuffer/2, 0)*pt), OrderTakeProfit(), 0, clrMintCream);
               if (!success){
                  int lErr = GetLastError();
                  Print("OrderModify LastError: "+(string)lErr);
                  ResetLastError();
               } else {
                  Print("Orders Open: "+ (string)OrdersTotal() + " Orders Saved:"+ (string)(OrdersSaved+1));
               }
            }
            if (success) OrdersSaved++;
         } else {
 //           Print("OrderNr.: "+(string)o+" Diff:"+ (string)(NormalizeDouble(OrderOpenPrice() - (Bid - (TPBuffer*pt)),Digits)));
         }
      } else if (OrderType() == OP_SELL){
         if (OrderOpenPrice() > Ask + TPBuffer){
            bool success = false;
            if (OrderStopLoss() > Ask + TPBuffer)
            {
               success = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + (NormalizeDouble(TPBuffer/2, 0)*pt), OrderTakeProfit(), 0, clrMintCream);
               if (!success){
                  int lErr = GetLastError();
                  Print("OrderModify LastError: "+(string)lErr);
                  ResetLastError();
               } else {
                  Print("Orders Open: "+ (string)OrdersTotal() + " Orders Saved:"+ (string)(OrdersSaved+1));
               }
            }
            if (success) OrdersSaved++;
         } else {
 //           Print("OrderNr.: "+(string)o+" Diff:"+ (string)(NormalizeDouble((Ask + (TPBuffer*pt) - OrderOpenPrice()),Digits)));
            
         }
      }
   }
}
  
int IndicateTrade()
{
   double previousFast = iMA(NULL,0,FastMa,FastMaShift, FastMaShift, FastMaAppliedTo, 2);
   double currentFast = iMA(NULL,0,FastMa,FastMaShift, FastMaShift, FastMaAppliedTo, 1);
   double previousSlow = iMA(NULL,0,SlowMa,SlowMaShift, SlowMaShift, SlowMaAppliedTo, 2);
   double currentSlow = iMA(NULL,0,SlowMa,SlowMaShift, SlowMaShift, SlowMaAppliedTo, 1);
   
   if (previousFast<previousSlow && currentFast>currentSlow)
      return BUY;
   
   if (previousFast>previousSlow && currentFast<currentSlow)
      return SELL;
      
   return 0;
}
  
int OrderEntry(int trade){
   if (trade == BUY){
      int ticket = OrderSend(Symbol(), OP_BUY, LotSize, Ask, 3, 0, 0, NULL, MAGICMA, 0, clrGreen);
      int lErr = GetLastError();
      Print("OrderBUY ticket: "+(string)ticket+ " LastError: "+(string)lErr);
      ResetLastError();
      
      if (ticket>0) {
         Print("StopLoss: "+ (string)StopLoss + " pt: " + (string) pt );
         Print("Modify StopLoss to:" + (string)(Ask-(StopLoss*pt)) + " Ask: "+(string)Ask + " StopLoss*pt: "+(string)(StopLoss*pt));
         lErr = OrderModify(ticket, OrderOpenPrice(), Ask-(StopLoss*pt), 0, 0, clrYellow);
         Print("OrderModify LastError: "+(string)lErr);
         ResetLastError();
      }
   }
   
   if (trade == SELL) {
      int ticket = OrderSend(Symbol(), OP_SELL, LotSize, Bid, 3, 0, 0, NULL, MAGICMA, 0, clrBlue);
      int lErr = GetLastError();
      Print("OrderSELL ticket: "+(string)ticket+ " LastError: "+(string)lErr);
      ResetLastError();
      
      if (ticket>0) {
      Print("StopLoss: "+ (string)StopLoss + " pt: " + (string) pt );
         Print("Modify StopLoss to:" + (string)(Bid+(StopLoss*pt)) + " Ask: "+(string)Ask + " StopLoss*pt: "+(string)(StopLoss*pt));
         lErr = OrderModify(ticket, OrderOpenPrice(), Bid+(StopLoss*pt), 0, 0, clrYellow);
         Print("OrderModify LastError: "+(string)lErr);
         ResetLastError();    
      }
   }
   
   return -1;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   Comment("LotSize is: " + (string) lot + "\n"+
           "Ask: "+ (string) Ask  + "\n"+
           "Bid: "+ (string) Bid  + "\n" +
           "MODE_STOPLEVEL: "+ (string) MarketInfo(Symbol(),MODE_STOPLEVEL) + "\n" +
           "pt: "+ (string) pt  + "\n" +
           "Digits: "+ (string) Digits  + "\n" +
           "Point: "+ (string) Point  + "\n");
  
//---
   if (IsNewCandle()){
      int ret = OrderEntry(IndicateTrade());
      ModifyOrders();  
   }

  }
//+------------------------------------------------------------------+
