"""add_driver_ratings

Revision ID: 0d580ed97900
Revises: 9c8b1a72d4e6
Create Date: 2026-08-06 18:01:56.552279

"""

from typing import Sequence, Union

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0d580ed97900"
down_revision: Union[str, Sequence[str], None] = "9c8b1a72d4e6"
branch_labels = None
depends_on = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass