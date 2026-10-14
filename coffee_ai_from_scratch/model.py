from __future__ import annotations

import torch
from torch import nn


class CoffeeTransformer(nn.Module):
    """Small decoder-only transformer for next-character prediction."""

    def __init__(self, vocab_size: int, block_size: int = 256, n_embd: int = 192, n_head: int = 6, n_layer: int = 4):
        super().__init__()
        self.block_size = block_size
        self.token_embedding = nn.Embedding(vocab_size, n_embd)
        self.position_embedding = nn.Embedding(block_size, n_embd)
        layer = nn.TransformerEncoderLayer(d_model=n_embd, nhead=n_head, dim_feedforward=4 * n_embd, batch_first=True, activation="gelu")
        self.blocks = nn.TransformerEncoder(layer, num_layers=n_layer)
        self.norm = nn.LayerNorm(n_embd)
        self.lm_head = nn.Linear(n_embd, vocab_size, bias=False)
        self.lm_head.weight = self.token_embedding.weight

    def forward(self, idx: torch.Tensor, targets: torch.Tensor | None = None):
        _, length = idx.shape
        if length > self.block_size:
            raise ValueError(f"sequence length {length} exceeds block size {self.block_size}")
        positions = torch.arange(length, device=idx.device)
        x = self.token_embedding(idx) + self.position_embedding(positions)[None, :, :]
        mask = torch.triu(torch.ones(length, length, device=idx.device, dtype=torch.bool), diagonal=1)
        x = self.blocks(x, mask=mask)
        logits = self.lm_head(self.norm(x))
        loss = None if targets is None else nn.functional.cross_entropy(logits.reshape(-1, logits.size(-1)), targets.reshape(-1))
        return logits, loss

    @torch.no_grad()
    def generate(self, idx: torch.Tensor, max_new_tokens: int = 300, temperature: float = 0.8):
        for _ in range(max_new_tokens):
            context = idx[:, -self.block_size :]
            logits, _ = self(context)
            logits = logits[:, -1, :] / max(temperature, 1e-4)
            probabilities = torch.softmax(logits, dim=-1)
            next_token = torch.multinomial(probabilities, num_samples=1)
            idx = torch.cat((idx, next_token), dim=1)
        return idx
