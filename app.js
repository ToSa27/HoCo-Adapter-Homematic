var config = require("./config.js");
var log = require("./log.js");
var Bus = require("./bus.js");
var Homematic = require("./homematic.js");

var adaptertype = "homematic";
var adapterid;

var bus;
var gw;

gw = new Homematic(config.homematic);

gw.on("connected", function(homeid) {
        if (bus)
                if (bus.connected())
                        ready();
});

function ready() {
	bus.adapterSend("@status", "online", {}, 0, false);
}
