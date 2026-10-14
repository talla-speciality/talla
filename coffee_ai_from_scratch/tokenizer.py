from __future__ import annotations

import json
from pathlib import Path


class CharTokenizer:
    """Transparent character tokenizer: simple, inspectable, and dependency-free."""

    def __init__(self, text: str | None = None, vocab: list[str] | None = None):
        chars = sorted(set(text or "")) if vocab is None else vocab
        self.itos = ["<pad>", "<unk>"] + [c for c in chars if c not in {"<pad>", "<unk>"}]
        self.stoi = {ch: i for i, ch in enumerate(self.itos)}
        self.pad_id = self.stoi["<pad>"]
        self.unk_id = self.stoi["<unk>"]

    @property
    def vocab_size(self) -> int:
        return len(self.itos)

    def encode(self, text: str) -> list[int]:
        return [self.stoi.get(ch, self.unk_id) for ch in text]

    def decode(self, ids: list[int]) -> str:
        return "".join(self.itos[i] if 0 <= i < len(self.itos) else "" for i in ids if i > 1)

    def save(self, path: Path) -> None:
        path.write_text(json.dumps({"itos": self.itos}, ensure_ascii=False), encoding="utf-8")

    @classmethod
    def load(cls, path: Path) -> "CharTokenizer":
        return cls(vocab=json.loads(path.read_text(encoding="utf-8"))["itos"][2:])
