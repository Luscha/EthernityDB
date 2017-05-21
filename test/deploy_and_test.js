const fs = require('fs');
const solc = require('solc');
const Web3 = require('web3');

// Connect to local Ethereum node
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

const fee = 100000;

// Compiled Stuffs stuffs
var compiledConstracts = {}

// Database creation param
var databaseConstructorParam = {"name" : "Database di prova", "private" : true};

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
	else if (path === 'interfaces.sol')
		return { contents: fs.readFileSync('./interfaces.sol').toString() }
	else if (path === 'document.sol')
		return { contents: fs.readFileSync('./document.sol').toString() }
	else
		return { error: 'File not found' }
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
	
	console.log(' ---> Deploying and linking library ' + libraryName);
	
	var bytecodeLib = contracts[libraryName].bytecode;
	var abiLib = JSON.parse(contracts[libraryName].interface);
	var lib = web3.eth.contract(abiLib);
	
	var estimate = web3.eth.estimateGas({data: '0x' + bytecodeLib})
	console.log('Estimated gas to deploy ' + libraryName + ' = ' + estimate);
	
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
			console.log('Linking ' + libraryName + ' at ' + res.address);
			bytecode = linkLibrary(bytecode, libraryName, res.address);
			deployLibrary(bytecode, contracts, fallback);
		} else {
			// Log the tx, you can explore status with eth.getTransaction()
			console.log('Library transaction Hash ' + res.transactionHash);
		}
	});
}

function deployDriver(bytecode) {
	console.log('------------ Deploying Driver ------------');
	var driver = web3.eth.contract(compiledConstracts["driver"]["abi"]);
	compiledConstracts["driver"]["bytecode"] = bytecode;
	
	var estimate = web3.eth.estimateGas({data: '0x' + bytecode})
	console.log('Estimated gas to deploy Driver = ' + estimate);
	
	var driverInstance = driver.new({
		data: '0x' + bytecode,
		from: web3.eth.coinbase,
		gas: estimate + fee}, (err, res) => {
		if (err) {
			console.log(err);
			return;
		}
		
		if (res.address) {
			console.log('Mined Driver at ' + res.address);
			compiledConstracts["driver"]["address"] = res.address;
			compileAndDeployDB() 
		} else {
			console.log('Driver transaction Hash ' + res.transactionHash);
		}
	});
}

function deployDB(bytecode) {
	console.log('------------ Deploying Database ------------');
	var db = web3.eth.contract(compiledConstracts["database"]["abi"]);
	compiledConstracts["database"]["bytecode"] = bytecode;
	
	var dbBytecode = db.new.getData(databaseConstructorParam["name"], 
													databaseConstructorParam["private"],
													compiledConstracts["driver"]["address"],
													{data: '0x' + bytecode});
													
	compiledConstracts["database"]["bytecodeWithParam"] = bytecode;
													
	var estimate = web3.eth.estimateGas({data: dbBytecode});
	console.log('Estimated gas to deploy Database = ' + estimate);
	
	var dbInstance = db.new({
		data: dbBytecode,
		from: web3.eth.coinbase,
		gas: estimate + fee}, (err, res) => {
		if (err) {
			console.log(err);
			return;
		}
		
		if (res.address) {
			console.log('Mined Database at ' + res.address);
			compiledConstracts["database"]["address"] = res.address;
		} else {
			console.log('Database transaction Hash ' + res.transactionHash);
		}
	});
}

function compileAndDeployDriver() {
	var input = {
		'driver.sol' : fs.readFileSync('./driver.sol').toString(),	
	}
	
	var output = solc.compile({sources : input}, 1, findImports);
	
	var hasErrors = false;
	for (var error in output.errors) {
		console.log(output.errors[error]);
		hasErrors = true;
	}
	if (hasErrors) {
		return;
	}
	compiledConstracts["driver"] = {};
	compiledConstracts["driver"]["bytecode"] = output.contracts['driver.sol:Driver'].bytecode;
	compiledConstracts["driver"]["abi"] = JSON.parse(output.contracts['driver.sol:Driver'].interface);
	
	deployLibrary(compiledConstracts["driver"]["bytecode"], output.contracts, deployDriver);
	console.log('Waiting for links');
}

function compileAndDeployDB() {
	var input = {
		'database.sol' : fs.readFileSync('./database.sol').toString(),	
	}
	
	var output = solc.compile({sources : input}, 1, findImports);
	
	var hasErrors = false;
	for (var error in output.errors) {
		console.log(output.errors[error]);
		hasErrors = true;
	}
	if (hasErrors) {
		return;
	}
	compiledConstracts["database"] = {};
	compiledConstracts["database"]["bytecode"] = output.contracts['database.sol:Database'].bytecode;
	compiledConstracts["database"]["abi"] = JSON.parse(output.contracts['database.sol:Database'].interface);
	
	deployLibrary(compiledConstracts["database"]["bytecode"], output.contracts, deployDB);
	console.log('Waiting for links');
}

unlockAccount();
compileAndDeployDriver();