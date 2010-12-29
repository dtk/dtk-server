/*
Copyright (c) 2010, Yahoo! Inc. All rights reserved.
Code licensed under the BSD License:
http://developer.yahoo.com/yui/license.html
version: 3.3.0pr3
build: 3110
*/
YUI.add("base-build",function(d){var b=d.Base,a=d.Lang,c;b._build=function(f,n,r,v,u,q){var w=b._build,g=w._ctor(n,q),k=w._cfg(n,q),t=w._mixCust,p=k.aggregates,e=k.custom,j=g._yuibuild.dynamic,o,m,h,s;if(j&&p){for(o=0,m=p.length;o<m;++o){h=p[o];if(n.hasOwnProperty(h)){g[h]=a.isArray(n[h])?[]:{};}}}for(o=0,m=r.length;o<m;o++){s=r[o];d.mix(g,s,true,null,1);t(g,s,p,e);g._yuibuild.exts.push(s);}if(v){d.mix(g.prototype,v,true);}if(u){d.mix(g,w._clean(u,p,e),true);t(g,u,p,e);}g.prototype.hasImpl=w._impl;if(j){g.NAME=f;g.prototype.constructor=g;}return g;};c=b._build;d.mix(c,{_mixCust:function(g,f,i,h){if(i){d.aggregate(g,f,true,i);}if(h){for(var e in h){if(h.hasOwnProperty(e)){h[e](e,g,f);}}}},_tmpl:function(e){function f(){f.superclass.constructor.apply(this,arguments);}d.extend(f,e);return f;},_impl:function(h){var n=this._getClasses(),m,f,e,k,o,g;for(m=0,f=n.length;m<f;m++){e=n[m];if(e._yuibuild){k=e._yuibuild.exts;o=k.length;for(g=0;g<o;g++){if(k[g]===h){return true;}}}}return false;},_ctor:function(e,f){var h=(f&&false===f.dynamic)?false:true,i=(h)?c._tmpl(e):e,g=i._yuibuild;if(!g){g=i._yuibuild={};}g.id=g.id||null;g.exts=g.exts||[];g.dynamic=h;return i;},_cfg:function(e,f){var g=[],j={},i,h=(f&&f.aggregates),l=(f&&f.custom),k=e;while(k&&k.prototype){i=k._buildCfg;if(i){if(i.aggregates){g=g.concat(i.aggregates);}if(i.custom){d.mix(j,i.custom,true);}}k=k.superclass?k.superclass.constructor:null;}if(h){g=g.concat(h);}if(l){d.mix(j,f.cfgBuild,true);}return{aggregates:g,custom:j};},_clean:function(m,k,g){var j,f,e,h=d.merge(m);for(j in g){if(h.hasOwnProperty(j)){delete h[j];}}for(f=0,e=k.length;f<e;f++){j=k[f];if(h.hasOwnProperty(j)){delete h[j];}}return h;}});b.build=function(g,e,h,f){return c(g,e,h,null,null,f);};b.create=function(e,h,g,f,i){return c(e,h,g,f,i);};b.mix=function(e,f){return c(null,e,f,null,null,{dynamic:false});};b._buildCfg={custom:{ATTRS:function(j,h,f){h.ATTRS=h.ATTRS||{};if(f.ATTRS){var g=f.ATTRS,i=h.ATTRS,e;for(e in g){if(g.hasOwnProperty(e)){i[e]=i[e]||{};d.mix(i[e],g[e],true);}}}}},aggregates:["_PLUG","_UNPLUG"]};},"3.3.0pr3",{requires:["base-base"]});