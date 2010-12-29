/*
Copyright (c) 2010, Yahoo! Inc. All rights reserved.
Code licensed under the BSD License:
http://developer.yahoo.com/yui/license.html
version: 3.3.0pr3
build: 3110
*/
YUI.add("event-synthetic",function(b){var h=b.Env.evt.dom_map,d=b.Array,g=b.Lang,j=g.isObject,c=g.isString,e=b.Selector.query,i=function(){};function f(l,k){this.handle=l;this.emitFacade=k;}f.prototype.fire=function(q){var k=d(arguments,0,true),o=this.handle,p=o.evt,m=o.sub,r=m.context,l=m.filter,n=q||{};if(this.emitFacade){if(!q||!q.preventDefault){n=p._getFacade();if(j(q)&&!q.preventDefault){b.mix(n,q,true);k[0]=n;}else{k.unshift(n);}}n.type=p.type;n.details=k.slice();if(l){n.container=p.host;}}else{if(l&&j(q)&&q.currentTarget){k.shift();}}m.context=r||n.currentTarget||p.host;p.fire.apply(p,k);m.context=r;};function a(){this._init.apply(this,arguments);}b.mix(a,{Notifier:f,getRegistry:function(q,p,n){var o=q._node,m=b.stamp(o),l="event:"+m+p+"_synth",k=h[m]||(h[m]={});if(!k[l]&&n){k[l]={type:"_synth",fn:i,capture:false,el:o,key:l,domkey:m,notifiers:[],detachAll:function(){var r=this.notifiers,s=r.length;while(--s>=0){r[s].detach();}}};}return(k[l])?k[l].notifiers:null;},_deleteSub:function(l){if(l&&l.fn){var k=this.eventDef,m=(l.filter)?"detachDelegate":"detach";this.subscribers={};this.subCount=0;k[m](l.node,l,this.notifier,l.filter);k._unregisterSub(l);delete l.fn;delete l.node;delete l.context;}},prototype:{constructor:a,_init:function(){var k=this.publishConfig||(this.publishConfig={});this.emitFacade=("emitFacade" in k)?k.emitFacade:true;k.emitFacade=false;},processArgs:i,on:i,detach:i,delegate:i,detachDelegate:i,_on:function(n,p){var o=[],l=this.processArgs(n,p),k=n[2],r=p?"delegate":"on",m,q;m=(c(k))?e(k):d(k);if(!m.length&&c(k)){q=b.on("available",function(){b.mix(q,b[r].apply(b,n),true);},k);return q;}b.Array.each(m,function(t){var u=n.slice(),s;t=b.one(t);if(t){if(p){s=u.splice(3,1)[0];}u.splice(0,4,u[1],u[3]);if(!this.preventDups||!this.getSubs(t,n,null,true)){q=this._getNotifier(t,u,l,s);this[r](t,q.sub,q.notifier,s);o.push(q);}}},this);return(o.length===1)?o[0]:new b.EventHandle(o);},_getNotifier:function(n,q,o,m){var s=new b.CustomEvent(this.type,this.publishConfig),p=s.on.apply(s,q),r=new f(p,this.emitFacade),l=a.getRegistry(n,this.type,true),k=p.sub;p.notifier=r;k.node=n;k.filter=m;if(o){this.applyArgExtras(o,k);}b.mix(s,{eventDef:this,notifier:r,host:n,currentTarget:n,target:n,el:n._node,_delete:a._deleteSub},true);l.push(p);return p;},applyArgExtras:function(k,l){l._extra=k;},_unregisterSub:function(m){var k=a.getRegistry(m.node,this.type),l;if(k){for(l=k.length-1;l>=0;--l){if(k[l].sub===m){k.splice(l,1);break;}}}},_detach:function(m){var r=m[2],p=(c(r))?e(r):d(r),q,o,k,n,l;m.splice(2,1);for(o=0,k=p.length;o<k;++o){q=b.one(p[o]);if(q){n=this.getSubs(q,m);if(n){for(l=n.length-1;l>=0;--l){n[l].detach();}}}}},getSubs:function(l,q,k,n){var r=a.getRegistry(l,this.type),s=[],m,p,o;if(r){if(!k){k=this.subMatch;}for(m=0,p=r.length;m<p;++m){o=r[m];if(k.call(this,o.sub,q)){if(n){return o;}else{s.push(r[m]);}}}}return s.length&&s;},subMatch:function(l,k){return !k[1]||l.fn===k[1];}}},true);b.SyntheticEvent=a;b.Event.define=function(m,l,o){if(!l){l={};}var n=(j(m))?m:b.merge({type:m},l),p,k;if(o||!b.Node.DOM_EVENTS[n.type]){p=function(){a.apply(this,arguments);};b.extend(p,a,n);k=new p();m=k.type;b.Node.DOM_EVENTS[m]=b.Env.evt.plugins[m]={eventDef:k,on:function(){return k._on(d(arguments));},delegate:function(){return k._on(d(arguments),true);},detach:function(){return k._detach(d(arguments));}};}return k;};},"3.3.0pr3",{requires:["node-base","event-custom"]});