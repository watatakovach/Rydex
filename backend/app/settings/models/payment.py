from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    Float,
    DateTime,
    func,
)

from app.database.database import Base



class PaymentSettings(Base):

    __tablename__ = "payment_settings"


    id = Column(
        Integer,
        primary_key=True,
        index=True
    )


    currency = Column(
        String(10),
        nullable=False,
        default="KES"
    )


    currency_symbol = Column(
        String(10),
        nullable=False,
        default="KSh"
    )


    # Payment Methods

    cash_enabled = Column(
        Boolean,
        default=True
    )


    mpesa_enabled = Column(
        Boolean,
        default=True
    )


    card_enabled = Column(
        Boolean,
        default=False
    )


    wallet_enabled = Column(
        Boolean,
        default=True
    )



    # Commission

    driver_commission_percentage = Column(
        Float,
        default=20.0
    )


    platform_fee_percentage = Column(
        Float,
        default=0.0
    )


    tax_percentage = Column(
        Float,
        default=0.0
    )



    # Wallet

    minimum_wallet_balance = Column(
        Float,
        default=0
    )


    maximum_wallet_balance = Column(
        Float,
        default=100000
    )



    # Transactions

    refund_enabled = Column(
        Boolean,
        default=True
    )


    automatic_payment_confirmation = Column(
        Boolean,
        default=True
    )


    payment_timeout_minutes = Column(
        Integer,
        default=15
    )



    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )


    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )