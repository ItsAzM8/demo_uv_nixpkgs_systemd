import os
import asyncio
from fastapi import FastAPI
from uvicorn import Config, Server

fast_api = FastAPI()


@fast_api.get("/")
async def root():
    var = os.getenv("UV_NIXPKGS_TEST_ENV")
    print(var)

    return {"message": "Hello World"}


async def main():
    server = Server(
        config=Config(app=fast_api))

    await server.serve()


def app():
    asyncio.run(main())


if __name__ == "__main__":
    app()
