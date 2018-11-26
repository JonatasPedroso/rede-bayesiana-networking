library(forecast)
library(ggplot2)
library(stringi)

#Leitura do Arquivo vendas.txt
vendas = read.table('data/serieVendas.csv', header=TRUE, sep=";")
vendas$venda<- as.numeric(vendas$venda)

#Serie Temporal
serieTemporal <- ts(vendas$venda, start=c(2010, 1), end=c(2016, 12), frequency=12)

#Teste Estacionariedade
#p-value < 0.05 = serie é estacionária
Box.test(serieTemporal, lag=20, type="Ljung-Box")

#Centralizar Titulo
theme_update(plot.title = element_text(hjust = 0.5))
ggplot() + ggtitle()

#Auto Plot - Serie Temporal
titleSerieTemporal <- stri_encode("Series Temporais - Vendas de Produtos", "", "UTF-8")
autoplot(serieTemporal, main = titleSerieTemporal, xlab="Tempo", ylab="Vendas")

#Ajuste - Modelo ARIMA
fitArima <- auto.arima(serieTemporal)

#Ajuste - Modelo Exponencial
fitExponencial <- ets(serieTemporal)

#Ajuste - Modelo TBATS
fitTBats <- tbats(serieTemporal)

#Ajuste - Modelo Neural Network
lambda = BoxCox.lambda(serieTemporal)
fitNeural <- nnetar(serieTemporal,repeats=1000,lambda=lambda)




# Precisao dos Modelos
exponencial.acc <-accuracy(fitExponencial)
arima.acc <-accuracy(fitArima)
tbats.acc <-accuracy(fitTBats)
neural.acc <- accuracy(fitNeural)

#Erro Percentual Absoluto Médio (MAPE)
dataSetMAPE <- c(Neural=neural.acc[,'MAPE'], 
                 ARIMA=arima.acc[,'MAPE'], 
                 TBATS=tbats.acc[,'MAPE'],
                 Exponencial=exponencial.acc[,'MAPE'])
dataSetMAPE

#Erro percentual Absoluto Médio
barplot(dataSetMAPE,
        main = "Erro Percentual Absoluto Médio (MAPE)",
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
