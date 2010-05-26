var workspaceComponents = {
	'comp1': {
		'id' : 'comp1',
		'type': 'component',
		'name': 'Apache',
		'connectors': {
			'xyz': {
				'type': 'fullBezier',
				'startElement': {
					'elemID': 'comp1',
					'location': 'west',
					'connectElemID': 'comp1-west-0',
				},
				'endElements': [{
					'elemID': 'comp2',
					'location': 'east',
					'connectElemID': 'comp2-east-0'
				}]
			}
		},
		'inUsePorts': [],
		'availPorts': {
			'north': [{
				'id': '0',
				'type': 'basic',
				'location':'north'
			}],
			'south': [{
				'id': '0',
				'type': 'basic',
				'location':'south'
			},{
				'id': '1',
				'type': 'basic',
				'location':'south'
			},{
				'id': '2',
				'type': 'basic',
				'location':'south'
			},{
				'id': '3',
				'type': 'basic',
				'location':'south'
			}],
			'east': [{
				'id': '0',
				'type': 'basic',
				'location':'east'
			},{
				'id': '1',
				'type': 'basic',
				'location':'east'
			}],
			'west': [{
				'id': '0',
				'type': 'basic',
				'location':'west'
			},{
				'id': '1',
				'type': 'basic',
				'location':'west'
			}],
		},
		'top':350,
		'left':460,
		'template':'basic'
	},
	'comp2': {
		'id' : 'comp2',
		'type': 'component',
		'name': 'PgPool',
		'connectors':{
			'xyz': {
				'type': 'fullBezier',
				'startElement': {
					'elemID': 'comp1',
					'location': 'west',
					'connectElemID': 'comp1-west-0',
				},
				'endElements': [{
					'elemID': 'comp2',
					'location': 'east',
					'connectElemID': 'comp2-east-0'
				}]
			}
		},
		'inUsePorts': [],
		'availPorts': {
			'north': [{
				'id': '0',
				'type': 'basic',
				'location':'north'
			}],
			'south': [{
				'id': '0',
				'type': 'basic',
				'location':'south'
			}],
			'east': [{
				'id': '0',
				'type': 'basic',
				'location':'east'
			}],
			'west': [{
				'id': '0',
				'type': 'basic',
				'location':'west'
			}],
		},
		'top':120,
		'left':250,
		'template':'basic'
	},
/*
	'comp3': {
		'id' : 'comp3',
		'type': 'component',
		'name': 'Postgres Master',
		'inUseConnectors': [],
		'availConnectors': {
			'north': [{
				'id': '0',
				'type': 'basic'
			}],
			'south': [{
				'id': '0',
				'type': 'basic'
			},{
				'id': '1',
				'type': 'basic'
			}],
			'east': [{
				'id': '0',
				'type': 'basic'
			}],
			'west': [{
				'id': '0',
				'type': 'basic'
			},{
				'id': '3',
				'type': 'basic'
			}],
		},
		'top':100,
		'left':300,
		'template':'basic'
	}
*/
};

var workspacePorts = {
	'comp1-south-0' : {'compID':'comp1','location':'south','id':'0','type':'basic'},
	'comp1-south-1' : {'compID':'comp1','location':'south','id':'1','type':'basic'},
	'comp1-south-2' : {'compID':'comp1','location':'south','id':'2','type':'basic'},
	'comp1-south-3' : {'compID':'comp1','location':'south','id':'3','type':'basic'},
	'comp1-west-0' : {'compID':'comp1','location':'west','id':'0','type':'basic'},
	'comp1-west-1' : {'compID':'comp1','location':'west','id':'1','type':'basic'},
	'comp1-north-0' : {'compID':'comp1','location':'north','id':'0','type':'basic'},
	'comp1-east-0' : {'compID':'comp1','location':'east','id':'0','type':'basic'},
	'comp1-east-1' : {'compID':'comp1','location':'east','id':'1','type':'basic'},
	'comp2-south-0' : {'compID':'comp2','location':'south','id':'0','type':'basic'},
	'comp2-west-0' : {'compID':'comp2','location':'west','id':'0','type':'basic'},
	'comp2-north-0' : {'compID':'comp2','location':'north','id':'0','type':'basic'},
	'comp2-east-0' : {'compID':'comp2','location':'east','id':'0','type':'basic'},
}

var workspaceConnectors = {
	'xyz': {
		'type': 'fullBezier',
		'startElement': {
			'elemID': 'comp1',
			'location': 'west',
			'connectElemID': 'comp1-west-0',
		},
		'endElements': [{
			'elemID': 'comp2',
			'location': 'east',
			'connectElemID': 'comp2-east-0'
		}]
	}
};
/*
	'abc': {
		'type':'fullBezier',
		'startElement': {
			'elemID': 'comp1',
			'connectFacing': 'south',
			'connectElemID': 'comp1-s-1'
		},
		'endElements': [{
			'elemID': 'comp3',
			'connectFacing': 'north',
			'connectElemID': 'comp3-n-0'
		}]
	},
	'fffc': {
		'type':'fullBezier',
		'startElement': {
			'elemID': 'comp1',
			'connectFacing': 'south',
			'connectElemID': 'comp1-s-3'
		},
		'endElements': [{
			'elemID': 'comp2',
			'connectFacing': 'north',
			'connectElemID': 'comp2-n-0'
		}]
	}
};
*/