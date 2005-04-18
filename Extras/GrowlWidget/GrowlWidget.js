function setup() {
	return 0;
}

function appendMessage(html) {
   	//GrowlPlugin.logMessage("appendMessage:" + html);
	//Append the new message to the bottom of our block
	notifications = document.getElementById("Notifications");
	range = document.createRange();
	range.selectNode(notifications);
	documentFragment = range.createContextualFragment(html);
	notifications.appendChild(documentFragment);
}
