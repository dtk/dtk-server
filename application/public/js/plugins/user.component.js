
function initUserForm(){
	var dirNameNode = R8.Utils.Y.one('#home_directory_name'), userNameNode = R8.Utils.Y.one('#username');
	//console.log(R8.Utils.Y.one('#username'));
	userNameNode.on('keyup', function(e){
		var usernameValue = e.currentTarget.get('value');
		dirNameNode.set('value', usernameValue);
	});
}

