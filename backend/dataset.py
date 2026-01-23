import db
from graph import Graph
from dataset_nodes import classes as dataset_nodes_classes
import pandas as pd
from pandas import DataFrame
import base64
import json


async def create_dataset(args={}) -> str:
    dataset_name = args['dataset_name']
    db.execute("""
        INSERT INTO Datasets (dataset_name)
        VALUES (?)
        """, (dataset_name,))
    return dataset_name + " created."


async def get_datasets(args={}) -> list:
    return db.execute_fetch_all("SELECT (dataset_id, dataset_name, dataset_graph) FROM Datasets ORDER BY created_at DESC")


async def delete_dataset(args={}):
    db.execute("DELETE FROM Datasets WHERE dataset_id = ?", (args['dataset_id'],))


async def update_dataset(args={}):
    db.execute("""
        UPDATE Datasets
        SET dataset_name = ?, dataset_graph = ?
        WHERE dataset_id = ?
        """, (args['dataset_name'], json.dumps(args['dataset_graph']), args['dataset_id'],))


async def execute_dataset_graph(args={}):
    dataset_name = args['dataset_name']
    graph = Graph(args['nodes'], args['connections'], dataset_nodes_classes)
    output: DataFrame = await graph.calculate_output()
    output.info()
    file_name = dataset_name + ".csv"
    file_path = f"./csv/{file_name}"
    output.to_csv(file_path, index=False)
    return {'file_name': file_name}
    

async def download_dataset(args={}) -> str:
    dataset_name = args.get('dataset_name')

    file_path = f"./csv/{dataset_name}.csv"
    df = pd.read_csv(file_path)
    csv_bytes = df.to_csv(index=False).encode("utf-8")

    return {
        "file_name": f"{dataset_name}.csv",
        "csv_base64": base64.b64encode(csv_bytes).decode("ascii")
    }

