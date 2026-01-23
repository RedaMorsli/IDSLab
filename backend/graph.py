from abc import ABC, abstractmethod


class GraphNode(ABC):
        id: int
        name: str
        params: dict

        def __init__(self, id, name, params):
            self.id = id
            self.name = name
            self.params = params
        
        @abstractmethod
        def get_output_data(self, input_data: list, output_port: int):
            pass
            

class GraphLink:
        from_node: GraphNode
        from_port: int
        to_node: GraphNode
        to_port: int

        def __init__(self, from_node, from_port, to_node, to_port):
            self.from_node = from_node
            self.from_port = from_port
            self.to_node = to_node
            self.to_port = to_port


class Graph:    
    nodes = []
    links = []
    output_node: GraphNode = None

    def __init__(self, p_nodes: list, p_links: list, node_classes: dict = {}):
        self.nodes = []
        self.links = []
        for dict in p_nodes:
            node = node_classes[dict['node_name']](dict['node_id'], dict['node_name'], dict['params'])
            self.nodes.append(node)
            if 'output' in node.name:
                self.output_node = node
        for dict in p_links:
            self.links.append(GraphLink(self.get_node_by_id(dict['from_node']), dict['from_port'], self.get_node_by_id(dict['to_node']), dict['to_port']))
    

    async def calculate_output(self):
        return await self._calculate_output(self.output_node, 0)


    def get_node_by_id(self, node_id: int) -> GraphNode:
        for node in self.nodes:
            if node.id == node_id:
                return node
        return None

    async def _get_input_nodes_ports(self, node: GraphNode) -> list[GraphNode, int]:
        selected_links = []
        for link in self.links:
            if link.to_node.id == node.id:
                selected_links.append(link)
        selected_links.sort(key=lambda l: l.from_port)
        inputs = []
        for link in selected_links:
            inputs.append((link.from_node, link.from_port))
        return inputs
    

    async def _calculate_output(self, node: GraphNode, output_port: int):
        input_nodes_ports = await self._get_input_nodes_ports(node)
        input_data = []
        for input_node, input_port in input_nodes_ports:
            data = await self._calculate_output(input_node, input_port)
            input_data.append(data)
        return await node.get_output_data(input_data, output_port)
