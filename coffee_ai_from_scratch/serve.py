#!/usr/bin/env python3
"""Line-oriented inference service for the Talla backend."""

import json
import sys
from pathlib import Path

import torch

from model import CoffeeTransformer
from tokenizer import CharTokenizer


ROOT = Path(__file__).resolve().parent
tokenizer = CharTokenizer.load(ROOT / "data/tokenizer.json")
checkpoint = torch.load(ROOT / "coffee_ai.pt", map_location="cpu")
model = CoffeeTransformer(**checkpoint["config"])
model.load_state_dict(checkpoint["model"])
model.eval()


def generate(question: str, context: str = "") -> str:
    prompt = f"\nUser: {question}\nCoffee AI:"
    if context:
        prompt = f"\nUser context: {context}\n" + prompt
    ids = torch.tensor([tokenizer.encode(prompt)], dtype=torch.long)
    with torch.no_grad():
        output = model.generate(ids, max_new_tokens=400, temperature=0.2)[0].tolist()
    answer = tokenizer.decode(output[len(ids[0]) :])
    for marker in ("\nUser:", "\n\nUser:"):
        if marker in answer:
            answer = answer.split(marker, 1)[0]
    return answer.strip()


for line in sys.stdin:
    try:
        request = json.loads(line)
        question = str(request.get("question", "")).strip()
        context = str(request.get("context", "")).strip()[:4000]
        if not question:
            raise ValueError("question is required")
        print(json.dumps({"answer": generate(question, context)}, ensure_ascii=False), flush=True)
    except Exception as error:
        print(json.dumps({"error": str(error)}), flush=True)
