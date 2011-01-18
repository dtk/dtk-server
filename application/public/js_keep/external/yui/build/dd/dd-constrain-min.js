/*
Copyright (c) 2010, Yahoo! Inc. All rights reserved.
Code licensed under the BSD License:
http://developer.yahoo.com/yui/license.html
version: 3.3.0pr3
build: 3110
*/
YUI.add("dd-constrain",function(B){var M="dragNode",O="offsetHeight",F="offsetWidth",R="host",G="tickXArray",P="tickYArray",Q=B.DD.DDM,E="top",K="right",N="bottom",D="left",L="view",I=null,J="drag:tickAlignX",H="drag:tickAlignY",A=function(C){this._lazyAddAttrs=false;A.superclass.constructor.apply(this,arguments);};A.NAME="ddConstrained";A.NS="con";A.ATTRS={host:{},stickX:{value:false},stickY:{value:false},tickX:{value:false},tickY:{value:false},tickXArray:{value:false},tickYArray:{value:false},gutter:{value:"0",setter:function(C){return B.DD.DDM.cssSizestoObject(C);}},constrain:{value:L,setter:function(C){var S=B.one(C);if(S){C=S;}return C;}},constrain2region:{setter:function(C){return this.set("constrain",C);}},constrain2node:{setter:function(C){return this.set("constrain",B.one(C));}},constrain2view:{setter:function(C){return this.set("constrain",L);}},cacheRegion:{value:true}};I={_lastTickXFired:null,_lastTickYFired:null,initializer:function(){this._createEvents();this.get(R).on("drag:end",B.bind(this._handleEnd,this));this.get(R).on("drag:start",B.bind(this._handleStart,this));this.get(R).after("drag:align",B.bind(this.align,this));this.get(R).after("drag:drag",B.bind(this.drag,this));},_createEvents:function(){var C=this;var S=[J,H];B.each(S,function(U,T){this.publish(U,{type:U,emitFacade:true,bubbles:true,queuable:false,prefix:"drag"});},this);},_handleEnd:function(){this._lastTickYFired=null;this._lastTickXFired=null;},_handleStart:function(){this.resetCache();},_regionCache:null,_cacheRegion:function(){this._regionCache=this.get("constrain").get("region");},resetCache:function(){this._regionCache=null;},_getConstraint:function(){var C=this.get("constrain"),S=this.get("gutter"),T;if(C){if(C instanceof B.Node){if(!this._regionCache){B.on("resize",B.bind(this._cacheRegion,this),B.config.win);this._cacheRegion();}T=B.clone(this._regionCache);if(!this.get("cacheRegion")){this.resetCache();}}else{if(B.Lang.isObject(C)){T=B.clone(C);}}}if(!C||!T){C=L;}if(C===L){T=this.get(R).get(M).get("viewportRegion");}B.each(S,function(U,V){if((V==K)||(V==N)){T[V]-=U;}else{T[V]+=U;}});return T;},getRegion:function(V){var T={},U=null,C=null,S=this.get(R);T=this._getConstraint();if(V){U=S.get(M).get(O);C=S.get(M).get(F);T[K]=T[K]-C;T[N]=T[N]-U;}return T;},_checkRegion:function(C){var T=C,V=this.getRegion(),U=this.get(R),W=U.get(M).get(O),S=U.get(M).get(F);if(T[1]>(V[N]-W)){C[1]=(V[N]-W);}if(V[E]>T[1]){C[1]=V[E];}if(T[0]>(V[K]-S)){C[0]=(V[K]-S);}if(V[D]>T[0]){C[0]=V[D];}return C;},inRegion:function(T){T=T||this.get(R).get(M).getXY();var S=this._checkRegion([T[0],T[1]]),C=false;if((T[0]===S[0])&&(T[1]===S[1])){C=true;}return C;},align:function(){var T=this.get(R),C=[T.actXY[0],T.actXY[1]],S=this.getRegion(true);if(this.get("stickX")){C[1]=(T.startXY[1]-T.deltaXY[1]);}if(this.get("stickY")){C[0]=(T.startXY[0]-T.deltaXY[0]);}if(S){C=this._checkRegion(C);}C=this._checkTicks(C,S);T.actXY=C;},drag:function(V){var U=this.get(R),S=this.get("tickX"),T=this.get("tickY"),C=[U.actXY[0],U.actXY[1]];if((B.Lang.isNumber(S)||this.get(G))&&(this._lastTickXFired!==C[0])){this._tickAlignX();this._lastTickXFired=C[0];}if((B.Lang.isNumber(T)||this.get(P))&&(this._lastTickYFired!==C[1])){this._tickAlignY();this._lastTickYFired=C[1];}},_checkTicks:function(X,V){var U=this.get(R),W=(U.startXY[0]-U.deltaXY[0]),T=(U.startXY[1]-U.deltaXY[1]),C=this.get("tickX"),S=this.get("tickY");if(C&&!this.get(G)){X[0]=Q._calcTicks(X[0],W,C,V[D],V[K]);}if(S&&!this.get(P)){X[1]=Q._calcTicks(X[1],T,S,V[E],V[N]);}if(this.get(G)){X[0]=Q._calcTickArray(X[0],this.get(G),V[D],V[K]);}if(this.get(P)){X[1]=Q._calcTickArray(X[1],this.get(P),V[E],V[N]);}return X;},_tickAlignX:function(){this.fire(J);},_tickAlignY:function(){this.fire(H);}};B.namespace("Plugin");B.extend(A,B.Base,I);B.Plugin.DDConstrained=A;B.mix(Q,{_calcTicks:function(Y,X,U,W,V){var S=((Y-X)/U),T=Math.floor(S),C=Math.ceil(S);if((T!==0)||(C!==0)){if((S>=T)&&(S<=C)){Y=(X+(U*T));if(W&&V){if(Y<W){Y=(X+(U*(T+1)));}if(Y>V){Y=(X+(U*(T-1)));}}}}return Y;},_calcTickArray:function(Z,a,Y,V){var S=0,W=a.length,U=0,T,C,X;if(!a||(a.length===0)){return Z;}else{if(a[0]>=Z){return a[0];}else{for(S=0;S<W;S++){U=(S+1);if(a[U]&&a[U]>=Z){T=Z-a[S];C=a[U]-Z;X=(C>T)?a[S]:a[U];if(Y&&V){if(X>V){if(a[S]){X=a[S];}else{X=a[W-1];}}}return X;}}return a[a.length-1];}}}});},"3.3.0pr3",{requires:["dd-drag"],skinnable:false});