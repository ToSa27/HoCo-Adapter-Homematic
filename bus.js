const EventEmitter = require('events');
const util = require('util');
const log = require("./log.js");
const Mqtt = require('mqtt');

var _config;
var _adaptertype;
var _adapterid;
var _prefix;
var _mqtt;
var _connected = false;

function Bus(config, adaptertype, adapterid) {
	EventEmitter.call(this);
	var self = this;
	_config = config;
	_adaptertype = adaptertype;
	_adapterid = adapterid;
	_prefix = _config.prefix + "/" + _adaptertype + "/" + _adapterid;
	_mqtt = Mqtt.connect(_config.url, {
		username: _config.username,
		password: _config.password,
		will: {
			topic: _prefix + "/@status",
			payload: JSON.stringify({
				val: "offline",
				data: {}
			}),
			qos: 0,
			retain: false
		}
	});
	
	_mqtt.on('connect', function () {
		_connected = true;
// ToDo: subscribe to system wide topics like $time etc.
		_mqtt.subscribe(_prefix + "/#");
		send("@status", "online", {}, 0, false);
		self.emit("connected");
	});

	_mqtt.on('reconnect', function() {
		log.info('bus reconnect');
		_connected = false;
		self.emit("disconnected");
	});

	_mqtt.on('close', function() {
		log.info('bus close');
		_connected = false;
		self.emit("disconnected");
	});

	_mqtt.on('offline', function() {
		log.info('bus offline');
		_connected = false;
		self.emit("disconnected");
	});

	_mqtt.on('error', function(err) {
		log.info('bus error: ' + JSON.stringify(err));
		_connected = false;
		self.emit("error", err);
	});

// packetreceive
// packetsend
// outgoingEmpty

	_mqtt.on('message', function (topic, message) {
//		log.info("bus rx: " + topic + " = " + message);
// ToDo: handle system wide topics like $time etc.
		if (!topic.startsWith(_prefix + "/"))
			return;
		var topicParts = topic.substring(_prefix.length + 1).split('/');
		if (topicParts[0].startsWith("@")) {
			return;
		} else if (topicParts[0].startsWith("$")) {
			self.emit("adapter", topicParts[0].substring(1), message);
		} else {
			if (topicParts[1].startsWith("@")) {
				return;
			} else if (topicParts[1].startsWith("$")) {
				self.emit("node", topicParts[0], topicParts[1].substring(1), message);
			} else {
				if (topicParts[2].startsWith("@")) {
					return;
				} else if (topicParts[2].startsWith("$")) {
					self.emit("parameter", topicParts[0], topicParts[1], topicParts[2].substring(1), message);
				} else {
// ToDo:
				}
			}
		}
	});
};

util.inherits(Bus, EventEmitter)

function send(topic, value, data, qos = 0, retain = true) {
	if (_connected) {
		_mqtt.publish(_prefix + "/" + topic, JSON.stringify({
			val: value,
			data: data
		}), { qos: qos, retain: retain });
	};
};

Bus.prototype.connected = function() {
	return _connected;
};

Bus.prototype.adapterSend = function(command, value, data, qos = 0, retain = true) {
	send("@" + command, value, data, qos, retain);
};
	
Bus.prototype.nodeSend = function(nodeid, command, value, data, qos = 0, retain = true) {
	send(nodeid + "/@" + command, value, data, qos, retain);
};
	
Bus.prototype.parameterSend = function(nodeid, parameterid, command, value, data, qos = 0, retain = true) {
	send(nodeid + "/" + parameterid + "/@" + command, value, data, qos, retain);
};

module.exports = Bus;

