const express = require('express');
const app = express();
const { Gateway, Wallets } = require('fabric-network');
const path = require('path');
const fs = require('fs');

const ccpPath = path.resolve(__dirname, 'connection.json');
const walletPath = path.join(__dirname, 'wallet');

const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));

app.use(express.json());

app.post('/createWallet', async (req, res) => {
  try {
    const { identityLabel, certificatePath, privateKeyPath, mspId } = req.body;

    const certificate = fs.readFileSync(certificatePath).toString();
    const privateKey = fs.readFileSync(privateKeyPath).toString();

    const identity = {
      credentials: {
        certificate,
        privateKey,
      },
      mspId,
      type: 'X.509',
    };

    const wallet = await Wallets.newFileSystemWallet(walletPath);
    await wallet.put(identityLabel, identity);

    res.status(200).send(`Identity ${identityLabel} has been added to the wallet`);
  } catch (error) {
    console.error(error);
    res.status(500).send('Error creating wallet');
  }
});

app.post('/queryCar', async (req, res) => {
  try {
    const { carNumber, identityLabel } = req.body;

    
    const wallet = await Wallets.newFileSystemWallet(walletPath);
    const identity = await wallet.get(identityLabel);

    if (!identity) {
      return res.status(401).send(`Identity ${identityLabel} not found in the wallet`);
    }

    const gateway = new Gateway();
    await gateway.connect(ccp, { wallet, identity, discovery: { enabled: true, asLocalhost: true } });

    const network = await gateway.getNetwork('mychannel');
    const contract = network.getContract('fabcar');
    const result = await contract.evaluateTransaction('queryCar', carNumber);

    console.log(result.toString());

    await gateway.disconnect();

    res.status(200).send(result.toString());
  } catch (error) {
    console.error(error);
    res.status(500).send('Error querying car');
  }
});

app.post('/createCar', async (req, res) => {
    try {
      const {carNumber, make, model, color, owner, identityLabel } = req.body;
  
      const wallet = await Wallets.newFileSystemWallet(walletPath);
      const identity = await wallet.get(identityLabel);
  
      if (!identity) {
        return res.status(401).send(`Identity ${identityLabel} not found in the wallet`);
      }
    
      const gateway = new Gateway();
    await gateway.connect(ccp, { wallet, identity, discovery: { enabled: true, asLocalhost: true } });

    const network = await gateway.getNetwork('mychannel');
    const contract = network.getContract('fabcar');
  
      await contract.submitTransaction('createCar',carNumber, make, model, color, owner);
  
      res.status(200).send({ message: 'Car created successfully!' });
    } catch (error) {
      console.error(`Failed to create car: ${error}`);
      res.status(500).send({ message: 'Failed to create car' });
    }
  });

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server started on port ${PORT}`);
});
