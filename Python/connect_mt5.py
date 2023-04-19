import MetaTrader5 as mt5
import pandas as pd
from datetime import datetime
import time

timeframe_names = {
    mt5.TIMEFRAME_M1: "M1",
    mt5.TIMEFRAME_M5: "M5",
    mt5.TIMEFRAME_M15: "M15",
    mt5.TIMEFRAME_H1: "H1",
}

# set the timeframes
timeframes = [mt5.TIMEFRAME_M1, mt5.TIMEFRAME_M5, mt5.TIMEFRAME_M15, mt5.TIMEFRAME_H1]

# loop through each USD pair and extract the candles
usd_pairs = ['AUDUSD', 'EURUSD', 'GBPUSD', 'NZDUSD', 'USDCAD', 'USDCHF', 'USDJPY']

########################################################################################

def extract_candles(symbol, timeframes):
    # create an empty DataFrame to store the OHLC data
    data = pd.DataFrame(columns=["time", "open", "high", "low", "close", "volume"])

    # loop through each timeframe
    for tf in timeframes:
        # get the number of candles to load (4 in this case)
        num_candles = 5
        # get the OHLC data for the specified symbol and timeframe
        ohlc = mt5.copy_rates_from_pos(symbol, tf, 0, num_candles)
            
        # add the OHLC data to the DataFrame
        data = pd.concat([data, pd.DataFrame(ohlc, columns=["time", "open", "high", "low", "close", "volume"])])

    # convert the time column to a datetime object
    data["time"] = pd.to_datetime(data["time"], unit="s")

    # return the OHLC data
    return data
    
##########################################################################################
        
# connect to MetaTrader 5
if not mt5.initialize():
    print("Failed to initialize MetaTrader 5")
    exit()

while True:    
    for symbol in usd_pairs:        
        # extract the candles
        ohlc = extract_candles(symbol, timeframes)
        
        # save the OHLC data to a txt file
        ohlc.to_csv(f"{symbol}_ohlc_data.txt", index=False)
           
    time.sleep(5)

# account_info = mt5.account_info()
# print(account_info)

# disconnect from MetaTrader 5
mt5.shutdown()
