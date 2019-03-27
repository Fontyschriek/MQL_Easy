//+------------------------------------------------------------------+
//|                                                     OrderMT4.mqh |
//|                           Copyright 2018, Dionisis Nikolopoulos. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Dionisis Nikolopoulos."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "OrderBase.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class COrder : public COrderBase
  {
protected:
   COrderBase              *mObject;  

public:
                           COrder(string symbolPar = NULL, long magicNumberPar = WRONG_VALUE, GROUP_ORDERS groupPar = GROUP_ORDERS_ALL);
                          ~COrder();
   //-- Group Properties
   virtual int             GroupTotal();  
   virtual double          GroupTotalVolume();
   virtual void            GroupCloseAll(uint triesPar = 20);
   //-- Order Properties                
   virtual long            GetTicket();
   virtual datetime        GetTimeSetUp();
   virtual datetime        GetTimeExpiration();
   virtual int             GetType(); 
   virtual long            GetMagicNumber();   
   virtual double          GetVolume();
   virtual double          GetPriceOpen();  
   virtual double          GetStopLoss();
   virtual double          GetTakeProfit();
   virtual string          GetSymbol();
   virtual string          GetComment();
   virtual bool            Close(uint triesPar = 20);
   virtual bool            Modify(double priceOpenPar = WRONG_VALUE,double stopLossPar = WRONG_VALUE,double takeProfitPar = WRONG_VALUE,
                                       ENUM_SLTP_TYPE sltpPar = SLTP_PRICE, datetime expirationPar = WRONG_VALUE);   
   virtual long            SelectByIndex(int indexPar);
   virtual bool            SelectByTicket(long ticketPar);   
   //-- Quick Access
   COrder*                 operator[](const int indexPar);
   COrder*                 operator[](const long ticketPar);                          
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
COrder::COrder(string symbolPar = NULL, long magicNumberPar = WRONG_VALUE, GROUP_ORDERS groupPar = GROUP_ORDERS_ALL) 
         : COrderBase(symbolPar,magicNumberPar,groupPar)
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
COrder::~COrder()
  {
   if(CheckPointer(this.mObject) == POINTER_DYNAMIC)delete this.mObject;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                     operator for index                           |
//+------------------------------------------------------------------+
COrder* COrder::operator[](const int indexPar)
{
   if(CheckPointer(this.mObject) == POINTER_INVALID)this.mObject = new COrder(this.GroupSymbol,this.GroupMagicNumber,this.Group);
   long ticketTemp = this.SelectByIndex(indexPar);
   return this.mObject;
} 


//+------------------------------------------------------------------+
//|                     operator for ticket                          |
//+------------------------------------------------------------------+
COrder* COrder::operator[](const long ticketPar)
{
   if(CheckPointer(this.mObject) == POINTER_INVALID)this.mObject = new COrder(this.GroupSymbol,this.GroupMagicNumber,this.Group);
   this.SelectByTicket(ticketPar);
   return this.mObject;
}


//+------------------------------------------------------------------+
//|      select an order by index
//+------------------------------------------------------------------+
long COrder::SelectByIndex(int indexPar)
{
   int numberOrders      = 0;
   for (int i = 0; i < OrdersTotal(); i++){
		if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
		   this.ValidSelection = true; //  the selection is valid
         if(this.ValidOrder(OrderSymbol(),OrderMagicNumber(),OrderType())){ 	
            if(numberOrders == indexPar){
               return OrderTicket();   
            }
            numberOrders++; 
         }
		}else{
         string msgTemp = "The Order with index "+(string)i+" WAS NOT Selected.";
         this.Error.CreateErrorCustom(msgTemp,true,false,(__FUNCTION__));
         this.ValidSelection = false;
      }
	}

	//-- Case when the index is greater than the total orders
	if(indexPar >= numberOrders){
	   string msgTemp    = "The index of selection can NOT be equal or greater than the total orders. \n";
	          msgTemp   += "indexPar = "+(string)indexPar+" -- "+"Total Orders = "+(string)numberOrders;
      this.Error.CreateErrorCustom(msgTemp,false,false,(__FUNCTION__));
      this.ValidSelection = false;
	}
   return -1;
}


//+------------------------------------------------------------------+
//|     select an order by ticket
//+------------------------------------------------------------------+
bool COrder::SelectByTicket(long ticketPar)
{
   if(OrderSelect((int)ticketPar,SELECT_BY_TICKET,MODE_TRADES)){
      this.ValidSelection  = true;
      return true;
   }
   else{
      this.ValidSelection  = false;
      string msgTemp       = "The Order WAS NOT Selected.";
      return this.Error.CreateErrorCustom(msgTemp,true,false,(__FUNCTION__));
   }
}


//+------------------------------------------------------------------+
//|     get the total orders of a group
//+------------------------------------------------------------------+
int COrder::GroupTotal()
{
   int totalOrders   = 0;
   for (int i = OrdersTotal()-1; i >= 0; i--){
		if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
         if(this.ValidOrder(OrderSymbol(),OrderMagicNumber(),OrderType()))
            totalOrders++;  		   
		}else{
         string msgTemp = "The Order WAS NOT Selected.";
         this.Error.CreateErrorCustom(msgTemp,true,false,(__FUNCTION__));
      }
	}
   return totalOrders; 
}



//+------------------------------------------------------------------+
//|     get the total volume of a group
//+------------------------------------------------------------------+
double COrder::GroupTotalVolume(void)
{
   double volumeOrders   = 0;
   for (int i = OrdersTotal()-1; i >= 0; i--){
		if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
         if(this.ValidOrder(OrderSymbol(),OrderMagicNumber(),OrderType()))
            volumeOrders += OrderLots();
		}else{
         string msgTemp = "The Order WAS NOT Selected.";
         this.Error.CreateErrorCustom(msgTemp,true,false,(__FUNCTION__));
      }
	}
   return volumeOrders;   
}


//+------------------------------------------------------------------+
//|     close all orders of a group
//+------------------------------------------------------------------+
void COrder::GroupCloseAll(uint triesPar = 20)
{
   //-- tries to close an order
   uint triesTemp = 0;
	for (int i=OrdersTotal()-1; i >=0; i--)
	{
		if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
		{
		   ulong magicTemp   = OrderMagicNumber();
		   string symbolTemp = OrderSymbol();
		   int typeTemp      = OrderType();
		   if(!this.ValidOrder(symbolTemp,magicTemp,typeTemp))continue;
		   //-- Close Order		   
		   bool resultTemp = OrderDelete(OrderTicket());
		   if (resultTemp != true){//if it did not close
		      string msgTemp = "The Order WAS NOT Closed.";
            this.Error.CreateErrorCustom(msgTemp,true,false,(__FUNCTION__));
            Sleep(1000);
            triesTemp++;
            if(triesTemp >= triesPar)continue;
            i++;
		   }			   
		}else{
		   string msgTemp = "The Order WAS NOT Selected.";
         this.Error.CreateErrorCustom(msgTemp,true,false,(__FUNCTION__));
      }
	}
}


//+------------------------------------------------------------------+
//|     get the ticket of an order
//+------------------------------------------------------------------+
long COrder::GetTicket(void)
{
   if(!this.ValidSelection)return -1;
   return OrderTicket();
}  



//+------------------------------------------------------------------+
//|     get the time setup of an order
//+------------------------------------------------------------------+
datetime COrder::GetTimeSetUp(void)
{
   if(!this.ValidSelection)return -1;
   return(OrderOpenTime());
}


//+------------------------------------------------------------------+
//|     get the time expiration of an order
//+------------------------------------------------------------------+
datetime COrder::GetTimeExpiration(void)
{
   if(!this.ValidSelection)return -1;
   return(OrderExpiration());
}


//+------------------------------------------------------------------+
//|    get the type of an order
//+------------------------------------------------------------------+
int COrder::GetType(void)
{
   if(!this.ValidSelection)return -1;
   return(OrderType());
}


//+------------------------------------------------------------------+
//|    get the time magic number of an order
//+------------------------------------------------------------------+
long COrder::GetMagicNumber(void)
{
   if(!this.ValidSelection)return -1;
   return(OrderMagicNumber());
}


//+------------------------------------------------------------------+
//|    get the volume of an order
//+------------------------------------------------------------------+
double COrder::GetVolume(void)
{
   if(!this.ValidSelection)return -1;
   return OrderLots();
}


//+------------------------------------------------------------------+
//|    get the open price of an order
//+------------------------------------------------------------------+
double COrder::GetPriceOpen(void)
{
   if(!this.ValidSelection)return -1;
   return OrderOpenPrice();
}


//+------------------------------------------------------------------+
//|    get the stoploss of an order
//+------------------------------------------------------------------+
double COrder::GetStopLoss(void) 
{
   if(!this.ValidSelection)return -1;
   return OrderStopLoss();
}


//+------------------------------------------------------------------+
//|    get the takeprofit of an order
//+------------------------------------------------------------------+
double COrder::GetTakeProfit(void)
{
   if(!this.ValidSelection)return -1;
   return OrderTakeProfit();
}


//+------------------------------------------------------------------+
//|     get the symbol of an order
//+------------------------------------------------------------------+
string COrder::GetSymbol(void)
{
   if(!this.ValidSelection)return "";
   return OrderSymbol();
}


//+------------------------------------------------------------------+
//|     get the comment of an order
//+------------------------------------------------------------------+
string COrder::GetComment(void)
{
   if(!this.ValidSelection)return "";
   return OrderComment();
}


//+------------------------------------------------------------------+
//|     close an order
//+------------------------------------------------------------------+
bool COrder::Close(uint triesPar = 20)
{
   if(!this.ValidSelection)return false;
   bool status = false;
   for(uint i = 0; i < triesPar; i++)
	{     
      //-- Close Order		   
	   bool resultTemp = OrderDelete((int)this.GetTicket());
	   if (resultTemp != true){//if it did not close
	      string msgTemp = "The Order WAS NOT Closed.";
         this.Error.CreateErrorCustom(msgTemp,true,false,(__FUNCTION__));
         Sleep(1000);
         //-- Extra Layer Of Safety
         if(!OrderSelect((int)this.GetTicket(),SELECT_BY_TICKET,MODE_TRADES)){
            string msgTemp2 = "The Order WAS NOT Selected.";
            this.Error.CreateErrorCustom(msgTemp2,true,false,(__FUNCTION__));   
            break;
         }
		}else {
		   status = true;
		   break;	
		}
	}
   return status;
}


//+------------------------------------------------------------------+
//|     modify an order
//+------------------------------------------------------------------+
bool COrder::Modify(double priceOpenPar = WRONG_VALUE,double stopLossPar = WRONG_VALUE,double takeProfitPar = WRONG_VALUE, ENUM_SLTP_TYPE sltpPar = SLTP_PRICE,
                           datetime expirationPar = WRONG_VALUE)
{
   if(!this.ValidSelection)return false;
   //-- Check for wrong parameters
   if(stopLossPar == WRONG_VALUE && takeProfitPar == WRONG_VALUE && priceOpenPar == WRONG_VALUE && expirationPar == WRONG_VALUE)return false; 
   //--
   double stopLossTemp     = WRONG_VALUE;
   double takeProfitTemp   = WRONG_VALUE;
   double priceOpenTemp    = WRONG_VALUE;
   datetime expirationTemp = WRONG_VALUE;
   string symbolTemp       = this.GetSymbol();
   int   typeTemp          = (int)this.GetType(); 
   //-- Check Expiration Parameter
   if(expirationPar == WRONG_VALUE)expirationTemp = (datetime)this.GetTimeExpiration();
   else if(expirationPar <= TimeCurrent()){
      Print("The expiration parameter must be greater than "+(string)TimeCurrent()+" , Function("+__FUNCTION__+")");
      string msgTemp = "The expiration parameter must be greater than "+(string)TimeCurrent();
      return this.Error.CreateErrorCustom(msgTemp,true,false);
   }  
   CValidationCheck validationCheckTemp;
   //-- Price Open Validation
   if(priceOpenPar != WRONG_VALUE){
      if(!validationCheckTemp.CheckPendingFreezeLevel(symbolTemp,typeTemp,priceOpenPar)){this.Error.Copy(validationCheckTemp.Error);return false;}
      priceOpenTemp = priceOpenPar;
   }else priceOpenTemp = this.GetPriceOpen();
   //-- SLTP Convert
   CUtilities utilsTemp;
   if(!utilsTemp.SetSymbol(symbolTemp)){this.Error.Copy(utilsTemp.Error);return false;}
   if(!utilsTemp.SltpConvert(sltpPar,typeTemp,priceOpenTemp,stopLossPar,takeProfitPar,stopLossTemp,takeProfitTemp))
      return false;
   //-- Check the validation of stoploss and takeprofit 
   if(!validationCheckTemp.CheckStopLossTakeprofit(symbolTemp,(ENUM_ORDER_TYPE)typeTemp,priceOpenTemp,stopLossTemp,takeProfitTemp)){this.Error.Copy(validationCheckTemp.Error);return false;}
   //-- set SLTP 
   stopLossTemp   = (stopLossPar == WRONG_VALUE)      ? this.GetStopLoss()    : stopLossTemp;  
   takeProfitTemp = (takeProfitPar == WRONG_VALUE)    ? this.GetTakeProfit()  : takeProfitTemp;
   //-- Check if there is no need to make any modification
   if(!validationCheckTemp.CheckModifyLevels(this.GetTicket(),priceOpenTemp,stopLossTemp,takeProfitTemp)){this.Error.Copy(validationCheckTemp.Error);return false;}
   //-- Modify              
   if(!OrderModify((int)this.GetTicket(),priceOpenTemp,stopLossTemp,takeProfitTemp,0,clrBlue)){
      string msgTemp = "The Order WAS NOT Modified.";
      this.Error.CreateErrorCustom(msgTemp,true,false,(__FUNCTION__));
      return false;        
   }    
   return true;
}


