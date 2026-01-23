class_name ClusterUtils
extends Script


static func get_k3d_cluster_state(cluster: Dictionary) -> String:
	if !cluster.has('serversRunning') or !cluster.has('serversCount') or !cluster.has('agentsRunning') or !cluster.has('agentsCount'):
		return 'Error reading status'
	if cluster['serversRunning'] == cluster['serversCount'] and cluster['agentsRunning'] == cluster['agentsCount']:
		return 'Running'
	elif cluster['serversRunning'] == 0 and cluster['agentsRunning'] == 0:
		return 'Stopped'
	else:
		return 'Partially running'
