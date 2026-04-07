import pandas as pd
from pandas import DataFrame
import numpy as np

# "ts,processName,container_id,hostName,podName,arg_len,arg_sockfd,arg_addrlen,argsNum,returnValue,time_since_prev_global_s,time_since_prev_same_container_s,rc1_container,rc5_container,rm5_len_container"

async def timestamp(df: DataFrame) -> pd.Series:
    return df.apply(parse_date, axis=1)


async def container_id(df: DataFrame) -> pd.Series:
    return df.apply(lambda r: (r.get("container") or {}).get("id") if isinstance(r.get("container"), dict) else np.nan, axis=1)


async def process_name(df: DataFrame) -> pd.Series:
    return df.get("processName", "").astype(str)


async def host_name(df: DataFrame) -> pd.Series:
    return df.get("hostName", "").astype(str)


async def pod_name(df: DataFrame) -> pd.Series:
    return df.apply(lambda r: (r.get("kubernetes") or {}).get("podName") if isinstance(r.get("kubernetes"), dict) else np.nan, axis=1)


async def argsNum(df: DataFrame) -> pd.Series:
    return pd.to_numeric(df.get("argsNum", np.nan), errors="coerce")


async def return_value(df: DataFrame) -> pd.Series:
    return pd.to_numeric(df.get("returnValue", np.nan), errors="coerce")


def _get_arg_value(args_list, name):
    if not isinstance(args_list, list):
        return np.nan
    for arg in args_list:
        if isinstance(arg, dict) and arg.get("name") == name:
            try:
                return float(arg["value"])
            except (TypeError, ValueError):
                return np.nan
    return np.nan


async def arg_len(df: DataFrame) -> pd.Series:
    return df["args"].apply(lambda a: _get_arg_value(a, "len"))


async def arg_sockfd(df: DataFrame) -> pd.Series:
    return df["args"].apply(lambda a: _get_arg_value(a, "sockfd"))


async def arg_addrlen(df: DataFrame) -> pd.Series:
    return df["args"].apply(lambda a: _get_arg_value(a, "addrlen"))


def _compute_ts(df: DataFrame) -> pd.Series:
    return df.apply(parse_date, axis=1)


def _compute_container_id(df: DataFrame) -> pd.Series:
    return df.apply(lambda r: (r.get("container") or {}).get("id") if isinstance(r.get("container"), dict) else None, axis=1)


async def time_since_prev_global_s(df: DataFrame) -> pd.Series:
    ts = _compute_ts(df)
    sorted_ts = ts.sort_values()
    diff = sorted_ts.diff().dt.total_seconds()
    return diff.reindex(df.index)


async def time_since_prev_same_container_s(df: DataFrame) -> pd.Series:
    ts = _compute_ts(df)
    cid = _compute_container_id(df)
    work = pd.DataFrame({"ts": ts, "cid": cid}).sort_values("ts")
    diff = work.groupby("cid", sort=False)["ts"].diff().dt.total_seconds()
    return diff.reindex(df.index)


def _rolling_per_container(df: DataFrame, window: str, value_col: pd.Series, agg: str) -> pd.Series:
    ts = _compute_ts(df)
    cid = _compute_container_id(df)
    work = pd.DataFrame({"ts": ts, "cid": cid, "val": value_col})
    valid = work.dropna(subset=["ts"]).sort_values("ts")

    out = pd.Series(np.nan, index=df.index)
    for _, group in valid.groupby("cid", sort=False):
        g = group.set_index("ts")["val"]
        rolled = g.rolling(window).sum() if agg == "sum" else g.rolling(window).mean()
        for orig_idx, val in zip(group.index, rolled.values):
            out[orig_idx] = val
    return out.fillna(0.0)


async def rc1_container(df: DataFrame) -> pd.Series:
    ones = pd.Series(1.0, index=df.index)
    return _rolling_per_container(df, "1s", ones, "sum")


async def rc5_container(df: DataFrame) -> pd.Series:
    ones = pd.Series(1.0, index=df.index)
    return _rolling_per_container(df, "5s", ones, "sum")


async def rm5_len_container(df: DataFrame) -> pd.Series:
    lens = df["args"].apply(lambda a: _get_arg_value(a, "len"))
    return _rolling_per_container(df, "5s", lens, "mean")


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
