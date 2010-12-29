/*
Copyright (c) 2010, Yahoo! Inc. All rights reserved.
Code licensed under the BSD License:
http://developer.yahoo.com/yui/license.html
version: 3.3.0pr3
build: 3110
*/
YUI.add("io-xdr",function(c){var l=c.publish("io:xdrReady",{fireOnce:true}),g={},h={},k=c.config.doc,m=c.config.win,b=m&&m.XDomainRequest;function i(d,q){var n='<object id="yuiIoSwf" type="application/x-shockwave-flash" data="'+d+'" width="0" height="0">'+'<param name="movie" value="'+d+'">'+'<param name="FlashVars" value="yid='+q+'">'+'<param name="allowScriptAccess" value="always">'+"</object>",p=k.createElement("div");k.body.appendChild(p);p.innerHTML=n;}function a(d,n){d.c.onprogress=function(){h[d.id]=3;};d.c.onload=function(){h[d.id]=4;c.io.xdrResponse(d,n,"success");};d.c.onerror=function(){h[d.id]=4;c.io.xdrResponse(d,n,"failure");};if(n.timeout){d.c.ontimeout=function(){h[d.id]=4;c.io.xdrResponse(d,n,"timeout");};d.c.timeout=n.timeout;}}function e(r,q,n){var p,d;if(!r.e){p=q?decodeURI(r.c.responseText):r.c.responseText;d=n==="xml"?c.DataType.XML.parse(p):null;return{id:r.id,c:{responseText:p,responseXML:d}};}else{return{id:r.id,e:r.e};}}function j(d,n){return d.c.abort(d.id,n);}function f(d){return b?h[d.id]!==4:d.c.isInProgress(d.id);}c.mix(c.io,{_transport:{},xdr:function(d,n,p){if(p.xdr.use==="flash"){g[n.id]={on:p.on,context:p.context,arguments:p.arguments};p.context=null;p.form=null;m.setTimeout(function(){if(n.c){n.c.send(d,p,n.id);}else{c.io.xdrResponse(n,p,"transport error");}},c.io.xdr.delay);}else{if(b){a(n,p);n.c.open(p.method||"GET",d);n.c.send(p.data);}else{n.c.send(d,n,p);}}return{id:n.id,abort:function(){return n.c?j(n,p):false;},isInProgress:function(){return n.c?f(n.id):false;}};},xdrResponse:function(s,u,r){var n,d=b?h:g,q=u.xdr.use==="flash"?true:false,p=u.xdr.dataType;u.on=u.on||{};if(q){n=g[s.id]?g[s.id]:null;if(n){u.on=n.on;u.context=n.context;u.arguments=n.arguments;}}switch(r){case"start":c.io.start(s.id,u);break;case"complete":c.io.complete(s,u);break;case"success":c.io.success(p||q?e(s,q,p):s,u);delete d[s.id];break;case"timeout":case"abort":case"transport error":s.e=r;case"failure":c.io.failure(p||q?e(s,q,p):s,u);delete d[s.id];break;}},xdrReady:function(d){c.io.xdr.delay=0;c.fire(l,d);},transport:function(p){var q=p.yid||c.id,d=p.id||"flash",n=c.UA.ie?p.src+"?d="+new Date().valueOf().toString():p.src;if(d==="native"||d==="flash"){i(n,q);this._transport.flash=k.getElementById("yuiIoSwf");}else{if(d){this._transport[p.id]=p.src;}}}});c.io.xdr.delay=50;},"3.3.0pr3",{requires:["io-base","datatype-xml"]});