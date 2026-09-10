"""remove legacy admin settings

Revision ID: <KEEP_GENERATED_ID>
Revises: abef1a2e60dd
"""

from typing import Sequence, Union

from alembic import op


revision: str = "ace8d3583f02"
down_revision: Union[str, Sequence[str], None] = "abef1a2e60dd"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.drop_table("admin_settings")


def downgrade() -> None:
    raise NotImplementedError(
        "The legacy admin_settings table was removed "
        "because it has been replaced by the RYDEX settings tables."
    )