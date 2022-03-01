//+------------------------------------------------------------------+
//|                                                         B3CA.mq5 |
//|                                   Copyright 2021, Sávio Batista. |
//|                                     https://www.saviobatista.com |
//+------------------------------------------------------------------+
#include <Info.mqh>
//--- input parameters
input int      papeis=100;
input int      incremento=0;
input double   lucro=1.0;
input double   desvio=1.0;
input int      max=20;
input int      spread=5;

uint NUMERO_MAGICO = 20210316;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
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
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   MqlTick ultimo_tick;
   if(SymbolInfoTick(_Symbol,ultimo_tick)) {
      if(ultimo_tick.volume==0) {
         Print("Pré-abertura / Leilão");
      }
      else if(!PositionSelect(_Symbol)&&GetLastError()==ERR_TRADE_POSITION_NOT_FOUND)
      {
         Print("Apagando ordens pendentes");
         MqlTradeRequest req = {};
         MqlTradeResult res = {};
         for(int i=OrdersTotal()-1; i>=0; i--)
         {
            ulong order_ticket = OrderGetTicket(i);
            ulong order_magic = OrderGetInteger(ORDER_MAGIC);
            string order_symbol = OrderGetString(ORDER_SYMBOL);
            //--- Se foi gerado pelo bot
            if(NUMERO_MAGICO==order_magic&&order_symbol==_Symbol)
            {
               ZeroMemory(res);
               ZeroMemory(req);
               req.action = TRADE_ACTION_REMOVE;
               req.order = order_ticket;
               if(!OrderSend(req,res))PrintFormat("OrderSend error %d",GetLastError());
            }
         }
         Print("ABRINDO NEGOCIAÇÃO");
         int qtd = papeis;
         double step = ultimo_tick.ask * desvio/100;
         for(int contador = 0;contador<max;contador++)
         { 
            for(int i=0;i<contador;i++)
            {
               qtd+=incremento;
            }
            //Abre ordem
            MqlTradeRequest request = {};
            MqlTradeResult  result  = {};
            request.symbol = _Symbol;
            request.price = NormalizeDouble(ultimo_tick.ask-(contador*step),_Digits);
            request.tp = NormalizeDouble((ultimo_tick.ask-(contador*step))*(1+lucro/100),_Digits);
            request.volume = NormalizeDouble(qtd,0);
            request.action = TRADE_ACTION_PENDING;
            request.type = ORDER_TYPE_BUY_LIMIT;
            request.type_filling = ORDER_FILLING_RETURN;
            request.type_time = ORDER_TIME_GTC;
            request.magic = NUMERO_MAGICO;
            request.comment = "Negociação do custo médio etapa #"+IntegerToString(contador);
            request.deviation = 2;
            if(!OrderSend(request,result))
            {
               PrintFormat("ERRO TAKE PROFIT! #%d %u %s",GetLastError(),result.retcode,result.comment);
            }
         }
      }
   }
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
//---
   ENUM_TRADE_TRANSACTION_TYPE type = (ENUM_TRADE_TRANSACTION_TYPE)trans.type;
   //Print("#########################################################################");
   //Print(EnumToString(type));
   //Print("---------RequestDescription\r\n",RequestDescription(request));
   //Print("---------ResultDescrption\r\n",TradeResultDescription(result));
   //Print("---------TransactionDescrption\r\n",TransactionDescription(trans));
   //Print("#########################################################################");
   MqlTick ultimo_tick;
   if(
      //trans.type==TRADE_TRANSACTION_ORDER_DELETE && //É uma remoção de transação
      trans.type==TRADE_TRANSACTION_HISTORY_ADD &&
      trans.deal_type==DEAL_TYPE_BUY && //É uma negociação de compra
      trans.order_type==ORDER_TYPE_SELL && //É uma execução de venda
      trans.order_state==ORDER_STATE_FILLED //Foi preenchida
   )
   {
      Print(EnumToString(type));
      Print("SHOW! Lucro na operação!");
      //Cancela ordens abertas (safeties)
      
   }
  }
//+------------------------------------------------------------------+
