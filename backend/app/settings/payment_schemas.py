from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class PaymentSettingsBase(BaseModel):
    currency: str = "KES"
    currency_symbol: str = "KSh"

    # Payment Methods
    cash_enabled: bool = True
    mpesa_enabled: bool = True
    card_enabled: bool = False
    wallet_enabled: bool = True

    # Commission
    driver_commission_percentage: float = Field(
        default=20.0,
        ge=0,
        le=100,
    )

    platform_fee_percentage: float = Field(
        default=0.0,
        ge=0,
        le=100,
    )

    tax_percentage: float = Field(
        default=0.0,
        ge=0,
        le=100,
    )

    # Wallet
    minimum_wallet_balance: float = 0
    maximum_wallet_balance: float = 100000

    # Transactions
    refund_enabled: bool = True
    automatic_payment_confirmation: bool = True
    payment_timeout_minutes: int = 15


class PaymentSettingsCreate(PaymentSettingsBase):
    pass


class PaymentSettingsUpdate(BaseModel):
    currency: str | None = None
    currency_symbol: str | None = None

    # Payment Methods
    cash_enabled: bool | None = None
    mpesa_enabled: bool | None = None
    card_enabled: bool | None = None
    wallet_enabled: bool | None = None

    # Commission
    driver_commission_percentage: float | None = Field(
        default=None,
        ge=0,
        le=100,
    )

    platform_fee_percentage: float | None = Field(
        default=None,
        ge=0,
        le=100,
    )

    tax_percentage: float | None = Field(
        default=None,
        ge=0,
        le=100,
    )

    # Wallet
    minimum_wallet_balance: float | None = None
    maximum_wallet_balance: float | None = None

    # Transactions
    refund_enabled: bool | None = None
    automatic_payment_confirmation: bool | None = None
    payment_timeout_minutes: int | None = None


class PaymentSettingsResponse(PaymentSettingsBase):
    id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True
    )