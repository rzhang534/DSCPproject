
# Fall24_STAT605_Group10_Accelerating-Brazil-Weather-Forecasting-with-CHTC


## Overview
This project aims to predict Brazilian weather using statistical modeling techniques. Hourly Brazilian weather dataset is used and time series and machine learning techniques are applied to build predictive models for key meteorological indicators. CHTC is used to accelerate both training and forecasting.


## Repository Structure
- `data/`: Our data after preprocessing and cleaning are stored on CHTC: /home/groups/STAT_DSCP/project3/DataCleaned
- `code/`: Includes all codes used for modeling and parallel computing submission files
- `visualization/`: Includes some visualization plots explored by our data
- `report/`: Includes proposal and report files


## Statistical Analysis
Key variables, including temperature, pressure, precipitation, and humidity, were selected for training. Auto-ARIMA was applied to those with clear time series patterns using a 7:3 train-test split. For variables with weak time-series characteristics, such as precipitation, a random forest model is employed for prediction. 


