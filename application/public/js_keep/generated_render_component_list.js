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
	a5.setAttribute("href","javascript:R8.ctrl.request('component/list?listStart=" + tplVars['listStartPrev']);
	var txtSpan17= document.createElement("span");
	txtSpan17.innerHTML = "&lt;-Prev";
	a5.appendChild(txtSpan17);
	div4.appendChild(a5);
	//end rendering for element a5
	
	var txtSpan21= document.createElement("span");
	txtSpan21.innerHTML = "&nbsp;&nbsp;&nbsp;&nbsp;";
	div4.appendChild(txtSpan21);
	var a6= document.createElement("a");
	a6.setAttribute("href","javascript:R8.ctrl.request('component/list?listStart=" + tplVars['listStartNext']);
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
	th10.setAttribute("id","name-th");
	th10.setAttribute("class","r8-td-col");
	var txtSpan46= document.createElement("span");
	txtSpan46.innerHTML = "name";
	th10.appendChild(txtSpan46);
	tr9.appendChild(th10);
	//end rendering for element th10
	
	var th11= document.createElement("th");
	th11.setAttribute("id","is_active-th");
	th11.setAttribute("class","r8-td-col");
	var txtSpan53= document.createElement("span");
	txtSpan53.innerHTML = "is_active";
	th11.appendChild(txtSpan53);
	tr9.appendChild(th11);
	//end rendering for element th11
	
	var th12= document.createElement("th");
	th12.setAttribute("id","select_one-th");
	th12.setAttribute("class","r8-td-col");
	var txtSpan60= document.createElement("span");
	txtSpan60.innerHTML = "select_one";
	th12.appendChild(txtSpan60);
	tr9.appendChild(th12);
	//end rendering for element th12
	
	var th13= document.createElement("th");
	th13.setAttribute("id","description-th");
	th13.setAttribute("class","r8-td-col");
	var txtSpan67= document.createElement("span");
	txtSpan67.innerHTML = "description";
	th13.appendChild(txtSpan67);
	tr9.appendChild(th13);
	//end rendering for element th13
	
	var th14= document.createElement("th");
	th14.setAttribute("id","select_two-th");
	th14.setAttribute("class","r8-td-col");
	var txtSpan74= document.createElement("span");
	txtSpan74.innerHTML = "select_two";
	th14.appendChild(txtSpan74);
	tr9.appendChild(th14);
	//end rendering for element th14
	
	var th15= document.createElement("th");
	th15.setAttribute("id","radiobtn-th");
	th15.setAttribute("class","r8-td-col");
	var txtSpan81= document.createElement("span");
	txtSpan81.innerHTML = "radiobtn";
	th15.appendChild(txtSpan81);
	tr9.appendChild(th15);
	//end rendering for element th15
	
	var th16= document.createElement("th");
	th16.setAttribute("id","date_created-th");
	th16.setAttribute("class","r8-td-col");
	var txtSpan88= document.createElement("span");
	txtSpan88.innerHTML = "date_created";
	th16.appendChild(txtSpan88);
	tr9.appendChild(th16);
	//end rendering for element th16
	
	table8.appendChild(tr9);
	//end rendering for element tr9
	
	for(var component in tplVars['component_list']) { 
		var tr17= document.createElement("tr");
		tr17.setAttribute("id","listRow-" + component);
		tr17.setAttribute("class",tplVars['component_list'][component]['class']);
		var td18= document.createElement("td");
		td18.setAttribute("id","name-td-" + component);
		td18.setAttribute("class","r8-td-col");
		tr17.appendChild(td18);
		//end rendering for element td18
		
		var txtSpan103= document.createElement("span");
		txtSpan103.innerHTML = "a href="javascript:R8.ctrl.request('obj=componentaction=displayid=" + tplVars['component_list'][component]['id'] + "');"" + tplVars['component_list'][component]['name'];
		tr17.appendChild(txtSpan103);
		table8.appendChild(tr17);
		//end rendering for element tr17
		
		div7.appendChild(table8);
		//end rendering for element table8
		
		var td19= document.createElement("td");
		td19.setAttribute("id","is_active-td-" + component);
		td19.setAttribute("class","r8-td-col");
		div7.appendChild(td19);
		//end rendering for element td19
		
		var txtSpan114= document.createElement("span");
		txtSpan114.innerHTML = "input disabled="disabled" type="checkbox" id="is_active" name="is_active" class="r8-checkbox" value="1" checked="" + tplVars['component_list'][component]['is_active'];
		div7.appendChild(txtSpan114);
		div2.appendChild(div7);
		//end rendering for element div7
		
		var td20= document.createElement("td");
		td20.setAttribute("id","select_one-td-" + component);
		td20.setAttribute("class","r8-td-col");
		div2.appendChild(td20);
		//end rendering for element td20
		
		var txtSpan123= document.createElement("span");
		txtSpan123.innerHTML = tplVars['component_list'][component]['select_one'];
		div2.appendChild(txtSpan123);
		div_tplRoot.appendChild(div2);
		//end rendering for element div2
		
		var td21= document.createElement("td");
		td21.setAttribute("id","description-td-" + component);
		td21.setAttribute("class","r8-td-col");
		div_tplRoot.appendChild(td21);
		//end rendering for element td21
		
		var txtSpan132= document.createElement("span");
		txtSpan132.innerHTML = tplVars['component_list'][component]['description'];
		div_tplroot.appendChild(txtSpan132);
		if(R8.Utils.isUndefined(renderType) || renderType !='append') {
			doc.getElementById("mainBodyPanel").innerHTML="";
		}
		doc.getElementById("mainBodyPanel").appendChild(div_tplRoot);
	}
