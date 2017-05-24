const BSON = require('bson')
const Web3 = require('web3');
const jsonfile = require('jsonfile')
const byteBuffer = require("bytebuffer");

const bson = new BSON();
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

function unlockAccount(){
    var accounts = web3.eth.accounts;
    var passPhrase = "aaa";
    web3.personal.unlockAccount(accounts[0], passPhrase);
}

function loadContractsInformations() {
	return jsonfile.readFileSync("./test/contracts.json");
}

function buildDBContract(dbInfos) {
	var db = web3.eth.contract(dbInfos["abi"]);
	return db.at(dbInfos["address"]);
}

function hexStringToHexArray(str) {
  a = [];
  for (var i = 0; i < str.length; i += 2) {
      a.push("0x" + str.substr(i, 2));
  }
  return a;
}

function parseHexString(str) {
    var result = [];
    while (str.length >= 8) {
        result.push(parseInt(str.substring(0, 8), 16));

        str = str.substring(8, str.length);
    }

    return result;
}

function main() {
  var queries = [
    {"asd":2000},
    {"asd":2000, "a": 10},
    {"asd":2000, "a": {}},
    {"foo":{"bar": 19}},
    {"asd":2000, "foo":{"a": 19}},
    {"asd":2000, "foo":{"lol": "h"}},
    {"foo":{"lol": "heheheheheh"}},
    {},
    {"|": [{"asd": 2002}, {"asd": 2001}]},
    {"|": [{"asd": 2002}, {"asd": 2001}, {"asd": 2000}]},
    {"|": [{"asd": 2000}, {"asd": 2001}]},
    {"|": [{"asd": 2001}, {"asd": 2000}]},
    {"|": [{"a":{"lol": "h"}}], "foo":{"bar": 19}},
    {"|": [{"foo":{"lol": "h"}}, {"a": 0}]},
    {"|": [{"foo":{"lol": "h"}}, {"foo":{"bar": 19}}]},
  ];
	unlockAccount();
	var compiledConstracts = loadContractsInformations();
	var dbInstance = buildDBContract(compiledConstracts["database"]);
  queries.forEach((q, index) => {
    var hexQ = hexStringToHexArray(bson.serialize(q).toString('hex'));
    //console.log("Query " + hexStringToHexArray(bson.serialize(q).toString('hex')));
    console.log("Query " + JSON.stringify(q));
    var i = 0;
    var n = 0;
    while (true) {
      var ret = dbInstance.queryFind("a", i, hexQ);
      i = parseInt(ret[1]) + 1;
      if (i == 0) {
        console.log("No more results\n");
        break;
      }

      var buffer = byteBuffer.fromHex(String(ret[2]).substr(2))["buffer"];
      console.log("Result n" + n + ": " + JSON.stringify(bson.deserialize(buffer)));
      n++;
    }

  })
}

main();
