"""init

Revision ID: c6b6fb03f1c5
Revises: 
Create Date: 2025-05-10 20:06:14.005231
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'c6b6fb03f1c5'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('identifiers',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('Identifier', sa.Text(), nullable=False),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_identifiers_id'), 'identifiers', ['id'], unique=False)
    op.create_table('user',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('username', sa.String(), nullable=True),
    sa.Column('email', sa.String(), nullable=True),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_user_email'), 'user', ['email'], unique=True)
    op.create_index(op.f('ix_user_id'), 'user', ['id'], unique=False)
    op.create_index(op.f('ix_user_username'), 'user', ['username'], unique=True)
    op.create_table('files',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('Identifier_field', sa.Integer(), nullable=True),
    sa.Column('content', sa.String(), nullable=False),
    sa.ForeignKeyConstraint(['Identifier_field'], ['identifiers.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_files_id'), 'files', ['id'], unique=False)
    op.create_table('passes',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('Identifier_field', sa.Integer(), nullable=True),
    sa.Column('transformpass', sa.Text(), nullable=False),
    sa.ForeignKeyConstraint(['Identifier_field'], ['identifiers.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_passes_id'), 'passes', ['id'], unique=False)
    # ### end Alembic commands ###

def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_index(op.f('ix_passes_id'), table_name='passes')
    op.drop_table('passes')
    op.drop_index(op.f('ix_files_id'), table_name='files')
    op.drop_table('files')
    op.drop_index(op.f('ix_user_username'), table_name='user')
    op.drop_index(op.f('ix_user_id'), table_name='user')
    op.drop_index(op.f('ix_user_email'), table_name='user')
    op.drop_table('user')
    op.drop_index(op.f('ix_identifiers_id'), table_name='identifiers')
    op.drop_table('identifiers')
    # ### end Alembic commands ###
