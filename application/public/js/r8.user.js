
if (!R8.User) {

	R8.User = function() {
		var _id = '',

			_settingsCookie = '',
			_settingsCookieKey = '_userSettingsCookie-'+_id,
			_updateBackgroundCall = null,
			_settings = {},
			_settingsUpdateList = {},

			_events = {};

		return {
			init: function(userDef) {
				_id = 1;

				this.startUpdater();

				YUI().use('cookie','json', function(Y){
					var settingsCookieJSON = Y.Cookie.get(_settingsCookieKey);
					_settingsCookie = (settingsCookieJSON == null) ? {} : Y.JSON.parse(settingsCookieJSON);

					for(var s in _settingsCookie) {
						R8.User.setSetting(s,_settingsCookie[s]);
					}
				});
			},
			getSetting: function(key) {

			},
			setSetting: function(key,value) {
				_settingsUpdateList[key] = value;
				_settings[key] = value;
//DEBUG
//console.log('just set setting:'+key);
			},
			startUpdater: function() {
				var that = this;
				var fireBackgroundUpdate = function() {
					that.backgroundUpdater();
				}
				_updateBackgroundCall = setTimeout(fireBackgroundUpdate,5000);
			},

			stopUpdater: function() {
				clearTimeout(_updateBackgroundCall);
			},
			purgePendingSettings: function(ioId,responseObj) {
				_settingsUpdateList = {};
				YUI().use("cookie",function(Y){
					Y.Cookie.remove(_settingsCookieKey);
				});
			},
//TODO: generalize the background updater.., have it be centralized and people subscribe to
			backgroundUpdater: function() {
				var count = 0;
				for(item in _settingsUpdateList) {
					count++;
				}
				var that = this;
				if (count > 0) {
					YUI().use("json", function(Y) {
//DEBUG
//console.log('going to pass back settings for persisting...');
//console.log(_settingsUpdateList);
						var reqParam = 'settings=' + Y.JSON.stringify(_settingsUpdateList);

						var params = {
							'cfg': {
								'data': reqParam
							},
							'callbacks': {
								'io:success':that.purgePendingSettings
							}
						};
						R8.Ctrl.call('user/update_settings/' + _id, params);
					});
				}

				var fireBackgroundUpdate = function() {
					that.backgroundUpdater();
				}
				_updateBackgroundCall = setTimeout(fireBackgroundUpdate,5000);
			}
		}
	}();
}