# ehm
A model of the English Housing Market in NetLogo

originally by Nigel Gilbert, John C. Hawksworth, and Paul A. Swinney

Centre for Research in Social Simulation, University of Surrey, Guildford, UK
email: n.gilbert@surrey.ac.uk
web: http://cress.soc.surrey.ac.uk
PricewaterhouseCoopers LLP, 1 Embankment Place, London WC2N 6RH, UK

Our main objective in this research was to see if we could replicate key features of real world housing market behaviour using a simple stylised agent-based model. The UK housing market is characterised by a number of basic relationships that have persisted through 'bubbles' and 'crashes'. These include:

Prices are sensitive to prevailing interest rates. A rise in the mortgage interest rate will reduce the price that potential owners can afford, unless there is a change in Affordability, that is, the proportion of income that is spent on housing costs.

Newcomers to the market ('first time buyers') are important in maintaining prices. Without newcomers, the number of owners will decrease (through migration and death) and house prices will drift downwards due to a lack of demand.

Sharp increases in demand for housing (demand 'shocks') are slow to filter through to increases in supply, because it is difficult to increase the housing stock quickly. Hence an upward demand shock will result in an immediate general increase in house prices, which is slowly relaxed as more houses come onto the market.
Sharp reductions in housing demand will, in contrast, be reflected in correspondingly sharp reductions in supply, with relatively less impact on the general level of prices.

The model does not simulate any particular geographical location. There is intentionally no attempt to represent either the characteristics of individual housing units, nor spatial attributes such as distance to an urban centre or proximity to facilities. Houses are differentiated only by a neighbourhood index that is based on the prices at which other houses in the locality have been sold. Households move either when forced to exit the area (e.g. due to death or a job relocation) or when their mortgages become too expensive for their income, when they try to trade down, or when their incomes rise to the point where they can comfortably afford a more expensive house. Having decided to sell, they approach one or more nearby realtors for valuations, which are based on the realtor's experience of recent price levels in that locality. The seller puts the house on the market at the highest valuation initially but reduces the price later if it does not sell. Buyers look for a house that best suits their income level.

### Disclaimer
This model has been prepared for general guidance on matters of interest only, and does not constitute professional advice. The results are purely illustrative. You should not act upon any results from this model without obtaining specific professional advice. No representation or warranty (express or implied) is given as to the accuracy or completeness of the model, and, to the extent permitted by law, PricewaterhouseCoopers, its members, employees and agents accept no liability, and disclaim all responsibility, for the consequences of you or anyone else acting, or refraining to act, in reliance on the model or for any decision based on it.

Copyright 2008-10 PricewaterhouseCoopers LLP. All rights reserved. "PricewaterhouseCoopers" refers to PricewaterhouseCoopers LLP (a limited liability partnership in the United Kingdom).

To refer to this model in academic literature, cite: Gilbert, N, Hawksworth, J C, and Sweeney, P (2008) 'An Agent-based Model of the UK Housing Market'. University of Surrey http://cress.soc.surrey.ac.uk/housingmarket/index.html
