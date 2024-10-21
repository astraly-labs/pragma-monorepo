const fs = require("fs");
const solc = require("solc");
const path = require("path");

/**
 * Generate ABI files for the given contracts and save them in the `abis` directory.
 * Creates the `abis` directory if it does not exist.
 *
 * @param contracts List of file names assuming each contract is in the file with the same name.
 */
function generateAbi(contracts) {
  var sources = {};
  var outputSelection = {};
  const remappingsPath = "remappings.txt";
  const remappings = fs.existsSync(remappingsPath)
    ? fs
        .readFileSync(remappingsPath, "utf8")
        .split("\n")
        .filter((line) => line.trim() !== "")
    : [];
  for (let contract of contracts) {
    const contractFile = `${contract}.sol`;
    sources[contractFile] = {
      content: fs.readFileSync(contractFile).toString(),
    };
    outputSelection[contractFile] = {};
    outputSelection[contractFile][contract] = ["abi"];
  }
  var input = {
    language: "Solidity",
    sources,
    settings: {
      outputSelection,
      remappings: remappings,
    },
  };

  function findImports(path) {
    return {
      contents: fs.readFileSync(path).toString(),
    };
  }

  const output = JSON.parse(
    solc.compile(JSON.stringify(input), { import: findImports }),
  );
  console.log(output);

  if (!fs.existsSync("abis")) {
    fs.mkdirSync("abis");
  }

  for (let contract of contracts) {
    const trimedContract = contract.split("/").pop();
    const contractFile = `${trimedContract}.sol`;

    const abi = output.contracts[contractFile][trimedContract].abi;
    fs.writeFileSync(
      `abis/${trimedContract}.json`,
      JSON.stringify(abi, null, 2) + "\n",
    );
  }
}

module.exports = { generateAbi };
