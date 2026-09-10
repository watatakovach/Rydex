"""add ride lifecycle and admin audit fields

Revision ID: ebd5a4e402a6
Revises: 50be9fcabda4
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "ebd5a4e402a6"
down_revision: Union[str, Sequence[str], None] = "50be9fcabda4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "rides",
        sa.Column(
            "accepted_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
    )

    op.add_column(
        "rides",
        sa.Column(
            "started_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
    )

    op.add_column(
        "rides",
        sa.Column(
            "admin_note",
            sa.String(length=500),
            nullable=True,
        ),
    )

    op.add_column(
        "rides",
        sa.Column(
            "admin_action",
            sa.String(length=100),
            nullable=True,
        ),
    )

    op.add_column(
        "rides",
        sa.Column(
            "admin_id",
            sa.Integer(),
            nullable=True,
        ),
    )

    op.add_column(
        "rides",
        sa.Column(
            "admin_action_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
    )

    op.create_foreign_key(
        "fk_rides_admin_id_users",
        "rides",
        "users",
        ["admin_id"],
        ["id"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "fk_rides_admin_id_users",
        "rides",
        type_="foreignkey",
    )

    op.drop_column("rides", "admin_action_at")
    op.drop_column("rides", "admin_id")
    op.drop_column("rides", "admin_action")
    op.drop_column("rides", "admin_note")
    op.drop_column("rides", "started_at")
    op.drop_column("rides", "accepted_at")