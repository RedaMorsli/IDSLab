from graph import GraphNode
import minioapi
import pandas as pd
from pandas import DataFrame
import io
import event_features


class InputNode(GraphNode):
    async def get_output_data(self, input_data: list, output_port: int):
        bucket_name = self.params['bucket_name']
        file_paths = self.params['file_pahts']
        dataframes = []

        for obj_path in file_paths:
            content = await minioapi.get_object_content(bucket_name, obj_path)
            if not content.strip():
                continue

            df = pd.read_json(io.StringIO(content), lines=True)
            dataframes.append(df)

            if not dataframes:
                return DataFrame()

        return pd.concat(dataframes, ignore_index=True)


class OutputNode(GraphNode):
    async def get_output_data(self, input_data: list, output_port: int):
        return input_data[0]


class FeatureExtractionNode(GraphNode):
    async def get_output_data(self, input_data: list, output_port: int):
        df: DataFrame = input_data[0]
        selected_columns = self.params['features']
        result = DataFrame()
        for col in selected_columns:
            if hasattr(event_features, col) and callable(getattr(event_features, col)):
                result[col] = await getattr(event_features, col)(df)
        return result



LABELING_OPERATORS = {
    '=':  lambda col, val: col == val,
    '!=': lambda col, val: col != val,
}


class LabelingNode(GraphNode):
    async def get_output_data(self, input_data: list, output_port: int):
        df: DataFrame = input_data[0].copy()

        for entry in self.params['labels']:
            op_fn = LABELING_OPERATORS[entry['operator']]
            df.loc[op_fn(df[entry['column']], entry['value']), 'label'] = entry['label']

        return df


classes = {
    'dataset_file_input_node': InputNode,
    'dataset_output_node': OutputNode,
    'dataset_feature_extraction_node': FeatureExtractionNode,
    'dataset_labeling_node': LabelingNode,
}