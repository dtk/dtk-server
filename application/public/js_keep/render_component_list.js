function render_component_list(tplVars,renderType) {
	var doc = document;
	var div_tplRoot= document.createElement("div");
	var br0= document.createElement("br");
	div_tplRoot.appendChild(br0);
	//end rendering for element br0

	var br1= document.createElement("br");
	div_tplRoot.appendChild(br1);
	//end rendering for element br1

	var div2= document.createElement("div");
	div2.setAttribute("style","width: 100%;");
	var div3= document.createElement("div");
	div3.setAttribute("style","width: 100%;");
	var div4= document.createElement("div");
	div4.setAttribute("style","float: right; margin-right: 10px;");
	var a5= document.createElement("a");
	a5.setAttribute("href","javascript:R8.ctrl.request('component/list?listStart=" + tplVars['listStartPrev'] + "');");
	var txtSpan17= document.createElement("span");
	txtSpan17.innerHTML = "&lt;-Prev";
	a5.appendChild(txtSpan17);
	div4.appendChild(a5);
	//end rendering for element a5

	var txtSpan21= document.createElement("span");
	txtSpan21.innerHTML = "&nbsp;&nbsp;&nbsp;&nbsp;";
	div4.appendChild(txtSpan21);
	var a6= document.createElement("a");
	a6.setAttribute("href","javascript:R8.ctrl.request('component/list?listStart=" + tplVars['listStartNext'] + "');");
	var txtSpan25= document.createElement("span");
	txtSpan25.innerHTML = "Next-&gt;";
	a6.appendChild(txtSpan25);
	div4.appendChild(a6);
	//end rendering for element a6

	div3.appendChild(div4);
	//end rendering for element div4

	div2.appendChild(div3);
	//end rendering for element div3

	var div7= document.createElement("div");
	div7.setAttribute("style","width: 100%; float: left;");
	var table8= document.createElement("table");
	table8.setAttribute("cellspacing","0");
	table8.setAttribute("cellpadding","0");
	table8.setAttribute("border","1");
	table8.setAttribute("style","width: 100%;");
	var tr9= document.createElement("tr");
	tr9.setAttribute("id","component-list-header-row");
	tr9.setAttribute("class","");
	var th10= document.createElement("th");
	th10.setAttribute("id","display_name-th");
	th10.setAttribute("class","r8-td-col");
	var txtSpan46= document.createElement("span");
	txtSpan46.innerHTML = "Name";
	th10.appendChild(txtSpan46);
	tr9.appendChild(th10);
	//end rendering for element th10

	var th11= document.createElement("th");
	th11.setAttribute("id","description-th");
	th11.setAttribute("class","r8-td-col");
	var txtSpan53= document.createElement("span");
	txtSpan53.innerHTML = "Description";
	th11.appendChild(txtSpan53);
	tr9.appendChild(th11);
	//end rendering for element th11

	table8.appendChild(tr9);
	//end rendering for element tr9

	for(var component in tplVars['component_list']) { 
		var tr12= document.createElement("tr");
		tr12.setAttribute("id","listRow-" + component);
		tr12.setAttribute("class",tplVars['component_list'][component]['class']);
		var td13= document.createElement("td");
		td13.setAttribute("id","display_name-td-" + component);
		td13.setAttribute("class","r8-td-col");
		var a14= document.createElement("a");
		a14.setAttribute("href","javascript:R8.ctrl.request('obj=component&action=display&id=" + tplVars['component_list'][component]['id'] + "');");
		var txtSpan68= document.createElement("span");
		txtSpan68.innerHTML = tplVars['component_list'][component]['display_name'];
		a14.appendChild(txtSpan68);
		td13.appendChild(a14);
		//end rendering for element a14

		tr12.appendChild(td13);
		//end rendering for element td13

		var td15= document.createElement("td");
		td15.setAttribute("id","description-td-" + component);
		td15.setAttribute("class","r8-td-col");
		var txtSpan77= document.createElement("span");
		txtSpan77.innerHTML = tplVars['component_list'][component]['description'];
		td15.appendChild(txtSpan77);
		tr12.appendChild(td15);
		//end rendering for element td15

		table8.appendChild(tr12);
		//end rendering for element tr12

	}
	div7.appendChild(table8);
	//end rendering for element table8

	div2.appendChild(div7);
	//end rendering for element div7

	div_tplRoot.appendChild(div2);
	//end rendering for element div2

	if(R8.Utils.isUndefined(renderType) || renderType !='append') {
		doc.getElementById("leftColPanel").innerHTML="";
	}
	doc.getElementById("leftColPanel").appendChild(div_tplRoot);
}
