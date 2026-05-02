// Test fixture: Anchor 0.29 TypeScript patterns (should match migration rules)
// Also includes correct 0.30 patterns (should NOT match) for false-positive testing.

// === M-TS-001: AnchorProvider with 3 args (empty opts) ===
// 0.29 pattern - SHOULD MATCH
const provider029 = new AnchorProvider(connection, wallet, {});

// Correct 0.30 pattern - should NOT match
const provider030 = new AnchorProvider(connection, wallet);

// === M-TS-002: Program with programId argument ===
// 0.29 pattern - SHOULD MATCH
const program029 = new Program(idl, programId);
const program029WithConstId = new Program(idl, PROGRAM_ID);
const program029WithProvider = new Program(idl, programId, provider);
const program029WithConstProvider = new Program(idl, PROGRAM_ID, provider);

// Correct 0.30 pattern - should NOT match
const program030 = new Program(idl);

// === M-TS-003: .accounts() with resolvable accounts (systemProgram, etc.) ===
// 0.29 pattern - SHOULD MATCH (these auto-accounts are resolved implicitly in 0.30)
await program029.methods
  .initialize()
  .accounts({
    systemProgram: anchor.web3.SystemProgram.programId,
    clock: anchor.web3.SYSVAR_CLOCK_PUBKEY,
    rent: anchor.web3.SYSVAR_RENT_PUBKEY,
    tokenProgram: TokenProgramId,
  })
  .rpc();

// === M-TS-004: snake_case method names (should be camelCase in 0.30) ===
// 0.29 pattern - SHOULD MATCH
await program029.methods.initialize_user().accounts({}).rpc();
await program029.methods.create_account().accounts({}).rpc();

// === M-TS-005: discriminator function usage ===
// 0.29 pattern - SHOULD MATCH (discriminator functions removed in 0.30)
const accountDiscriminator = program029.account.myAccount.discriminator;
const instructionDiscriminator = program029.instruction.createAccount.discriminator;

// === M-TS-006: associated / associatedAddress methods ===
// 0.29 pattern - SHOULD MATCH (removed in 0.30)
const associated = program029.account.myAccount.associated(wallet.publicKey);
const associatedAddr = program029.account.myAccount.associatedAddress(wallet.publicKey);

// === M-TS-007: anchor-deprecated-state feature (package.json reference) ===
// This would be in package.json, not in .ts files
// Flagged for AI step to check package.json

// === Edge cases that should NOT match ===

// Provider with non-empty opts (not the simple {} case)
const customProvider = new AnchorProvider(
  connection,
  wallet,
  { preflightCommitment: 'confirmed', commitment: 'confirmed' }
);

// Already-migrated code (0.30 style) - should NOT match
await program030.methods
  .initializeUser()
  .accounts({ user: userPubkey })
  .rpc();

// Regular .accounts() call with non-auto accounts should NOT match
await program030.methods
  .transfer()
  .accounts({
    from: fromPubkey,
    to: toPubkey,
  })
  .rpc();

// Non-accounts object argument should NOT match auto-accounts rules
someHelperCall({
  systemProgram: anchor.web3.SystemProgram.programId,
});
