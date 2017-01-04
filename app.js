const config = require("./config.js");
const log = require("./log.js");
const Bus = require("./bus.js");

if (process.argv.length < 3)
	log.err('missing adapter argument');

const Gw = require("./" + process.argv[2] + ".js");

var adaptertype = process.argv.length > 3 ? process.argv[3] : process.argv[2];
var adapterid;

var bus;
var gw;

gw = new Gw(config[adaptertype]);

gw.on("connected", function(id) {
        adapterid = id;
        bus = new Bus(config.mqtt, adaptertype, adapterid);

        bus.on("connected", () => {
                log.info("bus connected");
                if (gw)
                        if (gw.connected())
                                bus.adapterSend("status", "online", {}, 0, false);
        });

        bus.on("adapter", (command, message) => {
                log.info("bus adapter command: " + command + ": " + message);
                gw.adapter(command, message);
        });

        bus.on("node", (nodeid, command, message) => {
                log.info("bus node command: " + command + " for " + nodeid + ": " + message);
		gw.node(nodeid, command, message);
        });

        bus.on("parameter", (nodeid, parameterid, command, message) => {
                log.info("bus parameter command: " + command + " for " + nodeid + "/" + parapeterid + ": " + message);
		gw.parameter(nodeid, parameterid, command, message);
        });

});
