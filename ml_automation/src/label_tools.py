import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def plot_stream(path, zoom=False, loc=2000, scale=2000):
    df = pd.read_csv(path)

    fig, ax = plt.subplots(figsize=(18, 6))

    sensor_cols = "clean_accel_"
    sensor_df = df.filter(regex=f"^{sensor_cols}").drop_duplicates()

    timestamp_col = f"{sensor_cols}timestamp"
    sensor_df[timestamp_col] = (
        sensor_df[timestamp_col] - sensor_df[timestamp_col].iloc[0]
    )
    if zoom == True:
        sensor_df = sensor_df[
            (sensor_df[timestamp_col] <= loc + scale)
            & (sensor_df[timestamp_col] >= loc - scale)
        ]

    sensor_df[f"{sensor_cols}magnitude"] = np.sqrt(
        sensor_df[f"{sensor_cols}x"] ** 2
        + sensor_df[f"{sensor_cols}y"] ** 2
        + sensor_df[f"{sensor_cols}z"] ** 2
    )

    ax.plot(sensor_df[timestamp_col], sensor_df[f"{sensor_cols}magnitude"])

    ax.set_title(sensor_cols[:-1])

    if zoom == False:
        ax.set_xticks(
            np.arange(
                sensor_df[timestamp_col].iloc[0],
                sensor_df[timestamp_col].iloc[-1] + 1000,
                1000,
            ),
            minor=True,
        )
        ax.grid(True, which="minor", axis="x", alpha=0.5)
        ax.grid(True, which="major", axis="x", alpha=1)
    else:
        ax.grid(True, which="major", axis="x", alpha=0.5)

    plt.tight_layout()
    return ax

def mark(path, df, ax, *timestamps):
    df.loc[path] = timestamps

    for timestamp in timestamps:
        ax.axvline(x=timestamp, color="green", linestyle="--", linewidth=2)
