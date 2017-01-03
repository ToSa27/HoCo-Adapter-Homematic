var logger = function() {};

logger.prototype.info = function(msg) {
	console.log("INFO: " + msg);
};

logger.prototype.warn = function(msg) {
	console.log("WARN: " + msg);
};

logger.prototype.err = function(msg) {
	console.log("ERROR: " + msg);
};

module.exports = new logger();
