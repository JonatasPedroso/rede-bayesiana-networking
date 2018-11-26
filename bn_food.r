library(bnlearn)
library(bnviewer)
library(forecast)
library(ggplot2)
library(stringi)

#Leitura do DataSet
dados.vendas <- read.csv("data/food-sp.csv", header=TRUE)
dados.vendas = as.data.frame(dados.vendas)

dados.vendas$VENDA <- as.numeric(dados.vendas$VENDA)

#Limpando os Valores de Variaveis == 0
dados.vendas[is.na(dados.vendas)] <- 0
dados.vendas$PROJETO.CAFE[dados.vendas$PROJETO.CAFE == 0] <- mean(dados.vendas$PROJETO.CAFE)
dados.vendas$BRINDE[dados.vendas$BRINDE == 0] <- mean(dados.vendas$BRINDE)
dados.vendas$VENDA[dados.vendas$VENDA == 0] <- mean(dados.vendas$VENDA)



#Limpando o DataSet com os Campos desejados
dados.vendas = dados.vendas[, c(
  'VENDA',
  'GELADO.E.MILK.SHAKE', 
  'SANDUICHE', 
  'BEBIDA', 
  'ACOMPANHAMENTO',
  'ADICIONAL', 
  'PROJETO.CAFE',
  'BRINDE',
  'PRATO'
)]

dados.vendas.hc = hc(dados.vendas)

#Plotagem inicial das redes com o algoritimo Hill Climb
viewer(dados.vendas.hc,
       bayesianNetwork.width = "100%",
       bayesianNetwork.height = "80%",
       bayesianNetwork.layout = "layout_in_circle",
       bayesianNetwork.title = "Rede Bayesiana Discreta - Food-SP",
       bayesianNetwork.subtitle = "Vendas",
       edges.dashes = TRUE,
       node.colors = list(background = "#8e44ad", border = "#1abc9c",
                          highlight = list(background = "#3498db",
                                           border = "#2b7ce9"))
)


data.transform.boot = boot.strength(dados.vendas, R = 50, algorithm = "hc")

#plotagem da rede Bayesiana com base em meta aprendizado com geraçõesde redes por meio do algoritmo Hill Climbing
strength.viewer(
  data.transform.boot,
  bayesianNetwork.arc.strength.threshold.min = 0.8,
  bayesianNetwork.arc.strength.threshold.expression.color = "@threshold >= 0.90 & @threshold <= 1",
  bayesianNetwork.arc.strength.threshold.color = "#1abc9c",
  bayesianNetwork.arc.strength.label = TRUE,
  bayesianNetwork.arc.strength.label.prefix = "",
  bayesianNetwork.arc.strength.label.color = "#8e44ad",
  bayesianNetwork.arc.strength.tooltip = TRUE,
  bayesianNetwork.width = "100%",
  bayesianNetwork.height = "80vh",
  bayesianNetwork.layout = "layout_in_circle",
  bayesianNetwork.title="Teste de Boosting",
  bayesianNetwork.subtitle = "Testes com Fast Food",
  edges.dashes = TRUE,
  node.colors = list(background = "#8e44ad", border = "#1abc9c",
                     highlight = list(background = "#3498db",
                                      border = "#2b7ce9"))
)

dados.vendas.bnfit = bn.fit(dados.vendas.hc, data = dados.vendas)


cpquery(dados.vendas.bnfit,
        event = (VENDA > 500),
        evidence = (GELADO.E.MILK.SHAKE <= 10000))


cpquery(dados.vendas.bnfit,
        event = (VENDA < 13500),
        evidence = (BEBIDA >= 5500 & PRATO <= 6000))


cpquery(dados.vendas.bnfit,
        event = (BEBIDA < 3300),
        evidence = (VENDA >= 5100))
serie.temporal <- ts(data.transform$VENDA, start=c(2010, 1), end=c(2017, 12), frequency=12)

# Teste de Estacionaridade(p-value < 0.05)
Box.test(serie.temporal, lag=20, type="Ljung-Box")

#Centralizar os Titulos
theme_update(plot.title = element_text(hjust = 0.5))
ggplot() + ggtitle()

title.Serie.temporal <- stri_encode("Series Temporais - Vendas de Milkshake", "", "UTF-8")
autoplot(serie.temporal, main = title.Serie.temporal, xlab="Tempo", ylab="Vendas")

#Ajuste - Modelo ARIMA
fitArima <- auto.arima(serie.temporal)

#Ajuste - Modelo Exponencial
fitExponencial <- ets(serie.temporal)

#Ajuste - Modelo TBATS
fitTBats <- tbats(serie.temporal)

#Ajuste - Modelo Neural Network
lambda = BoxCox.lambda(serie.temporal)
fitNeural <- nnetar(serie.temporal, repeats=1000, lambda=lambda)

# Precisao dos Modelos
exponencial.acc <-accuracy(fitExponencial)
arima.acc <-accuracy(fitArima)
tbats.acc <-accuracy(fitTBats)
neural.acc <- accuracy(fitNeural)

#Erro Percentual Absoluto MÃ©dio (MAPE)
dataSetMAPE <- c(Neural=neural.acc[,'MAPE'], 
                 ARIMA=arima.acc[,'MAPE'], 
                 TBATS=tbats.acc[,'MAPE'],
                 Exponencial=exponencial.acc[,'MAPE'])
dataSetMAPE

#Erro percentual Absoluto MÃ©dio
barplot(dataSetMAPE,
        main = "Erro Percentual Absoluto MÃ©dio (MAPE)",
        col="light blue",
        ylab="MAPE")


# Previsao do 1 Semestre de 2017
forecast(fitArima, 6)
forecast(fitNeural, 6)
forecast(fitTBats, 6)
forecast(fitExponencial, 6)


#Plot
titleForecast <- stri_encode("Previsao de Vendas de Produtos", "", "UTF-8")
autoplot(forecast(fitTBats, 6), main = titleForecast, xlab="Tempo", ylab="Vendas")

forecast(fitTBats, 6)