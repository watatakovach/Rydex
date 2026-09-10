
"""add driver profile vehicle and location fields

Revision ID: 50ca14afba3f
Revises: 50be9fcabda4
Create Date: 2026-07-28

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "50ca14afba3f"
down_revision: Union[str, Sequence[str], None] = "50be9fcabda4"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Add missing driver fields."""

    op.add_column(
        "drivers",
        sa.Column("vehicle_make", sa.String(length=100), nullable=True),
    )

    op.add_column(
        "drivers",
        sa.Column("vehicle_model", sa.String(length=100), nullable=True),
    )

    op.add_column(
        "drivers",
        sa.Column("vehicle_color", sa.String(length=50), nullable=True),
    )

    op.add_column(
        "drivers",
        sa.Column("vehicle_plate", sa.String(length=30), nullable=True),
    )

    op.add_column(
        "drivers",
        sa.Column("profile_photo", sa.String(), nullable=True),
    )

    op.add_column(
        "drivers",
        sa.Column("vehicle_photo", sa.String(), nullable=True),
    )

    op.add_column(
        "drivers",
        sa.Column("latitude", sa.Float(), nullable=True),
    )

    op.add_column(
        "drivers",
        sa.Column("longitude", sa.Float(), nullable=True),
    )

    op.add_column(
        "drivers",
        sa.Column(
            "location_updated_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
    )


def downgrade() -> None:
    """Remove driver profile, vehicle and location fields."""

    op.drop_column("drivers", "location_updated_at")
    op.drop_column("drivers", "longitude")
    op.drop_column("drivers", "latitude")
    op.drop_column("drivers", "vehicle_photo")
    op.drop_column("drivers", "profile_photo")
    op.drop_column("drivers", "vehicle_plate")
    op.drop_column("drivers", "vehicle_color")
    op.drop_column("drivers", "vehicle_model")
    op.drop_column("drivers", "vehicle_make")

