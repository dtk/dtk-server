/*
Copyright (c) 2010, Yahoo! Inc. All rights reserved.
Code licensed under the BSD License:
http://developer.yahoo.com/yui/license.html
version: 3.3.0pr3
build: 3110
*/
YUI.add("pluginhost-base",function(C){var A=C.Lang;function B(){this._plugins={};}B.prototype={plug:function(G,D){var E,H,F;if(A.isArray(G)){for(E=0,H=G.length;E<H;E++){this.plug(G[E]);}}else{if(G&&!A.isFunction(G)){D=G.cfg;G=G.fn;}if(G&&G.NS){F=G.NS;D=D||{};D.host=this;if(this.hasPlugin(F)){this[F].setAttrs(D);}else{this[F]=new G(D);this._plugins[F]=G;}}}return this;},unplug:function(F){var E=F,D=this._plugins;if(F){if(A.isFunction(F)){E=F.NS;if(E&&(!D[E]||D[E]!==F)){E=null;}}if(E){if(this[E]){this[E].destroy();delete this[E];}if(D[E]){delete D[E];}}}else{for(E in this._plugins){if(this._plugins.hasOwnProperty(E)){this.unplug(E);}}}return this;},hasPlugin:function(D){return(this._plugins[D]&&this[D]);},_initPlugins:function(D){this._plugins=this._plugins||{};if(this._initConfigPlugins){this._initConfigPlugins(D);}},_destroyPlugins:function(){this.unplug();}};C.namespace("Plugin").Host=B;},"3.3.0pr3",{requires:["yui-base"]});YUI.add("pluginhost-config",function(C){var B=C.Plugin.Host,A=C.Lang;B.prototype._initConfigPlugins=function(E){var G=(this._getClasses)?this._getClasses():[this.constructor],D=[],H={},F,I,K,L,J;for(I=G.length-1;I>=0;I--){F=G[I];L=F._UNPLUG;if(L){C.mix(H,L,true);}K=F._PLUG;if(K){C.mix(D,K,true);}}for(J in D){if(D.hasOwnProperty(J)){if(!H[J]){this.plug(D[J]);}}}if(E&&E.plugins){this.plug(E.plugins);}};B.plug=function(E,I,G){var J,H,D,F;if(E!==C.Base){E._PLUG=E._PLUG||{};if(!A.isArray(I)){if(G){I={fn:I,cfg:G};}I=[I];}for(H=0,D=I.length;H<D;H++){J=I[H];F=J.NAME||J.fn.NAME;E._PLUG[F]=J;}}};B.unplug=function(E,H){var I,G,D,F;if(E!==C.Base){E._UNPLUG=E._UNPLUG||{};if(!A.isArray(H)){H=[H];}for(G=0,D=H.length;G<D;G++){I=H[G];F=I.NAME;if(!E._PLUG[F]){E._UNPLUG[F]=I;}else{delete E._PLUG[F];}}}};},"3.3.0pr3",{requires:["pluginhost-base"]});YUI.add("pluginhost",function(A){},"3.3.0pr3",{use:["pluginhost-base","pluginhost-config"]});