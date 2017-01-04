const config = require("./config.js");
const log = require("./log.js");
const Bus = require("./bus.js");

var Gw = {};
for (var i = 0; i < config.adapter.length; i++) {
	if (!Gw[config.adapter[i].module]) {
		Gw[config.adapter[i].module] = require("./" + config.adapter[i].module + ".js");
		log.info("loading adapter module: " + config.adapter[i].module);
	}
}

//var gw = [];
for (var i = 0; i < config.adapter.length; i++) {
	var newgw = new Gw[config.adapter[i].module](config.adapter[i]);
	newgw.type = config.adapter[i].adaptertype;

	newgw.on("connected", function(id) {
                newgw.adapterid = id;

		var bus = new Bus(config.mqtt, newgw.adaptertype, newgw.adapterid);
		newgw.bus = bus;

		bus.gw = newgw;

		bus.on("connected", () => {
		        log.info("bus connected");
                	if (bus.gw.connected)
                        	bus.adapterSend("status", "online", {}, 0, false);
	        });

        	bus.on("adapter", (command, message) => {
                	log.info("bus adapter command: " + command + ": " + message);
                	bus.gw.adapter(command, message);
        	});

        	bus.on("node", (nodeid, command, message) => {
                	log.info("bus node command: " + command + " for " + nodeid + ": " + message);
                	bus.gw.node(nodeid, command, message);
        	});

	        bus.on("parameter", (nodeid, parameterid, command, message) => {
        	        log.info("bus parameter command: " + command + " for " + nodeid + "/" + parapeterid + ": " + message);
                	bus.gw.parameter(nodeid, parameterid, command, message);
        	});
	});

//	gw.push(newgw);
}
