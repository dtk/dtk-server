

R8.Templating.render_basic_component = function(templateVars) {
	var compDiv = document.createElement('div');
	compDiv.setAttribute('id',templateVars['id']);
	compDiv.setAttribute('class', templateVars['template']+'-component component');
	compDiv.setAttribute('style','top:'+templateVars['top']+'px; left:'+templateVars['left']+'px;');

	var tlCorner = document.createElement('div');
	tlCorner.setAttribute('class',templateVars['template']+'-tl-corner corner');
	compDiv.appendChild(tlCorner);

	var compHeader = document.createElement('div');
	compHeader.setAttribute('class','header');
	compDiv.appendChild(compHeader);

	var trCorner = document.createElement('div');
	trCorner.setAttribute('class',templateVars['template']+'-tr-corner corner');
	compDiv.appendChild(trCorner);

	var mainCompBody = document.createElement('div');
	mainCompBody.innerHTML = templateVars['name'];
	mainCompBody.setAttribute('class','body');
	mainCompBody.setAttribute('id',templateVars['id']+'-body');
	compDiv.appendChild(mainCompBody);

	var blCorner = document.createElement('div');
	blCorner.setAttribute('class',templateVars['template']+'-bl-corner corner');
	compDiv.appendChild(blCorner);

	var compFooter = document.createElement('div');
	compFooter.setAttribute('class','footer');
	compDiv.appendChild(compFooter);

	var brCorner = document.createElement('div');
	brCorner.setAttribute('class',templateVars['template']+'-br-corner corner');
	compDiv.appendChild(brCorner);

	return compDiv;
};