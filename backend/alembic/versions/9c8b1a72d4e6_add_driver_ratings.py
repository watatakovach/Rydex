"""add driver ratings

Revision ID: 9c8b1a72d4e6
Revises: 131c554e2c78
Create Date: 2026-08-05 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "9c8b1a72d4e6"
down_revision: Union[str, Sequence[str], None] = "131c554e2c78"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "driver_ratings",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("ride_id", sa.Integer(), nullable=False),
        sa.Column("passenger_id", sa.Integer(), nullable=False),
        sa.Column("driver_id", sa.Integer(), nullable=False),
        sa.Column("rating", sa.Integer(), nullable=False),
        sa.Column("comment", sa.String(length=500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["driver_id"], ["drivers.id"]),
        sa.ForeignKeyConstraint(["passenger_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["ride_id"], ["rides.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("ride_id", name="uq_driver_ratings_ride_id"),
    )
    op.create_index(
        op.f("ix_driver_ratings_created_at"),
        "driver_ratings",
        ["created_at"],
        unique=False,
    )
    op.create_index(
        op.f("ix_driver_ratings_driver_id"),
        "driver_ratings",
        ["driver_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_driver_ratings_id"),
        "driver_ratings",
        ["id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_driver_ratings_passenger_id"),
        "driver_ratings",
        ["passenger_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_driver_ratings_rating"),
        "driver_ratings",
        ["rating"],
        unique=False,
    )
    op.create_index(
        op.f("ix_driver_ratings_ride_id"),
        "driver_ratings",
        ["ride_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_driver_ratings_ride_id"),
        table_name="driver_ratings",
    )
    op.drop_index(
        op.f("ix_driver_ratings_rating"),
        table_name="driver_ratings",
    )
    op.drop_index(
        op.f("ix_driver_ratings_passenger_id"),
        table_name="driver_ratings",
    )
    op.drop_index(
        op.f("ix_driver_ratings_id"),
        table_name="driver_ratings",
    )
    op.drop_index(
        op.f("ix_driver_ratings_driver_id"),
        table_name="driver_ratings",
    )
    op.drop_index(
        op.f("ix_driver_ratings_created_at"),
        table_name="driver_ratings",
    )
    op.drop_table("driver_ratings")
