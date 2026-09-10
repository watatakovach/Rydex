"""add rydex settings tables

Revision ID: xxxxxxxx
Revises: 0d580ed97900
Create Date: 2026-08-07
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision: str = "xxxxxxxx"
revision: str = "5719de33d0a6"
down_revision: Union[str, Sequence[str], None] = "0d580ed97900"
branch_labels = None
depends_on = None


def upgrade() -> None:

    op.create_table(
        "general_settings",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("company_name", sa.String(150), nullable=False, server_default="RYDEX"),
        sa.Column("company_email", sa.String(150)),
        sa.Column("company_phone", sa.String(50)),
        sa.Column("company_address", sa.String(255)),
        sa.Column("website", sa.String(255)),
        sa.Column("logo", sa.String(255)),
        sa.Column("timezone", sa.String(100), server_default="Africa/Nairobi"),
        sa.Column("language", sa.String(50), server_default="English"),
        sa.Column("currency", sa.String(10), server_default="KES"),
        sa.Column("currency_symbol", sa.String(10), server_default="KSh"),
        sa.Column("distance_unit", sa.String(20), server_default="Kilometers"),
        sa.Column("date_format", sa.String(30), server_default="dd/MM/yyyy"),
        sa.Column("time_format", sa.String(10), server_default="24 Hour"),
        sa.Column("maintenance_mode", sa.Boolean(), server_default="false"),
        sa.Column("registration_enabled", sa.Boolean(), server_default="true"),
        sa.Column(
            "driver_registration_enabled",
            sa.Boolean(),
            server_default="true",
        ),
        sa.Column(
            "passenger_registration_enabled",
            sa.Boolean(),
            server_default="true",
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
        ),
    )


    op.create_index(
        "ix_general_settings_id",
        "general_settings",
        ["id"],
    )


def downgrade() -> None:

    op.drop_index(
        "ix_general_settings_id",
        table_name="general_settings",
    )

    op.drop_table("general_settings")