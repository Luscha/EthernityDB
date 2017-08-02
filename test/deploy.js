const fs = require('fs');
const solc = require('solc');
const Web3 = require('web3');
const jsonfile = require('jsonfile')

// Connect to local Ethereum node
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

const fee = 100000;

// Compiled Stuffs stuffs
var compiledConstracts = {};
var compiledLibraries = {};
var gasSpent = 0;

// Database creation param
var databaseConstructorParam = {"name" : "Database di prova", "private" : true, "verbose" : true};

function unlockAccount(){
    var accounts = web3.eth.accounts;
    var passPhrase = "aaa";
    web3.personal.unlockAccount(accounts[0], passPhrase);
}

function findImports(path) {
	if (path === 'lib/stringUtils.sol')
		return { contents: fs.readFileSync('./lib/stringUtils.sol').toString() }
	else if (path === 'lib/treeflat.sol')
		return { contents: fs.readFileSync('./lib/treeflat.sol').toString() }
	else if (path === 'bson/documentparser.sol')
		return { contents: fs.readFileSync('./bson/documentparser.sol').toString() }
	else if (path === 'lib/bytesUtils.sol')
		return { contents: fs.readFileSync('./lib/bytesUtils.sol').toString() }
	else if (path === 'lib/flag.sol')
		return { contents: fs.readFileSync('./lib/flag.sol').toString() }
	else if (path === 'interfaces.sol')
		return { contents: fs.readFileSync('./interfaces.sol').toString() }
	else if (path === 'document.sol')
		return { contents: fs.readFileSync('./document.sol').toString() }
	else if (path === 'queryengine.sol')
		return { contents: fs.readFileSync('./queryengine.sol').toString() }
	else if (path === 'collection.sol')
		return { contents: fs.readFileSync('./collection.sol').toString() }
	else
		return { error: 'File not found' }
}

function printErrors(bytecode) {
	var hasErrors = false;
	for (var error in bytecode.formal.errors) {
		//console.log(bytecode.formal.errors[error]);
		hasErrors = true;
	}
	return false;
}

function linkLibrary(bytecode, libraryName, address) {
	var libLabel = '__' + libraryName + Array(39 - libraryName.length).join('_')
    var hexAddress = address.toString('hex')
    if (hexAddress.slice(0, 2) === '0x') {
      hexAddress = hexAddress.slice(2)
    }
    hexAddress = Array(40 - hexAddress.length + 1).join('0') + hexAddress
    while (bytecode.indexOf(libLabel) >= 0) {
      bytecode = bytecode.replace(libLabel, hexAddress)
    }
	return bytecode;
}

function deployLibrary(bytecode, contracts, fallback) {
	var m;
	if ((m = bytecode.match(/__([^_]{1,36})__/)) != null) {
		var libraryName = m[1];
	} else {
		fallback(bytecode);
		return;
	}

  if (!(libraryName in compiledLibraries)) {
    console.log('      ---> Deploying and linking library ' + libraryName);

  	var bytecodeLib = contracts[libraryName].bytecode;
  	var abiLib = JSON.parse(contracts[libraryName].interface);
  	var lib = web3.eth.contract(abiLib);

  	var estimate = web3.eth.estimateGas({data: '0x' + bytecodeLib})
  	console.log('      ---> Estimated gas to deploy ' + libraryName + ' = ' + estimate);
  	gasSpent += estimate + fee;

  	// Deploy contract instance
  	var libInstance = lib.new({
  		data: '0x' + bytecodeLib,
  		from: web3.eth.coinbase,
  		gas: estimate + fee}, (err, res) => {
  		if (err) {
  			console.log(err);
  			return;
  		}

  		// If we have an address property, the contract was deployed
  		if (res.address) {
  			console.log('      ---> Linking ' + libraryName + ' at ' + res.address);
  			bytecode = linkLibrary(bytecode, libraryName, res.address);
        compiledLibraries[libraryName] = res.address;
  			deployLibrary(bytecode, contracts, fallback);
  		} else {
  			// Log the tx, you can explore status with eth.getTransaction()
  			console.log('      ---> Library transaction Hash ' + res.transactionHash);
  		}
  	});
  } else {
    console.log('      ---> Linking precompiled ' + libraryName + ' at ' + compiledLibraries[libraryName]);
    bytecode = linkLibrary(bytecode, libraryName, compiledLibraries[libraryName]);
    deployLibrary(bytecode, contracts, fallback);
  }
}

function deployQueryEngine(bytecode) {
	console.log('------------ Deploying Query Engine ------------');
	var engine = web3.eth.contract(compiledConstracts["queryengine"]["abi"]);
	compiledConstracts["queryengine"]["bytecode"] = bytecode;

	var estimate = web3.eth.estimateGas({data: '0x' + bytecode})
	console.log('    > Estimated gas to deploy Query Engine = ' + estimate);
	gasSpent += estimate + fee;

	var engineInstance = engine.new({
		data: '0x' + bytecode,
		from: web3.eth.coinbase,
		gas: estimate + fee}, (err, res) => {
		if (err) {
			console.log(err);
			return;
		}

		if (res.address) {
			console.log('    >>> Mined Driver Query Engine ' + res.address + ' <<<\n');
			compiledConstracts["queryengine"]["address"] = res.address;
			compileDriver();
		} else {
			console.log('    Query Engine transaction Hash ' + res.transactionHash);
		}
	});
}

function deployDriver(bytecode) {
	console.log('------------ Deploying Driver ------------');
	var driver = web3.eth.contract(compiledConstracts["driver"]["abi"]);
	compiledConstracts["driver"]["bytecode"] = bytecode;

	var driverBytecode = driver.new.getData(
													compiledConstracts["queryengine"]["address"],
													{data: '0x' + bytecode});

	var estimate = web3.eth.estimateGas({data: '0x' + bytecode})
	console.log('    Estimated gas to deploy Driver = ' + estimate);
	gasSpent += estimate + fee;

	var driverInstance = driver.new({
		data: driverBytecode,
		from: web3.eth.coinbase,
		gas: estimate + fee}, (err, res) => {
		if (err) {
			console.log(err);
			return;
		}

		if (res.address) {
			console.log('    >>> Mined Driver at ' + res.address + ' <<<\n');
			compiledConstracts["driver"]["address"] = res.address;
			compileDB();
		} else {
			console.log('    Driver transaction Hash ' + res.transactionHash);
		}
	});
}

function deployDB(bytecode) {
	console.log('------------ Deploying Database ------------');
	var db = web3.eth.contract(compiledConstracts["database"]["abi"]);
	compiledConstracts["database"]["bytecode"] = bytecode;

	var dbBytecode = db.new.getData(databaseConstructorParam["name"],
													databaseConstructorParam["private"],
													databaseConstructorParam["verbose"],
													compiledConstracts["driver"]["address"],
													{data: '0x' + bytecode});

	var estimate = web3.eth.estimateGas({data: dbBytecode});
	console.log('    Estimated gas to deploy Database = ' + estimate);
	gasSpent += estimate + fee;

	var dbInstance = db.new({
		data: dbBytecode,
		from: web3.eth.coinbase,
		gas: estimate + fee}, (err, res) => {
		if (err) {
			console.log(err);
			return;
		}

		if (res.address) {
			console.log('    >>> Mined Database at ' + res.address + ' <<<\n');
			compiledConstracts["database"]["address"] = res.address;
			printTotalGas();
			exportContractJSON();
		} else {
			console.log('    Database transaction Hash ' + res.transactionHash);
		}
	});
}

function compileQueryEngine() {
	console.log('------------ Compiling Query Engine ------------');
	var input = {
		'queryengine.sol' : fs.readFileSync('./queryengine.sol').toString(),
	}

	var output = solc.compile({sources : input}, 1, findImports);

	if (true == printErrors(output)) {
		return;
	}
	compiledConstracts["queryengine"] = {};
	compiledConstracts["queryengine"]["bytecode"] = output.contracts['queryengine.sol:QueryEngine'].bytecode;
	compiledConstracts["queryengine"]["abi"] = JSON.parse(output.contracts['queryengine.sol:QueryEngine'].interface);

	console.log('    > Waiting for links');
	deployLibrary(compiledConstracts["queryengine"]["bytecode"], output.contracts, deployQueryEngine);
}

function compileDriver() {
	console.log('------------ Compiling Driver ------------');
	var input = {
		'driver.sol' : fs.readFileSync('./driver.sol').toString(),
	}

	var output = solc.compile({sources : input}, 1, findImports);

	if (true == printErrors(output)) {
		return;
	}
	compiledConstracts["driver"] = {};
	compiledConstracts["driver"]["bytecode"] = output.contracts['driver.sol:Driver'].bytecode;
	compiledConstracts["driver"]["abi"] = JSON.parse(output.contracts['driver.sol:Driver'].interface);

	console.log('    > Waiting for links');
	deployLibrary(compiledConstracts["driver"]["bytecode"], output.contracts, deployDriver);
}

function compileDB() {
	console.log('------------ Compiling Database ------------');
	var input = {
		'database.sol' : fs.readFileSync('./database.sol').toString(),
	}

	var output = solc.compile({sources : input}, 1, findImports);

	if (true == printErrors(output)) {
		return;
	}
	compiledConstracts["database"] = {};
	compiledConstracts["database"]["bytecode"] = output.contracts['database.sol:Database'].bytecode;
	compiledConstracts["database"]["abi"] = JSON.parse(output.contracts['database.sol:Database'].interface);
	
	compiledConstracts["collection"] = {};
	compiledConstracts["collection"]["bytecode"] = output.contracts['collection.sol:Collection'].bytecode;
	compiledConstracts["collection"]["abi"] = JSON.parse(output.contracts['collection.sol:Collection'].interface);

	console.log('    > Waiting for links');
	deployLibrary(compiledConstracts["database"]["bytecode"], output.contracts, deployDB);
}

function printTotalGas() {
	console.log('Total gas spent for the deploying:\n' + gasSpent.toLocaleString());
}

function exportContractJSON() {
  var usefullInfos = {"database": {"abi": compiledConstracts["database"]["abi"],"address": compiledConstracts["database"]["address"]},
                  "driver": {"abi": compiledConstracts["driver"]["abi"],"address": compiledConstracts["driver"]["address"]},
                  "queryengine": {"abi": compiledConstracts["queryengine"]["abi"],"address": compiledConstracts["queryengine"]["address"]},
				  "collection": {"abi": compiledConstracts["collection"]["abi"]}}
  jsonfile.writeFileSync("./test/contracts.json", usefullInfos, {spaces: 2})
}

unlockAccount();
compileQueryEngine();
