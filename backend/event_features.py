import pandas as pd
from pandas import DataFrame
import numpy as np

# "ts,processName,container_id,hostName,podName,arg_len,arg_sockfd,arg_addrlen,argsNum,returnValue,time_since_prev_global_s,time_since_prev_same_container_s,rc1_container,rc5_container,rm5_len_containe"

async def timestamp(df: DataFrame) -> DataFrame:
    return df.apply(parse_date, axis=1)


async def container_id(df: DataFrame) -> DataFrame:
    return df.apply(lambda r: (r.get("container") or {}).get("id") if isinstance(r.get("container"), dict) else np.nan, axis=1)


async def process_name(df: DataFrame) -> DataFrame:
    return df.get("processName", "").astype(str)


async def host_name(df: DataFrame) -> DataFrame:
    return df.get("hostName", "").astype(str)


async def pod_name(df: DataFrame) -> DataFrame:
    return df.apply(lambda r: (r.get("kubernetes") or {}).get("podName") if isinstance(r.get("kubernetes"), dict) else np.nan, axis=1)


# async def arg_len(df: DataFrame) -> DataFrame:
#     return pd.to_datetime(df['timestamp'])


def parse_date(row):
    if pd.notna(row.get("date")):
        try:
            return pd.to_datetime(row["date"], utc=True)
        except Exception:
            pass
    ts = row.get("timestamp")
    if pd.notna(ts):
        try:
            return pd.to_datetime(int(ts), unit="ns", utc=True)
        except Exception:
            try:
                return pd.to_datetime(float(ts), unit="s", utc=True)
            except Exception:
                return pd.NaT
    return pd.NaT
