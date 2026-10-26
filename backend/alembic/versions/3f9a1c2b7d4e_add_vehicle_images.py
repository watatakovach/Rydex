"""add vehicle images

Revision ID: 3f9a1c2b7d4e
Revises: 11ef77016007
Create Date: 2026-10-26 09:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '3f9a1c2b7d4e'
down_revision: Union[str, Sequence[str], None] = '11ef77016007'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        'vehicle_images',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('vehicle_id', sa.Integer(), nullable=False),
        sa.Column('file_path', sa.String(length=255), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['vehicle_id'], ['vehicles.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_vehicle_images_id'), 'vehicle_images', ['id'], unique=False)
    op.create_index(op.f('ix_vehicle_images_vehicle_id'), 'vehicle_images', ['vehicle_id'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_vehicle_images_vehicle_id'), table_name='vehicle_images')
    op.drop_index(op.f('ix_vehicle_images_id'), table_name='vehicle_images')
    op.drop_table('vehicle_images')
