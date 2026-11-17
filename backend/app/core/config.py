from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    DATABASE_URL: str

    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    PAYPACK_CLIENT_ID: str = "d10f09aa-e28b-11f1-86ae-00163ea80869"
    PAYPACK_CLIENT_SECRET: str = "0d9db74f9a68eb60e530b702ce64fb5dda39a3ee5e6b4b0d3255bfef95601890afd80709"
    PAYPACK_WEBHOOK_SECRET: str = "0d9db74f9a68eb60e530b702ce64fb5dda39a3ee5e6b4b0d3255bfef95601890afd80709"
    PAYPACK_BASE_URL: str = "https://payments.paypack.rw/api"

    WEBHOOK_SIGNING_SECRET: str = "twende_webhook_secret_key"

    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore"
    )


settings = Settings()
