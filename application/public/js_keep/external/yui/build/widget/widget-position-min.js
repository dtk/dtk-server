/*
Copyright (c) 2010, Yahoo! Inc. All rights reserved.
Code licensed under the BSD License:
http://developer.yahoo.com/yui/license.html
version: 3.3.0pr3
build: 3110
*/
YUI.add("widget-position",function(A){var I=A.Lang,L=A.Widget,N="xy",J="position",G="positioned",K="boundingBox",H="relative",M="renderUI",F="bindUI",D="syncUI",C=L.UI_SRC,E="xyChange";function B(O){this._posNode=this.get(K);A.after(this._renderUIPosition,this,M);A.after(this._syncUIPosition,this,D);A.after(this._bindUIPosition,this,F);}B.ATTRS={x:{setter:function(O){this._setX(O);},getter:function(){return this._getX();},lazyAdd:false},y:{setter:function(O){this._setY(O);},getter:function(){return this._getY();},lazyAdd:false},xy:{value:[0,0],validator:function(O){return this._validateXY(O);}}};B.POSITIONED_CLASS_NAME=L.getClassName(G);B.prototype={_renderUIPosition:function(){this._posNode.addClass(B.POSITIONED_CLASS_NAME);},_syncUIPosition:function(){var O=this._posNode;if(O.getStyle(J)===H){this.syncXY();}this._uiSetXY(this.get(N));},_bindUIPosition:function(){this.after(E,this._afterXYChange);},move:function(){var O=arguments,P=(I.isArray(O[0]))?O[0]:[O[0],O[1]];this.set(N,P);},syncXY:function(){this.set(N,this._posNode.getXY(),{src:C});},_validateXY:function(O){return(I.isArray(O)&&I.isNumber(O[0])&&I.isNumber(O[1]));},_setX:function(O){this.set(N,[O,this.get(N)[1]]);},_setY:function(O){this.set(N,[this.get(N)[0],O]);},_getX:function(){return this.get(N)[0];},_getY:function(){return this.get(N)[1];},_afterXYChange:function(O){if(O.src!=C){this._uiSetXY(O.newVal);}},_uiSetXY:function(O){this._posNode.setXY(O);}};A.WidgetPosition=B;},"3.3.0pr3",{requires:["base-build","node-screen","widget"]});