
install.packages(c("quantmod", "vars", "xts", "frequencyConnectedness", "ConnectednessApproach"))

# PACKAGES
library(quantmod)
library(vars)
library(xts)
library(frequencyConnectedness)
library(ConnectednessApproach)

# DOWNLOAD DATA
start <- "2013-01-01"
end   <- "2025-01-01"

getSymbols("^NSEI", src="yahoo", from=start, to=end)
getSymbols("^GSPC", src="yahoo", from=start, to=end)
getSymbols("^VIX",  src="yahoo", from=start, to=end)
getSymbols("CL=F",  src="yahoo", from=start, to=end)

spx  <- Cl(GSPC)
nifty  <- Cl(NSEI)
vix <- VIX$VIX.Close
oil    <- Cl(`CL=F`) 


# Merge
market_data <- merge(nifty, spx, vix, oil)
colnames(market_data) <- c("NIFTY","SPX","VIX","OIL")
summary(market_data)



weekend_index <- .indexwday(market_data) %in% c(0, 6)
market_data_clean <- market_data[!weekend_index]

market_data_clean <- na.approx(market_data_clean)  # Interpolate
market_data_clean <- na.locf(market_data_clean)     # Forward fill any remaining
summary(market_data_clean)


market_returns <- diff(log(market_data_clean)) * 100
market_returns <- market_returns[-1, ]
market_returns <- na.omit(market_returns) # omititng 2 nas in oil

plot.xts(market_returns, main ="log returns plot", multi.panel = TRUE)

# VAR
lag <- VARselect(market_returns, lag.max=10)$selection["SC(n)"]

var_model <- vars::VAR(market_returns, p=lag, type="const")
var_model
summary(var_model)

# STATIC DY12    
sp12 <- spilloverDY12(var_model, n.ahead=20, no.corr=FALSE)
print(sp12)

overall(sp12)
to(sp12)
from(sp12)
net(sp12)
pairwise(sp12)



# DYNAMIC CONNECTEDNESS
dca_dyn <- ConnectednessApproach(
  market_returns,
  nlag=lag,
  nfore=20,
  window.size=180,
  model="VAR",
  connectedness="Time",
  Connectedness_config=list(TimeConnectedness=list(generalized=TRUE))
)

summary(dca_dyn$TCI)
TCI_xts <- as.xts(dca_dyn$TCI)
# Date of maximum connectedness
max_TCI <- TCI_xts[which.max(TCI_xts)]
max_TCI

# Date of minimum connectedness
min_TCI <- TCI_xts[which.min(TCI_xts)]
min_TCI

plot.xts(as.xts(dca_dyn$TCI), main="Total Connectedness Index",grid.ticks.lty = 0)





cols <- c("black","red","lightgreen","blue") 

plot.xts(as.xts(dca_dyn$NET),
         main="Net Spillovers",
         col=cols,,grid.ticks.lty = 0,
         legend.loc="topright")
summary(dca_dyn$NET)






idx_nifty <- 1
idx_spx   <- 2
idx_vix   <- 3
idx_oil   <- 4

dates <- as.Date(dimnames(dca_dyn$CT)[[3]])

spx_to_nifty <- xts(dca_dyn$CT[idx_nifty, idx_spx, ], order.by = dates)
nifty_to_spx <- xts(dca_dyn$CT[idx_spx, idx_nifty, ], order.by = dates)

plot.xts(
  merge(spx_to_nifty, nifty_to_spx),
  main = "Dynamic Spillovers: SPX ↔ NIFTY",
  col = c("red", "blue"),
  legend.loc = "topright"
)



vix_to_nifty <- xts(dca_dyn$CT[idx_nifty, idx_vix, ], order.by = dates)
nifty_to_vix <- xts(dca_dyn$CT[idx_vix, idx_nifty, ], order.by = dates)

plot.xts(
  merge(vix_to_nifty, nifty_to_vix),
  main = "Dynamic Spillovers: VIX ↔ NIFTY",
  col = c("purple", "blue"),
  legend.loc = "topright"
)


oil_to_nifty <- xts(dca_dyn$CT[idx_nifty, idx_oil, ], order.by = dates)
nifty_to_oil <- xts(dca_dyn$CT[idx_oil, idx_nifty, ], order.by = dates)

plot.xts(
  merge(oil_to_nifty, nifty_to_oil),
  main = "Dynamic Spillovers: OIL ↔ NIFTY",
  col = c("darkgreen", "blue"),
  legend.loc = "topright"
)



global_to_nifty <- merge(spx_to_nifty, vix_to_nifty, oil_to_nifty)
colnames(global_to_nifty) <- c("SPX_to_NIFTY", "VIX_to_NIFTY", "OIL_to_NIFTY")

plot.xts(
  global_to_nifty,
  main = "Dynamic Spillovers to NIFTY",
  col = c("red", "purple", "darkgreen"),
  legend.loc = "topright"
)





# AVERAGE SPILLOVERS DURING CRISIS PERIODS ( 3 spikes in TCI)
crisis_2015 <- "2015-06/2016-03"
crisis_2020 <- "2020-02/2020-06"
crisis_2022 <- "2022-02/2022-09"

crisis_table <- data.frame(
  Period = c("2015–16", "COVID", "2022"),
  SPX = c(
    mean(spx_to_nifty[crisis_2015]),
    mean(spx_to_nifty[crisis_2020]),
    mean(spx_to_nifty[crisis_2022])
  )*100,
  VIX = c(
    mean(vix_to_nifty[crisis_2015]),
    mean(vix_to_nifty[crisis_2020]),
    mean(vix_to_nifty[crisis_2022])
  )*100,
  OIL = c(
    mean(oil_to_nifty[crisis_2015]),
    mean(oil_to_nifty[crisis_2020]),
    mean(oil_to_nifty[crisis_2022])
  )*100
)
# average spillovers during crisis periods
crisis_table


ConnectednessApproach::PlotNetwork(
  dca_dyn,
  method="NPDC",
  threshold=0,
  width=8,
  height=8
)
 