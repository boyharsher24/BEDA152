from fastapi import FastAPI
from fastapi.responses import HTMLResponse

app = FastAPI(title="Raskur")

PAGE = """<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Раскур удачный</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body {
            height: 100%;
            font-family: -apple-system, "Segoe UI", system-ui, sans-serif;
        }
        body {
            display: flex;
            align-items: center;
            justify-content: center;
            background: radial-gradient(circle at 30% 20%, #1b2a2a 0%, #0c1414 55%, #060a0a 100%);
            color: #e8fff5;
            overflow: hidden;
        }
        .card {
            text-align: center;
            padding: 3rem 4rem;
        }
        h1 {
            font-size: clamp(2.5rem, 8vw, 6rem);
            font-weight: 200;
            letter-spacing: 0.04em;
            background: linear-gradient(90deg, #6ee7b7, #a7f3d0, #6ee7b7);
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
            animation: glow 4s ease-in-out infinite;
        }
        .rule {
            width: 120px;
            height: 1px;
            margin: 1.6rem auto 0;
            background: rgba(110, 231, 183, 0.5);
        }
        @keyframes glow {
            0%, 100% { opacity: 0.85; filter: drop-shadow(0 0 12px rgba(110,231,183,0.25)); }
            50%      { opacity: 1;    filter: drop-shadow(0 0 28px rgba(110,231,183,0.55)); }
        }
    </style>
</head>
<body>
    <div class="card">
        <h1>Раскур удачный</h1>
        <div class="rule"></div>
    </div>
</body>
</html>
"""


@app.get("/", response_class=HTMLResponse)
async def index():
    return PAGE
