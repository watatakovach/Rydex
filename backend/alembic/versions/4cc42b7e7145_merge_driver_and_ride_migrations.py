"""merge driver and ride migrations

Revision ID: 4cc42b7e7145
Revises: 50ca14afba3f, ebd5a4e402a6
Create Date: 2026-07-29 13:27:05.181011

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '4cc42b7e7145'
down_revision: Union[str, Sequence[str], None] = ('50ca14afba3f', 'ebd5a4e402a6')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
