"""add missing general settings columns

Revision ID: abef1a2e60dd
Revises: 5719de33d0a6
Create Date: 2026-08-07 17:10:03.012657

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "abef1a2e60dd"
down_revision: Union[str, Sequence[str], None] = "5719de33d0a6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""

    # Admin settings timestamps
    op.add_column(
        "admin_settings",
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )

    op.add_column(
        "admin_settings",
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )

    # Existing rows need a default value
    op.add_column(
        "admin_settings",
        sa.Column(
            "platform_commission_percentage",
            sa.Float(),
            server_default="10",
            nullable=False,
        ),
    )

    # General settings additions
    op.add_column(
        "general_settings",
        sa.Column(
            "support_email",
            sa.String(length=150),
            nullable=True,
        ),
    )

    op.add_column(
        "general_settings",
        sa.Column(
            "support_phone",
            sa.String(length=50),
            nullable=True,
        ),
    )

    op.add_column(
        "general_settings",
        sa.Column(
            "app_version",
            sa.String(length=50),
            nullable=True,
        ),
    )


def downgrade() -> None:
    """Downgrade schema."""

    op.drop_column("general_settings", "app_version")
    op.drop_column("general_settings", "support_phone")
    op.drop_column("general_settings", "support_email")

    op.drop_column("admin_settings", "platform_commission_percentage")
    op.drop_column("admin_settings", "updated_at")
    op.drop_column("admin_settings", "created_at")