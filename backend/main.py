from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import List, Optional
import httpx
import json

# İşte Python'ın aradığı ve @app'i tanımlayan o kritik satır:
app = FastAPI()

class MessageItem(BaseModel):
    role: str
    content: str
    images: Optional[List[str]] = None

class ChatRequest(BaseModel):
    messages: List[MessageItem]

OLLAMA_URL = "http://localhost:11434/api/chat"

@app.post("/solve-math")
async def solve_math(request: ChatRequest):
    
    async def stream_generator():
        # YENİ: YAPAY ZEKANIN BEYNİNE KAZIDIĞIMIZ SİSTEM MESAJI (KİŞİLİK)
        formatted_messages =[
            {
                "role": "system",
                "content": "RULE 1: No matter which language the user writes in, or the language of the text in any image they provide, you must respond strictly in that same language. RULE 2: Your explanations should be clear, friendly, and grammatically correct in that language."
            }
        ]
        
        # Flutter'dan gelen mesajları sistem mesajının altına ekliyoruz
        for msg in request.messages:
            msg_dict = {"role": msg.role, "content": msg.content}
            if msg.images: 
                msg_dict["images"] = msg.images
            formatted_messages.append(msg_dict)
            
        payload = {
            "model": "qwen3-vl:8b", 
            "messages": formatted_messages, # En üstte sistem kuralları, altında sohbet geçmişi var!
            "stream": True,
            "options": {
                "num_ctx": 16384, 
                "num_gpu": -1
            }
        }
        
        async with httpx.AsyncClient() as client:
            async with client.stream("POST", OLLAMA_URL, json=payload, timeout=None) as response:
                async for chunk in response.aiter_bytes():
                    yield chunk

    return StreamingResponse(stream_generator(), media_type="application/x-ndjson")