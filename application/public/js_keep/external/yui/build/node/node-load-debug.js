/*
Copyright (c) 2010, Yahoo! Inc. All rights reserved.
Code licensed under the BSD License:
http://developer.yahoo.com/yui/license.html
version: 3.3.0pr3
build: 3110
*/
YUI.add('node-load', function(Y) {


Y.Node.prototype._ioComplete = function(code, response, args) {
    var selector = args[0],
        callback = args[1],
        tmp,
        content;

    if (response && response.responseText) {
        content = response.responseText;
        if (selector) {
            tmp = Y.DOM.create(content);
            content = Y.Selector.query(selector, tmp);
        }
        this.setContent(content);
    }
    if (callback) {
        callback.call(this, code, response);
    }
};

/**
 * Loads content from the given url and replaces the Node's
 * existing content with it. 
 * @method load
 * @param {String} html The markup to wrap around the node. 
 * @param {String} selector An optional selector representing subset
 * @param {Function} selector An optional function to run after the content has been loaded. 
 * of the content.
 * @chainable
 */
Y.Node.prototype.load = function(url, selector, callback) {
    if (typeof selector == 'function') {
        callback = selector;
        selector = null;
    }
    var config = {
        context: this,
        on: {
            complete: this._ioComplete
        },
        arguments: [selector, callback]
    };

    Y.io(url, config);
    return this;
}


}, '3.3.0pr3' ,{requires:['node-base', 'io-base']});
