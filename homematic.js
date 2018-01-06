const EventEmitter = require('events');
const util = require('util');
const fs = require("fs-extra");
const path = require('path');
const log = require("../common/log.js");
const xmlrpc = require('homematic-xmlrpc');
const binrpc = require('binrpc');
const http = require('http');
const tmp = require('tmp');
const targz = require('targz');
const readline = require('readline');

const serialfilename = '/opt/hm/var/rf_serial';
const cryptfilename = '/opt/hm/etc/config/crypttool.cfg';

function Homematic(config) {
	log.debug("homematic config: " + JSON.stringify(config));
	EventEmitter.call(this);
	var self = this;
	this.config = config;
	this.id = fs.readFileSync(serialfilename, "utf-8").trim();
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
		log.err('homematic method not found: ' + method);
	});

	this.server.on('system.multicall', function (method, params, callback) {
		log.debug('homematic server system multicall: ' + method + JSON.stringify(params));
		var response = [];
		for (var i = 0; i < params[0].length; i++) {
			if (self.rpcMethods[params[0][i].methodName]) {
				response.push(self.rpcMethods[params[0][i].methodName](null, params[0][i].params));
			} else {
				log.err('RPC <- undefined method ' + method + ' ' + JSON.stringify(params).slice(0,80));
				response.push('');
			}
		}
		callback(null, response);
	});

	this.server.on('event', function (err, params, callback) {
		log.debug('homematic server event');
		callback(null, self.rpcMethods.event(err, params));
	});

	this.server.on('newDevices', function (err, params, callback) {
                log.debug('homematic server new device');
		callback(null, self.rpcMethods.newDevices(err, params));
	});

	this.server.on('deleteDevices', function(err, params, callback) {
                log.debug('homematic server delete device');
		callback(null, self.rpcMethods.deleteDevices(err, params));
	});

	this.server.on('replaceDevice', function(err, params, callback) {
                log.debug('homematic server replace device');
		callback(null, self.rpcMethods.replaceDevice(err, params));
	});

	this.server.on('listDevices', function(err, params, callback) {
                log.debug('homematic server list devices');
		callback(null, self.rpcMethods.listDevices(err, params));
	});

	this.server.on('system.listMethods', function(err, params, callback) {
                log.debug('homematic server system list methods');
		callback(null, self.rpcMethods['system.listMethods'](err, params));
	});

	this.rpcMethods = {
		event: function (err, params) {
			log.debug('RPC <- event ' + JSON.stringify(params));
			self.emit("parameter value", self, params[1], params[2], params[3], params);
			return '';
		},
		newDevices: function (err, params) {
			log.debug('RPC <- newDevices ' + JSON.stringify(params));
			var interface_id = params[0];
			var dev_descriptions = params[1];
			for (var i = 0; i < dev_descriptions.length; i++) {
				var dev = dev_descriptions[i];
				self.emit("node added", self, dev.ADDRESS, dev);
			}
			return '';
		},
		deleteDevices: function (err, params) {
			log.debug('RPC <- deleteDevices ' + JSON.stringify(params));
			for (var i = 0; i < params[1].length; i++) {
				var nodeid = params[1][i];
				self.emit("node removed", self, nodeid);
			}
			return '';
		},
		replaceDevice: function (err, params) {
			log.debug('RPC <- replaceDevice ' + JSON.stringify(params));
			return '';
		},
		listDevices: function (err, params) {
			log.debug('RPC <- listDevices ' + JSON.stringify(params));
			var res = [];
			log.debug('RPC -> listDevices response length ' + res.length);
			return res;
		},
		'system.listMethods': function (err, params) {
			return ['system.multicall', 'system.listMethods', 'listDevices', 'deleteDevices', 'newDevices', 'event'];
		}
	};

	setTimeout(() => {
		var initUrl = '';
		if (this.config.protocol == 'binrpc') {
			this.client = binrpc.createClient({
	                        host: this.config.rfd_host,
        	                port: this.config.rfd_port
                	});
			initUrl = 'xmlrpc_bin://' + self.config.interface_host + ':' + self.config.interface_port;
		} else if (this.config.protocol == 'xmlrpc') {
                        this.client = xmlrpc.createClient({
                                host: this.config.rfd_host,
                                port: this.config.rfd_port
                        });
                        initUrl = 'http://' + self.config.interface_host + ':' + self.config.interface_port;
		}
//                this.client.on('error', function (e) {
//                        log.err(e);
//                });
                self.rpcSend('init', [initUrl, self.id], (err, data) => {
                        if (err) {
                                self.connected = false;
                                self.emit("disconnected", self);
                        } else {
                        	if (self.config.key)
	                        	self.setKey(self.config.key);
	                        self.connected = true;
	                        self.emit("connected", self, self.id);
	                }
                });
	}, 2000);
};

util.inherits(Homematic, EventEmitter)

convertHmIPKeyBase32ToBase16 = function(valueString) {

  var HMIP_KEY_CHARS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A',
    'B', 'C', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'U', 'W', 'X', 'Y', 'Z' ];

  var buffer = new ArrayBuffer(16),
    keyValue = new Uint8Array(buffer),
    value = 0,
    counter = valueString.length - 1 ,
    bits = 0,
    byteCounter = keyValue.length - 1,
    keyString = "";

  while (counter >= 0) {
    for(var i= 0; i < HMIP_KEY_CHARS.length; i++) {
      if(HMIP_KEY_CHARS[i] == valueString.charAt(counter)) {
        value |= i << bits;
        //console.log(value +" - break");
        break;
      }
    }

    bits += 5;
    counter--;
    while (bits > 8 && byteCounter >= 0) {
      keyValue[byteCounter] = value & 0xff;
      value >>= 8;
      bits -= 8;
      byteCounter--;
    }
  }

  for(var i = 0; i < keyValue.length; i++)
  {
    if (keyValue[i] < 16) {
     keyString += "0";
    }
    keyString += keyValue[i].toString(16);
  }

  return keyString.toUpperCase();
};

Homematic.prototype.setKey = function(key) {
  if (key) {
    log.info("Setting new key.");
    try {
      require('child_process').execSync('/opt/hm/bin/crypttool -v -t 3 -k ' + key + ' -f ' + cryptfilename, {stdio:[0,1,2]});
      log.warn("New key matches current key.");
    } catch(ex) {
      log.info("New key does not match current key.");
      this.rpcSend('changeKey', [ key ], function(err, data) {
        if (err)
          log.warn("Error sending changeKey command: " + err);
        else {
          log.info("Successfully sent changeKey command.");
          var indexBuf = require('child_process').execSync('/opt/hm/bin/crypttool -g -f ' + cryptfilename + ' | /bin/grep "Current user key" | /usr/bin/cut -d" " -f5');
          var index = parseInt(indexBuf.toString(), 10) + 1;
          log.info("New key index: " + index.toString());
          try {
            require('child_process').execSync('/opt/hm/bin/crypttool -S -k ' + key + ' -i ' + index.toString() + ' -f ' + cryptfilename, {stdio:[0,1,2]});
            log.info("Successfully stored new key.");
          } catch (ex) {
            log.warn("Failed to store new key.");
          }
        }
      });
    }
  }
};

Homematic.prototype.rpcSend = function(fn, args, cb) {
	var msg = 'RPC -> ' + fn + '(' + JSON.stringify(args) + ')';
	log.debug(msg);
	this.client.methodCall(fn, args, function(err, data) {
	if (err)
		log.err('    <- ' + fn + ' error ' + JSON.stringify(err));
	else
		log.debug('    <- ' + fn + ' response ' + JSON.stringify(data));
	if (cb)
		cb(err, data);
	});
};

Homematic.prototype.connected = function() {
        return this.connected;
};

Homematic.prototype.adapter = function(command, message) {
        var self = this;
	log.debug('homematic adapter: ' + command + ': ' + JSON.stringify(message));
        switch (command) {
		case "all":
			this.rpcSend('getServiceMessages', [], function(err, data) {
				for (var i = 0; i < data.length; i++)
					log.debug("ServiceMessage: " + JSON.stringify(data));
			});
			break;
		case "details":
			this.rpcSend('listBidcosInterfaces', [], function(err, data) {
				self.emit("adapter details", self, data);
			});
			break;
                case "scan":
			var msg = message;
			if (!msg.KEY || !msg.SGTIN)
	                        this.rpcSend('setInstallMode', [true, 30], function(err, data) {});
			else
				this.rpcSend('setInstallModeWithWhitelist', [true, 30, [ { ADDRESS: msg.SGTIN.replace(/-/g,"").toUpperCase(), KEY_MODE: "LOCAL", KEY: convertHmIPKeyBase32ToBase16(msg.KEY.replace(/-/g,"").toUpperCase()) } ]]);
                        break;
                case "nodes":
                        this.rpcSend('listDevices', [], function(err, data) {});
                        break;
                case "firmware":
		        var self = this;
			var msg = message;
			if (msg.URL) {
                                tmp.dir(function _tempDirCreated(err, tmppath, cleanupCallback) {
                                        if (!err) {
                                                var tgzfn = path.join(tmppath, 'firmware.tgz');
                                                log.info('downloading to: ' + tgzfn);
                                                var tgzf = fs.createWriteStream(tgzfn);
                                                var request = http.get(msg.URL, function(res) {
                                                        res.pipe(tgzf);
                                                        tgzf.on('finish', function() {
                                                                tgzf.close(function() {
                                                                        targz.decompress({ src: tgzfn, dest: tmppath }, function(err) {
                                                                                if (!err) {
                                                                                        var infofn = path.join(tmppath, 'info');
                                                                                        var inford = readline.createInterface({ input: fs.createReadStream(infofn) });
                                                                                        var info = {};
                                                                                        inford.on('line', function (line) {
                                                                                                var linesplit = line.split('=');
                                                                                                if (linesplit.length == 2 && linesplit[0].indexOf('#') == -1 && linesplit[1].indexOf('#') == -1)
                                                                                                        info[linesplit[0].trim().toLowerCase()] = linesplit[1].trim();
                                                                                        });
                                                                                        inford.on('close', function () {
                                                                                                if (info.typecode) {
                                                                                                        var fwdir = path.join('/opt/hm/firmware', info.typecode);
                                                                                                        if (fs.existsSync(fwdir))
                                                                                                                fs.removeSync(fwdir);
                                                                                                        fs.mkdirSync(fwdir);
                                                                                                        var files = fs.readdirSync(tmppath);
                                                                                                        for (var i = 0; i < files.length; i++) {
                                                                                                                if (files[i] != 'firmware.tgz')
                                                                                                                        fs.copySync(path.join(tmppath, files[i]), path.join(fwdir, files[i]));
                                                                                                        }
                                                                                                        self.rpcSend('refreshDeployedDeviceFirmwareList', [], function(err, data) {});
//                                                                                                        cleanupCallback();
                                                                                                }
                                                                                        });
                                                                                }
                                                                        });
                                                                });
                                                        });
                                                });
                                        }
                                });
			}
			//this.rpcSend('refreshDeployedDeviceFirmwareList', [], function(err, data) {});
			break;
        }
};

Homematic.prototype.node = function(nodeid, command, message) {
	var self = this;
        switch (command) {
		case "details":
			this.rpcSend('getDeviceDescription', [nodeid], function(err, data) {
				self.emit("node details", self, nodeid, data);
			});
			break;
                case "parameters":
			this.rpcSend('getDeviceDescription', [nodeid], function(err, data) {
				if (err)
					return;
				for (var i = 0; i < data.PARAMSETS.length; i++)
					self.rpcSend('getParamsetDescription', [nodeid, data.PARAMSETS[i]], function(err, data) {
						if (err)
							return;
						self.emit("node parameters", self, nodeid, data);
					});
			});
                        break;
		case "delete":
                        this.rpcSend('deleteDevice', [nodeid, 1], function(err, data) {});
                        break;
                case "update":
			if (this.config.type == 'homematic')
				this.rpcSend('updateFirmware', [nodeid], function(err, data) {
					self.emit("node update", self, nodeid, data);
				});
			else if (this.config.type == 'homematicip')
	                        this.rpcSend('installFirmware', [nodeid], function(err, data) {
        	                        self.emit("node update", self, nodeid, data);
                	        });
                        break;
        }
}

Homematic.prototype.parameter = function(nodeid, parameterid, command, message) {
        switch (command) {
                case "set":
                        this.rpcSend('setValue', [nodeid, parameterid, message.val], function(err, data) {});
                        break;
        }
}

module.exports = Homematic;
