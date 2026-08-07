import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from IPython.display import display

def check_sampling_rates(path):
    df = pd.read_csv(path)

    timestamp_cols = [
        "raw_accel_timestamp",
        "clean_accel_timestamp",
        "gyro_timestamp",
        "gps_timestamp",
    ]

    for timestamp_col in timestamp_cols:
        unique_timestamps = df[[timestamp_col]].drop_duplicates()
        delta = unique_timestamps.diff().rename(columns={timestamp_col: "delta"})
        summary = unique_timestamps.join(delta)

        display(summary)
        print(f"Summary for {timestamp_col}")
        print(f"Median delta: {delta.iloc[1:,0].median()}")
        print(f"Max delta: {delta.iloc[1:,0].max()}")

def plot_sensor_streams(path):
    df = pd.read_csv(path)
    
    fig, axes = plt.subplots(nrows=3, ncols=1, figsize=(18, 11))
    axes = axes.flatten()

    gps_start_idx = df.columns.get_loc("gps_timestamp")
    gps_df = df.iloc[:, gps_start_idx : gps_start_idx + 3].drop_duplicates()
    gps_df["gps_timestamp"] = gps_df["gps_timestamp"] - gps_df["gps_timestamp"].iloc[0]

    data_cols = ["raw_accel_", "clean_accel_", "gyro_"]
    for i, sensor_cols in enumerate(data_cols):
        sensor_df = df.filter(regex=f"^{sensor_cols}").drop_duplicates()

        timestamp_col = f"{sensor_cols}timestamp"
        sensor_df[timestamp_col] = (
            sensor_df[timestamp_col] - sensor_df[timestamp_col].iloc[0]
        )

        sensor_df[f"{sensor_cols}magnitude"] = np.sqrt(
            sensor_df[f"{sensor_cols}x"] ** 2
            + sensor_df[f"{sensor_cols}y"] ** 2
            + sensor_df[f"{sensor_cols}z"] ** 2
        )

        axes[i].set_title(sensor_cols[:-1])
        axes[i].plot(sensor_df[timestamp_col], sensor_df[f"{sensor_cols}magnitude"])

        ax_speed = axes[i].twinx()
        ax_speed.plot(gps_df["gps_timestamp"], gps_df["speed"], color="green")
        ax_speed.fill_between(
            gps_df["gps_timestamp"],
            gps_df["speed"] - gps_df["speed_accuracy"],
            gps_df["speed"] + gps_df["speed_accuracy"],
            color="green",
            alpha=0.15,
        )
        axes[i].set_xticks(np.arange(0, sensor_df[timestamp_col].iloc[-1], 1000), minor=True)
        axes[i].grid(True, which='minor', axis='x', alpha=0.5)
        axes[i].grid(True, which='major', axis='x', alpha=1)

    plt.tight_layout()
    plt.show()
    plt.close("all")
