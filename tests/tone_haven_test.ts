import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can register new piece",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const title = "My First Song";
        const ipfsHash = "QmXyZ123...";
        const licenseType = "standard";
        const price = 100;

        let block = chain.mineBlock([
            Tx.contractCall('tone-haven', 'register-piece', [
                types.utf8(title),
                types.ascii(ipfsHash),
                types.ascii(licenseType),
                types.uint(price)
            ], deployer.address)
        ]);

        block.receipts[0].result.expectOk().expectUint(0);
    }
});

Clarinet.test({
    name: "Can purchase license for piece",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user = accounts.get('wallet_1')!;
        
        // First register a piece
        let block1 = chain.mineBlock([
            Tx.contractCall('tone-haven', 'register-piece', [
                types.utf8("Test Song"),
                types.ascii("QmTest123"),
                types.ascii("standard"),
                types.uint(100)
            ], deployer.address)
        ]);

        // Then purchase license
        let block2 = chain.mineBlock([
            Tx.contractCall('tone-haven', 'purchase-license', [
                types.uint(0)
            ], user.address)
        ]);

        block2.receipts[0].result.expectOk().expectBool(true);
        
        // Verify license
        let block3 = chain.mineBlock([
            Tx.contractCall('tone-haven', 'check-license', [
                types.uint(0),
                types.principal(user.address)
            ], user.address)
        ]);

        block3.receipts[0].result.expectOk().expectSome();
    }
});

Clarinet.test({
    name: "Can like a piece",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user = accounts.get('wallet_1')!;

        // Register piece
        let block1 = chain.mineBlock([
            Tx.contractCall('tone-haven', 'register-piece', [
                types.utf8("Like Test Song"),
                types.ascii("QmTest123"),
                types.ascii("standard"),
                types.uint(100)
            ], deployer.address)
        ]);

        // Like the piece
        let block2 = chain.mineBlock([
            Tx.contractCall('tone-haven', 'like-piece', [
                types.uint(0)
            ], user.address)
        ]);

        block2.receipts[0].result.expectOk().expectBool(true);
        
        // Check stats
        let block3 = chain.mineBlock([
            Tx.contractCall('tone-haven', 'get-piece-stats', [
                types.uint(0)
            ], user.address)
        ]);

        const stats = block3.receipts[0].result.expectOk().expectSome();
        assertEquals(stats.likes, types.uint(1));
    }
});