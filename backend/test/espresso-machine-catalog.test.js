const test = require("node:test");
const assert = require("node:assert/strict");

const { espressoMachineCatalog } = require("../modules/brewing/espresso-machine-catalog");

test("machine catalog includes profiled, official, and manual paths", () => {
    assert.ok(espressoMachineCatalog.some((machine) => machine.id === "decent-de1" && machine.streams.includes("pressure")));
    assert.ok(espressoMachineCatalog.some((machine) => machine.id === "home-connect-coffee" && machine.supportLevel === "officialCloudAPI"));
    assert.ok(espressoMachineCatalog.some((machine) => machine.id === "bookoo-mini" && machine.accessMode === "readOnly"));
    assert.ok(espressoMachineCatalog.some((machine) => machine.id === "rocket-profitec-ecm" && machine.supportLevel === "manualOnly"));
});
