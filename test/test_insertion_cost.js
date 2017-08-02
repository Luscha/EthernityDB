const BSON = require('bson')
const Web3 = require('web3');
const jsonfile = require('jsonfile')

const bson = new BSON();
// Connect to local Ethereum node
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

const fee = 100000;

const queriesPlain = [
				{"a": null},
				{"asd":2000, "bar":19},
				{"asd":2000, "bar":19, "lol": "heheheheheh"},
				{"asd":2000, "bar":19, "lol": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh"},
				{"asd":2000, "bar":19, "lol": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol2": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh"},
				{"asd":2000, "bar":19, "lol": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol2": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol3": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh"},
				{"asd":2000, "bar":19, "lol": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol2": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol3": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol4": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol5": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh"},
				{"asd":2000, "bar":19, "lol": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol2": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol3": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol4": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol5": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol6": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh"},
				/*{"asd":2000, "bar":19, "lol": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol2": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol3": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol4": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol5": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol6": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol7": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh"},
				{"asd":2000, "bar":19, "lol": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol2": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol3": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol4": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol5": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol6": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol7": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh", "lol8": "hedfsdfslkhlaskdjdhlakjhfslkjhfdslkdjfhlkjdshfhheheheheh"},*/
				];
			  
const queriesNested = [
				{"lol": "hedfsdfslkhlaskdhheheheheh"},
				{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh"}},
				{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh"}}},
				{"lol": "hedfsdfslkhlaskdhheheheheh"," foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh"}}}},
				{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo2":{"lol": "hedfsdfslkhlaskdhheheheheh"}}}}},
				{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo2":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo3":{"lol": "hedfsdfslkhlaskdhheheheheh"}}}}}},
				{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo2":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo3":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo4":{"lol": "hedfsdfslkhlaskdhheheheheh"}}}}}}},
				{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo2":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo3":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo4":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo5":{"lol": "hedfsdfslkhlaskdhheheheheh"}}}}}}}},
				{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo2":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo3":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo4":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo5":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo6":{"lol": "hedfsdfslkhlaskdhheheheheh"}}}}}}}}},
				/*{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo2":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo3":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo4":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo5":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo6":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo7":{"lol": "hedfsdfslkhlaskdhheheheheh"}}}}}}}}}},
				{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo2":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo3":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo4":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo5":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo6":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo7":{"lol": "hedfsdfslkhlaskdhheheheheh", "foo8":{"lol": "hedfsdfslkhlaskdhheheheheh"}}}}}}}}}}}*/
              ];

function unlockAccount(){
    var accounts = web3.eth.accounts;
    var passPhrase = "aaa";
    web3.personal.unlockAccount(accounts[0], passPhrase);
}

function loadContractsInformations() {
	return jsonfile.readFileSync("./test/databases.json");
}

function buildDBContract(dbInfos) {
	var db = web3.eth.contract(dbInfos["abi"]);
	return db.at(dbInfos["address"]);
}

function InsertCostTest(db, collectionName, type) {
	console.log('------------ Insertion of plain document Test ' + type + ' ------------');

  queriesPlain.forEach((q, index) => {
    var hexQ = hexStringToHexArray(bson.serialize(q).toString('hex'));

  	var myCallData = db.queryInsert.getData(collectionName, hexQ, "0x00000000000000000000000");
  	var estimate = web3.eth.estimateGas({data: myCallData, to: db.address});

  	console.log('    Estimated gas to insert ' + hexQ.length + ' bytes = ' + estimate);
  });
}

function InsertNestedCostTest(db, collectionName, type) {
	console.log('------------ Insertion of nested document Test ' + type + ' ------------');

  queriesNested.forEach((q, index) => {
    var hexQ = hexStringToHexArray(bson.serialize(q).toString('hex'));

  	var myCallData = db.queryInsert.getData(collectionName, hexQ, "0x000000000000000000000000");
  	var estimate = web3.eth.estimateGas({data: myCallData, to: db.address});

  	console.log('    Estimated gas to insert ' + hexQ.length + ' bytes in ' + (getDepth(q) - 1) +' nested documents = ' + estimate);
  });
}

function getDepth (jsonObj) {
	var level = 1;
    var key;
    for(key in jsonObj) {
        if (!jsonObj.hasOwnProperty(key)) continue;

        if(typeof jsonObj[key] == 'object'){
            var depth = getDepth(jsonObj[key]) + 1;
            level = Math.max(depth, level);
        }
    }
    return level;
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
	var dbVerboseInstance = buildDBContract(compiledConstracts["database_verbose"]);
	
	InsertCostTest(dbInstance, "a", "NON-VERBOSE");
	InsertCostTest(dbVerboseInstance, "a", "VERBOSE");
	
	InsertNestedCostTest(dbInstance, "a", "NON-VERBOSE");
	InsertNestedCostTest(dbVerboseInstance, "a", "VERBOSE");
}

main();
