function render_component_display(tplVars,renderType) {
	var doc = document;
	var div_tplRoot= document.createElement("div");
	var button0= document.createElement("button");
	button0.setAttribute("id","editBtn");
	button0.setAttribute("onclick","R8.forms.submit('component-display-form');");
	var txtSpan6= document.createElement("span");
	txtSpan6.innerHTML = "Edit";
	button0.appendChild(txtSpan6);
	div_tplRoot.appendChild(button0);
	//end rendering for element button0

	var form1= document.createElement("form");
	form1.setAttribute("id","component-display-form");
	form1.setAttribute("action","index.php");
	var input2= document.createElement("input");
	input2.setAttribute("type","hidden");
	input2.setAttribute("name","obj");
	input2.setAttribute("id","obj");
	input2.setAttribute("value","component");
	form1.appendChild(input2);
	//end rendering for element input2

	var input3= document.createElement("input");
	input3.setAttribute("type","hidden");
	input3.setAttribute("name","action");
	input3.setAttribute("id","action");
	input3.setAttribute("value","save");
	form1.appendChild(input3);
	//end rendering for element input3

	var input4= document.createElement("input");
	input4.setAttribute("type","hidden");
	input4.setAttribute("name","id");
	input4.setAttribute("id","id");
	input4.setAttribute("value","");
	form1.appendChild(input4);
	//end rendering for element input4

	div_tplRoot.appendChild(form1);
	//end rendering for element form1

	var table5= document.createElement("table");
	table5.setAttribute("cellspacing","0");
	table5.setAttribute("cellpadding","0");
	table5.setAttribute("border","0");
	var tr6= document.createElement("tr");
	tr6.setAttribute("id","g0-r0");
	var td7= document.createElement("td");
	td7.setAttribute("id","display_name-label");
	td7.setAttribute("class","r8-label-edit");
	var txtSpan45= document.createElement("span");
	txtSpan45.innerHTML = "Name";
	td7.appendChild(txtSpan45);
	tr6.appendChild(td7);
	//end rendering for element td7

	var td8= document.createElement("td");
	td8.setAttribute("id","display_name-field");
	td8.setAttribute("class","r8-field-edit");
	var txtSpan52= document.createElement("span");
	txtSpan52.innerHTML = tplVars['component']['display_name'];
	td8.appendChild(txtSpan52);
	tr6.appendChild(td8);
	//end rendering for element td8

	table5.appendChild(tr6);
	//end rendering for element tr6

	var tr9= document.createElement("tr");
	tr9.setAttribute("id","g0-r1");
	var td10= document.createElement("td");
	td10.setAttribute("id","description-label");
	td10.setAttribute("class","r8-label-edit");
	var txtSpan63= document.createElement("span");
	txtSpan63.innerHTML = "Description";
	td10.appendChild(txtSpan63);
	tr9.appendChild(td10);
	//end rendering for element td10

	var td11= document.createElement("td");
	td11.setAttribute("id","description-field");
	td11.setAttribute("class","r8-field-edit");
	var txtSpan70= document.createElement("span");
	txtSpan70.innerHTML = tplVars['component']['description'];
	td11.appendChild(txtSpan70);
	tr9.appendChild(td11);
	//end rendering for element td11

	table5.appendChild(tr9);
	//end rendering for element tr9

	div_tplRoot.appendChild(table5);
	//end rendering for element table5

	if(R8.Utils.isUndefined(renderType) || renderType !='append') {
		doc.getElementById("appBodyPanel").innerHTML="";
	}
	doc.getElementById("appBodyPanel").appendChild(div_tplRoot);
}
