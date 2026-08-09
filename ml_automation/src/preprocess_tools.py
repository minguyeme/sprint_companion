import numpy as np
import pandas as pd

def decouple_streams(master_df):
    raw_accel = master_df.filter(regex="^raw_accel_").drop_duplicates()
    raw_accel = raw_accel.rename(columns=lambda x: x.replace("raw_accel_", ""))

    clean_accel = master_df.filter(regex="^clean_accel_").drop_duplicates()
    clean_accel = clean_accel.rename(columns=lambda x: x.replace("clean_accel_", ""))

    gyro = master_df.filter(regex="^gyro_").drop_duplicates()
    gyro = gyro.rename(columns=lambda x: x.replace("gyro_", ""))

    zero_timestamp = min(raw_accel['timestamp'].iloc[0], clean_accel['timestamp'].iloc[0], gyro['timestamp'].iloc[0])

    raw_accel['timestamp'] = raw_accel['timestamp'] - zero_timestamp
    clean_accel['timestamp'] = clean_accel['timestamp'] - zero_timestamp
    gyro['timestamp'] = gyro['timestamp'] - zero_timestamp

    return raw_accel, clean_accel, gyro
