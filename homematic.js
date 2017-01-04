const EventEmitter = require('events');
const util = require('util');
const log = require("./log.js");
const xmlrpc = require('homematic-xmlrpc');
const binrpc = require('binrpc');

function Homematic(config) {
	log.info("homematic config: " + JSON.stringify(config));
	EventEmitter.call(this);
	var self = this;
	this.config = config;
	this.id = this.config.module_serial;
	this.connected = false;

	if (this.config.protocol == 'binrpc') {
	        this.server = binrpc.createServer({
        	        host: this.config.interface_host,
                	port: this.config.interface_port
        });
	} else if (this.config.protocol == 'xmlrpc') {
	        this.server = xmlrpc.createServer({
        	        host: this.config.interface_host,
                	port: this.config.interface_port
        });
	} else {
		log.err('unknown protocol: ' + this.config.protocol);
	}

	this.server.on('NotFound', function (method, params) {
		log.warn('homematic server not found');
	});

	this.server.on('system.multicall', function (method, params, callback) {
		log.info('homematic server system multicall: ' + method + JSON.stringify(params));
		var response = [];
		for (var i = 0; i < params[0].length; i++) {
			if (rpcMethods[params[0][i].methodName]) {
				response.push(rpcMethods[params[0][i].methodName](null, params[0][i].params));
			} else {
				log.warn('RPC <- undefined method ' + method + ' ' + JSON.stringify(params).slice(0,80));
				response.push('');
			}
		}
		callback(null, response);
	});

	this.server.on('event', function (err, params, callback) {
		log.info('homematic server event');
		lastEvent = (new Date()).getTime();
		callback(null, rpcMethods.event(err, params));
	});

	this.server.on('newDevices', function (err, params, callback) {
                log.info('homematic server new device');
		callback(null, rpcMethods.newDevices(err, params));
	});

	this.server.on('deleteDevices', function(err, params, callback) {
                log.info('homematic server delete device');
		callback(null, rpcMethods.deleteDevices(err, params));
	});

	this.server.on('replaceDevice', function(err, params, callback) {
                log.info('homematic server replace device');
		callback(null, rpcMethods.replaceDevice(err, params));
	});

	this.server.on('listDevices', function(err, params, callback) {
                log.info('homematic server list devices');
		callback(null, rpcMethods.listDevices(err, params));
	});

	this.server.on('system.listMethods', function(err, params, callback) {
                log.info('homematic server system list methods');
		callback(null, rpcMethods['system.listMethods'](err, params));
	});

	if (this.config.protocol == 'binrpc') {
		this.client = binrpc.createClient({
		        host: this.config.rfd_host,
        		port: this.config.rfd_port,
        		path: '/'
		});
	} else {
                this.client = xmlrpc.createClient({
                        host: this.config.rfd_host,
                        port: this.config.rfd_port,
                        path: '/'
                });
	}

	if (this.config.protocol == 'binrpc') {
		this.client.on('connect', function () {
			var initUrl = 'xmlrpc_bin://' + self.config.interface_host + ':' + self.config.interface_port;
log.info("bin url: " + initUrl);
log.info("bin config: " + JSON.stringify(this.config));
			rpcSend(self.client, 'init', [initUrl, self.id], function(err, data) {
				if (err) {
					self.connected = false;
					self.emit("disconnected");
				} else {
			                self.connected = true;
	         			self.emit("connected", this.id);
				}
			});
		});
	        this.client.on('error', function (e) {
	                log.err(e);
	        });
	} else {
                var initUrl = 'http://' + self.config.interface_host + ':' + self.config.interface_port;
log.info("xml url: " + initUrl);
log.info("xml config: " + JSON.stringify(this.config));
                rpcSend(self.client, 'init', [initUrl, self.id], function(err, data) {
                        if (err) {
                                self.connected = false;
                                self.emit("disconnected");
                        } else {
                                self.connected = true;
                                self.emit("connected", this.id);
                        }
                });
	}
};

util.inherits(Homematic, EventEmitter)

function rpcSend(client, fn, args, cb) {
        var msg = 'RPC -> ' + fn + '(';
        for (var i = 0; i < args.length; i++) {
                if (i > 0)
                        msg += ',';
                msg += args[i].toString();
        }
        msg += ')';
        log.info(msg);
	client.methodCall(fn, args, function(err, data) {
                if (err)
                        log.err('    <- ' + fn + ' error ' + JSON.stringify(err));
                else
                        log.info('    <- ' + fn + ' response ' + JSON.stringify(data));
                if (cb)
                        cb(err, data);
        });
}

var rpcMethods = {
        event: function (err, params) {
                log.info('RPC <- event ' + JSON.stringify(params));
//                mqttAnnounceValue(params);
                return '';
        },
        newDevices: function (err, params) {
                log.info('RPC <- newDevices ' + JSON.stringify(params).slice(0, 80));
                lastEvent = (new Date()).getTime();
//                if (!localDevices) localDevices = {};
                for (var i = 0; i < params[1].length; i++) {
                        var dev = params[1][i];
//                        localDevices[dev.ADDRESS] = dev;
//                        mqttAnnounceNode(dev.ADDRESS);
                }
//              saveJson(config.devicesFile, localDevices);
                return '';
        },
        deleteDevices: function (err, params) {
                log.info('RPC <- deleteDevices ' + JSON.stringify(params));
//                mqtt.publish(config.mqtt.prefix + '/homematic/' + homematic_homeid + '/' + 'deleteDevices', JSON.stringify(params));
                lastEvent = (new Date()).getTime();
//                if (!localDevices || !params[1]) return;
                for (var i = 0; i < params[1].length; i++) {
                        var address = params[1][i];
//                        delete localDevices[address];
                }
//              saveJson(config.devicesFile, localDevices);
                return '';
        },
        replaceDevice: function (err, params) {
                log.info('RPC <- replaceDevice ' + JSON.stringify(params));
//                mqtt.publish(config.mqtt.prefix + '/homematic/' + homematic_homeid + '/' + 'replaceDevices', JSON.stringify(params));
                lastEvent = (new Date()).getTime();
//                if (!localDevices || !params[1]) return;
//                localNames[params[2]] = localNames[params[1]];
//                delete localNames[params[1]];
//                saveJson(config.namesFile, localNames);
//                delete localDevices[params[1]];
//              saveJson(config.devicesFile, localDevices);
                return '';
        },
        listDevices: function (err, params) {
                log.info('RPC <- listDevices ' + JSON.stringify(params));
//                mqtt.publish(config.mqtt.prefix + '/homematic/' + homematic_homeid + '/' + 'listDevices', JSON.stringify(params));
                var res = [];
//                for (var address in localDevices) {
//                        res.push({ADDRESS: address, VERSION: localDevices[address].VERSION});
//                }
                log.info('RPC -> listDevices response length ' + res.length);
                return res;
        },
        'system.listMethods': function (err, params) {
                return ['system.multicall', 'system.listMethods', 'listDevices', 'deleteDevices', 'newDevices', 'event'];
        }
};

/*
Homematic.prototype.connected = function() {
        return this.connected;
};
*/

Homematic.prototype.adapter = function(command, message) {
	log.info('homematic adapter: ' + command + ': ' + message);
        switch (command) {
                case "learn":
                        rpcSend(this.client, 'setInstallMode', [true, 30], function(err, data) {});
                        break;
        }
};

Homematic.prototype.node = function(nodeid, command, message) {
}

Homematic.prototype.parameter = function(nodeid, parameterid, command, message) {
}

module.exports = Homematic;
