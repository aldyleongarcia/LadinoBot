//+------------------------------------------------------------------+
//|                                                 TradeIn.mqh |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"

#include <LadinoBot/Strategies/Candlestick.mqh>
#include <LadinoBot/Strategies/SR.mqh>
#include <LadinoBot/LadinoCore.mqh>

class TradeIn: public LadinoCore {
   private:
      bool _ForcarOperacao;
      bool _ForcarEntrada;
   public:
      TradeIn(void);
      bool inicializarCompra(double price, double stopLoss);
      bool inicializarVenda(double price, double stopLoss);
      bool aumentarCompra(double lot, double price, double stopLoss);
      bool aumentarVenda(double lot, double price, double stopLoss);
      bool comprarCruzouHiLo(ENUM_SINAL_TENDENCIA tendenciaHiLo, ENUM_TIMEFRAMES tempo, VELA& velaAtual, VELA& velaAnterior, double mm);
      bool venderCruzouHiLo(ENUM_SINAL_TENDENCIA tendenciaHiLo, ENUM_TIMEFRAMES tempo, VELA& velaAtual, VELA& velaAnterior, double mm);
      bool comprarNaTendencia(VELA& velaAtual, VELA& velaAnterior);
      bool venderNaTendencia(VELA& velaAtual, VELA& velaAnterior);
      void comprarDunnigan(ENUM_TIMEFRAMES tempo, VELA& velaAtual, VELA& velaAnterior, VELA& vela3, VELA& vela4);
      void venderDunnigan(ENUM_TIMEFRAMES tempo, VELA& velaAtual, VELA& velaAnterior, VELA& vela3, VELA& vela4);
      bool iniciandoExecucaoCompra();
      bool iniciandoExecucaoVenda();
      bool executarAumento(ENUM_SINAL_POSICAO tendencia, double volume);
      void verificarRompimentoLTB();
      void verificarRompimentoLTA();
      bool verificarEntrada();
      bool getForcarOperacao();
      void setForcarOperacao(bool value);
      bool getForcarEntrada();
      void setForcarEntrada(bool value);
};

TradeIn::TradeIn(void) {

}

bool TradeIn::inicializarCompra(double price, double stopLoss) {

   if (_TipoOperacao != COMPRAR_VENDER && _TipoOperacao != APENAS_COMPRAR)
      return false;

   double sl = price - NormalizeDouble(stopLoss - getStopExtra(), _Digits);
   if (getStopLossMax() > 0 && sl >= getStopLossMax()) {
      if (_ultimoStopMax != sl) {
         _ultimoStopMax = sl;
         //escreverLog("Stop Loss exceeds max value=" + IntegerToString((int)sl) + ".");
         escreverLog(StringFormat(ERROR_STOPLOSS_MAXVALUE, (int)sl));
      }
      if (getForcarEntrada())
         sl = getStopLossMax();
      else
         return false;
   }
   
   if (getStopLossMin() > 0 && sl < getStopLossMin())
      sl = getStopLossMin();
   
   double lot = this.validarFinanceiro(_InicialVolume, sl);
   if (lot <= 0)
      return false;

   if (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) {
      if (getForcarOperacao()) {
         if (this.comprarForcado(lot, sl, 0, 10)) {
            //configurarTakeProfit(COMPRADO, price);
            return true;
         }
      }
      else {
         if (this.comprar(lot, price, sl)) {
            //configurarTakeProfit(COMPRADO, price);
            return true;
         }
      }
   }
   return false;
}

bool TradeIn::inicializarVenda(double price, double stopLoss) {

   if (_TipoOperacao != COMPRAR_VENDER && _TipoOperacao != APENAS_VENDER)
      return false;

   double tickMinimo = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   double sl = NormalizeDouble(stopLoss + getStopExtra(), _Digits) - price;
   
   if (getStopLossMax() > 0 && sl >= getStopLossMax()) {
      if (_ultimoStopMax != sl) {
         _ultimoStopMax = sl;
         //escreverLog("Stop Loss exceeds max value=" + IntegerToString((int)sl) + ".");
         escreverLog(StringFormat(ERROR_STOPLOSS_MAXVALUE, (int)sl));
      }
      if (getForcarEntrada())
         sl = getStopLossMax();
      else
         return false;      
   }
   if (getStopLossMin() > 0 && sl < getStopLossMin())
      sl = getStopLossMin();
   
   double lot = this.validarFinanceiro(_volumeAtual, sl);
   if (lot <= 0)
      return false;
   
   if (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) {      
      if (getForcarOperacao()) {
         if (this.venderForcado(lot, sl, 0, 10)) {
            //configurarTakeProfit(VENDIDO, price);
            return true;
         }      
      }
      else {
         if (this.vender(lot, price, sl)) {
            //configurarTakeProfit(VENDIDO, price);
            return true;
         }
      }
   }
   return false;
}


bool TradeIn::aumentarCompra(double lot, double price, double stopLoss) {

   if (!(price > (this.ultimoPrecoEntrada() + getAumentoMinimo())))
      return false;      
   if ((MathAbs(this.getVolume()) + lot) > _MaximoVolume)
      return false;

   double sl = NormalizeDouble(stopLoss, _Digits);   
   if (getStopLossMin() > 0 && sl < getStopLossMin())
      sl = getStopLossMin();

   if (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) {
      if (this.comprar(lot, price, sl)) {
         return true;
      }
   }
   return false;
}

bool TradeIn::aumentarVenda(double lot, double price, double stopLoss) {

   if (!(price < (this.ultimoPrecoEntrada() - getAumentoMinimo())))
      return false;
   if ((MathAbs(this.getVolume()) + lot) > _MaximoVolume)
      return false;

   double sl = NormalizeDouble(stopLoss, _Digits);   
   if (getStopLossMin() > 0 && sl < getStopLossMin())
      sl = getStopLossMin();

   if (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) {
      if (this.vender(lot, price, sl)) {
         return true;
      }
   }
   return false;
}

bool TradeIn::comprarCruzouHiLo(ENUM_SINAL_TENDENCIA tendenciaHiLo, ENUM_TIMEFRAMES tempo, VELA& velaAtual, VELA& velaAnterior, double mm) {
   if (tendenciaHiLo == ALTA && _negociacaoAtual != ALTA) {
      if (velaAtual.tipo == COMPRADORA && velaAnterior.tipo == COMPRADORA && _precoCompra > velaAtual.abertura) { // Rompeu a anterior
         if (_precoCompra > mm && mm >= velaAtual.minima && mm <= velaAtual.maxima) {
            if (getT1LinhaTendencia()) {
               _negociacaoAtual = ALTA;
               atualizarNegociacaoAtual();
               _tamanhoLinhaTendencia = autoTrend.gerarLTB(ultimaLT, tempo, ChartID(), 15);
               return true;
            }
            else {
               double posicaoStop = pegarPosicaoStop(COMPRADO);
               if (inicializarCompra(_precoCompra, posicaoStop)) {
                  ultimaLT = velaAtual.tempo;
                  return true;
               }
            }
         }
      }
   }
   return false;
}

bool TradeIn::venderCruzouHiLo(ENUM_SINAL_TENDENCIA tendenciaHiLo, ENUM_TIMEFRAMES tempo, VELA& velaAtual, VELA& velaAnterior, double mm) {
   if (tendenciaHiLo == BAIXA && _negociacaoAtual != BAIXA) {
      if (velaAtual.tipo == VENDEDORA && velaAnterior.tipo == VENDEDORA && _precoVenda < velaAtual.abertura) { // Rompeu a anterior
         if (_precoVenda < mm && mm <= velaAtual.maxima && mm >= velaAtual.minima) {
         
            if (getT1LinhaTendencia()) {
               _negociacaoAtual = BAIXA;
               atualizarNegociacaoAtual();
               _tamanhoLinhaTendencia = autoTrend.gerarLTA(ultimaLT, tempo, ChartID(), 15);
               return true;
            }
            else {
               double posicaoStop = pegarPosicaoStop(VENDIDO);
               if (inicializarVenda(_precoVenda, posicaoStop)) {
                  ultimaLT = velaAtual.tempo;
                  return true;
               }
            }
            
         }
      }
   }
   return false;
}

bool TradeIn::comprarNaTendencia(VELA& velaAtual, VELA& velaAnterior) {
   if (getT1HiloTendencia() && _t1TendenciaHiLo != ALTA) 
      return false;
   if (getT2HiloTendencia() && _t2TendenciaHiLo != ALTA) 
      return false;
   if (getT3HiloTendencia() && _t3TendenciaHiLo != ALTA) 
      return false;
      
   if (getT1SRTendencia() && _t1TendenciaSR != ALTA)
      return false;
   if (getT2SRTendencia() && _t2TendenciaSR != ALTA)
      return false;
   if (getT3SRTendencia() && _t3TendenciaSR != ALTA)
      return false;
      
   if (!(velaAtual.tipo == COMPRADORA && _precoCompra > velaAtual.abertura)) 
      return false;
   if (!(velaAnterior.tipo == COMPRADORA && _precoCompra > velaAnterior.maxima)) 
      return false;
   _negociacaoAtual = ALTA;
   atualizarNegociacaoAtual();
   _tamanhoLinhaTendencia = autoTrend.gerarLTB(ultimaLT, PERIOD_CURRENT, ChartID(), 15);
   return true;
}

bool TradeIn::venderNaTendencia(VELA& velaAtual, VELA& velaAnterior) {
   if (getT1HiloTendencia() && _t1TendenciaHiLo != BAIXA) 
      return false;
   if (getT2HiloTendencia() && _t2TendenciaHiLo != BAIXA) 
      return false;
   if (getT3HiloTendencia() && _t3TendenciaHiLo != BAIXA) 
      return false;
      
   if (getT1SRTendencia() && _t1TendenciaSR != BAIXA)
      return false;
   if (getT2SRTendencia() && _t2TendenciaSR != BAIXA)
      return false;
   if (getT3SRTendencia() && _t3TendenciaSR != BAIXA)
      return false;
      
   if (!(velaAtual.tipo == VENDEDORA && _precoVenda < velaAtual.abertura)) 
      return false;
   if (!(velaAnterior.tipo == VENDEDORA && _precoVenda < velaAnterior.minima)) 
      return false;
   _negociacaoAtual = BAIXA;
   atualizarNegociacaoAtual();
   _tamanhoLinhaTendencia = autoTrend.gerarLTA(ultimaLT, PERIOD_CURRENT, ChartID(), 15);
   return true;
}

void TradeIn::comprarDunnigan(ENUM_TIMEFRAMES tempo, VELA& velaAtual, VELA& velaAnterior, VELA& vela3, VELA& vela4) {
}

void TradeIn::venderDunnigan(ENUM_TIMEFRAMES tempo, VELA& velaAtual, VELA& velaAnterior, VELA& vela3, VELA& vela4) {
}

bool TradeIn::iniciandoExecucaoCompra() {
   double posicaoLTB = 0, posicaoStop = 0;
   if (_negociacaoAtual != ALTA)
      return false;
   if (getT1HiloTendencia() && _t1TendenciaHiLo != ALTA) 
      return false;
   if (getT2GraficoExtra() && getT2HiloTendencia() && _t2TendenciaHiLo != ALTA)
      return false;
   if (getT3GraficoExtra() && getT3HiloTendencia() && _t3TendenciaHiLo != ALTA) 
      return false;
      
   if (getT1SRTendencia() && _t1TendenciaSR != ALTA)
      return false;
   if (getT2GraficoExtra() && getT2SRTendencia() && _t2TendenciaSR != ALTA)
      return false;
   if (getT3GraficoExtra() && getT3SRTendencia() && _t3TendenciaSR != ALTA)
      return false;
      
   if (_tamanhoLinhaTendencia >= 3 && _t1VelaAnterior.tipo == COMPRADORA)
      posicaoLTB = autoTrend.posicaoLTB(ChartID(), _t1VelaAtual.tempo) + getLTExtra();
   else
      return false;
   if (posicaoLTB > 0 && _precoCompra > posicaoLTB && posicaoLTB >= _t1VelaAtual.minima && posicaoLTB <= _t1VelaAtual.maxima && _precoCompra > _t1VelaAnterior.maxima)
      posicaoStop = pegarPosicaoStop(COMPRADO);
   else
      return false;
   if (inicializarCompra(_precoCompra, posicaoStop)) {
      autoTrend.limparLinha(ChartID());
      ultimaLT = _t1VelaAtual.tempo;
      return true;
   }
   return false;
}

bool TradeIn::iniciandoExecucaoVenda() {
   double posicaoLTA = 0, posicaoStop = 0;
   if (_negociacaoAtual != BAIXA)
      return false;
   if (getT1HiloTendencia() && _t1TendenciaHiLo != ALTA) 
      return false;
   if (getT2GraficoExtra() && getT2HiloTendencia() && _t2TendenciaHiLo != BAIXA) 
      return false;
   if (getT3GraficoExtra() && getT3HiloTendencia() && _t3TendenciaHiLo != BAIXA) 
      return false;
      
   if (getT1SRTendencia() && _t1TendenciaSR != BAIXA)
      return false;
   if (getT2GraficoExtra() && getT2SRTendencia() && _t2TendenciaSR != BAIXA)
      return false;
   if (getT3GraficoExtra() && getT3SRTendencia() && _t3TendenciaSR != BAIXA)
      return false;

   if (_tamanhoLinhaTendencia >= 3 && _t1VelaAnterior.tipo == VENDEDORA)
      posicaoLTA = autoTrend.posicaoLTA(ChartID(), _t1VelaAtual.tempo) - getLTExtra();
   else
      return false;
   if (posicaoLTA > 0 && _precoVenda < posicaoLTA && posicaoLTA >= _t1VelaAtual.minima && posicaoLTA <= _t1VelaAtual.maxima && _precoVenda < _t1VelaAnterior.minima)
      posicaoStop = pegarPosicaoStop(VENDIDO);
   else
      return false;
   if (inicializarVenda(_precoVenda, posicaoStop)) {
      autoTrend.limparLinha(ChartID());
      ultimaLT = _t1VelaAtual.tempo;
      return true;
   }
   return false;
}


bool TradeIn::executarAumento(ENUM_SINAL_POSICAO tendencia, double volume) {
   double sl = 0;
   double stopLoss = pegarPosicaoStop(tendencia);
   if (tendencia == COMPRADO)
      sl = (_precoCompra - stopLoss) + getAumentoStopExtra();
   else if (tendencia == VENDIDO)
      sl = (stopLoss - _precoVenda) + getAumentoStopExtra();
   
   double volumeLocal = volume;
   if (getGestaoRisco() == RISCO_PROGRESSIVO) {
      double precoSR = 0;
      if (tendencia == COMPRADO)
         precoSR = _precoCompra + sl;
      else if (tendencia == VENDIDO)
         precoSR = _precoVenda - sl;
      double pontos = this.posicaoPontoEmAberto(precoSR);
      volumeLocal = MathFloor(pontos / sl);
   }
   if (volumeLocal > 0) {
      if (tendencia == COMPRADO) {
         if (aumentarCompra(volumeLocal, _precoCompra, sl)) {
            autoTrend.limparLinha(ChartID());
            ultimaLT = _t1VelaAtual.tempo;
            if (getGestaoRisco() == RISCO_PROGRESSIVO) {
               double volumeTP = MathAbs(this.getVolume());
               this.venderTP(volumeTP, _precoCompra + 100);
            }
            return true;
         }
      }
      else if (tendencia == VENDIDO) {
         if (aumentarVenda(volumeLocal, _precoVenda, sl)) {
            autoTrend.limparLinha(ChartID());
            ultimaLT = _t1VelaAtual.tempo;
            if (getGestaoRisco() == RISCO_PROGRESSIVO) {
               double volumeTP = MathAbs(this.getVolume());
               this.comprarTP(volumeTP, _precoVenda - 100);
            }
            return true;
         }
      }
   }
   else 
      ultimaLT = _t1VelaAtual.tempo;
   return false;
}


void TradeIn::verificarRompimentoLTB() {
   if (this.getPosicaoAtual() == COMPRADO && _negociacaoAtual == ALTA && _tamanhoLinhaTendencia >= 3) {
      double posicaoLTB = autoTrend.posicaoLTB(ChartID(), _t1VelaAtual.tempo);
      if (posicaoLTB > 0 && _precoCompra > posicaoLTB && posicaoLTB >= _t1VelaAtual.minima && posicaoLTB <= _t1VelaAtual.maxima && _precoCompra > _t1VelaAnterior.maxima) {
         executarObjetivo(this.getPosicaoAtual());
      }
   }
}

void TradeIn::verificarRompimentoLTA() {
   if (this.getPosicaoAtual() == VENDIDO && _negociacaoAtual == BAIXA && _tamanhoLinhaTendencia >= 3) {
      double posicaoLTA = autoTrend.posicaoLTA(ChartID(), _t1VelaAtual.tempo);
      if (posicaoLTA > 0 && _precoVenda < posicaoLTA && posicaoLTA >= _t1VelaAtual.minima && posicaoLTA <= _t1VelaAtual.maxima && _precoVenda < _t1VelaAnterior.minima) {
         executarObjetivo(this.getPosicaoAtual());
      }
   }
}


bool TradeIn::verificarEntrada() {

   if(Bars(_Symbol,_Period)<100)
      return false;
    
   atualizarPreco();
      
   carregarVelaT1();
   carregarVelaT2();
   carregarVelaT3();

   if(t1NovaVela)
      tentativaCandle = false;
   if (tentativaCandle)
      return false;

   if(t1NovaVela) {
      atualizarSR(ALTA);
      ENUM_SINAL_TENDENCIA tendencia = t1hilo.tendenciaAtual();
      if (tendencia != _t1TendenciaHiLo) {
         if (getCondicaoEntrada() == HILO_CRUZ_MM_T1_TICK || getCondicaoEntrada() == HILO_CRUZ_MM_T1_FECHAMENTO) {
            _negociacaoAtual = INDEFINIDA;
            atualizarNegociacaoAtual();
         }
         _t1TendenciaHiLo = tendencia;
      }
   }

   // De acordo com cruzamento de média no HiLo
   if (t2NovaVela) {
      ENUM_SINAL_TENDENCIA tendencia = t2hilo.tendenciaAtual();
      if (tendencia != _t2TendenciaHiLo) {
         if (getCondicaoEntrada() == HILO_CRUZ_MM_T2_TICK || getCondicaoEntrada() == HILO_CRUZ_MM_T2_FECHAMENTO) {
            _negociacaoAtual = INDEFINIDA;
            atualizarNegociacaoAtual();
         }
         _t2TendenciaHiLo = tendencia;
      }
   }
   if (t3NovaVela) {
      ENUM_SINAL_TENDENCIA tendencia = t3hilo.tendenciaAtual();
      if (tendencia != _t3TendenciaHiLo) {
         if (getCondicaoEntrada() == HILO_CRUZ_MM_T3_TICK || getCondicaoEntrada() == HILO_CRUZ_MM_T3_FECHAMENTO) {
            _negociacaoAtual = INDEFINIDA;
            atualizarNegociacaoAtual();
         }
         _t3TendenciaHiLo = tendencia;
      }
   }

   if (getCondicaoEntrada() == HILO_CRUZ_MM_T1_TICK) {
      double mm = pegarMMT1();
      string nome = "arrow_" + TimeToString(_t1VelaAtual.tempo);
      if (comprarCruzouHiLo(_t1TendenciaHiLo, _Period, _t1VelaAtual, _t1VelaAnterior, mm)) {
         ObjectCreate(ChartID(), nome, OBJ_ARROW_UP, 0, _t1VelaAtual.tempo, _precoCompra);
         ObjectSetInteger(ChartID(), nome, OBJPROP_COLOR, clrLimeGreen); 
      }
      if (venderCruzouHiLo(_t1TendenciaHiLo, _Period, _t1VelaAtual, _t1VelaAnterior, mm)) {
         ObjectCreate(ChartID(), nome, OBJ_ARROW_DOWN, 0, _t1VelaAtual.tempo, _precoVenda);
         ObjectSetInteger(ChartID(), nome, OBJPROP_COLOR, clrRed); 
      }
   }   
   else if (getCondicaoEntrada() == HILO_CRUZ_MM_T2_TICK) {
      double mm = pegarMMT2();
      string nome = "arrow_" + TimeToString(_t2VelaAtual.tempo);
      if (comprarCruzouHiLo(_t2TendenciaHiLo, getT2TempoGrafico(), _t2VelaAtual, _t2VelaAnterior, mm)) {         
         t2DesenharSetaCima(_t2VelaAtual.tempo, _precoCompra);
      }
      if (venderCruzouHiLo(_t2TendenciaHiLo, getT2TempoGrafico(), _t2VelaAtual, _t2VelaAnterior, mm)) {
         t2DesenharSetaBaixo(_t2VelaAtual.tempo, _precoVenda);
      }
   }
   else if (getCondicaoEntrada() == HILO_CRUZ_MM_T3_TICK) {
      double mm = pegarMMT3();
      string nome = "arrow_" + TimeToString(_t3VelaAtual.tempo);
      if (comprarCruzouHiLo(_t3TendenciaHiLo, getT3TempoGrafico(), _t3VelaAtual, _t3VelaAnterior, mm)) {
         t3DesenharSetaCima(_t3VelaAtual.tempo, _precoCompra);
      }
      if (venderCruzouHiLo(_t3TendenciaHiLo, getT3TempoGrafico(), _t3VelaAtual, _t3VelaAnterior, mm)) {
         t3DesenharSetaBaixo(_t3VelaAtual.tempo, _precoCompra);
      }
   }
   else if (getCondicaoEntrada() == HILO_CRUZ_MM_T1_FECHAMENTO && t1NovaVela) {
      double mm = pegarMMT1();
      string nome = "arrow_" + TimeToString(_t1VelaAtual.tempo);
      if (comprarCruzouHiLo(_t1TendenciaHiLo, _Period, _t1VelaAtual, _t1VelaAnterior, mm)) {
         t1DesenharSetaCima(_t1VelaAtual.tempo, _precoCompra);
      }
      if (venderCruzouHiLo(_t1TendenciaHiLo, _Period, _t1VelaAtual, _t1VelaAnterior, mm)) {
         t1DesenharSetaBaixo(_t1VelaAtual.tempo, _precoVenda);
      }
   }
   else if (getCondicaoEntrada() == HILO_CRUZ_MM_T2_FECHAMENTO && t2NovaVela) {
      double mm = pegarMMT2();
      string nome = "arrow_" + TimeToString(_t2VelaAtual.tempo);
      if (comprarCruzouHiLo(_t2TendenciaHiLo, getT2TempoGrafico(), _t2VelaAtual, _t2VelaAnterior, mm)) {
         t1DesenharSetaCima(_t1VelaAtual.tempo, _precoCompra);
      }
      if (venderCruzouHiLo(_t2TendenciaHiLo, getT2TempoGrafico(), _t2VelaAtual, _t2VelaAnterior, mm)) {
         t2DesenharSetaBaixo(_t2VelaAtual.tempo, _precoVenda);
      }
   }
   else if (getCondicaoEntrada() == HILO_CRUZ_MM_T3_FECHAMENTO && t3NovaVela) {
      double mm = pegarMMT3();
      string nome = "arrow_" + TimeToString(_t3VelaAtual.tempo);
      if (comprarCruzouHiLo(_t3TendenciaHiLo, getT3TempoGrafico(), _t3VelaAtual, _t3VelaAnterior, mm)) {
         t3DesenharSetaCima(_t3VelaAtual.tempo, _precoCompra);
      }
      if (venderCruzouHiLo(_t3TendenciaHiLo, getT3TempoGrafico(), _t3VelaAtual, _t3VelaAnterior, mm)) {
         t3DesenharSetaBaixo(_t3VelaAtual.tempo, _precoVenda);
      }
   }
   else if (getCondicaoEntrada() == APENAS_TENDENCIA_T1) {
      comprarNaTendencia(_t1VelaAtual, _t1VelaAnterior);
      venderNaTendencia(_t1VelaAtual, _t1VelaAnterior);
   }
   else if (getCondicaoEntrada() == APENAS_TENDENCIA_T2) {
      comprarNaTendencia(_t2VelaAtual, _t2VelaAnterior);
      venderNaTendencia(_t2VelaAtual, _t2VelaAnterior);
   }
   else if (getCondicaoEntrada() == APENAS_TENDENCIA_T3) {
      comprarNaTendencia(_t3VelaAtual, _t3VelaAnterior);
      venderNaTendencia(_t3VelaAtual, _t3VelaAnterior);
   }
   
   if (t1NovaVela && getT1LinhaTendencia())
      desenharLinhaTendencia();

   iniciandoExecucaoCompra();
   iniciandoExecucaoVenda();
   inicializarPosicao();
   
   return false;
}

bool TradeIn::getForcarOperacao() {
   return _ForcarOperacao;
}

void TradeIn::setForcarOperacao(bool value) {
   _ForcarOperacao = value;
}

bool TradeIn::getForcarEntrada() {
   return _ForcarEntrada;
}

void TradeIn::setForcarEntrada(bool value) {
   _ForcarEntrada = value;
}