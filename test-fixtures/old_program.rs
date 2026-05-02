// Test fixture: realistic Anchor 0.29 Rust code for codemod validation

use anchor_lang::prelude::*;
use anchor_spl::token::{Token, TokenAccount, Mint};
use anchor_spl::shared_memory::program::id;
use anchor_syn::idl::types::IdlAccount;

declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

const CLOSED_DISC: [u8; 8] = anchor_lang::CLOSED_ACCOUNT_DISCRIMINATOR;

#[program]
pub mod my_program {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>, amount: u64) -> Result<()> {
        let bump: u8 = ctx.bumps.get("vault").unwrap();
        let other: u8 = ctx.bumps.get("state").unwrap();

        let state = &mut ctx.accounts.state;
        state.amount = amount;
        state.bump = bump;

        msg!("Initialized with amount: {}", amount);
        Ok(())
    }

    pub fn close_account(ctx: Context<CloseAccount>) -> Result<()> {
        msg!("Closing account");
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(
        init,
        payer = user,
        space = 8 + 8 + 1,
        seeds = [b"state", user.key().as_ref()],
        bump
    )]
    pub state: Account<'info, State>,
    #[account(mut)]
    pub user: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct CloseAccount<'info> {
    #[account(mut)]
    pub state: Account<'info, State>,
    #[account(mut)]
    pub user: Signer<'info>,
}

#[account]
pub struct State {
    pub amount: u64,
    pub bump: u8,
}
