from sqlalchemy.orm import Session

from .crud import (
    get_settings,
    update_settings,
)

from .schemas import (
    GeneralSettingsUpdate,
)


class SettingsService:

    @staticmethod
    def get(db: Session):
        return get_settings(db)

    @staticmethod
    def update(
        db: Session,
        data: GeneralSettingsUpdate,
    ):
        return update_settings(db, data)