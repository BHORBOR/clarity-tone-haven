import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can register new piece with collaborators",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const collaborator1 = accounts.get('wallet_1')!;
        const collaborator2 = accounts.get('wallet_2')!;
        
        const title = "Collab Song";
        const ipfsHash = "QmXyZ123...";
        const licenseType = "standard";
        const price = 100;
        const collaborators = [
            {address: collaborator1.address, share: 20},
            {address: collaborator2.address, share: 30}
        ];

        let block = chain.mineBlock([
            Tx.contractCall('tone-haven', 'register-piece', [
                types.utf8(title),
                types.ascii(ipfsHash),
                types.ascii(licenseType),
                types.uint(price),
                types.list(collaborators.map(c => 
                    types.tuple({
                        address: types.principal(c.address),
                        share: types.uint(c.share)
                    })
                ))
            ], deployer.address)
        ]);

        block.receipts[0].result.expectOk().expectUint(0);
    }
});

Clarinet.test({
    name: "Can purchase license with royalty distribution",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const buyer = accounts.get('wallet_3')!;
        const collaborator1 = accounts.get('wallet_1')!;
        const collaborator2 = accounts.get('wallet_2')!;
        
        // Register piece with collaborators
        let block1 = chain.mineBlock([
            Tx.contractCall('tone-haven', 'register-piece', [
                types.utf8("Royalty Test"),
                types.ascii("QmTest123"),
                types.ascii("standard"),
                types.uint(1000),
                types.list([
                    types.tuple({
                        address: types.principal(collaborator1.address),
                        share: types.uint(20)
                    }),
                    types.tuple({
                        address: types.principal(collaborator2.address),
                        share: types.uint(30)
                    })
                ])
            ], deployer.address)
        ]);

        // Purchase license
        let block2 = chain.mineBlock([
            Tx.contractCall('tone-haven', 'purchase-license', [
                types.uint(0)
            ], buyer.address)
        ]);

        block2.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Prevents invalid royalty shares",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const collaborator1 = accounts.get('wallet_1')!;
        
        // Try to register with >100% total shares
        let block = chain.mineBlock([
            Tx.contractCall('tone-haven', 'register-piece', [
                types.utf8("Invalid Shares"),
                types.ascii("QmTest123"),
                types.ascii("standard"),
                types.uint(100),
                types.list([
                    types.tuple({
                        address: types.principal(collaborator1.address),
                        share: types.uint(101)
                    })
                ])
            ], deployer.address)
        ]);

        block.receipts[0].result.expectErr().expectUint(104);
    }
});
