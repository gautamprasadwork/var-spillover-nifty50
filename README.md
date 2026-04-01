# Global Financial Spillovers to NIFTY 50
## VAR Spillover Analysis — S&P 500, VIX, WTI Crude Oil

> **Financial Econometrics Research Project** | MSc Quantitative Finance | PUEB | 2025  
> **Author:** Gautam Prasad | [LinkedIn](https://linkedin.com/in/gautamprasadwork)

---

## Research Question

> *How do global financial market shocks transmit to NIFTY 50, and is NIFTY 50 a net transmitter or receiver of cross-market spillovers?*

---

## What This Project Is About

This project applies the **Diebold-Yilmaz (2012) VAR Spillover methodology** to quantify financial risk transmission across four global markets over a 12-year daily horizon (2013–2025):

| Asset | Ticker | Role |
|---|---|---|
| NIFTY 50 | ^NSEI | Indian equity benchmark |
| S&P 500 | ^GSPC | US equity market |
| VIX | ^VIX | Global fear / risk sentiment |
| WTI Crude Oil | CL=F | Commodity / geopolitical risk |

The methodology produces directional spillover measures — identifying which markets **transmit** risk and which **receive** it — with both static (full-sample) and **dynamic (rolling window)** connectedness measures.

---

## Repository Structure

```
var-spillover-nifty/
│
├── spillover_analysis.R        # Complete R script — data download to results
├── presentation.pdf            # Slides with all charts and findings
├── README.md
│
└── plots/
    ├── log_returns.png         # Log return series for all 4 assets
    ├── tci_dynamic.png         # Total Connectedness Index (2013–2024)
    ├── net_spillovers.png      # Net spillover: transmitter vs receiver
    ├── pairwise_spx_nifty.png  # Dynamic spillover: SPX ↔ NIFTY
    ├── pairwise_vix_nifty.png  # Dynamic spillover: VIX ↔ NIFTY
    ├── pairwise_oil_nifty.png  # Dynamic spillover: OIL ↔ NIFTY
    └── network_plot.png        # Connectedness network diagram
```

---

## Methodology

### Step 1 — Data Transformation

Daily closing prices downloaded from Yahoo Finance via `quantmod`. Transformed to **log-returns**:

```r
market_returns <- diff(log(market_data_clean)) * 100
```

Log-returns ensure stationarity and comparability across markets with different price levels.

### Step 2 — VAR Model Estimation

A **Vector Autoregression (VAR)** model estimated on the 4-variable return system. Lag length selected using the **Schwarz Information Criterion (SIC/BIC)**:

```r
lag <- VARselect(market_returns, lag.max=10)$selection["SC(n)"]
var_model <- vars::VAR(market_returns, p=lag, type="const")
```

**Result:** VAR(2) selected. All characteristic roots < 1 → model is stable.

### Step 3 — Diebold-Yilmaz (2012) Spillover Decomposition

**Generalised Forecast Error Variance Decomposition (FEVD)** — measures how much of the forecast error variance of one market is explained by shocks from other markets:

```r
sp12 <- spilloverDY12(var_model, n.ahead=20, no.corr=FALSE)
```

This produces:
- **Total Connectedness Index (TCI)** — overall system interconnectedness
- **Directional spillovers TO** each market (how much each transmits)
- **Directional spillovers FROM** each market (how much each receives)
- **Net spillovers** = TO − FROM (positive = net transmitter)
- **Pairwise spillovers** — bilateral connectedness between any two markets

### Step 4 — Dynamic Connectedness (Rolling Window)

VAR re-estimated on a **180-day rolling window** to capture time-varying spillover dynamics:

```r
dca_dyn <- ConnectednessApproach(
  market_returns, nlag=lag, nfore=20,
  window.size=180, model="VAR",
  connectedness="Time",
  Connectedness_config=list(TimeConnectedness=list(generalized=TRUE))
)
```

---

## Key Results

### Static Spillover Table (Full Sample: 2013–2025)

|  | NIFTY | SPX | VIX | OIL | FROM |
|---|---|---|---|---|---|
| **NIFTY** | 74.77 | 14.51 | 8.65 | 2.07 | **6.31** |
| **SPX** | 8.11 | 57.97 | 31.11 | 2.80 | 10.51 |
| **VIX** | 3.86 | 33.43 | 60.67 | 2.05 | 9.83 |
| **OIL** | 1.03 | 4.81 | 3.27 | 90.89 | 2.28 |
| **TO** | 3.25 | 13.19 | 10.76 | 1.73 | **TCI = 28.9%** |

**Net Spillovers:**
| Market | Net Value | Role |
|---|---|---|
| S&P 500 | +2.68 | **Net transmitter** |
| VIX | +0.92 | **Net transmitter** |
| NIFTY 50 | −3.06 | **Net receiver** |
| Crude Oil | −0.55 | Net receiver |

### Dynamic TCI Summary

| Metric | Value | Event |
|---|---|---|
| Average TCI | 32.6% | Full sample |
| **Maximum TCI** | **53.5%** | March 2020 — COVID-19 crash |
| Minimum TCI | 18.6% | July 2024 — stable period |

Crisis period spillover spikes:
- **2015–16** (Yuan devaluation, Demonetisation, Brexit): TCI ~45%
- **COVID-19 (2020)**: TCI ~50%
- **Russia-Ukraine War (2022)**: TCI ~42%

### Average SPX → NIFTY Spillover During Crisis Periods

| Period | SPX→NIFTY | VIX→NIFTY | OIL→NIFTY |
|---|---|---|---|
| 2015–16 | 15.5% | 17.3% | 2.4% |
| COVID-19 | 19.3% | 7.3% | 8.1% |
| 2022 | 17.8% | 16.4% | 2.0% |

---

## Conclusions

1. **NIFTY 50 is primarily a net receiver** of global return spillovers — structurally dependent on US equity market direction and global risk sentiment
2. **S&P 500 is the dominant transmitter** — NIFTY absorbs more shocks from SPX than from any other market
3. **Spillover intensity is crisis-driven** — connectedness spikes during major global events, confirming contagion dynamics
4. **VIX transmits strongly during non-COVID crises** (2015–16, 2022) but less so during COVID when all markets fell simultaneously
5. **Policy implication:** Indian equity portfolios cannot be considered insulated from global financial shocks

---

## Tools & Libraries

```r
library(quantmod)                  # Data download
library(vars)                      # VAR estimation
library(xts)                       # Time series handling
library(frequencyConnectedness)    # Diebold-Yilmaz spillovers
library(ConnectednessApproach)     # Dynamic connectedness
```

---

## How to Run

```r
# Install required packages
install.packages(c("quantmod", "vars", "xts", "frequencyConnectedness", "ConnectednessApproach"))

# Run the complete analysis
source("spillover_analysis.R")

# Data downloads automatically from Yahoo Finance (requires internet)
# All plots generated in sequence
```

---

## References

- Diebold, F.X. and Yilmaz, K. (2012). *Better to Give than to Receive: Predictive Directional Measurement of Volatility Spillovers.* International Journal of Forecasting, 28(1), 57–66.
- Antonakakis, N., Chatziantoniou, I., and Gabauer, D. (2020). *Refined Measures of Dynamic Connectedness Based on TVP-VAR.* JRI.

---

## Author

**Gautam Prasad**  
MSc Quantitative Finance — PUEB, Poznań, Poland  
[linkedin.com/in/gautamprasadwork](https://linkedin.com/in/gautamprasadwork)
