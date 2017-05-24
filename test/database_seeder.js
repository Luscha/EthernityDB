const BSON = require('bson')
const Web3 = require('web3');
const jsonfile = require('jsonfile')

const bson = new BSON();
// Connect to local Ethereum node
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

const fee = 100000;

/*const query = [
	{"asd":2000,"foo":{"bar":19}},
	{"asd":2000,"foo":{"bar":19, "lol": "heheheheheh"}},
	{"|": [{"asd": 2001}, {"asd": 2000}, {"asd": 2000}]}
];

query.forEach((q, index) => {
	console.log(bson.serialize(q).toString('hex'));
	console.log(bson.deserialize(bson.serialize(q)));
})*/

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

function createNewCollection(db, collectionName) {
	console.log('------------ Creating new Collection ------------');
	var myCallData = db.newCollection.getData(collectionName);
	var estimate = web3.eth.estimateGas({data: myCallData, to: db.address});

	console.log('    Estimated gas to create the collection = ' + estimate);
	db.newCollection(collectionName, {
		from: web3.eth.coinbase,
		gas: estimate + fee}, (err, res) => {
		if (err) {
			console.log(err);
			return;
		}
		console.log('    Collection transaction Hash ' + res);
		setTimeout(InsertTest, 3000, db, collectionName);
	});
}

function InsertTest(db, collectionName) {
	console.log('------------ Insertion Test ------------');
	var queries = [{"asd":2000,"foo":{"bar":19}},
                //{"asd":2000,"foo":{"bar":19, "lol": "heheheheheh"}}
              ];

  queries.forEach((q, index) => {
    var hexQ = hexStringToHexArray(bson.serialize(q).toString('hex'));

  	var myCallData = db.queryInsert.getData(collectionName, hexQ);
  	var estimate = web3.eth.estimateGas({data: myCallData, to: db.address});

  	console.log('    Estimated gas to insert ' + hexQ.length + ' bytes = ' + estimate);
  	db.queryInsert(collectionName, hexQ, {
  		from: web3.eth.coinbase,
  		gas: estimate + fee}, (err, res) => {
  		if (err) {
  			console.log(err);
  			return;
  		}
      console.log('    Query: ' + JSON.stringify(q));
  		console.log('    Insertion transaction Hash ' + res);
  	});
  });
}

function hexStringToHexArray(str) {
  a = [];
  for (var i = 0; i < str.length; i += 2) {
      a.push("0x" + str.substr(i, 2));
  }
  return a;
}

function main () {
	unlockAccount();
	var compiledConstracts = loadContractsInformations();
	var dbInstance = buildDBContract(compiledConstracts["database"]);
	createNewCollection(dbInstance, "a");
	//InsertTest(dbInstance, "a");
}

main();
